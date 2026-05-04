import 'package:flutter/material.dart';
import 'package:memo_pin/common/omi_button.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../../../../../http/api/mp_template.dart';
import '../../../../../http/schema/mp_data_model.dart';
import '../../../../../http/schema/mp_template.dart';
import '../../../../../utils/mp_toast_utils.dart';

Future<void> showMPChooseSummaryTemplateSheet(
  BuildContext context, {
  MPTemplateStruct? recentTemplate,
  required List<MPTemplateStruct> recommendTemplates,
  required List<MPTemplateStruct> customTemplates,
  MPTemplateStruct? selected,
  void Function(MPTemplateStruct tpl)? onTemplateConfirmed,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (BuildContext ctx) {
      return _MPChooseSummaryTemplateSheet(
        recentTemplate: recentTemplate,
        recommendTemplates: recommendTemplates,
        customTemplates: customTemplates,
        selected: selected,
        onTemplateConfirmed: onTemplateConfirmed,
      );
    },
  );
}

class _MPChooseSummaryTemplateSheet extends StatefulWidget {
  const _MPChooseSummaryTemplateSheet({
    required this.recommendTemplates,
    required this.customTemplates,
    this.recentTemplate,
    this.selected,
    this.onTemplateConfirmed,
  });

  final MPTemplateStruct? recentTemplate;
  final List<MPTemplateStruct> recommendTemplates;
  final List<MPTemplateStruct> customTemplates;
  final MPTemplateStruct? selected;
  final void Function(MPTemplateStruct tpl)? onTemplateConfirmed;

  @override
  State<_MPChooseSummaryTemplateSheet> createState() =>
      _MPChooseSummaryTemplateSheetState();
}

class _MPChooseSummaryTemplateSheetState
    extends State<_MPChooseSummaryTemplateSheet> {
  MPTemplateStruct? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected ??
        widget.recentTemplate ??
        (widget.recommendTemplates.isNotEmpty
            ? widget.recommendTemplates.first
            : (widget.customTemplates.isNotEmpty
                ? widget.customTemplates.first
                : null));
  }

  void _pop() => Navigator.of(context).pop();

  Future<void> _onUseThisStyle() async {
    final MPTemplateStruct? sel = _selected;
    if (sel == null) return;

    final String id = (sel.id ?? '').trim();
    if (id.isEmpty) {
      widget.onTemplateConfirmed?.call(sel);
      _pop();
      return;
    }

    final MPSetTemplateDefaultResponse? resp = await setTemplateDefault(
      MPSetTemplateDefaultRequest(templateId: id),
    );
    if (!mounted) return;
    if (resp == null || resp.baseResp.code != 0) {
      MPToastUtils.showMessage(
        'Couldn\'t set default template. Please try again later.',
        context: context,
      );
      return;
    }

    widget.onTemplateConfirmed?.call(sel);
    _pop();
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    'Choose summary style',
                    style: OmiTextStyle.create(
                      fontSize: OmiFontSize.t9_18,
                      fontWeight: OmiFontWeight.medium,
                      color: mainTextColor,
                      height: 1.25,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    children: <Widget>[
                      if (widget.recentTemplate != null) ...<Widget>[
                        _MPTemplateSectionTitle(title: 'Recent'),
                        _MPTemplateTile(
                          tpl: widget.recentTemplate!,
                          selected: _selected?.id == widget.recentTemplate!.id,
                          onTap: () => setState(() => _selected =
                              widget.recentTemplate),
                        ),
                        const SizedBox(height: 14),
                      ],
                      _MPTemplateSectionTitle(title: 'Recommended'),
                      for (final MPTemplateStruct t in widget.recommendTemplates)
                        _MPTemplateTile(
                          tpl: t,
                          selected: _selected?.id == t.id,
                          onTap: () => setState(() => _selected = t),
                        ),
                      const SizedBox(height: 14),
                      _MPTemplateSectionTitle(title: 'Custom'),
                      if (widget.customTemplates.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'No custom templates',
                            style: OmiTextStyle.create(
                              fontSize: OmiFontSize.t4_13,
                              fontWeight: OmiFontWeight.regular,
                              color: secondTextColor,
                            ),
                          ),
                        )
                      else
                        for (final MPTemplateStruct t in widget.customTemplates)
                          _MPTemplateTile(
                            tpl: t,
                            selected: _selected?.id == t.id,
                            onTap: () => setState(() => _selected = t),
                          ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    12 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: OmiButton(
                    text: 'Use this style',
                    width: double.infinity,
                    height: 50,
                    bgColor: blueTextColor,
                    textColor: Colors.white,
                    textFontSize: OmiFontSize.t5_14,
                    textFontWeight: OmiFontWeight.bold,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: _selected == null ? null : _onUseThisStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MPTemplateSectionTitle extends StatelessWidget {
  const _MPTemplateSectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: OmiTextStyle.create(
          fontSize: OmiFontSize.t3_12,
          fontWeight: OmiFontWeight.bold,
          color: secondTextColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _MPTemplateTile extends StatelessWidget {
  const _MPTemplateTile({
    required this.tpl,
    required this.selected,
    this.onTap,
  });

  final MPTemplateStruct tpl;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String title = (tpl.title ?? '').trim().isNotEmpty
        ? (tpl.title ?? '').trim()
        : 'Template';
    final String subtitle = (tpl.prompt ?? '').trim().isNotEmpty
        ? (tpl.prompt ?? '').trim()
        : ((tpl.type ?? '').trim().isNotEmpty ? (tpl.type ?? '').trim() : '');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F4FF) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(12),
          border: selected
              ? Border.all(color: blueTextColor.withValues(alpha: 0.65))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: OmiTextStyle.create(
                      fontSize: OmiFontSize.t5_14,
                      fontWeight: OmiFontWeight.medium,
                      color: mainTextColor,
                      height: 1.25,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
            if (selected) ...<Widget>[
              const SizedBox(width: 8),
              Icon(Icons.check, size: 18, color: blueTextColor),
            ],
          ],
        ),
      ),
    );
  }
}

