import 'package:flutter/material.dart';
import 'package:memo_pin/common/mp_dismissible_modal_backdrop.dart';
import 'package:memo_pin/common/omi_button.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../../../../../cache/mp_hive_util.dart';
import '../../../../../http/api/mp_template.dart';
import '../../../../../http/schema/mp_data_model.dart';
import '../../../../../http/schema/mp_memory.dart';
import '../../../../../http/schema/mp_template.dart';
import '../../../../../generated/assets.dart';
import '../../../../../utils/mp_toast_utils.dart';
import '../../../../../utils/omi_image_loader.dart';
import 'mp_choose_summary_style_sheet.dart';

/// 底部说明与确认；确认后返回 [MPSummaryRecordRequest]（含 [MPSummaryRecordRequest.isRegen] 对应接口 `is_regen`）。
Future<MPSummaryRecordRequest?> showMPMemoryGenerateSummarySheet(
  BuildContext context, {
  required String memoryId,
  required String recordUrl,
  required bool isRegen,
  int recordMemoAt = 0,
  VoidCallback? onChangeMode,
}) {
  return showModalBottomSheet<MPSummaryRecordRequest?>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    /// 使用根 Navigator，避免嵌套路由（如 Tab）时底部 sheet 不显示或层级异常
    useRootNavigator: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (BuildContext ctx) {
      return MPDismissibleModalBackdrop(
        child: _MPGenerateSummarySheet(
        memoryId: memoryId,
        recordUrl: recordUrl,
        isRegen: isRegen,
        recordMemoAt: recordMemoAt,
        onChangeMode: onChangeMode,
        ),
      );
    },
  );
}

class _MPGenerateSummarySheet extends StatefulWidget {
  const _MPGenerateSummarySheet({
    required this.memoryId,
    required this.recordUrl,
    required this.isRegen,
    this.recordMemoAt = 0,
    this.onChangeMode,
  });

  final String memoryId;
  final String recordUrl;
  final bool isRegen;
  final int recordMemoAt;

  final VoidCallback? onChangeMode;

  @override
  State<_MPGenerateSummarySheet> createState() =>
      _MPGenerateSummarySheetState();
}

class _MPGenerateSummarySheetState extends State<_MPGenerateSummarySheet> {
  MPGetTemplateListResponse? _tplResp;
  MPTemplateStruct? _selectedTemplate;

  static const Color _kFeatureCardBg = Color(0xFFF2F2F7);
  static const Color _kAutopilotBg = Color(0xFFF7F2E8);
  static const Color _kAutopilotBorder = Color(0xFFE8DCC8);

  static const String _kSummaryTemplateCacheKey =
      'mp_memory_generate_summary_selected_template';

  static MPTemplateStruct _kAutoPilotTemplate = MPTemplateStruct(
    id: null,
    title: 'AutoPilot',
    subTitle: 'AI decides what matters',
    icon: null,
    type: 'autopilot',
    prompt: null,
  );

  @override
  void initState() {
    super.initState();
    _selectedTemplate = _kAutoPilotTemplate;
    _loadCachedSelectedTemplate();
    _loadTemplates();
  }

