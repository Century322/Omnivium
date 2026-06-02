import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/remote_config_service.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../../../agent/presentation/bloc/agent_bloc.dart';
import '../../../agent/presentation/bloc/agent_event.dart';
import '../../../agent/presentation/bloc/agent_state.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/locale_cubit.dart';

class AIWorkbenchTemplate {
  final String id;
  final String nameKey;
  final String emoji;
  final String systemPromptKey;
  final String userPromptKey;
  final String? remoteSystemPrompt;
  final String? remoteUserPrompt;

  const AIWorkbenchTemplate({
    required this.id,
    required this.nameKey,
    required this.emoji,
    required this.systemPromptKey,
    required this.userPromptKey,
    this.remoteSystemPrompt,
    this.remoteUserPrompt,
  });

  String get systemPrompt =>
      remoteSystemPrompt ?? localeProvider.t(systemPromptKey);
  String get userPromptTemplate =>
      remoteUserPrompt ?? localeProvider.t(userPromptKey);
}

const _localTemplates = [
  AIWorkbenchTemplate(id: 'write', nameKey: 'template_write', emoji: '✍️', systemPromptKey: 'tpl_write_system', userPromptKey: 'tpl_write_user'),
  AIWorkbenchTemplate(id: 'translate', nameKey: 'template_translate', emoji: '🌐', systemPromptKey: 'tpl_translate_system', userPromptKey: 'tpl_translate_user'),
  AIWorkbenchTemplate(id: 'summarize', nameKey: 'template_summarize', emoji: '📋', systemPromptKey: 'tpl_summarize_system', userPromptKey: 'tpl_summarize_user'),
  AIWorkbenchTemplate(id: 'code', nameKey: 'template_code', emoji: '💻', systemPromptKey: 'tpl_code_system', userPromptKey: 'tpl_code_user'),
  AIWorkbenchTemplate(id: 'explain', nameKey: 'template_explain', emoji: '💡', systemPromptKey: 'tpl_explain_system', userPromptKey: 'tpl_explain_user'),
  AIWorkbenchTemplate(id: 'polish', nameKey: 'template_polish', emoji: '✨', systemPromptKey: 'tpl_polish_system', userPromptKey: 'tpl_polish_user'),
  AIWorkbenchTemplate(id: 'email', nameKey: 'template_email', emoji: '📧', systemPromptKey: 'tpl_email_system', userPromptKey: 'tpl_email_user'),
  AIWorkbenchTemplate(id: 'brainstorm', nameKey: 'template_brainstorm', emoji: '🧠', systemPromptKey: 'tpl_brainstorm_system', userPromptKey: 'tpl_brainstorm_user'),
];

List<AIWorkbenchTemplate> get templates {
  final remoteTemplates = getIt<RemoteConfigService>().getValue<List<dynamic>>('workbench_templates');
  if (remoteTemplates == null || remoteTemplates.isEmpty) return _localTemplates;
  final result = <AIWorkbenchTemplate>[];
  for (final t in remoteTemplates) {
    final m = t as Map<String, dynamic>;
    final id = m['id'] as String? ?? '';
    final local = _localTemplates.where((l) => l.id == id).firstOrNull;
    result.add(AIWorkbenchTemplate(
      id: id,
      nameKey: local?.nameKey ?? m['name_key'] as String? ?? id,
      emoji: m['emoji'] as String? ?? local?.emoji ?? '🔧',
      systemPromptKey: local?.systemPromptKey ?? '',
      userPromptKey: local?.userPromptKey ?? '',
      remoteSystemPrompt: m['system_prompt'] as String?,
      remoteUserPrompt: m['user_prompt'] as String?));
  }
  return result.isNotEmpty ? result : _localTemplates;
}

class AIWorkbenchViewNew extends StatelessWidget {
  const AIWorkbenchViewNew({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AgentBloc>()..add(const AgentModelsLoadRequested())),
        BlocProvider(create: (_) => getIt<ChatBloc>()),
      ],
      child: const _AIWorkbenchContent());
  }
}

class _AIWorkbenchContent extends StatefulWidget {
  const _AIWorkbenchContent();

  @override
  State<_AIWorkbenchContent> createState() => _AIWorkbenchContentState();
}

