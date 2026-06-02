import 'action_executor.dart';
import 'omni_model.dart';
import 'agent_service.dart';
import 'agent/cognitive/multi_agent_society.dart';
import 'agent/cognitive/cognitive_engine.dart';
import 'agent/cognitive/recall_engine.dart';
import 'agent/agent_reminder_service.dart';
import 'natural_time_parser.dart';
import 'matrix/matrix_service.dart';
import 'matrix/matrix_cubit.dart';
import 'note_service.dart';
import 'workspace_service.dart';
import 'agent/cognitive/goal_store.dart';
import 'planning_engine.dart';
import 'app_logger.dart';
import 'di/app_di.dart';
import 'model_cubit.dart';
import 'agent/agent_orchestrator.dart';

class ActionHandlerRegistry {
  static void registerAll() {
    final executor = ActionExecutor.instance;
    final agentService = getIt<AgentService>();

    _registerChatHandlers(executor);
    _registerNoteHandlers(executor);
    _registerAgentHandlers(executor, agentService);
    _registerFileHandlers(executor);
    _registerProjectHandlers(executor);
    _registerCognitiveHandlers(executor);
    _registerReminderHandlers(executor);
    _registerShareHandlers(executor);
    _registerFriendHandlers(executor);

    AppLogger.instance.info('All action handlers registered');
  }

  static void _registerChatHandlers(ActionExecutor executor) {
    executor.registerActionHandler('chatroom.send_message', (target, params) async {
      try {
        final matrix = getIt<MatrixService>();
        final roomId = target.state['roomId'] as String? ?? target.id.replaceFirst('room_', '');
        final message = params['message'] as String? ?? params['text'] as String? ?? '';
        if (message.isEmpty) {
          return ActionResult.failure('chatroom.send_message', target.id, 'Message is empty');
        }
        await matrix.sendMessage(roomId, message);
        return ActionResult.success('chatroom.send_message', target.id, {'sent': true, 'roomId': roomId});
      } catch (e) {
        return ActionResult.failure('chatroom.send_message', target.id, e.toString());
      }
    });

    executor.registerActionHandler('message.forward', (target, params) async {
      try {
        final matrix = getIt<MatrixService>();
        final targetRoomId = params['targetRoomId'] as String?;
        final targetUser = params['targetUser'] as String?;
        final content = params['content'] as String? ?? target.state['content'] as String? ?? '';

        if (targetRoomId != null) {
          await matrix.sendMessage(targetRoomId, content);
          return ActionResult.success('message.forward', target.id, {'forwardedTo': targetRoomId});
        }

        if (targetUser != null) {
          final users = await matrix.searchUsers(targetUser);
          if (users.isNotEmpty) {
            final roomId = await matrix.createDirectChat(users.first.userId);
            await matrix.sendMessage(roomId, content);
            return ActionResult.success('message.forward', target.id, {'forwardedTo': targetUser, 'roomId': roomId});
          }
          return ActionResult.failure('message.forward', target.id, 'User not found: $targetUser');
        }

        return ActionResult.failure('message.forward', target.id, 'No target specified');
      } catch (e) {
        return ActionResult.failure('message.forward', target.id, e.toString());
      }
    });

    executor.registerActionHandler('message.copy', (target, params) async {
      try {
        final content = target.state['content'] as String? ?? '';
        if (content.isEmpty) {
          return ActionResult.failure('message.copy', target.id, 'No content to copy');
        }
        return ActionResult.success('message.copy', target.id, {'content': content, 'copied': true});
      } catch (e) {
        return ActionResult.failure('message.copy', target.id, e.toString());
      }
    });

    executor.registerActionHandler('message.delete', (target, params) async {
      try {
        final cubit = getIt<MatrixCubit>();
        final messageId = target.state['messageId'] as String? ?? target.id.replaceFirst('msg_', '');
        final roomId = target.state['roomId'] as String? ?? '';
        if (roomId.isEmpty || messageId.isEmpty) {
          return ActionResult.failure('message.delete', target.id, 'Missing roomId or messageId');
        }
        await cubit.redactMessage(roomId, messageId, reason: 'Requested by user/AI');
        return ActionResult.success('message.delete', target.id, {'deleted': true, 'messageId': messageId});
      } catch (e) {
        return ActionResult.failure('message.delete', target.id, e.toString());
      }
    });

    executor.registerActionHandler('message.share_to_plaza', (target, params) async {
      try {
        final content = target.state['content'] as String? ?? '';
        final caption = params['caption'] as String? ?? params['comment'] as String? ?? '';
        if (content.isEmpty) {
          return ActionResult.failure('message.share_to_plaza', target.id, 'No content to share');
        }
        return ActionResult.success('message.share_to_plaza', target.id, {
          'shared': true,
          'content': content,
          'caption': caption,
          'source': target.state['roomId'],
        });
      } catch (e) {
        return ActionResult.failure('message.share_to_plaza', target.id, e.toString());
      }
    });

    executor.registerActionHandler('chatroom.invite', (target, params) async {
      try {
        final cubit = getIt<MatrixCubit>();
        final userId = params['userId'] as String? ?? '';
        final roomId = target.state['roomId'] as String? ?? target.id.replaceFirst('room_', '');
        if (userId.isEmpty) {
          return ActionResult.failure('chatroom.invite', target.id, 'No userId specified');
        }
        await cubit.inviteToRoom(roomId, userId);
        return ActionResult.success('chatroom.invite', target.id, {'roomId': roomId, 'userId': userId, 'invited': true});
      } catch (e) {
        return ActionResult.failure('chatroom.invite', target.id, e.toString());
      }
    });
  }