  Future<void> _loadCachedSelectedTemplate() async {
    try {
      final MPTemplateStruct? cached = await MPHiveUtil.instance.getObject(
        key: _kSummaryTemplateCacheKey,
        fromJson: MPTemplateStruct.fromJson,
      );
      if (!mounted || cached == null) return;
      setState(() {
        _selectedTemplate = cached;
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _cacheSelectedTemplate(MPTemplateStruct tpl) async {
    try {
      await MPHiveUtil.instance.putObject(
        key: _kSummaryTemplateCacheKey,
        object: tpl,
        toJson: (MPTemplateStruct v) => v.toJson(),
      );
    } catch (_) {
      // ignore
    }
  }

  MPTemplateStruct? _findTemplateById(MPGetTemplateListResponse resp, String id) {
    if (id.trim().isEmpty) return null;
    if (resp.recentTemplate?.id == id) return resp.recentTemplate;
    for (final MPTemplateStruct t in resp.recommendTemplates) {
      if (t.id == id) return t;
    }
    for (final MPTemplateStruct t in resp.customTemplates) {
      if (t.id == id) return t;
    }
    for (final List<MPTemplateStruct> list in resp.templates.values) {
      for (final MPTemplateStruct t in list) {
        if (t.id == id) return t;
      }
    }
    return null;
  }

  Future<void> _loadTemplates() async {
    try {
      final MPGetTemplateListResponse? resp = await getTemplateList(
        MPGetTemplateListRequest(pageSize: 50, cursor: ''),
      );
      if (!mounted || resp == null) return;
      if (resp.baseResp.code != 0) return;
      final MPTemplateStruct? serverLatest = resp.recentTemplate;
      final MPTemplateStruct? cur = _selectedTemplate;
      final String? curId = cur?.id?.trim();
      final MPTemplateStruct? refreshedById =
          (curId != null && curId.isNotEmpty) ? _findTemplateById(resp, curId) : null;
      final MPTemplateStruct? next = serverLatest ?? refreshedById ?? cur;

      setState(() {
        _tplResp = resp;
        _selectedTemplate = next;
      });

      if (next != null) {
        await _cacheSelectedTemplate(next);
      }
    } catch (_) {
      // ignore: avoid_catches_without_on_clauses
    }
  }

  String get _modeTitle {
    final String t = (_selectedTemplate?.title ?? '').trim();
    return t;
  }

  String get _modeSubtitle {
    final MPTemplateStruct? tpl = _selectedTemplate;
    return tpl?.subTitle ?? '';
  }

  void _onConfirmGenerate() {
    final String url = widget.recordUrl.trim();
    if (url.isEmpty) {
      MPToastUtils.showMessage('No recording URL available.');
      return;
    }
    final String mid = widget.memoryId.trim();
    if (mid.isEmpty) {
      MPToastUtils.showMessage('Invalid memory.');
      return;
    }
    final String? tplId = _selectedTemplate?.id?.trim();
    Navigator.of(context).pop(
      MPSummaryRecordRequest(
        memoryId: mid,
        recordUrl: url,
        recordMemoAt: widget.recordMemoAt,
        templateId: (tplId != null && tplId.isNotEmpty) ? tplId : null,
        isRegen: widget.isRegen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double maxH = MediaQuery.sizeOf(context).height * 0.8;
    final double kb = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: kb),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Material(
          color: Colors.white,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 8),
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          "Here's what AI will do for you",
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t9_18,
                            fontWeight: OmiFontWeight.medium,
                            color: mainTextColor,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'AI will analyze this memory from a new perspective and create a resummary.',
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t4_13,
                            fontWeight: OmiFontWeight.regular,
                            color: secondTextColor,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _kFeatureCardBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "What you'll get:",
                                style: OmiTextStyle.create(
                                  fontSize: OmiFontSize.t5_14,
                                  fontWeight: OmiFontWeight.medium,
                                  color: mainTextColor,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _MPFeatureRow(
                                icon: OmiImageLoader.localImg(
                                  Assets.omiSparkles,
                                  width: 18,
                                  height: 18,
                                  color: blueTextColor,
                                  fit: BoxFit.contain,
                                ),
                                title: 'Different perspective',
                                subtitle:
                                    'Analyze this memory through a new lens',
                              ),
                              const SizedBox(height: 14),
                              _MPFeatureRow(
                                icon: OmiImageLoader.localImg(
                                  Assets.omiBookText,
                                  width: 18,
                                  height: 18,
                                  color: blueTextColor,
                                  fit: BoxFit.contain,
                                ),
                                title: 'Fresh insights',
                                subtitle:
                                    'Discover details you might have missed',
                              ),
                              const SizedBox(height: 14),
                              _MPFeatureRow(
                                icon: OmiImageLoader.localImg(
                                  Assets.omiQuestion,
                                  width: 18,
                                  height: 18,
                                  color: blueTextColor,
                                  fit: BoxFit.contain,
                                ),
                                title: 'Structured analysis',
                                subtitle:
                                    'Organized sections based on style',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _kAutopilotBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kAutopilotBorder),
                          ),
                          child: Row(
                            crossAxisAlignment: _modeSubtitle.isNotEmpty ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                            children: <Widget>[
                              OmiImageLoader.localImg(
                                Assets.omiSparkles,
                                width: 18,
                                height: 18,
                                color: orangeTextColor,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      _modeTitle,
                                      style: OmiTextStyle.create(
                                        fontSize: OmiFontSize.t5_14,
                                        fontWeight: OmiFontWeight.medium,
                                        color: mainTextColor,
                                        height: 1.25,
                                      ),
                                    ),
                                    if (_modeSubtitle.isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 2),
                                      Text(
                                        _modeSubtitle,
                                        style: OmiTextStyle.create(
                                          fontSize: OmiFontSize.t3_12,
                                          fontWeight: OmiFontWeight.regular,
                                          color: secondTextColor,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  final MPGetTemplateListResponse? resp =
                                      _tplResp;
                                  if (resp == null) return;
                                  showMPChooseSummaryStyleSheet(
                                    context,
                                    recentTemplate: resp.recentTemplate,
                                    recommendTemplates: resp.recommendTemplates,
                                    initialSelected: _selectedTemplate,
                                    onTemplateConfirmed:
                                        (MPTemplateStruct tpl) {
                                      setState(() {
                                        _selectedTemplate = tpl;
                                      });
                                      _cacheSelectedTemplate(tpl);
                                      widget.onChangeMode?.call();
                                    },
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text(
                                        'Change',
                                        style: OmiTextStyle.create(
                                          fontSize: OmiFontSize.t4_13,
                                          fontWeight: OmiFontWeight.medium,
                                          color: blueTextColor,
                                        ),
                                      ),
                                      OmiImageLoader.localImg(Assets.omiSolidRightArrow, width: 8, height: 8),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      12 + MediaQuery.paddingOf(context).bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        OmiButton(
                          text: 'Generate summary',
                          width: double.infinity,
                          height: 50,
                          bgColor: blueTextColor,
                          textColor: Colors.white,
                          textFontSize: OmiFontSize.t5_14,
                          textFontWeight: OmiFontWeight.bold,
                          borderRadius: BorderRadius.circular(12),
                          icon: OmiImageLoader.localImg(
                            Assets.omiSparkles,
                            width: 20,
                            height: 20,
                            color: Colors.white,
                            fit: BoxFit.contain,
                          ),
                          onPressed: _onConfirmGenerate,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'This will add a new activity card below',
                          textAlign: TextAlign.center,
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t2_11,
                            fontWeight: OmiFontWeight.regular,
                            color: secondTextColor.withValues(alpha: 0.85),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MPFeatureRow extends StatelessWidget {
  const _MPFeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final Widget icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(width: 18, child: Center(child: icon)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: OmiTextStyle.create(
                  fontSize: OmiFontSize.t4_13,
                  fontWeight: OmiFontWeight.medium,
                  color: mainTextColor,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: OmiTextStyle.create(
                  fontSize: OmiFontSize.t3_12,
                  fontWeight: OmiFontWeight.regular,
                  color: secondTextColor,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
