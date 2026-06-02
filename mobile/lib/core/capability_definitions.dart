import 'capability_system.dart';

class CapabilityDefinitions {
  static void registerAll(CapabilityRegistry registry) {
    _registerInformationCapabilities(registry);
    _registerCommunicationCapabilities(registry);
    _registerCreationCapabilities(registry);
    _registerModificationCapabilities(registry);
    _registerManagementCapabilities(registry);
    _registerAutomationCapabilities(registry);
    _registerMediaCapabilities(registry);
    _registerCommerceCapabilities(registry);
  }

  static void _registerInformationCapabilities(CapabilityRegistry registry) {
    registry.registerCapability(const Capability(
      id: 'search',
      name: 'Search',
      description: 'Search for information, messages, files, or entities',
      category: CapabilityCategory.information,
      applicableObjectTypes: {'message', 'chatRoom', 'file', 'note', 'project', 'agent'},
      paramSchema: {'query': 'string', 'scope': 'string?'},
    ));

    registry.registerCapability(const Capability(
      id: 'read',
      name: 'Read',
      description: 'Read or view content of an object',
      category: CapabilityCategory.information,
      applicableObjectTypes: {'message', 'file', 'note', 'project'},
      paramSchema: {'objectId': 'string'},
    ));

    registry.registerCapability(const Capability(
      id: 'recall',
      name: 'Recall',
      description: 'Recall memories, past events, or historical context',
      category: CapabilityCategory.information,
      paramSchema: {'query': 'string', 'workspaceId': 'string?'},
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'search',
      providerName: 'Internal Entity Search',
      actionId: 'entity.search',
      priority: 1.0,
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'search',
      providerName: 'Message Search',
      actionId: 'chat.message.search',
      objectTypes: {'message', 'chatRoom'},
      priority: 0.8,
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'read',
      providerName: 'File Reader',
      actionId: 'file.open',
      objectTypes: {'file'},
      priority: 1.0,
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'read',
      providerName: 'Note Reader',
      actionId: 'note.edit',
      objectTypes: {'note'},
      priority: 1.0,
      paramMapping: {'mode': 'read'},
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'recall',
      providerName: 'Cognitive Recall',
      actionId: 'cognitive.recall',
      priority: 1.0,
    ));
  }

  static void _registerCommunicationCapabilities(CapabilityRegistry registry) {
    registry.registerCapability(const Capability(
      id: 'send',
      name: 'Send',
      description: 'Send a message to a chat, room, or contact',
      category: CapabilityCategory.communication,
      applicableObjectTypes: {'chatRoom', 'contact'},
      paramSchema: {'message': 'string', 'roomId': 'string?'},
    ));

    registry.registerCapability(const Capability(
      id: 'share',
      name: 'Share',
      description: 'Share content to a chat, contact, or public space',
      category: CapabilityCategory.communication,
      applicableObjectTypes: {'message', 'file', 'note', 'product', 'post'},
      paramSchema: {'targetId': 'string', 'targetType': 'string'},
    ));

    registry.registerCapability(const Capability(
      id: 'forward',
      name: 'Forward',
      description: 'Forward a message or content to another recipient',
      category: CapabilityCategory.communication,
      applicableObjectTypes: {'message'},
      paramSchema: {'recipientId': 'string'},
    ));

    registry.registerCapability(const Capability(
      id: 'notify',
      name: 'Notify',
      description: 'Send a notification or alert to a user or agent',
      category: CapabilityCategory.communication,
      applicableObjectTypes: {'agent', 'contact'},
      paramSchema: {'message': 'string', 'priority': 'string?'},
    ));

    registry.registerCapability(const Capability(
      id: 'invite',
      name: 'Invite',
      description: 'Invite a member to a room, project, or group',
      category: CapabilityCategory.communication,
      applicableObjectTypes: {'chatRoom', 'project', 'agentGroup'},
      paramSchema: {'userId': 'string'},
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'send',
      providerName: 'Matrix Chat',
      actionId: 'chat.room.sendMessage',
      objectTypes: {'chatRoom'},
      priority: 1.0,
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'share',
      providerName: 'Share to Chat',
      actionId: 'chat.message.forward',
      objectTypes: {'message', 'file', 'note'},
      priority: 1.0,
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'share',
      providerName: 'Share to Plaza',
      actionId: 'chat.message.shareToPlaza',
      objectTypes: {'message', 'product', 'post'},
      priority: 0.7,
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'forward',
      providerName: 'Matrix Forward',
      actionId: 'chat.message.forward',
      objectTypes: {'message'},
      priority: 1.0,
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'invite',
      providerName: 'Matrix Invite',
      actionId: 'chat.room.invite',
      objectTypes: {'chatRoom'},
      priority: 1.0,
    ));
  }