  static void _registerCognitiveHandlers(ActionExecutor executor) {
    executor.registerActionHandler('entity.search', (target, params) async {
      try {
        final query = params['query'] as String? ?? params['q'] as String? ?? '';
        final scope = params['scope'] as String? ?? 'all';
        if (query.isEmpty) {
          return ActionResult.failure('entity.search', target.id, 'No search query provided');
        }

        final results = <Map<String, dynamic>>[];

        try {
          final noteService = getIt<NoteService>();
          final notes = noteService.getNotes();
          final lower = query.toLowerCase();
          for (final note in notes) {
            if (note.title.toLowerCase().contains(lower) ||
                (note.content ?? '').toLowerCase().contains(lower)) {
              results.add({
                'type': 'note',
                'id': note.id,
                'title': note.title,
                'preview': (note.content ?? '').length > 100
                    ? '${(note.content ?? '').substring(0, 100)}...'
                    : note.content ?? '',
              });
            }
          }
        } catch (_) {}

        try {
          final ws = getIt<WorkspaceService>();
          if (ws.isInitialized) {
            for (final w in ws.workspaces) {
              if (w.name.toLowerCase().contains(query.toLowerCase())) {
                results.add({
                  'type': 'project',
                  'id': w.id,
                  'title': w.name,
                });
              }
            }
          }
        } catch (_) {}

        try {
          final agentService = getIt<AgentService>();
          for (final agent in agentService.getAliveAgents()) {
            if (agent.name.toLowerCase().contains(query.toLowerCase())) {
              results.add({
                'type': 'agent',
                'id': agent.id,
                'title': agent.name,
              });
            }
          }
        } catch (_) {}

        return ActionResult.success('entity.search', target.id, {
          'query': query,
          'scope': scope,
          'results': results,
          'count': results.length,
        });
      } catch (e) {
        return ActionResult.failure('entity.search', target.id, e.toString());
      }
    });

    executor.registerActionHandler('cognitive.recall', (target, params) async {
      try {
        final clue = params['clue'] as String? ?? params['query'] as String? ?? '';
        if (clue.isEmpty) {
          return ActionResult.failure('cognitive.recall', target.id, 'No recall clue provided');
        }

        final cognitive = getIt<CognitiveEngine>();
        final result = await cognitive.recall(RecallQuery(
          clue: clue,
          workspaceId: params['workspaceId'] as String?,
        ));

        final recalledEvents = result.events.take(5).map((e) => {
          'summary': e.summary,
          'importance': e.importance,
          'time': e.timestamp.toIso8601String(),
        }).toList();

        final entities = result.relatedEntities.take(5).map((e) => {
          'name': e.name,
          'lifecycle': e.lifecycle.name,
        }).toList();

        return ActionResult.success('cognitive.recall', target.id, {
          'clue': clue,
          'relevanceScore': result.relevanceScore,
          'events': recalledEvents,
          'entities': entities,
          'isEmpty': result.isEmpty,
        });
      } catch (e) {
        return ActionResult.failure('cognitive.recall', target.id, e.toString());
      }
    });
  }