class _AIWorkbenchContentState extends State<_AIWorkbenchContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  AIWorkbenchTemplate? _selectedTemplate;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String t(String key) => localeProvider.t(key);

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this);
    _slideAnimation = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: localeProvider.t('back'),
          icon: Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary(context)),
          onPressed: () => Navigator.pop(context)),
        title: Text(
          t('ai_workbench'),
          style: TextStyle(color: AppColors.textPrimary(context), fontSize: 17, fontWeight: FontWeight.w600))),
      body: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            _buildModelSelector(),
            _buildTemplateGrid(),
            Expanded(child: _buildContentArea()),
            _buildInputArea(),
          ])));
  }

  Widget _buildModelSelector() {
    return BlocBuilder<AgentBloc, AgentState>(
      builder: (context, state) {
        if (state is! AgentModelsLoaded) {
          return const SizedBox.shrink();
        }
        final models = state.models;
        if (models.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sf(context),
              borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Icon(LucideIcons.alertCircle, size: 16, color: AppColors.warn(context)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t('no_model_configured'),
                    style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13))),
              ]));
        }
        final active = state.activeModel ?? models.first;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.sf(context),
            borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: active.id,
              isExpanded: true,
              icon: Icon(LucideIcons.chevronDown, size: 16, color: AppColors.textSecondary(context)),
              style: TextStyle(color: AppColors.textPrimary(context), fontSize: 14),
              dropdownColor: AppColors.sf(context),
              items: models.map((m) {
                return DropdownMenuItem(
                  value: m.id,
                  child: Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: AppColors.acc(context), shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(m.name, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text('(${m.provider})', style: TextStyle(color: AppColors.textSecondary(context), fontSize: 11)),
                    ]));
              }).toList(),
              onChanged: (id) {
                if (id != null) {
                  context.read<AgentBloc>().add(AgentModelSelected(id));
                  context.read<ChatBloc>().add(AiModelChanged(id));
                }
              })));
      });
  }

  Widget _buildTemplateGrid() {
    return Container(
      height: 90,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final tpl = templates[index];
          final isSelected = _selectedTemplate?.id == tpl.id;
          return Semantics(
            label: t(tpl.nameKey),
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() => _selectedTemplate = tpl);
                _inputController.text = tpl.userPromptTemplate;
              },
              child: Container(
                width: 76,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.acc(context).withValues(alpha: 0.12) : AppColors.sf(context),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? Border.all(color: AppColors.acc(context), width: 1.5) : null),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(tpl.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(
                      t(tpl.nameKey),
                      style: TextStyle(
                        color: isSelected ? AppColors.acc(context) : AppColors.textSecondary(context),
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  ]))));
        }));
  }

  Widget _buildContentArea() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        String content = '';
        bool isGenerating = false;
        if (state is AiChatGenerating) {
          content = state.partialContent;
          isGenerating = true;
        } else if (state is AiChatReady) {
          final last = state.messages.isNotEmpty ? state.messages.last : null;
          content = last?.content ?? '';
        } else if (state is AiChatError) {
          content = '${t('generation_error')}: ${state.message}';
        }

        if (content.isEmpty && !isGenerating) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.sparkles, size: 48, color: AppColors.iconGray(context)),
                const SizedBox(height: 12),
                Text(t('workbench_empty'), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 15)),
                const SizedBox(height: 4),
                Text(t('workbench_empty_hint'), style: TextStyle(color: AppColors.textDisabled(context), fontSize: 13)),
              ]));
        }

        if (isGenerating) _scrollToBottom();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.sf(context),
            borderRadius: BorderRadius.circular(12)),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedTemplate case final selTemplate?) ...[
                  Row(
                    children: [
                      Text(selTemplate.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(t(selTemplate.nameKey), style: TextStyle(color: AppColors.acc(context), fontSize: 13, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      if (!isGenerating && content.isNotEmpty) ...[
                        Semantics(
                          label: localeProvider.t('copy'),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: content));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(t('copied')), backgroundColor: AppColors.acc(context), duration: const Duration(milliseconds: 1500)));
                            },
                            child: Icon(LucideIcons.copy, size: 16, color: AppColors.textSecondary(context)))),
                        const SizedBox(width: 12),
                        Semantics(
                          label: localeProvider.t('share'),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => SharePlus.instance.share(ShareParams(text: content)),
                            child: Icon(LucideIcons.share2, size: 16, color: AppColors.textSecondary(context)))),
                      ],
                    ]),
                ],
                const SizedBox(height: 12),
                Divider(color: AppColors.divider(context), height: 1),
                const SizedBox(height: 12),
                SelectableText(
                  content + (isGenerating ? '▊' : ''),
                  style: TextStyle(color: AppColors.textPrimary(context), fontSize: 15, height: 1.6)),
                if (isGenerating) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.acc(context))),
                      const SizedBox(width: 8),
                      Text(t('generating'), style: TextStyle(color: AppColors.textSecondary(context), fontSize: 13)),
                    ]),
                ],
              ])));
      });
  }

  Widget _buildInputArea() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final isGenerating = state is AiChatGenerating;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.bg(context),
            border: Border(top: BorderSide(color: AppColors.divider(context), width: 0.5))),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: TextField(
                      controller: _inputController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: TextStyle(color: AppColors.textPrimary(context), fontSize: 15),
                      decoration: InputDecoration(
                        labelText: _selectedTemplate != null ? t('workbench_input_hint') : t('workbench_select_template'),
                        hintStyle: TextStyle(color: AppColors.textDisabled(context), fontSize: 14),
                        filled: true,
                        fillColor: AppColors.sf(context),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10))))),
                const SizedBox(width: 8),
                if (isGenerating)
                  Semantics(
                    label: localeProvider.t('stop_generating'),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.read<ChatBloc>().add(const AiGenerationStopped()),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.dng(context).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12)),
                        child: Icon(LucideIcons.square, color: AppColors.dng(context), size: 18))))
                else
                  Semantics(
                    label: localeProvider.t('send'),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        final input = _inputController.text.trim();
                        final tpl = _selectedTemplate;
                        if (input.isEmpty || tpl == null) return;
                        context.read<ChatBloc>().add(AiMessageSent(
                          content: tpl.userPromptTemplate + input));
                        _inputController.clear();
                      },
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: _selectedTemplate != null && _inputController.text.trim().isNotEmpty
                              ? AppColors.acc(context)
                              : AppColors.acc(context).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12)),
                        child: Icon(LucideIcons.sparkles, color: AppColors.textPrimary(context), size: 20)))),
              ])));
      });
  }
}
