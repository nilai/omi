// AI-generated START - 主要语言选择弹窗组件
import 'package:flutter/material.dart';
import 'package:omi/providers/home_provider.dart';
import 'package:provider/provider.dart';

/// 主要语言选择弹窗
class PrimaryLanguageDialog {
  /// 显示主要语言选择弹窗
  ///
  /// [context] - BuildContext
  /// [isRequired] - 是否必须选择（如果为true，则不能跳过）
  /// [onLanguageSelected] - 语言选择回调，参数为语言代码和语言名称
  static Future<void> show(
    BuildContext context, {
    bool isRequired = false,
    Function(String languageCode, String languageName)? onLanguageSelected,
  }) async {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final languages = homeProvider.availableLanguages.entries.toList();

    // 预设选中的语言
    String? selectedLanguage = homeProvider.userPrimaryLanguage.isNotEmpty ? homeProvider.userPrimaryLanguage : null;
    String? selectedLanguageName = selectedLanguage != null
        ? homeProvider.availableLanguages.entries.firstWhere((element) => element.value == selectedLanguage).key
        : null;

    await showDialog(
      context: context,
      barrierDismissible: !isRequired,
      builder: (dialogContext) {
        return _PrimaryLanguageDialogContent(
          languages: languages,
          selectedLanguage: selectedLanguage,
          selectedLanguageName: selectedLanguageName,
          isRequired: isRequired,
          onLanguageSelected: (languageCode, languageName) async {
            Navigator.of(dialogContext).pop();

            // final success = await homeProvider.updateUserPrimaryLanguage(languageCode);
            // if (success && dialogContext.mounted) {
            //   Provider.of<CaptureProvider>(dialogContext, listen: false).onRecordProfileSettingChanged();
            //   Navigator.of(dialogContext).pop();
            //   if (onLanguageSelected != null) {
            //     onLanguageSelected(languageCode, languageName);
            //   } else {
            //     AppSnackbar.showSnackbarSuccess('Language set to $languageName');
            //   }
            // } else {
            //   AppSnackbar.showSnackbarError('Failed to set language');
            // }
          },
        );
      },
    );
  }
}

class _PrimaryLanguageDialogContent extends StatefulWidget {
  final List<MapEntry<String, String>> languages;
  final String? selectedLanguage;
  final String? selectedLanguageName;
  final bool isRequired;
  final Function(String languageCode, String languageName) onLanguageSelected;

  const _PrimaryLanguageDialogContent({
    required this.languages,
    this.selectedLanguage,
    this.selectedLanguageName,
    required this.isRequired,
    required this.onLanguageSelected,
  });

  @override
  State<_PrimaryLanguageDialogContent> createState() => _PrimaryLanguageDialogContentState();
}

class _PrimaryLanguageDialogContentState extends State<_PrimaryLanguageDialogContent> {
  late String? _selectedLanguage;
  late String? _selectedLanguageName;
  String _searchQuery = '';
  List<MapEntry<String, String>> _filteredLanguages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage;
    _selectedLanguageName = widget.selectedLanguageName;
    _filteredLanguages = List.from(widget.languages);

    // 延迟滚动到选中项
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedLanguage();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedLanguage() {
    if (_selectedLanguage != null) {
      final selectedIndex = _filteredLanguages.indexWhere((lang) => lang.value == _selectedLanguage);
      if (selectedIndex != -1 && _scrollController.hasClients) {
        _scrollController.animateTo(
          selectedIndex * 56.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _filterLanguages(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (query.isEmpty) {
        _filteredLanguages = widget.languages;
      } else {
        _filteredLanguages = widget.languages.where((lang) {
          return lang.key.toLowerCase().contains(_searchQuery) || lang.value.toLowerCase().contains(_searchQuery);
        }).toList();
      }
      // 重新滚动到选中项
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedLanguage();
      });
    });
  }

  void _selectLanguage(String languageCode, String languageName) {
    setState(() {
      _selectedLanguage = languageCode;
      _selectedLanguageName = languageName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI-generated START - 标题栏
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 20.0, 16.0, 16.0),
              child: Row(
                children: [
                  // 地球图标
                  Container(
                    width: 32.0,
                    height: 32.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(
                      Icons.language,
                      color: Color(0xFF8B5CF6),
                      size: 20.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  // 标题
                  const Expanded(
                    child: Text(
                      'Primary Language',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // 关闭按钮
                  if (!widget.isRequired)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
            // AI-generated END - 标题栏

            // AI-generated START - 描述文字
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Set your language for sharper transcriptions and a personalized experience.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14.0,
                  height: 1.4,
                ),
              ),
            ),
            // AI-generated END - 描述文字

            const SizedBox(height: 20.0),

            // AI-generated START - 搜索框
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                controller: _searchController,
                onChanged: _filterLanguages,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search language by name ...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                ),
              ),
            ),
            // AI-generated END - 搜索框

            const SizedBox(height: 16.0),

            // AI-generated START - 语言列表
            Flexible(
              child: _filteredLanguages.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No languages found',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      shrinkWrap: true,
                      itemCount: _filteredLanguages.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemBuilder: (context, index) {
                        final language = _filteredLanguages[index];
                        final isSelected = _selectedLanguage == language.value;

                        return InkWell(
                          onTap: () => _selectLanguage(language.value, language.key),
                          borderRadius: BorderRadius.circular(12.0),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF8B5CF6).withOpacity(0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12.0),
                              border: isSelected
                                  ? Border.all(
                                      color: const Color(0xFF8B5CF6),
                                      width: 1.0,
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    language.key,
                                    style: TextStyle(
                                      color: isSelected ? const Color(0xFF8B5CF6) : Colors.black87,
                                      fontSize: 16.0,
                                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF8B5CF6),
                                    size: 20.0,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // AI-generated END - 语言列表

            const SizedBox(height: 16.0),

            // AI-generated START - 底部按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 20.0),
              child: Row(
                children: [
                  // Skip 按钮
                  if (!widget.isRequired)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  if (!widget.isRequired) const SizedBox(width: 12.0),
                  // Confirm 按钮
                  Expanded(
                    flex: widget.isRequired ? 1 : 1,
                    child: ElevatedButton(
                      onPressed: _selectedLanguage == null
                          ? null
                          : () => widget.onLanguageSelected(_selectedLanguage!, _selectedLanguageName!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        disabledBackgroundColor: const Color(0xFF8B5CF6).withOpacity(0.3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // AI-generated END - 底部按钮
          ],
        ),
      ),
    );
  }
}
// AI-generated END - primary_language_dialog.dart
