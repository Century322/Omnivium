import 'wasm_bridge/api.dart';
import 'wasm_bridge/lib.dart' as bridge;
import 'wasm_bridge/frb_generated.dart';

class WasmSandboxService {
  static WasmSandboxService? _instance;
  bool _initialized = false;

  WasmSandboxService._();

  static WasmSandboxService get instance =>
      _instance ??= WasmSandboxService._();

  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    await RustLib.init();
    _initialized = true;
  }

  Future<WasmExecutionResult> execute({
    required List<int> wasmBytes,
    required String functionName,
    List<WasmParam> params = const [],
    int maxMemoryMb = 64,
    int maxExecutionTimeMs = 5000,
    int maxStackDepth = 100,
    List<String> allowedCapabilities = const ['storage.read', 'memory.read'],
  }) async {
    if (!_initialized) throw StateError('WasmSandboxService not initialized');

    final config = bridge.SandboxConfig(
      maxMemoryMb: maxMemoryMb,
      maxExecutionTimeMs: BigInt.from(maxExecutionTimeMs),
      maxStackDepth: maxStackDepth,
      allowedCapabilities: allowedCapabilities);

    final bridgeParams = params
        .map((p) => bridge.SandboxParam(kind: p.kind, value: p.value))
        .toList();

    final result = await sandboxExecute(
      wasmBytes: wasmBytes,
      functionName: functionName,
      params: bridgeParams,
      config: config);

    return WasmExecutionResult(
      success: result.success,
      output: result.output,
      executionTimeMs: result.executionTimeMs.toInt(),
      memoryUsedBytes: result.memoryUsedBytes.toInt(),
      error: result.error);
  }

  Future<bool> validate(List<int> wasmBytes) async {
    if (!_initialized) throw StateError('WasmSandboxService not initialized');
    return sandboxValidate(wasmBytes: wasmBytes);
  }

  Future<List<WasmExport>> listExports(List<int> wasmBytes) async {
    if (!_initialized) throw StateError('WasmSandboxService not initialized');
    final exports = await sandboxListExports(wasmBytes: wasmBytes);
    return exports.map((e) => WasmExport(name: e.name, kind: e.kind)).toList();
  }
}

class WasmParam {
  final String kind;
  final String value;

  const WasmParam({required this.kind, required this.value});
}

class WasmExecutionResult {
  final bool success;
  final String output;
  final int executionTimeMs;
  final int memoryUsedBytes;
  final String? error;

  const WasmExecutionResult({
    required this.success,
    required this.output,
    required this.executionTimeMs,
    required this.memoryUsedBytes,
    this.error,
  });
}

class WasmExport {
  final String name;
  final String kind;

  const WasmExport({required this.name, required this.kind});
}
