import 'omni_model.dart';
import 'workspace_service.dart';

class ChatMessageObject extends OmniObject {
  final String messageId;
  final String roomId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isOwn;

  ChatMessageObject({
    required this.messageId,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.isOwn = false,
  });

  @override
  String get id => 'msg_$messageId';

  @override
  OmniObjectType get objectType => OmniObjectType.message;

  @override
  String get displayName => content.length > 50 ? '${content.substring(0, 50)}...' : content;

  @override
  Map<String, dynamic> get state => {
    'messageId': messageId,
    'roomId': roomId,
    'senderId': senderId,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'isOwn': isOwn,
  };

  @override
  List<OmniAction> get availableActions => [
    OmniAction(
      id: 'message.copy',
      name: '复制',
      description: '复制消息内容',
      objectTypeId: objectType.name,
      capabilityId: 'chat.message.copy',
      permission: 'auto',
    ),
    OmniAction(
      id: 'message.forward',
      name: '转发',
      description: '转发消息到其他聊天',
      objectTypeId: objectType.name,
      capabilityId: 'chat.message.forward',
      permission: 'confirm',
    ),
    OmniAction(
      id: 'message.share_to_plaza',
      name: '分享到广场',
      description: '将消息分享到广场',
      objectTypeId: objectType.name,
      capabilityId: 'chat.message.shareToPlaza',
      permission: 'confirm',
    ),
    OmniAction(
      id: 'message.delete',
      name: '删除',
      description: '删除消息',
      objectTypeId: objectType.name,
      capabilityId: 'chat.message.delete',
      isDestructive: true,
      permission: 'confirm',
    ),
  ];

  @override
  Map<String, dynamic> toJson() => state;
}

class ProjectObject extends OmniObject {
  final String projectId;
  final String name;
  final String domain;
  final String status;
  final List<String> entityNames;
  final int goalCount;
  final DateTime lastActiveAt;
  final List<ProjectTimelineEntry> recentTimeline;

  ProjectObject({
    required this.projectId,
    required this.name,
    this.domain = 'project',
    this.status = 'active',
    this.entityNames = const [],
    this.goalCount = 0,
    DateTime? lastActiveAt,
    this.recentTimeline = const [],
  }) : lastActiveAt = lastActiveAt ?? DateTime.now();

  @override
  String get id => 'project_$projectId';

  @override
  OmniObjectType get objectType => OmniObjectType.project;

  @override
  String get displayName => name;

  @override
  Map<String, dynamic> get state => {
    'projectId': projectId,
    'name': name,
    'domain': domain,
    'status': status,
    'entityNames': entityNames,
    'goalCount': goalCount,
    'lastActiveAt': lastActiveAt.toIso8601String(),
    'recentTimeline': recentTimeline.take(5).map((t) => {
      'time': t.timestamp.toIso8601String(),
      'type': t.type,
      'desc': t.description,
    }).toList(),
  };

  @override
  List<OmniAction> get availableActions => [
    OmniAction(
      id: 'project.open',
      name: '打开项目',
      description: '恢复项目上下文',
      objectTypeId: objectType.name,
      capabilityId: 'project.open',
      permission: 'auto',
    ),
    OmniAction(
      id: 'project.create_task',
      name: '创建任务',
      description: '在项目中创建任务',
      objectTypeId: objectType.name,
      capabilityId: 'project.createTask',
      permission: 'auto',
    ),
    OmniAction(
      id: 'project.archive',
      name: '归档',
      description: '归档项目',
      objectTypeId: objectType.name,
      capabilityId: 'project.archive',
      permission: 'confirm',
    ),
  ];

  @override
  Map<String, dynamic> toJson() => state;
}
class ChatRoomObject extends OmniObject {
  final String roomId;
  final String name;
  final bool isDirect;
  final bool isGroup;
  final List<String> memberIds;
  final int unreadCount;

  ChatRoomObject({
    required this.roomId,
    required this.name,
    this.isDirect = false,
    this.isGroup = false,
    this.memberIds = const [],
    this.unreadCount = 0,
  });

  @override
  String get id => 'room_$roomId';

  @override
  OmniObjectType get objectType => OmniObjectType.chatRoom;

  @override
  String get displayName => name;

  @override
  Map<String, dynamic> get state => {
    'roomId': roomId,
    'name': name,
    'isDirect': isDirect,
    'isGroup': isGroup,
    'memberIds': memberIds,
    'unreadCount': unreadCount,
  };

  @override
  List<OmniAction> get availableActions => [
    OmniAction(
      id: 'chatroom.send_message',
      name: '发送消息',
      description: '在聊天室发送消息',
      objectTypeId: objectType.name,
      capabilityId: 'chat.room.sendMessage',
      permission: 'auto',
    ),
    OmniAction(
      id: 'chatroom.invite',
      name: '邀请成员',
      description: '邀请用户加入聊天',
      objectTypeId: objectType.name,
      capabilityId: 'chat.room.invite',
      permission: 'confirm',
    ),
    OmniAction(
      id: 'chatroom.create_agent',
      name: '创建Agent',
      description: '在群聊中创建Agent',
      objectTypeId: objectType.name,
      capabilityId: 'chat.room.createAgent',
      permission: 'confirm',
    ),
    OmniAction(
      id: 'chatroom.archive',
      name: '归档',
      description: '归档聊天室',
      objectTypeId: objectType.name,
      capabilityId: 'chat.room.archive',
      permission: 'confirm',
    ),
  ];

