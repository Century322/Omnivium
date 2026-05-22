import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_provider.dart';
import '../../core/model_provider.dart';
import '../../core/providers/ai_provider.dart';
import '../../core/remote_config_service.dart';
import '../theme/app_colors.dart';
import '../theme/locale_provider.dart';

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
  AIWorkbenchTemplate(
    id: 'write',
    nameKey: 'template_write',
    emoji: '??',
    systemPromptKey: 'tpl_write_system',
    userPromptKey: 'tpl_write_user',
  ),
  AIWorkbenchTemplate(
    id: 'translate',
    nameKey: 'template_translate',
    emoji: '??',
    systemPromptKey: 'tpl_translate_system',
    userPromptKey: 'tpl_translate_user',
  ),
  AIWorkbenchTemplate(
    id: 'summarize',
    nameKey: 'template_summarize',
    emoji: '??',
    systemPromptKey: 'tpl_summarize_system',
    userPromptKey: 'tpl_summarize_user',
  ),
  AIWorkbenchTemplate(
    id: 'code',
    nameKey: 'template_code',
    emoji: '??',
    systemPromptKey: 'tpl_code_system',
    userPromptKey: 'tpl_code_user',
  ),
  AIWorkbenchTemplate(
    id: 'explain',
    nameKey: 'template_explain',
    emoji: '??',
    systemPromptKey: 'tpl_explain_system',
    userPromptKey: 'tpl_explain_user',
  ),
  AIWorkbenchTemplate(
    id: 'polish',
    nameKey: 'template_polish',
    emoji: '?',
    systemPromptKey: 'tpl_polish_system',
    userPromptKey: 'tpl_polish_user',
  ),
  AIWorkbenchTemplate(
    id: 'email',
    nameKey: 'template_email',
    emoji: '??',
    systemPromptKey: 'tpl_email_system',
    userPromptKey: 'tpl_email_user',
  ),
  AIWorkbenchTemplate(
    id: 'brainstorm',
    nameKey: 'template_brainstorm',
    emoji: '??',
    systemPromptKey: 'tpl_brainstorm_system',
    userPromptKey: 'tpl_brainstorm_user',
  ),
];

List<AIWorkbenchTemplate> get templates {
  final remoteTemplates = RemoteConfigService.instance.getValue<List<dynamic>>(
    'workbench_templates',
  );
  if (remoteTemplates == null || remoteTemplates.isEmpty)
    return _localTemplates;
  final result = <AIWorkbenchTemplate>[];
  for (final t in remoteTemplates) {
    final m = t as Map<String, dynamic>;
    final id = m['id'] as String? ?? '';
    final local = _localTemplates.where((l) => l.id == id).firstOrNull;
    result.add(
      AIWorkbenchTemplate(
        id: id,
        nameKey: local?.nameKey ?? m['name_key'] as String? ?? id,
        emoji: m['emoji'] as String? ?? local?.emoji ?? '??',
        systemPromptKey: local?.systemPromptKey ?? '',
        userPromptKey: local?.userPromptKey ?? '',
        remoteSystemPrompt: m['system_prompt'] as String?,
        remoteUserPrompt: m['user_prompt'] as String?,
      ),
    );
  }
  return result.isNotEmpty ? result : _localTemplates;
}

class AIWorkbenchView extends StatefulWidget {
  final AppProvider provider;
  const AIWorkbenchView({super.key, required this.provider});

  @override
  State<AIWorkbenchView> createState() => _AIWorkbenchViewState();
}