  static void _registerCreationCapabilities(CapabilityRegistry registry) {
    registry.registerCapability(const Capability(
      id: 'create',
      name: 'Create',
      description: 'Create a new object such as a note, project, task, or agent',
      category: CapabilityCategory.creation,
      applicableObjectTypes: {'note', 'project', 'task', 'agent', 'agentGroup', 'chatRoom'},
      paramSchema: {'name': 'string', 'type': 'string'},
    ));

    registry.registerCapability(const Capability(
      id: 'createProject',
      name: 'CreateProject',
      description: 'Create a new project with workspace and timeline',
      category: CapabilityCategory.creation,
      applicableObjectTypes: {'project'},
      paramSchema: {'name': 'string', 'domain': 'string?'},
    ));

    registry.registerCapability(const Capability(
      id: 'createAgent',
      name: 'CreateAgent',
      description: 'Create a new agent with specific role and capabilities',
      category: CapabilityCategory.creation,
      applicableObjectTypes: {'agent', 'agentGroup'},
      paramSchema: {'name': 'string', 'role': 'string', 'capabilities': 'list?'},
    ));

    registry.registerCapability(const Capability(
      id: 'createTask',
      name: 'CreateTask',
      description: 'Create a new task within a project',
      category: CapabilityCategory.creation,
      applicableObjectTypes: {'project', 'task'},
      paramSchema: {'title': 'string', 'description': 'string?', 'projectId': 'string?'},
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'create',
      providerName: 'Note Creator',
      actionId: 'note.create',
      objectTypes: {'note'},
      priority: 1.0,
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'createProject',
      providerName: 'Workspace Creator',
      actionId: 'project.open',
      objectTypes: {'project'},
      priority: 1.0,
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'createAgent',
      providerName: 'Agent Factory',
      actionId: 'chat.room.createAgent',
      objectTypes: {'agent', 'agentGroup', 'chatRoom'},
      priority: 1.0,
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'createTask',
      providerName: 'Goal Creator',
      actionId: 'project.createTask',
      objectTypes: {'project'},
      priority: 1.0,
    ));
  }

  static void _registerModificationCapabilities(CapabilityRegistry registry) {
    registry.registerCapability(const Capability(
      id: 'edit',
      name: 'Edit',
      description: 'Edit or modify the content of an object',
      category: CapabilityCategory.modification,
      applicableObjectTypes: {'note', 'message', 'project'},
      paramSchema: {'objectId': 'string', 'changes': 'map'},
    ));

    registry.registerCapability(const Capability(
      id: 'delete',
      name: 'Delete',
      description: 'Delete or remove an object',
      category: CapabilityCategory.modification,
      applicableObjectTypes: {'message', 'note', 'file', 'agent'},
      isDestructive: true,
      paramSchema: {'objectId': 'string'},
    ));

    registry.registerCapability(const Capability(
      id: 'copy',
      name: 'Copy',
      description: 'Copy content to clipboard or another location',
      category: CapabilityCategory.modification,
      applicableObjectTypes: {'message', 'note', 'file'},
      paramSchema: {'objectId': 'string'},
    ));

    registry.registerCapability(const Capability(
      id: 'complete',
      name: 'Complete',
      description: 'Mark a task, goal, or item as completed',
      category: CapabilityCategory.modification,
      applicableObjectTypes: {'note', 'task', 'project'},
      paramSchema: {'objectId': 'string'},
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'edit',
      providerName: 'Note Editor',
      actionId: 'note.edit',
      objectTypes: {'note'},
      priority: 1.0,
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'delete',
      providerName: 'Message Deleter',
      actionId: 'chat.message.delete',
      objectTypes: {'message'},
      priority: 1.0,
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'delete',
      providerName: 'Note Deleter',
      actionId: 'note.delete',
      objectTypes: {'note'},
      priority: 1.0,
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'delete',
      providerName: 'File Deleter',
      actionId: 'file.delete',
      objectTypes: {'file'},
      priority: 1.0,
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'copy',
      providerName: 'Message Copier',
      actionId: 'chat.message.copy',
      objectTypes: {'message'},
      priority: 1.0,
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'complete',
      providerName: 'Note Completer',
      actionId: 'note.toggleDone',
      objectTypes: {'note'},
      priority: 1.0,
    ));
  }

