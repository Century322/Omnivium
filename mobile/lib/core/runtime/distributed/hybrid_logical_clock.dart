import 'package:freezed_annotation/freezed_annotation.dart';

part 'hybrid_logical_clock.freezed.dart';
part 'hybrid_logical_clock.g.dart';

@freezed
class HybridTimestamp with _$HybridTimestamp {
  const HybridTimestamp._();

  const factory HybridTimestamp({
    @JsonKey(name: 'pt') required int physicalTime,
    @JsonKey(name: 'lt') @Default(0) int logicalTime,
    @JsonKey(name: 'node') @Default('local') String nodeId,
  }) = _HybridTimestamp;

  int compareTo(HybridTimestamp other) {
    final ptCmp = physicalTime.compareTo(other.physicalTime);
    if (ptCmp != 0) return ptCmp;
    return logicalTime.compareTo(other.logicalTime);
  }

  bool isAfter(HybridTimestamp other) => compareTo(other) > 0;
  bool isBefore(HybridTimestamp other) => compareTo(other) < 0;
  bool isSameTimeAs(HybridTimestamp other) => compareTo(other) == 0;
  bool happensBefore(HybridTimestamp other) => isBefore(other);
  bool isConcurrentWith(HybridTimestamp other) =>
      !isBefore(other) && !isAfter(other) && nodeId != other.nodeId;

  factory HybridTimestamp.fromJson(Map<String, dynamic> json) =>
      _$HybridTimestampFromJson(json);
}

class HybridLogicalClock {
  int _physicalTime;
  int _logicalTime;
  final String _nodeId;

  HybridLogicalClock({required String nodeId, int? initialTime})
    : _nodeId = nodeId,
      _physicalTime = initialTime ?? DateTime.now().millisecondsSinceEpoch,
      _logicalTime = 0;

  String get nodeId => _nodeId;
  int get physicalTime => _physicalTime;
  int get logicalTime => _logicalTime;

  HybridTimestamp get now => HybridTimestamp(
    physicalTime: _physicalTime,
    logicalTime: _logicalTime,
    nodeId: _nodeId);

  HybridTimestamp tick() {
    final wallTime = DateTime.now().millisecondsSinceEpoch;

    if (wallTime > _physicalTime) {
      _physicalTime = wallTime;
      _logicalTime = 0;
    } else {
      _logicalTime++;
    }

    return HybridTimestamp(
      physicalTime: _physicalTime,
      logicalTime: _logicalTime,
      nodeId: _nodeId);
  }

  HybridTimestamp receive(HybridTimestamp remote) {
    final wallTime = DateTime.now().millisecondsSinceEpoch;

    if (wallTime > _physicalTime && wallTime > remote.physicalTime) {
      _physicalTime = wallTime;
      _logicalTime = 0;
    } else if (_physicalTime > remote.physicalTime) {
      _logicalTime++;
    } else if (remote.physicalTime > _physicalTime) {
      _physicalTime = remote.physicalTime;
      _logicalTime = remote.logicalTime + 1;
    } else {
      _physicalTime = remote.physicalTime;
      _logicalTime = _logicalTime > remote.logicalTime
          ? _logicalTime + 1
          : remote.logicalTime + 1;
    }

    return HybridTimestamp(
      physicalTime: _physicalTime,
      logicalTime: _logicalTime,
      nodeId: _nodeId);
  }

  void reset({int? initialTime}) {
    _physicalTime = initialTime ?? DateTime.now().millisecondsSinceEpoch;
    _logicalTime = 0;
  }
}
