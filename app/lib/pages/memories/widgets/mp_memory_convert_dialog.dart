import 'package:flutter/material.dart';

/// Result returned by the convert dialog.
class MPMemoryConvertResult {
  final MPMemoryConvertTemplate template;
  final bool separateSpeakers;
  final String language;
  final String model;

  MPMemoryConvertResult({
    required this.template,
    required this.separateSpeakers,
    required this.language,
    required this.model,
  });
}

/// Template configuration for the dialog.
class MPMemoryConvertTemplate {
  final String id;
  final String title;
  final String description;
  final String provider;
  final String? badge;

  const MPMemoryConvertTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.provider,
    this.badge,
  });
}

/// Bottom sheet dialog to configure memory conversion.
class MPMemoryConvertDialog extends StatefulWidget {
  final List<MPMemoryConvertTemplate> templates;
  final bool initialSeparateSpeakers;
  final String initialLanguage;
  final String initialModel;

  const MPMemoryConvertDialog({
    super.key,
    required this.templates,
    this.initialSeparateSpeakers = true,
    this.initialLanguage = '中文简体-普通话',
    this.initialModel = 'Auto',
  });

  /// Shows the dialog using a modal bottom sheet and returns the selection.
  static Future<MPMemoryConvertResult?> show(
    BuildContext context, {
    List<MPMemoryConvertTemplate>? templates,
    bool initialSeparateSpeakers = true,
    String initialLanguage = '中文简体-普通话',
    String initialModel = 'Auto',
  }) {
    final dialogTemplates = templates ??
        const [
          MPMemoryConvertTemplate(
            id: 'meeting_notes',
            title: '会议纪要',
            description: '会议过程详细整理 + 详细的会议议题内容和行动事项拆分',
            provider: 'Milo',
            badge: '上次使用',
          ),
          MPMemoryConvertTemplate(
            id: 'smart_summary',
            title: '智能摘要',
            description: '自适应的输出 全场景覆盖',
            provider: 'Auto',
          ),
        ];

    return showModalBottomSheet<MPMemoryConvertResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MPMemoryConvertDialog(
        templates: dialogTemplates,
        initialSeparateSpeakers: initialSeparateSpeakers,
        initialLanguage: initialLanguage,
        initialModel: initialModel,
      ),
    );
  }

  @override
  State<MPMemoryConvertDialog> createState() => _MPMemoryConvertDialogState();
}

class _MPMemoryConvertDialogState extends State<MPMemoryConvertDialog> {
  late MPMemoryConvertTemplate _selectedTemplate;
  late bool _separateSpeakers;
  late String _language;
  late String _model;

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.templates.first;
    _separateSpeakers = widget.initialSeparateSpeakers;
    _language = widget.initialLanguage;
    _model = widget.initialModel;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFCFD2D7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '2025-10-17 16:14:51',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '24m 29s',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'MemoPin',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24, color: Color(0xFFE5E7EB)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '选择总结模版',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '剩余 2 个免费模版使用次数',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6366F1),
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('查看全部'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...widget.templates.map(
                        (template) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TemplateCard(
                            template: template,
                            selected: _selectedTemplate.id == template.id,
                            onTap: () => setState(() => _selectedTemplate = template),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSwitchTile(
                        title: '区分说话人',
                        value: _separateSpeakers,
                        onChanged: (val) => setState(() => _separateSpeakers = val),
                      ),
                      const SizedBox(height: 12),
                      _buildSelector(
                        title: '录音语言',
                        value: _language,
                        onTap: () => _showLanguageSheet(),
                      ),
                      const SizedBox(height: 12),
                      _buildSelector(
                        title: 'AI 模型',
                        value: _model,
                        onTap: () => _showModelSheet(),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(
                              MPMemoryConvertResult(
                                template: _selectedTemplate,
                                separateSpeakers: _separateSpeakers,
                                language: _language,
                                model: _model,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            '立即生成',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1F2937)),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: const Color(0xFF6366F1),
        ),
      ),
    );
  }

  Widget _buildSelector({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1F2937)),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet() async {
    final options = ['中文简体-普通话', 'English', '日本語'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _SimpleSelector(
        title: '录音语言',
        options: options,
        selected: _language,
      ),
    );
    if (selected != null && mounted) {
      setState(() => _language = selected);
    }
  }

  void _showModelSheet() async {
    final options = ['Auto', 'GPT-4o', 'Claude 3.5', 'Gemini'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _SimpleSelector(
        title: 'AI 模型',
        options: options,
        selected: _model,
      ),
    );
    if (selected != null && mounted) {
      setState(() => _model = selected);
    }
  }
}

class _TemplateCard extends StatelessWidget {
  final MPMemoryConvertTemplate template;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB);
    final bgColor = selected ? const Color(0xFFF5F7FF) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFEEF2FF) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: selected ? const Color(0xFF6366F1) : const Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        template.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      if (template.badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E7FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            template.badge!,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF4F46E5)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    template.description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Chip(text: template.provider),
                      const SizedBox(width: 8),
                      if (selected)
                        const Icon(Icons.check_circle, color: Color(0xFF6366F1), size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;

  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }
}

class _SimpleSelector extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selected;

  const _SimpleSelector({
    required this.title,
    required this.options,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFCFD2D7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          ListView.separated(
            shrinkWrap: true,
            itemCount: options.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE5E7EB)),
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = option == selected;
              return ListTile(
                title: Text(
                  option,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF6366F1)) : null,
                onTap: () => Navigator.of(context).pop(option),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
