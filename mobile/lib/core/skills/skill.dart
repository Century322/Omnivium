import 'dart:convert';
import '../agent/agent_state.dart';
import '../api_proxy_service.dart';
import '../app_logger.dart';

class SkillResult {
  final bool success;
  final dynamic data;
  final String? error;

  const SkillResult({required this.success, this.data, this.error});

  factory SkillResult.ok(dynamic data) =>
      SkillResult(success: true, data: data);
  factory SkillResult.fail(String error) =>
      SkillResult(success: false, error: error);
}

class SkillVersion {
  final int major;
  final int minor;
  final int patch;

  const SkillVersion({required this.major, this.minor = 0, this.patch = 0});

  factory SkillVersion.parse(String version) {
    final parts = version.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    return SkillVersion(
      major: parts.isNotEmpty ? parts[0] : 1,
      minor: parts.length > 1 ? parts[1] : 0,
      patch: parts.length > 2 ? parts[2] : 0,
    );
  }

  bool isCompatibleWith(SkillVersion required) {
    if (major != required.major) return false;
    if (minor < required.minor) return false;
    return true;
  }

  @override
  String toString() => '$major.$minor.$patch';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillVersion &&
          major == other.major &&
          minor == other.minor &&
          patch == other.patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);
}

abstract class Skill {
  String get id;
  String get name;
  String get description;
  IntentChannel get channel;
  PermissionLevel get permission;
  int get timeoutMs;
  int get maxRetries;
  bool get isDestructive;
  SkillVersion get version => const SkillVersion(major: 1, minor: 0, patch: 0);
  SkillVersion get minRequiredVersion =>
      const SkillVersion(major: 1, minor: 0, patch: 0);

  Future<SkillResult> execute(Map<String, dynamic> params);

  bool isCompatibleWith(SkillVersion appVersion) {
    return appVersion.isCompatibleWith(minRequiredVersion);
  }
}

class RemoteSkill extends Skill {
  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  final String endpoint;
  @override
  final SkillVersion version;

  @override
  IntentChannel get channel => IntentChannel.slow;
  @override
  PermissionLevel get permission => PermissionLevel.auto;
  @override
  int get timeoutMs => 30000;
  @override
  int get maxRetries => 1;
  @override
  bool get isDestructive => false;

  RemoteSkill({
    required this.id,
    required this.name,
    required this.description,
    required this.endpoint,
    this.version = const SkillVersion(major: 1),
  });

  @override
  Future<SkillResult> execute(Map<String, dynamic> params) async {
    try {
      final proxy = ApiProxyService.instance;
      if (!proxy.isConfigured)
        return SkillResult.fail('API proxy not configured');
      final uri = Uri.parse('${proxy.backendUrl}$endpoint');
      final response = await proxy.secureClient.post(
        uri,
        headers: {
          ...proxy.buildAuthHeaders(),
          ...proxy.buildDeviceHeaders(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode(params),
      );
      if (response.statusCode == 200) {
        return SkillResult.ok(response.body);
      }
      return SkillResult.fail('Remote skill failed: ${response.statusCode}');
    } catch (e, stackTrace) {
      AppLogger.instance.error(
        'Remote skill execute failed',
        error: e,
        stackTrace: stackTrace,
      );
      return SkillResult.fail(e.toString());
    }
  }
}
