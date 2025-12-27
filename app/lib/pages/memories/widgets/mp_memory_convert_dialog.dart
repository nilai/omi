import 'package:flutter/material.dart';
import 'package:omi/backend/http/mp_api/mp_memory.dart';
import 'package:omi/backend/schema/mp/mp_memory.dart';
import 'package:omi/providers/home_provider.dart';
import 'package:provider/provider.dart';

import '../../../backend/http/mp_api/mp_template.dart' as mp_template_api;
import '../../../backend/schema/mp/mp_data_model.dart';
import '../../../backend/schema/mp/mp_template.dart';
import '../../mp_custom_utils/mp_timestamp_utils.dart';
import '../../mp_custom_utils/mp_toast_utils.dart';
import '../../mp_template _selection/providers/template_selection_provider.dart';
import '../../mp_template _selection/template_selection_page.dart';

/// Template configuration for the dialog.
class MPMemoryConvertTemplate {
  final String id;
  final String title;
  final String description;
  final String provider;
  final String? badge;
  final String? icon;

  const MPMemoryConvertTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.provider,
    this.badge,
    this.icon,
  });
}

/// Bottom sheet dialog to configure memory conversion.
// ignore: must_be_immutable
class MPMemoryConvertDialog extends StatefulWidget {
  List<MPMemoryConvertTemplate> templates;
  final bool initialSeparateSpeakers;
  final String initialLanguage;
  final String initialModel;
  final MPMemoryStruct memory;

  /// 立即生成-成功回调
  final VoidCallback? onGenerate;

  MPMemoryConvertDialog({
    super.key,
    required this.memory,
    this.initialSeparateSpeakers = true,
    this.initialLanguage = 'English',
    this.initialModel = 'Auto',
    required this.templates,
    this.onGenerate,
  });

  /// Shows the dialog using a modal bottom sheet and returns the selection.
  static Future<void> show(
    BuildContext context, {
    bool initialSeparateSpeakers = true,
    String initialLanguage = 'English',
    String initialModel = 'Auto',
    required MPMemoryStruct memory,
    VoidCallback? onGenerate,
  }) async {
    final request = MPGetTemplateListRequest(
      pageSize: 20,
      cursor: '',
    );
    final response = await mp_template_api.getTemplateList(request);
    List<MPMemoryConvertTemplate> templates = [];
    if (response?.recentTemplate != null) {
      templates.add(MPMemoryConvertTemplate(
        id: response?.recentTemplate?.id ?? '',
        title: response?.recentTemplate?.title ?? '',
        description: response?.recentTemplate?.prompt ?? '',
        provider: 'Auto',
        icon: response?.recentTemplate?.icon,
      ));
    }
    final recommendTemplates = response?.recommendTemplates
            .map((template) => MPMemoryConvertTemplate(
                  id: template.id ?? '',
                  title: template.title ?? '',
                  description: template.prompt ?? '',
                  provider: 'Auto',
                  icon: template.icon,
                ))
            .toList() ??
        [];
    templates.addAll(recommendTemplates);
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MPMemoryConvertDialog(
        memory: memory,
        templates: templates,
        initialSeparateSpeakers: initialSeparateSpeakers,
        initialLanguage: initialLanguage,
        initialModel: initialModel,
        onGenerate: onGenerate,
      ),
    );
  }

  @override
  State<MPMemoryConvertDialog> createState() => _MPMemoryConvertDialogState();
}

class _MPMemoryConvertDialogState extends State<MPMemoryConvertDialog> {
  late MPMemoryConvertTemplate? _selectedTemplate;
  late bool _separateSpeakers;
  late String _language;
  late String _model;

