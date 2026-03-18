import 'package:flutter/material.dart';
import 'package:omi/pages/mp_custom_utils/mp_toast_utils.dart';
import 'package:omi/utils/responsive/responsive_helper.dart';
import 'package:omi/pages/mp_custom_widgets/mp_custom_switch.dart';

import '../../backend/http/mp_api/mp_memo.dart';
import '../../backend/schema/mp/mp_data_model.dart';
import '../../backend/schema/mp/mp_memo.dart';

/// AI 设置对话框
/// 用于自定义 MemoPin AI 的个性化设置
class MPAISettingDialog extends StatefulWidget {
  const MPAISettingDialog({super.key, this.aiSettings});

  final MPUserAISettings? aiSettings;

  /// 显示对话框
  static Future<void> show(BuildContext context, {MPUserAISettings? aiSettings}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MPAISettingDialog(aiSettings: aiSettings),
    );
  }

  @override
  State<MPAISettingDialog> createState() => _MPAISettingDialogState();
}

class _MPAISettingDialogState extends State<MPAISettingDialog> {
  // 状态变量
  bool _enableCustomization = true;
  String _verbosity = 'Medium';
  String _personality = 'Custom';
  final TextEditingController _personalityDescriptionController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _additionalInfoController = TextEditingController();

  // 下拉选项
  final List<String> _verbosityOptions = ['Low', 'Medium', 'High'];
  final List<String> _personalityOptions = ['Professional', 'Warm', 'Casual', 'Custom'];

  @override
  void initState() {
    // TODO: implement initState
    _nameController.text = widget.aiSettings?.appellation ?? '';
    super.initState();
  }

  @override
  void dispose() {
    _personalityDescriptionController.dispose();
    _nameController.dispose();
    _occupationController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  /// 保存设置
  void _onSave() async {
    final request = MPUpdateMemoAIRequest(
      appellation: _nameController.text,
      profession: _occupationController.text,
      aiPersonality: _personalityDescriptionController.text,
      responseStyle: _verbosity,
      customPrompt: _additionalInfoController.text,
    );
    final response = await updateMemoAI(request);
    if (response == null) {
      MPToastUtils.showMessage('Failed to update AI settings');
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  /// 取消并关闭对话框
  void _onCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDialogHeight = screenHeight * 0.9; // 屏幕高度的五分之四
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: GestureDetector(
        onTap: () {}, // 阻止事件冒泡
        child: Container(
          width: double.infinity,
          height: maxDialogHeight,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          child: Column(
            children: [
              // 顶部标题栏
              _buildHeader(),
              // 可滚动内容区域
              Expanded(
                child: _buildScrollableContent(),
              ),
              // 底部保存按钮
              _buildBottomSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建顶部标题栏
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左上角 Cancel 按钮（占位，保持对称）
          TextButton(
            onPressed: () {},
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.transparent,
                fontSize: 16,
              ),
            ),
          ),
          // 中间标题
          const Text(
            'Customize MemoPin AI',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          // 右上角 Cancel 按钮（
          TextButton(
            onPressed: _onCancel,
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建可滚动内容区域
  Widget _buildScrollableContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enable Customization 开关
          _buildSettingRow(
            label: 'Enable Customization',
            child: MPCustomSwitch(
              value: _enableCustomization,
              onChanged: (value) {
                setState(() {
                  _enableCustomization = value;
                });
              },
              activeColor: ResponsiveHelper.purplePrimary,
            ),
          ),
          const SizedBox(height: 24),
          // Verbosity 下拉菜单
          _buildSettingRow(
            label: 'Verbosity',
            child: _buildDropdown(
              value: _verbosity,
              items: _verbosityOptions,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _verbosity = value;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          // Personality 下拉菜单
          _buildSettingRow(
            label: 'Personality',
            showInfoIcon: true,
            child: _buildDropdown(
              value: _personality,
              items: _personalityOptions,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _personality = value;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          // Personality Description 文本区域
          if (_enableCustomization && _personality == 'Custom')
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: _buildMultilineInput(
                controller: _personalityDescriptionController,
                hint: 'Describe the personality and communication style you\'d like...',
                minLines: 4,
                enabled: true,
              ),
            ),
          // What should we call you? 输入框
          _buildSectionTitle('What should we call you?'),
          const SizedBox(height: 12),
          _buildTextInput(
            controller: _nameController,
            hint: 'Enter your name',
          ),
          const SizedBox(height: 24),
          // What do you do? 输入框
          _buildSectionTitle('What do you do?'),
          const SizedBox(height: 12),
          _buildTextInput(
            controller: _occupationController,
            hint: 'Tech founder, stay-at-home mom, student, etc.',
          ),
          const SizedBox(height: 24),
          // Anything else MemoPin should know about you? 文本区域
          if (_enableCustomization && _personality == 'Custom') ...[
            _buildSectionTitle('Anything else MemoPin should know about you?'),
            const SizedBox(height: 12),
            _buildMultilineInput(
              controller: _additionalInfoController,
              hint: 'Share any additional context that would help personalize your experience...',
              minLines: 4,
              enabled: true,
            ),
          ],
          // 底部间距，确保内容滑动到底部后距离底部 Save 按钮 24px
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// 构建设置行
  Widget _buildSettingRow({
    required String label,
    required Widget child,
    bool showInfoIcon = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
            if (showInfoIcon) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  // TODO: 显示信息提示
                },
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        child,
      ],
    );
  }

  /// 构建下拉菜单
  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        menuTheme: MenuThemeData(
          style: MenuStyle(
            backgroundColor: WidgetStateProperty.all(Colors.white),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            elevation: WidgetStateProperty.all(8),
            shadowColor: WidgetStateProperty.all(Colors.black.withOpacity(0.1)),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: DropdownButton<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          underline: const SizedBox.shrink(),
          icon: Icon(
            Icons.arrow_drop_down,
            color: Colors.grey[600],
          ),
          isExpanded: false,
          dropdownColor: Colors.white,
          menuMaxHeight: 200,
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// 构建文本输入框
  Widget _buildTextInput({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        cursorColor: Colors.black,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  /// 构建多行文本输入框
  Widget _buildMultilineInput({
    required TextEditingController controller,
    required String hint,
    int minLines = 4,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        minLines: minLines,
        enabled: enabled,
        cursorColor: Colors.black,
        style: TextStyle(
          color: enabled ? Colors.black87 : Colors.grey[400],
          fontSize: 14,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  /// 构建章节标题
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// 构建底部保存按钮
  Widget _buildBottomSaveButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: ResponsiveHelper.purplePrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Save',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
