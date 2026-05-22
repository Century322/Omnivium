class SemanticVersion implements Comparable<SemanticVersion> {
  final int major;
  final int minor;
  final int patch;
  final String? preRelease;
  final String? buildMetadata;

  const SemanticVersion({
    required this.major,
    this.minor = 0,
    this.patch = 0,
    this.preRelease,
    this.buildMetadata,
  });

  static SemanticVersion parse(String version) {
    final parts = version.split('+');
    final buildMeta = parts.length > 1 ? parts[1] : null;
    final preParts = parts[0].split('-');
    final preRelease = preParts.length > 1 ? preParts[1] : null;
    final versionParts = preParts[0].split('.');

    return SemanticVersion(
      major: int.parse(versionParts[0]),
      minor: versionParts.length > 1 ? int.parse(versionParts[1]) : 0,
      patch: versionParts.length > 2 ? int.parse(versionParts[2]) : 0,
      preRelease: preRelease,
      buildMetadata: buildMeta,
    );
  }

  bool get isPreRelease => preRelease != null;
  bool get isStable => preRelease == null;

  bool isCompatibleWith(SemanticVersion other) => major == other.major;

  bool isBackwardCompatibleWith(SemanticVersion other) {
    if (major != other.major) return false;
    if (major == 0) return minor == other.minor && patch == other.patch;
    return minor >= other.minor;
  }

  @override
  int compareTo(SemanticVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator <(SemanticVersion other) => compareTo(other) < 0;
  bool operator <=(SemanticVersion other) => compareTo(other) <= 0;
  bool operator >(SemanticVersion other) => compareTo(other) > 0;
  bool operator >=(SemanticVersion other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemanticVersion &&
          major == other.major &&
          minor == other.minor &&
          patch == other.patch &&
          preRelease == other.preRelease;

  @override
  int get hashCode => Object.hash(major, minor, patch, preRelease);

  @override
  String toString() {
    var s = '$major.$minor.$patch';
    if (preRelease != null) s += '-$preRelease';
    if (buildMetadata != null) s += '+$buildMetadata';
    return s;
  }
}

enum DeprecationLevel {
  active,
  deprecated,
  removed,
}

class DeprecationNotice {
  final String id;
  final String feature;
  final SemanticVersion deprecatedIn;
  final SemanticVersion? removedIn;
  final String replacement;
  final String migrationGuide;
  final DeprecationLevel level;

  const DeprecationNotice({
    required this.id,
    required this.feature,
    required this.deprecatedIn,
    this.removedIn,
    required this.replacement,
    this.migrationGuide = '',
    this.level = DeprecationLevel.deprecated,
  });

  bool isRemovedIn(SemanticVersion version) =>
      removedIn != null && version >= removedIn!;

  bool isDeprecatedIn(SemanticVersion version) => version >= deprecatedIn;
}

class ProtocolVersion {
  final int major;
  final int minor;
  final String identifier;

  const ProtocolVersion({
    required this.major,
    required this.minor,
    this.identifier = '',
  });

  bool isCompatibleWith(ProtocolVersion other) => major == other.major;

  @override
  String toString() => '$major.$minor${identifier.isNotEmpty ? '-$identifier' : ''}';
}

class CapabilityVersion {
  final String capabilityId;
  final SemanticVersion version;
  final List<String> breakingChanges;
  final List<String> additions;

  const CapabilityVersion({
    required this.capabilityId,
    required this.version,
    this.breakingChanges = const [],
    this.additions = const [],
  });

  bool get hasBreakingChanges => breakingChanges.isNotEmpty;
}

class MigrationStep {
  final String fromVersion;
  final String toVersion;
  final String description;
  final List<String> actions;
  final bool isBreaking;

  const MigrationStep({
    required this.fromVersion,
    required this.toVersion,
    required this.description,
    this.actions = const [],
    this.isBreaking = false,
  });
}

class RuntimeVersionRegistry {
  final SemanticVersion runtimeVersion;
  final ProtocolVersion protocolVersion;
  final Map<String, CapabilityVersion> _capabilityVersions = {};
  final List<DeprecationNotice> _deprecations = [];
  final List<MigrationStep> _migrations = [];

  RuntimeVersionRegistry({
    required this.runtimeVersion,
    required this.protocolVersion,
  });

  static RuntimeVersionRegistry current() => RuntimeVersionRegistry(
        runtimeVersion: const SemanticVersion(major: 0, minor: 8, patch: 0),
        protocolVersion: const ProtocolVersion(major: 1, minor: 0),
      );

  void registerCapability(CapabilityVersion cap) {
    _capabilityVersions[cap.capabilityId] = cap;
  }

  void addDeprecation(DeprecationNotice notice) {
    _deprecations.add(notice);
  }

  void addMigration(MigrationStep step) {
    _migrations.add(step);
  }

  CapabilityVersion? capabilityVersion(String id) => _capabilityVersions[id];

  List<DeprecationNotice> get deprecations => List.unmodifiable(_deprecations);
  List<MigrationStep> get migrations => List.unmodifiable(_migrations);

  List<DeprecationNotice> activeDeprecations() =>
      _deprecations.where((d) => d.level == DeprecationLevel.deprecated).toList();

  List<DeprecationNotice> removedFeatures() =>
      _deprecations.where((d) => d.level == DeprecationLevel.removed).toList();

  bool isFeatureAvailable(String featureId, SemanticVersion targetVersion) {
    final dep = _deprecations.where((d) => d.feature == featureId).firstOrNull;
    if (dep == null) return true;
    return !dep.isRemovedIn(targetVersion);
  }

  bool isCapabilityCompatible(String capabilityId, SemanticVersion targetVersion) {
    final cap = _capabilityVersions[capabilityId];
    if (cap == null) return false;
    return cap.version.isBackwardCompatibleWith(targetVersion);
  }

  List<MigrationStep> migrationsBetween(SemanticVersion from, SemanticVersion to) {
    return _migrations
        .where((m) {
          final mFrom = SemanticVersion.parse(m.fromVersion);
          final mTo = SemanticVersion.parse(m.toVersion);
          return mFrom >= from && mTo <= to;
        })
        .toList();
  }

  CompatibilityResult checkCompatibility(RuntimeVersionRegistry other) {
    final issues = <CompatibilityIssue>[];

    if (!runtimeVersion.isCompatibleWith(other.runtimeVersion)) {
      issues.add(CompatibilityIssue(
        type: CompatibilityType.runtimeVersion,
        message: 'Runtime major version mismatch: $runtimeVersion vs ${other.runtimeVersion}',
        isBreaking: true,
      ));
    }

    if (!protocolVersion.isCompatibleWith(other.protocolVersion)) {
      issues.add(CompatibilityIssue(
        type: CompatibilityType.protocolVersion,
        message: 'Protocol major version mismatch: $protocolVersion vs ${other.protocolVersion}',
        isBreaking: true,
      ));
    }

    for (final cap in _capabilityVersions.values) {
      final otherCap = other._capabilityVersions[cap.capabilityId];
      if (otherCap == null) {
        issues.add(CompatibilityIssue(
          type: CompatibilityType.missingCapability,
          message: 'Capability ${cap.capabilityId} not found in remote',
          isBreaking: false,
        ));
      } else if (!cap.version.isBackwardCompatibleWith(otherCap.version)) {
        issues.add(CompatibilityIssue(
          type: CompatibilityType.capabilityVersion,
          message: 'Capability ${cap.capabilityId} version incompatible: ${cap.version} vs ${otherCap.version}',
          isBreaking: true,
        ));
      }
    }

    return CompatibilityResult(
      isCompatible: !issues.any((i) => i.isBreaking),
      issues: issues,
    );
  }
}

enum CompatibilityType {
  runtimeVersion,
  protocolVersion,
  capabilityVersion,
  missingCapability,
  deprecatedFeature,
}

class CompatibilityIssue {
  final CompatibilityType type;
  final String message;
  final bool isBreaking;

  const CompatibilityIssue({
    required this.type,
    required this.message,
    required this.isBreaking,
  });
}

class CompatibilityResult {
  final bool isCompatible;
  final List<CompatibilityIssue> issues;

  const CompatibilityResult({
    required this.isCompatible,
    required this.issues,
  });

  List<CompatibilityIssue> get breakingIssues =>
      issues.where((i) => i.isBreaking).toList();

  List<CompatibilityIssue> get warnings =>
      issues.where((i) => !i.isBreaking).toList();
}