  static void _registerManagementCapabilities(CapabilityRegistry registry) {
    registry.registerCapability(const Capability(
      id: 'assign',
      name: 'Assign',
      description: 'Assign a task or responsibility to an agent or member',
      category: CapabilityCategory.management,
      applicableObjectTypes: {'agent', 'task', 'project'},
      paramSchema: {'agentId': 'string', 'task': 'string'},
    ));

    registry.registerCapability(const Capability(
      id: 'open',
      name: 'Open',
      description: 'Open or navigate to an object, project, or workspace',
      category: CapabilityCategory.management,
      applicableObjectTypes: {'project', 'file', 'chatRoom'},
      paramSchema: {'objectId': 'string'},
    ));

    registry.registerCapability(const Capability(
      id: 'archive',
      name: 'Archive',
      description: 'Archive an object for later reference',
      category: CapabilityCategory.management,
      applicableObjectTypes: {'project', 'chatRoom', 'note'},
      paramSchema: {'objectId': 'string'},
    ));

    registry.registerCapability(const Capability(
      id: 'destroy',
      name: 'Destroy',
      description: 'Permanently destroy an agent or resource',
      category: CapabilityCategory.management,
      applicableObjectTypes: {'agent', 'agentGroup'},
      isDestructive: true,
      paramSchema: {'agentId': 'string'},
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'assign',
      providerName: 'Agent Task Assigner',
      actionId: 'agent.task.assign',
      objectTypes: {'agent'},
      priority: 1.0,
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'open',
      providerName: 'Project Opener',
      actionId: 'project.open',
      objectTypes: {'project'},
      priority: 1.0,
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'open',
      providerName: 'File Opener',
      actionId: 'file.open',
      objectTypes: {'file'},
      priority: 1.0,
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'archive',
      providerName: 'Project Archiver',
      actionId: 'project.archive',
      objectTypes: {'project'},
      priority: 1.0,
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'destroy',
      providerName: 'Agent Destroyer',
      actionId: 'agent.lifecycle.destroy',
      objectTypes: {'agent'},
      priority: 1.0,
    ));
  }

  static void _registerAutomationCapabilities(CapabilityRegistry registry) {
    registry.registerCapability(const Capability(
      id: 'plan',
      name: 'Plan',
      description: 'Create a multi-step plan for complex tasks',
      category: CapabilityCategory.automation,
      paramSchema: {'title': 'string', 'steps': 'list'},
    ));

    registry.registerCapability(const Capability(
      id: 'automate',
      name: 'Automate',
      description: 'Automate a repetitive task or workflow',
      category: CapabilityCategory.automation,
      paramSchema: {'task': 'string', 'schedule': 'string?'},
    ));

    registry.registerBinding(const CapabilityBinding(
      capabilityId: 'plan',
      providerName: 'Planning Engine',
      actionId: 'plan.create',
      priority: 1.0,
    ));
  }

  static void _registerMediaCapabilities(CapabilityRegistry registry) {
    registry.registerCapability(const Capability(
      id: 'generateImage',
      name: 'GenerateImage',
      description: 'Generate an image from a description',
      category: CapabilityCategory.media,
      paramSchema: {'prompt': 'string', 'style': 'string?'},
    ));

    registry.registerCapability(const Capability(
      id: 'generateVideo',
      name: 'GenerateVideo',
      description: 'Generate a video from a description',
      category: CapabilityCategory.media,
      paramSchema: {'prompt': 'string', 'duration': 'number?'},
    ));

    registry.registerCapability(const Capability(
      id: 'transcribe',
      name: 'Transcribe',
      description: 'Transcribe audio or voice to text',
      category: CapabilityCategory.media,
      applicableObjectTypes: {'message'},
      paramSchema: {'audioData': 'string'},
    ));
  }

  static void _registerCommerceCapabilities(CapabilityRegistry registry) {
    registry.registerCapability(const Capability(
      id: 'purchase',
      name: 'Purchase',
      description: 'Purchase a product or service',
      category: CapabilityCategory.commerce,
      applicableObjectTypes: {'product'},
      isDestructive: true,
      paramSchema: {'productId': 'string', 'quantity': 'number?'},
    ));

    registry.registerCapability(const Capability(
      id: 'compare',
      name: 'Compare',
      description: 'Compare products, options, or alternatives',
      category: CapabilityCategory.commerce,
      applicableObjectTypes: {'product'},
      paramSchema: {'items': 'list', 'criteria': 'list?'},
    ));
  }
}
