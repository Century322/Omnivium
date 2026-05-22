import '../vocabulary/runtime_permission.dart';

enum TransportType { inProcess, isolate, wasm, http, websocket, mcp }

class CapabilityDeclaration {
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;
  final Map<String, dynamic> outputSchema;
  final String channel;
  final String permission;
  final bool isDestructive;
  final int timeoutMs;
  final int maxRetries;

  const CapabilityDeclaration({
    required this.id,
    required this.name,
    required this.description,
    this.inputSchema = const {},
    this.outputSchema = const {},
    this.channel = 'slow',
    this.permission = 'confirm',
    this.isDestructive = false,
    this.timeoutMs = 30000,
    this.maxRetries = 3,
  });
}

class PluginDependency {
  final String capabilityId;
  final String? minVersion;
  final bool optional;

  const PluginDependency({
    required this.capabilityId,
    this.minVersion,
    this.optional = false,
  });
}

class LifecycleConfig {
  final int loadTimeout;
  final int activateTimeout;
  final int suspendTimeout;
  final int unloadTimeout;
  final bool autoActivate;
  final bool keepAlive;

  const LifecycleConfig({
    this.loadTimeout = 10000,
    this.activateTimeout = 10000,
    this.suspendTimeout = 5000,
    this.unloadTimeout = 5000,
    this.autoActivate = true,
    this.keepAlive = false,
  });
}

class PluginMetadata {
  final String? icon;
  final String category;
  final List<String> tags;
  final String? homepage;
  final String? repository;
  final String license;
  final String minRuntimeVersion;

  const PluginMetadata({
    this.icon,
    this.category = 'general',
    this.tags = const [],
    this.homepage,
    this.repository,
    this.license = 'MIT',
    this.minRuntimeVersion = '1.0.0',
  });
}

class PluginDescriptor {
  final String id;
  final String name;
  final String version;
  final String description;
  final String author;
  final List<CapabilityDeclaration> capabilities;
  final RuntimePermission permissions;
  final IsolationLevel isolation;
  final List<PluginDependency> dependencies;
  final LifecycleConfig lifecycle;
  final PluginMetadata metadata;

  const PluginDescriptor({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    this.author = '',
    this.capabilities = const [],
    this.permissions = const RuntimePermission(),
    this.isolation = IsolationLevel.level0InProcess,
    this.dependencies = const [],
    this.lifecycle = const LifecycleConfig(),
    this.metadata = const PluginMetadata(),
  });

  List<String> get capabilityIds => capabilities.map((c) => c.id).toList();

  CapabilityDeclaration? capability(String id) {
    for (final c in capabilities) {
      if (c.id == id) return c;
    }
    return null;
  }
}