  static void _registerNoteHandlers(ActionExecutor executor) {
    executor.registerActionHandler('note.edit', (target, params) async {
      try {
        final noteService = getIt<NoteService>();
        final noteId = target.id.replaceFirst('note_', '');
        final title = params['title'] as String?;
        final content = params['content'] as String?;
        final notes = noteService.getNotes();
        final note = notes.firstWhere(
          (n) => n.id == noteId,
          orElse: () => NoteItem(
            id: noteId,
            title: title ?? 'Untitled',
            content: content ?? '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        final updated = NoteItem(
          id: note.id,
          title: title ?? note.title,
          content: content ?? note.content,
          type: note.type,
          isDone: note.isDone,
          dueDate: note.dueDate,
          createdAt: note.createdAt,
          updatedAt: DateTime.now(),
        );
        await noteService.updateItem(updated);
        return ActionResult.success('note.edit', target.id, {'noteId': noteId});
      } catch (e) {
        return ActionResult.failure('note.edit', target.id, e.toString());
      }
    });

    executor.registerActionHandler('note.toggle_done', (target, params) async {
      try {
        final noteService = getIt<NoteService>();
        final noteId = target.id.replaceFirst('note_', '');
        await noteService.toggleDone(noteId);
        return ActionResult.success('note.toggle_done', target.id, {'noteId': noteId});
      } catch (e) {
        return ActionResult.failure('note.toggle_done', target.id, e.toString());
      }
    });

    executor.registerActionHandler('note.delete', (target, params) async {
      try {
        final noteService = getIt<NoteService>();
        final noteId = target.id.replaceFirst('note_', '');
        await noteService.deleteItem(noteId);
        OmniObjectRegistry.instance.unregisterObject(target.id);
        return ActionResult.success('note.delete', target.id, {'deleted': true});
      } catch (e) {
        return ActionResult.failure('note.delete', target.id, e.toString());
      }
    });

    executor.registerActionHandler('note.create', (target, params) async {
      try {
        final noteService = getIt<NoteService>();
        final title = params['title'] as String? ?? params['name'] as String? ?? 'New Note';
        final content = params['content'] as String? ?? '';
        final workspaceId = params['workspaceId'] as String? ?? target.id;
        final newNote = NoteItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          content: content,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await noteService.addItem(newNote);
        return ActionResult.success('note.create', target.id, {'noteId': newNote.id, 'title': title});
      } catch (e) {
        return ActionResult.failure('note.create', target.id, e.toString());
      }
    });
  }

  static void _registerAgentHandlers(ActionExecutor executor, AgentService agentService) {
    executor.registerActionHandler('agent.destroy', (target, params) async {
      try {
        final agentId = target.id.replaceFirst('agent_', '');
        await agentService.destroyAgent(agentId);
        return ActionResult.success('agent.destroy', target.id, {'agentId': agentId});
      } catch (e) {
        return ActionResult.failure('agent.destroy', target.id, e.toString());
      }
    });

    executor.registerActionHandler('agent.assign_task', (target, params) async {
      try {
        final task = params['task'] as String? ?? params['description'] as String? ?? '';
        final agentId = target.id.replaceFirst('agent_', '');
        await agentService.assignTaskToAgent(agentId, task);
        return ActionResult.success('agent.assign_task', target.id, {'task': task, 'agentId': agentId});
      } catch (e) {
        return ActionResult.failure('agent.assign_task', target.id, e.toString());
      }
    });

    executor.registerActionHandler('agent.pause', (target, params) async {
      try {
        final agentId = target.id.replaceFirst('agent_', '');
        await agentService.pauseAgent(agentId);
        return ActionResult.success('agent.pause', target.id, {'agentId': agentId, 'paused': true});
      } catch (e) {
        return ActionResult.failure('agent.pause', target.id, e.toString());
      }
    });

    executor.registerActionHandler('agent.resume', (target, params) async {
      try {
        final agentId = target.id.replaceFirst('agent_', '');
        await agentService.resumeAgent(agentId);
        return ActionResult.success('agent.resume', target.id, {'agentId': agentId, 'resumed': true});
      } catch (e) {
        return ActionResult.failure('agent.resume', target.id, e.toString());
      }
    });

    executor.registerActionHandler('agent.spawn', (target, params) async {
      try {
        final parentAgentId = target.id.replaceFirst('agent_', '');
        final name = params['name'] as String? ?? 'Child Agent';
        final role = params['role'] as String? ?? 'executor';
        final capabilities = (params['capabilities'] as List<dynamic>?)?.cast<String>() ?? [];
        final child = await agentService.spawnChildAgent(
          parentAgentId: parentAgentId,
          name: name,
          role: AgentRole.values.firstWhere(
            (e) => e.name == role,
            orElse: () => AgentRole.executor,
          ),
          capabilities: capabilities,
        );
        return ActionResult.success('agent.spawn', target.id, {'childAgentId': child.id, 'name': name});
      } catch (e) {
        return ActionResult.failure('agent.spawn', target.id, e.toString());
      }
    });

    executor.registerActionHandler('agent.team.create', (target, params) async {
      try {
        final name = params['name'] as String? ?? 'New Team';
        final coordinatorName = params['coordinator'] as String? ?? '$name Lead';
        final roles = (params['roles'] as List<dynamic>?)?.cast<String>() ?? [];
        final group = await agentService.createTeam(
          name: name,
          coordinatorName: coordinatorName,
          specialistRoles: roles,
        );
        return ActionResult.success('agent.team.create', target.id, {'groupId': group.id, 'name': name});
      } catch (e) {
        return ActionResult.failure('agent.team.create', target.id, e.toString());
      }
    });

    executor.registerActionHandler('agent.group.dissolve', (target, params) async {
      try {
        final groupId = target.id.replaceFirst('group_', '');
        await agentService.dissolveGroup(groupId);
        return ActionResult.success('agent.group.dissolve', target.id, {'groupId': groupId});
      } catch (e) {
        return ActionResult.failure('agent.group.dissolve', target.id, e.toString());
      }
    });

    executor.registerActionHandler('chatroom.create_agent', (target, params) async {
      try {
        final name = params['name'] as String? ?? 'New Agent';
        final role = params['role'] as String? ?? 'executor';
        final capabilities = (params['capabilities'] as List<dynamic>?)?.cast<String>() ?? ['execution'];
        final groupId = target.id.replaceFirst('room_', '');
        final agent = await agentService.createAgent(
          name: name,
          role: AgentRole.values.firstWhere((r) => r.name == role, orElse: () => AgentRole.executor),
          capabilities: capabilities,
          groupId: groupId,
        );
        await agentService.startAgent(agent.id);
        return ActionResult.success('chatroom.create_agent', target.id, {'agentId': agent.id, 'agentName': agent.name});
      } catch (e) {
        return ActionResult.failure('chatroom.create_agent', target.id, e.toString());
      }
    });
  }

  static void _registerFileHandlers(ActionExecutor executor) {
    executor.registerActionHandler('file.open', (target, params) async {
      try {
        final path = target.state['path'] as String? ?? '';
        if (path.isEmpty) {
          return ActionResult.failure('file.open', target.id, 'No file path available');
        }
        return ActionResult.success('file.open', target.id, {'path': path, 'opened': true});
      } catch (e) {
        return ActionResult.failure('file.open', target.id, e.toString());
      }
    });

    executor.registerActionHandler('file.share', (target, params) async {
      try {
        final path = target.state['path'] as String? ?? '';
        final name = target.state['name'] as String? ?? 'File';
        if (path.isEmpty) {
          return ActionResult.failure('file.share', target.id, 'No file path available');
        }
        return ActionResult.success('file.share', target.id, {
          'shared': true,
          'path': path,
          'name': name,
        });
      } catch (e) {
        return ActionResult.failure('file.share', target.id, e.toString());
      }
    });

    executor.registerActionHandler('file.delete', (target, params) async {
      try {
        final path = target.state['path'] as String? ?? '';
        if (path.isEmpty) {
          return ActionResult.failure('file.delete', target.id, 'No file path available');
        }
        return ActionResult.success('file.delete', target.id, {'deleted': true, 'path': path});
      } catch (e) {
        return ActionResult.failure('file.delete', target.id, e.toString());
      }
    });
  }

  static void _registerProjectHandlers(ActionExecutor executor) {
    executor.registerActionHandler('project.open', (target, params) async {
      try {
        final ws = getIt<WorkspaceService>();
        if (!ws.isInitialized) await ws.init();
        final projectId = target.id.replaceFirst('project_', '');
        await ws.setActiveWorkspace(projectId);
        return ActionResult.success('project.open', target.id, {'projectId': projectId});
      } catch (e) {
        return ActionResult.failure('project.open', target.id, e.toString());
      }
    });

    executor.registerActionHandler('project.create_task', (target, params) async {
      try {
        final taskName = params['name'] as String? ?? params['title'] as String? ?? 'New Task';
        final goalStore = getIt<GoalStore>();
        final projectId = target.id.replaceFirst('project_', '');
        final goal = await goalStore.createGoal(
          title: taskName,
          workspaceId: projectId,
        );
        return ActionResult.success('project.create_task', target.id, {'goalId': goal.id, 'title': taskName});
      } catch (e) {
        return ActionResult.failure('project.create_task', target.id, e.toString());
      }
    });

    executor.registerActionHandler('project.archive', (target, params) async {
      try {
        final projectId = target.id.replaceFirst('project_', '');
        return ActionResult.success('project.archive', target.id, {
          'archived': true,
          'projectId': projectId,
        });
      } catch (e) {
        return ActionResult.failure('project.archive', target.id, e.toString());
      }
    });

    executor.registerActionHandler('plan.create', (target, params) async {
      try {
        final planningEngine = getIt<PlanningEngine>();
        if (!planningEngine.isInitialized) await planningEngine.init();
        final title = params['title'] as String? ?? params['name'] as String? ?? 'New Plan';
        final description = params['description'] as String? ?? '';
        final stepsData = params['steps'] as List<dynamic>? ?? [];
        final steps = stepsData.map((s) {
          final stepMap = s as Map<String, dynamic>;
          return PlanStep(
            id: stepMap['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
            description: stepMap['title'] as String? ?? stepMap['description'] as String? ?? '',
            dependencies: (stepMap['dependencies'] as List<dynamic>?)?.cast<String>() ?? [],
            actionId: stepMap['actionId'] as String?,
            objectType: stepMap['objectType'] as String?,
            objectId: stepMap['objectId'] as String?,
            params: (stepMap['params'] as Map<String, dynamic>?) ?? {},
          );
        }).toList();
        final plan = await planningEngine.createAndApprove(
          title: title,
          description: description,
          projectId: target.id.replaceFirst('project_', ''),
          steps: steps,
        );
        return ActionResult.success('plan.create', target.id, {'planId': plan.id, 'title': title});
      } catch (e) {
        return ActionResult.failure('plan.create', target.id, e.toString());
      }
    });
  }

  static void _registerReminderHandlers(ActionExecutor executor) {
    executor.registerActionHandler('reminder.set', (target, params) async {
      try {
        final title = params['title'] as String? ?? params['message'] as String? ?? 'Reminder';
        final description = params['description'] as String? ?? params['content'] as String? ?? '';
        final timeExpression = params['time'] as String? ?? params['when'] as String? ?? params['at'] as String? ?? '';
        if (timeExpression.isEmpty) {
          return ActionResult.failure('reminder.set', target.id, 'No time expression provided. Use natural language like "10分钟后" or "明天9点"');
        }

        final parsed = NaturalTimeParser.parse(timeExpression);
        if (!parsed.isValid) {
          return ActionResult.failure('reminder.set', target.id, 'Could not parse time expression: $timeExpression');
        }

        final reminderService = ReminderService.instance;
        await reminderService.init();

        final frequency = ReminderFrequency.custom(
          parsed.recurringInterval ?? (parsed.relativeDuration ?? const Duration(hours: 1)),
        );

        final type = parsed.isRecurring
            ? ReminderType.recurring
            : ReminderType.scheduled;

        final reminder = await reminderService.createReminder(
          type: type,
          title: title,
          description: description.isNotEmpty ? description : timeExpression,
          frequency: frequency,
        );

        return ActionResult.success('reminder.set', target.id, {
          'reminderId': reminder.id,
          'title': reminder.title,
          'nextTriggerAt': reminder.nextTriggerAt?.toIso8601String(),
          'isRecurring': parsed.isRecurring,
          'parsedTime': timeExpression,
        });
      } catch (e) {
        return ActionResult.failure('reminder.set', target.id, e.toString());
      }
    });

    executor.registerActionHandler('reminder.list', (target, params) async {
      try {
        final reminderService = ReminderService.instance;
        await reminderService.init();

        final active = reminderService.activeReminders;
        final all = reminderService.allReminders;

        return ActionResult.success('reminder.list', target.id, {
          'activeCount': active.length,
          'totalCount': all.length,
          'activeReminders': active.map((r) => {
            'id': r.id,
            'title': r.title,
            'description': r.description,
            'type': r.type.name,
            'status': r.status.name,
            'nextTriggerAt': r.nextTriggerAt?.toIso8601String(),
            'createdAt': r.createdAt.toIso8601String(),
          }).toList(),
          'allReminders': all.map((r) => {
            'id': r.id,
            'title': r.title,
            'status': r.status.name,
          }).toList(),
        });
      } catch (e) {
        return ActionResult.failure('reminder.list', target.id, e.toString());
      }
    });

    executor.registerActionHandler('reminder.cancel', (target, params) async {
      try {
        final reminderId = params['reminderId'] as String?;
        if (reminderId == null || reminderId.isEmpty) {
          return ActionResult.failure('reminder.cancel', target.id, 'No reminderId provided');
        }

        final reminderService = ReminderService.instance;
        await reminderService.cancelReminder(reminderId);

        return ActionResult.success('reminder.cancel', target.id, {'cancelled': true, 'reminderId': reminderId});
      } catch (e) {
        return ActionResult.failure('reminder.cancel', target.id, e.toString());
      }
    });
  }

  static void _registerShareHandlers(ActionExecutor executor) {
    executor.registerActionHandler('message.share_to_friend', (target, params) async {
      try {
        final content = params['content'] as String? ?? target.state['content'] as String? ?? '';
        if (content.isEmpty) {
          return ActionResult.failure('message.share_to_friend', target.id, 'No content to share');
        }
        return ActionResult.success('message.share_to_friend', target.id, {
          'content': content,
          'source': target.state['roomId'] ?? 'unknown',
          'action': 'share_to_friend',
        });
      } catch (e) {
        return ActionResult.failure('message.share_to_friend', target.id, e.toString());
      }
    });

    executor.registerActionHandler('message.analyze', (target, params) async {
      try {
        final content = params['content'] as String? ?? target.state['content'] as String? ?? '';
        if (content.isEmpty) {
          return ActionResult.failure('message.analyze', target.id, 'No content to analyze');
        }
        final cognitive = getIt<CognitiveEngine>();
        final analysis = await cognitive.recall(RecallQuery(
          clue: 'Analyze this content: $content',
          workspaceId: params['workspaceId'] as String?,
        ));
        return ActionResult.success('message.analyze', target.id, {
          'content': content,
          'relatedMemories': analysis.events.take(3).map((e) => e.summary).toList(),
          'relatedEntities': analysis.relatedEntities.take(3).map((e) => e.name).toList(),
        });
      } catch (e) {
        return ActionResult.failure('message.analyze', target.id, e.toString());
      }
    });

    executor.registerActionHandler('message.summarize', (target, params) async {
      try {
        final roomId = params['roomId'] as String? ?? target.state['roomId'] as String? ?? '';
        if (roomId.isEmpty) {
          return ActionResult.failure('message.summarize', target.id, 'No roomId provided');
        }
        final matrix = getIt<MatrixService>();
        final timeline = await matrix.getRoomTimeline(roomId, limit: 50);
        final messages = timeline.map((e) => e.body ?? '').where((b) => b.isNotEmpty).toList();
        if (messages.isEmpty) {
          return ActionResult.failure('message.summarize', target.id, 'No messages to summarize');
        }
        return ActionResult.success('message.summarize', target.id, {
          'roomId': roomId,
          'messageCount': messages.length,
          'preview': messages.take(10).join('\n'),
        });
      } catch (e) {
        return ActionResult.failure('message.summarize', target.id, e.toString());
      }
    });
  }

  static void _registerFriendHandlers(ActionExecutor executor) {
    executor.registerActionHandler('friend.add', (target, params) async {
      try {
        final userId = params['userId'] as String? ?? '';
        final matrix = getIt<MatrixCubit>();
        if (userId.isEmpty) {
          return ActionResult.failure('friend.add', target.id, 'No userId provided');
        }
        await matrix.inviteToRoom(userId, userId);
        return ActionResult.success('friend.add', target.id, {
          'userId': userId,
          'invited': true,
        });
      } catch (e) {
        return ActionResult.failure('friend.add', target.id, e.toString());
      }
    });

    executor.registerActionHandler('model.switch', (target, params) async {
      try {
        final modelId = params['modelId'] as String? ?? params['model'] as String? ?? '';
        if (modelId.isEmpty) {
          return ActionResult.failure('model.switch', target.id, 'No modelId provided');
        }
        final modelCubit = getIt<ModelCubit>();
        final availableModels = modelCubit.availableModels;
        final targetModel = availableModels.where((m) =>
            m.id.toLowerCase() == modelId.toLowerCase() ||
            m.name.toLowerCase().contains(modelId.toLowerCase())).firstOrNull;
        if (targetModel == null) {
          return ActionResult.failure('model.switch', target.id,
              'Model not found: $modelId. Available: ${availableModels.map((m) => m.id).join(", ")}');
        }
        modelCubit.selectModel(targetModel);
        return ActionResult.success('model.switch', target.id, {
          'modelId': targetModel.id,
          'modelName': targetModel.name,
          'switched': true,
        });
      } catch (e) {
        return ActionResult.failure('model.switch', target.id, e.toString());
      }
    });

    executor.registerActionHandler('message.share_to_ai', (target, params) async {
      try {
        final content = params['content'] as String? ?? target.state['content'] as String? ?? '';
        if (content.isEmpty) {
          return ActionResult.failure('message.share_to_ai', target.id, 'No content to share');
        }
        final orchestrator = getIt<AgentOrchestrator>();
        orchestrator.sendMessage(content);
        return ActionResult.success('message.share_to_ai', target.id, {
          'content': content,
          'shared': true,
        });
      } catch (e) {
        return ActionResult.failure('message.share_to_ai', target.id, e.toString());
      }
    });
  }
}