class _AIWorkbenchViewState extends State<AIWorkbenchView>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  String t(String key) => localeProvider.t(key);

  AIWorkbenchTemplate? _selectedTemplate;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _generatedContent = '';
  bool _isGenerating = false;
  StreamSubscription? _streamSub;
  ModelConfig? _selectedModel;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _slideController.forward();
    _selectedModel = widget.provider.model.activeModel;
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _slideController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final input = _inputController.text.trim();
    if (input.isEmpty || _selectedTemplate == null) return;
    if (_selectedModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('no_model_configured')),
          backgroundColor: AppColors.dng(context),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedContent = '';
    });

    ChatService.instance.setModel(_selectedModel!.name);

    final messages = [
      ChatMessage(role: 'system', content: _selectedTemplate!.systemPrompt),
      ChatMessage(
        role: 'user',
        content: _selectedTemplate!.userPromptTemplate + input,
      ),
    ];

    try {
      final stream = await ChatService.instance.chat(
        messages,
        temperature: 0.7,
        maxTokens: 4096,
      );

      _streamSub = stream.listen(
        (chunk) {
          if (mounted) {
            setState(() {
              _generatedContent += chunk;
            });
            _scrollToBottom();
          }
        },
        onDone: () {
          if (mounted) {
            setState(() => _isGenerating = false);
          }
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              _isGenerating = false;
              _generatedContent += '\n\n${t('generation_error')}: $e';
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generatedContent = '${t('generation_error')}: $e';
        });
      }
    }
  }

  void _stopGeneration() {
    _streamSub?.cancel();
    setState(() => _isGenerating = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
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
          icon: Icon(
            LucideIcons.chevronLeft,
            color: AppColors.textPrimary(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t('ai_workbench'),
          style: TextStyle(
            color: AppColors.textPrimary(context),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            _buildModelSelector(),
            _buildTemplateGrid(),
            Expanded(child: _buildContentArea()),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildModelSelector() {
    final models = widget.provider.model.models;
    if (models.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.sf(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 16,
              color: AppColors.warn(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t('no_model_configured'),
                style: TextStyle(
                  color: AppColors.textSecondary(context),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ModelConfig>(
          value: _selectedModel,
          isExpanded: true,
          icon: Icon(
            LucideIcons.chevronDown,
            size: 16,
            color: AppColors.textSecondary(context),
          ),
          style: TextStyle(color: AppColors.textPrimary(context), fontSize: 14),
          dropdownColor: AppColors.sf(context),
          items: models.map((m) {
            return DropdownMenuItem(
              value: m,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(m.name, style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    '(${m.provider})',
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (m) {
            if (m != null) setState(() => _selectedModel = m);
          },
        ),
      ),
    );
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
                  color: isSelected
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : AppColors.sf(context),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: AppColors.accent, width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(tpl.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(
                      t(tpl.nameKey),
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textSecondary(context),
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentArea() {
    if (_generatedContent.isEmpty && !_isGenerating) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.sparkles,
              size: 48,
              color: AppColors.iconGray(context),
            ),
            const SizedBox(height: 12),
            Text(
              t('workbench_empty'),
              style: TextStyle(
                color: AppColors.textSecondary(context),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t('workbench_empty_hint'),
              style: TextStyle(
                color: AppColors.textDisabled(context),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sf(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedTemplate != null) ...[
              Row(
                children: [
                  Text(
                    _selectedTemplate!.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    t(_selectedTemplate!.nameKey),
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (!_isGenerating && _generatedContent.isNotEmpty) ...[
                    Semantics(
                      label: localeProvider.t('copy'),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: _generatedContent),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t('copied')),
                              backgroundColor: AppColors.accent,
                              duration: const Duration(milliseconds: 1500),
                            ),
                          );
                        },
                        child: Icon(
                          LucideIcons.copy,
                          size: 16,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Semantics(
                      label: localeProvider.t('share'),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => SharePlus.instance.share(
                          ShareParams(text: _generatedContent),
                        ),
                        child: Icon(
                          LucideIcons.share2,
                          size: 16,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 12),
            Divider(color: AppColors.divider(context), height: 1),
            const SizedBox(height: 12),
            SelectableText(
              _generatedContent + (_isGenerating ? '��' : ''),
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 15,
                height: 1.6,
              ),
            ),
            if (_isGenerating) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    t('generating'),
                    style: TextStyle(
                      color: AppColors.textSecondary(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        border: Border(
          top: BorderSide(color: AppColors.divider(context), width: 0.5),
        ),
      ),
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
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    labelText: _selectedTemplate != null
                        ? t('workbench_input_hint')
                        : t('workbench_select_template'),
                    hintStyle: TextStyle(
                      color: AppColors.textDisabled(context),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: AppColors.sf(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_isGenerating)
              Semantics(
                label: localeProvider.t('stop_generating'),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _stopGeneration,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.dng(context).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.square,
                      color: AppColors.dng(context),
                      size: 18,
                    ),
                  ),
                ),
              )
            else
              Semantics(
                label: localeProvider.t('send'),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _generate,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          _selectedTemplate != null &&
                              _inputController.text.trim().isNotEmpty
                          ? AppColors.accent
                          : AppColors.accent.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.sparkles,
                      color: AppColors.textPrimary(context),
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
