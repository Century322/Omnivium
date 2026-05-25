mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */
mod api;

use anyhow::{anyhow, Result};
use serde::{Deserialize, Serialize};
use wasmtime::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SandboxConfig {
    pub max_memory_mb: u32,
    pub max_execution_time_ms: u64,
    pub max_stack_depth: u32,
    pub allowed_capabilities: Vec<String>,
}

impl Default for SandboxConfig {
    fn default() -> Self {
        Self {
            max_memory_mb: 64,
            max_execution_time_ms: 5000,
            max_stack_depth: 100,
            allowed_capabilities: vec!["storage.read".to_string(), "memory.read".to_string()],
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SandboxResult {
    pub success: bool,
    pub output: String,
    pub execution_time_ms: u64,
    pub memory_used_bytes: u64,
    pub error: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SandboxParam {
    pub kind: String,
    pub value: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SandboxExport {
    pub name: String,
    pub kind: String,
}

pub struct WasmSandbox {
    engine: Engine,
    config: SandboxConfig,
}

impl WasmSandbox {
    pub fn new(config: Option<SandboxConfig>) -> Result<Self> {
        let mut engine_config = Config::new();
        engine_config.cranelift_opt_level(OptLevel::Speed);
        engine_config.max_wasm_stack(1024 * 1024);
        engine_config.wasm_multi_memory(false);
        engine_config.wasm_threads(false);

        let engine = Engine::new(&engine_config)?;
        Ok(Self {
            engine,
            config: config.unwrap_or_default(),
        })
    }

    pub fn validate_module(&self, wasm_bytes: &[u8]) -> Result<bool> {
        Module::validate(&self.engine, wasm_bytes)
            .map(|_| true)
            .map_err(|e| anyhow!("Module validation failed: {}", e))
    }

    pub fn execute(
        &mut self,
        wasm_bytes: &[u8],
        function_name: &str,
        params: &[SandboxParam],
    ) -> Result<SandboxResult> {
        let start = std::time::Instant::now();

        let module = match Module::new(&self.engine, wasm_bytes) {
            Ok(m) => m,
            Err(e) => {
                return Ok(SandboxResult {
                    success: false,
                    output: String::new(),
                    execution_time_ms: start.elapsed().as_millis() as u64,
                    memory_used_bytes: 0,
                    error: Some(format!("Module compilation failed: {}", e)),
                });
            }
        };

        let mut store = Store::new(&self.engine, ());
        let memory = Memory::new(&mut store, MemoryType::new(1, Some(self.config.max_memory_mb)))
            .map_err(|e| anyhow!("Memory allocation failed: {}", e))?;

        let mut linker = Linker::new(&self.engine);
        linker
            .define(&store, "env", "memory", memory)
            .map_err(|e| anyhow!("Linker define failed: {}", e))?;

        linker
            .func_wrap("env", "sandbox_log", |_ptr: i32, _len: i32| {
            })
            .map_err(|e| anyhow!("Host function define failed: {}", e))?;

        let instance = match linker.instantiate(&mut store, &module) {
            Ok(inst) => inst,
            Err(e) => {
                return Ok(SandboxResult {
                    success: false,
                    output: String::new(),
                    execution_time_ms: start.elapsed().as_millis() as u64,
                    memory_used_bytes: 0,
                    error: Some(format!("Instantiation failed: {}", e)),
                });
            }
        };

        let func = match instance.get_func(&mut store, function_name) {
            Some(f) => f,
            None => {
                return Ok(SandboxResult {
                    success: false,
                    output: String::new(),
                    execution_time_ms: start.elapsed().as_millis() as u64,
                    memory_used_bytes: 0,
                    error: Some(format!("Function '{}' not found", function_name)),
                });
            }
        };

        let func_params: Vec<Val> = params.iter().map(|p| p.to_val()).collect();
        let mut results = vec![Val::I32(0); func.ty(&store).results().len()];

        match func.call(&mut store, &func_params, &mut results) {
            Ok(_) => {
                let output = results
                    .iter()
                    .map(|r| match r {
                        Val::I32(v) => v.to_string(),
                        Val::I64(v) => v.to_string(),
                        Val::F32(v) => f32::from_bits(*v).to_string(),
                        Val::F64(v) => f64::from_bits(*v).to_string(),
                        _ => String::from("?"),
                    })
                    .collect::<Vec<_>>()
                    .join(",");

                let mem_used = memory.data_size(&store) as u64;

                Ok(SandboxResult {
                    success: true,
                    output,
                    execution_time_ms: start.elapsed().as_millis() as u64,
                    memory_used_bytes: mem_used,
                    error: None,
                })
            }
            Err(e) => Ok(SandboxResult {
                success: false,
                output: String::new(),
                execution_time_ms: start.elapsed().as_millis() as u64,
                memory_used_bytes: memory.data_size(&store) as u64,
                error: Some(format!("Execution failed: {}", e)),
            }),
        }
    }

    pub fn list_exports(&self, wasm_bytes: &[u8]) -> Result<Vec<SandboxExport>> {
        let module = Module::new(&self.engine, wasm_bytes)?;
        let exports: Vec<SandboxExport> = module
            .exports()
            .map(|e| SandboxExport {
                name: e.name().to_string(),
                kind: match e.ty() {
                    ExternType::Func(_) => "function".to_string(),
                    ExternType::Table(_) => "table".to_string(),
                    ExternType::Memory(_) => "memory".to_string(),
                    ExternType::Global(_) => "global".to_string(),
                },
            })
            .collect();
        Ok(exports)
    }
}

impl SandboxParam {
    pub fn to_val(&self) -> Val {
        match self.kind.as_str() {
            "i32" => Val::I32(self.value.parse().unwrap_or(0)),
            "i64" => Val::I64(self.value.parse().unwrap_or(0)),
            "f32" => {
                let f: f32 = self.value.parse().unwrap_or(0.0);
                Val::F32(f.to_bits())
            }
            "f64" => {
                let f: f64 = self.value.parse().unwrap_or(0.0);
                Val::F64(f.to_bits())
            }
            _ => Val::I32(0),
        }
    }
}