  @override
  void initState() {
    super.initState();

    _selectedTemplate = widget.templates.isNotEmpty ? widget.templates.first : null;
    _separateSpeakers = widget.initialSeparateSpeakers;
    _language = widget.initialLanguage;
    _model = widget.initialModel;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.8; // 屏幕高度的五分之四

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.description_outlined,
                              size: 20,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    MPTimestampUtils.timestampToRelativeDateString(widget.memory.createAt),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F1F1F),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    // secondsToHumanReadable(widget.memory.duration),
                                    MPTimestampUtils.toMinutesAndSecondsString(widget.memory.duration),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
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
                              '选择总结模板',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F1F1F),
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                // MyApp.navigatorKey.currentState!.overlay!.context
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ChangeNotifierProvider<TemplateSelectionProvider>(
                                      create: (_) => TemplateSelectionProvider(),
                                      child: TemplateSelectionPage(
                                        type: TemplateSelectionPageType.select,
                                        onUseTemplate: (item) {
                                          if (_selectedTemplate != null && _selectedTemplate?.id == item.id) {
                                            return;
                                          }
                                          MPMemoryConvertTemplate? temp;
                                          for (var template in widget.templates) {
                                            if (template.id == item.id) {
                                              temp = template;
                                              break;
                                            }
                                          }
                                          if (temp != null) {
                                            _selectedTemplate = temp;
                                            setState(() {});
                                            return;
                                          }
                                          temp = MPMemoryConvertTemplate(
                                            id: item.id,
                                            title: item.title,
                                            description: item.prompt ?? '选中模版的prompt为空',
                                            provider: 'Auto',
                                            icon: item.imageUrl,
                                          );
                                          widget.templates.insert(0, temp);
                                          _selectedTemplate = temp;
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
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
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.card_giftcard,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '剩余2个免费模板使用次数',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Visibility(
                          visible: widget.templates.isNotEmpty,
                          child: SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.templates.length,
                              itemBuilder: (context, index) {
                                final template = widget.templates[index];
                                return Padding(
                                  padding: EdgeInsets.only(
                                    right: index < widget.templates.length - 1 ? 12 : 0,
                                  ),
                                  child: _TemplateCard(
                                    template: template,
                                    selected: _selectedTemplate?.id == template.id,
                                    onTap: () => setState(() {
                                      _selectedTemplate = template;
                                    }),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Visibility(visible: widget.templates.isNotEmpty, child: const SizedBox(height: 8)),
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
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: InkWell(
                      onTap: () {
                        _onGenerate(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 20,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '立即生成',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onGenerate(BuildContext context) async {
    final req = MPSummaryRecordRequest(
      memoryId: widget.memory.id,
      recordUrl: widget.memory.onlyRecordContent?.recordFile ?? '',
      recordMemoAt: widget.memory.createAt,
    );
    final res = await summaryRecord(req);
    if (res != null && res.baseResp.code == 0) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      widget.onGenerate?.call();
    } else {
      MPToastUtils.showMessage(res?.baseResp.message ?? '生成失败');
    }
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
          thumbColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF6366F1);
              }
              return Colors.white;
            },
          ),
          activeTrackColor: const Color(0xFF6366F1),
          trackColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF6366F1);
              }
              return Colors.white;
            },
          ),
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
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final options = homeProvider.availableLanguages.keys.toList();
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
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
      isScrollControlled: true,
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
        width: 150,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
        ),
        padding: const EdgeInsets.all(14),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 图标在左上角
                _buildIcon(),
                const SizedBox(height: 12),
                // 标题
                Text(
                  template.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                // 描述
                Text(
                  template.description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF4B5563),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Provider和图标
                _Chip(text: template.provider),
              ],
            ),
            // 选中标记在右下角
            if (selected)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6366F1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建图标（支持网络图片和本地asset图片）
  Widget _buildIcon() {
    final iconUrl = template.icon;

    if (iconUrl != null && iconUrl.isNotEmpty) {
      // 如果是网络图片URL
      if (iconUrl.startsWith('http://') || iconUrl.startsWith('https://')) {
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEEF2FF) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              iconUrl,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultIcon();
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return _buildDefaultIcon();
              },
            ),
          ),
        );
      } else if (iconUrl.startsWith('assets/')) {
        // 如果是本地asset图片
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEEF2FF) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              iconUrl,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultIcon();
              },
            ),
          ),
        );
      }
    }

    // 默认图标
    return _buildDefaultIcon();
  }

  /// 构建默认图标
  Widget _buildDefaultIcon() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEEF2FF) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(
          Icons.auto_awesome,
          size: 20,
          color: Color(0xFF6366F1),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
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
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.bar_chart,
          size: 14,
          color: Color(0xFF6B7280),
        ),
      ],
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
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.8,
          ),
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
              Flexible(
                child: ListView.separated(
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
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