  @override
  Map<String, dynamic> toJson() => state;
}

class AgentObject extends OmniObject {
  final String agentId;
  final String name;
  final String role;
  final String status;
  final List<String> capabilities;

  AgentObject({
    required this.agentId,
    required this.name,
    this.role = 'executor',
    this.status = 'idle',
    this.capabilities = const [],
  });

  @override
  String get id => 'agent_$agentId';

  @override
  OmniObjectType get objectType => OmniObjectType.agent;

  @override
  String get displayName => name;

  @override
  Map<String, dynamic> get state => {
    'agentId': agentId,
    'name': name,
    'role': role,
    'status': status,
    'capabilities': capabilities,
  };

  @override
  List<OmniAction> get availableActions => [
    OmniAction(
      id: 'agent.assign_task',
      name: '分配任务',
      description: '给Agent分配任务',
      objectTypeId: objectType.name,
      capabilityId: 'agent.task.assign',
      permission: 'auto',
    ),
    OmniAction(
      id: 'agent.pause',
      name: '暂停',
      description: '暂停Agent',
      objectTypeId: objectType.name,
      capabilityId: 'agent.lifecycle.pause',
      permission: 'confirm',
    ),
    OmniAction(
      id: 'agent.resume',
      name: '恢复',
      description: '恢复Agent运行',
      objectTypeId: objectType.name,
      capabilityId: 'agent.lifecycle.resume',
      permission: 'auto',
    ),
    OmniAction(
      id: 'agent.destroy',
      name: '销毁',
      description: '销毁Agent',
      objectTypeId: objectType.name,
      capabilityId: 'agent.lifecycle.destroy',
      isDestructive: true,
      permission: 'confirm',
    ),
  ];

  @override
  Map<String, dynamic> toJson() => state;
}

class FileObject extends OmniObject {
  final String fileId;
  final String name;
  final String path;
  final int sizeBytes;
  final String mimeType;
  final DateTime modifiedAt;

  FileObject({
    required this.fileId,
    required this.name,
    required this.path,
    this.sizeBytes = 0,
    this.mimeType = 'application/octet-stream',
    DateTime? modifiedAt,
  }) : modifiedAt = modifiedAt ?? DateTime.now();

  @override
  String get id => 'file_$fileId';

  @override
  OmniObjectType get objectType => OmniObjectType.file;

  @override
  String get displayName => name;

  @override
  Map<String, dynamic> get state => {
    'fileId': fileId,
    'name': name,
    'path': path,
    'sizeBytes': sizeBytes,
    'mimeType': mimeType,
    'modifiedAt': modifiedAt.toIso8601String(),
  };

  @override
  List<OmniAction> get availableActions => [
    OmniAction(
      id: 'file.open',
      name: '打开',
      description: '打开文件',
      objectTypeId: objectType.name,
      capabilityId: 'file.open',
      permission: 'auto',
    ),
    OmniAction(
      id: 'file.share',
      name: '分享',
      description: '分享文件',
      objectTypeId: objectType.name,
      capabilityId: 'file.share',
      permission: 'confirm',
    ),
    OmniAction(
      id: 'file.delete',
      name: '删除',
      description: '删除文件',
      objectTypeId: objectType.name,
      capabilityId: 'file.delete',
      isDestructive: true,
      permission: 'confirm',
    ),
  ];

  @override
  Map<String, dynamic> toJson() => state;
}

class NoteObject extends OmniObject {
  final String noteId;
  final String title;
  final String content;
  final String type;
  final bool isDone;
  final DateTime updatedAt;

  NoteObject({
    required this.noteId,
    required this.title,
    this.content = '',
    this.type = 'text',
    this.isDone = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  @override
  String get id => 'note_$noteId';

  @override
  OmniObjectType get objectType => OmniObjectType.note;

  @override
  String get displayName => title;

  @override
  Map<String, dynamic> get state => {
    'noteId': noteId,
    'title': title,
    'content': content,
    'type': type,
    'isDone': isDone,
    'updatedAt': updatedAt.toIso8601String(),
  };

  @override
  List<OmniAction> get availableActions => [
    OmniAction(
      id: 'note.edit',
      name: '编辑',
      description: '编辑笔记',
      objectTypeId: objectType.name,
      capabilityId: 'note.edit',
      permission: 'auto',
    ),
    OmniAction(
      id: 'note.toggle_done',
      name: '切换完成',
      description: '标记完成/未完成',
      objectTypeId: objectType.name,
      capabilityId: 'note.toggleDone',
      permission: 'auto',
    ),
    OmniAction(
      id: 'note.delete',
      name: '删除',
      description: '删除笔记',
      objectTypeId: objectType.name,
      capabilityId: 'note.delete',
      isDestructive: true,
      permission: 'confirm',
    ),
  ];

  @override
  Map<String, dynamic> toJson() => state;
}
