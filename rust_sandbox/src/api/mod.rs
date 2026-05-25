use crate::{SandboxConfig, SandboxExport, SandboxParam, SandboxResult, WasmSandbox};

pub fn sandbox_execute(
    wasm_bytes: Vec<u8>,
    function_name: String,
    params: Vec<SandboxParam>,
    config: Option<SandboxConfig>,
) -> SandboxResult {
    match WasmSandbox::new(config) {
        Ok(mut sandbox) => sandbox
            .execute(&wasm_bytes, &function_name, &params)
            .unwrap_or(SandboxResult {
                success: false,
                output: String::new(),
                execution_time_ms: 0,
                memory_used_bytes: 0,
                error: Some("Sandbox execution error".to_string()),
            }),
        Err(e) => SandboxResult {
            success: false,
            output: String::new(),
            execution_time_ms: 0,
            memory_used_bytes: 0,
            error: Some(format!("Sandbox creation failed: {}", e)),
        },
    }
}

pub fn sandbox_validate(wasm_bytes: Vec<u8>) -> bool {
    WasmSandbox::new(None)
        .and_then(|s| s.validate_module(&wasm_bytes))
        .unwrap_or(false)
}

pub fn sandbox_list_exports(wasm_bytes: Vec<u8>) -> Vec<SandboxExport> {
    WasmSandbox::new(None)
        .and_then(|s| s.list_exports(&wasm_bytes))
        .unwrap_or_default()
}
