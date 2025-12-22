// AI-generated START - 模板图标选择弹窗组件
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omi/gen/assets.gen.dart';
import 'package:omi/pages/mp_custom_utils/mp_toast_utils.dart';
import 'package:omi/services/mp_image_upload.dart';

/// 图标选择结果
/// 包含本地图片路径和上传后的URL
class IconSelectionResult {
  /// 本地图片路径（asset路径）
  final String localPath;

  /// 上传后的图片URL（上传成功后才有值）
  String? url;

  IconSelectionResult({
    required this.localPath,
    this.url,
  });
}

/// 模板图标选择弹窗组件
/// 显示 mp_apps_1 到 mp_apps_36 的图标，支持选择并上传
class MPTemplateIconSelectionPopup extends StatefulWidget {
  // AI-generated START - 构造函数
  const MPTemplateIconSelectionPopup({
    super.key,
    this.onIconSelected,
  });
  // AI-generated END - 构造函数

  /// 图标选择回调，参数为图标选择结果（包含本地路径和URL）
  final ValueChanged<IconSelectionResult>? onIconSelected;

  // AI-generated START - 创建状态
  @override
  State<MPTemplateIconSelectionPopup> createState() => _MPTemplateIconSelectionPopupState();
  // AI-generated END - 创建状态

  // AI-generated START - 显示弹窗静态方法
  /// 显示模板图标选择弹窗
  /// 返回 IconSelectionResult，包含本地路径和上传后的URL
  static Future<IconSelectionResult?> show({
    required BuildContext context,
  }) {
    return showDialog<IconSelectionResult>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) {
        return MPTemplateIconSelectionPopup(
          onIconSelected: (result) {
            // 回调仅用于通知，不在这里关闭弹窗
            // 弹窗关闭由 _onIconTap 方法处理
          },
        );
      },
    );
  }
  // AI-generated END - 显示弹窗静态方法
}

class _MPTemplateIconSelectionPopupState extends State<MPTemplateIconSelectionPopup> {
  // AI-generated START - 选中的图标索引
  int? _selectedIndex;
  // AI-generated END - _selectedIndex

  // AI-generated START - 是否正在上传
  bool _isUploading = false;
  // AI-generated END - _isUploading

  // AI-generated START - 图标列表
  /// 获取所有 mp_apps 图标的 AssetGenImage 列表（按数字顺序 1-36）
  List<AssetGenImage> get _iconAssets => [
        Assets.images.mpApps1,
        Assets.images.mpApps2,
        Assets.images.mpApps3,
        Assets.images.mpApps4,
        Assets.images.mpApps5,
        Assets.images.mpApps6,
        Assets.images.mpApps7,
        Assets.images.mpApps8,
        Assets.images.mpApps9,
        Assets.images.mpApps10,
        Assets.images.mpApps11,
        Assets.images.mpApps12,
        Assets.images.mpApps13,
        Assets.images.mpApps14,
        Assets.images.mpApps15,
        Assets.images.mpApps16,
        Assets.images.mpApps17,
        Assets.images.mpApps18,
        Assets.images.mpApps19,
        Assets.images.mpApps20,
        Assets.images.mpApps21,
        Assets.images.mpApps22,
        Assets.images.mpApps23,
        Assets.images.mpApps24,
        Assets.images.mpApps25,
        Assets.images.mpApps26,
        Assets.images.mpApps27,
        Assets.images.mpApps28,
        Assets.images.mpApps29,
        Assets.images.mpApps30,
        Assets.images.mpApps31,
        Assets.images.mpApps32,
        Assets.images.mpApps33,
        Assets.images.mpApps34,
        Assets.images.mpApps35,
        Assets.images.mpApps36,
      ];
  // AI-generated END - _iconAssets

  // AI-generated START - 构建方法
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AI-generated START - 顶部标题栏
            _buildHeader(),
            // AI-generated END - 顶部标题栏

            // AI-generated START - 图标网格
            Flexible(
              child: _buildIconGrid(),
            ),
            // AI-generated END - 图标网格
          ],
        ),
      ),
    );
  }
  // AI-generated END - 构建方法

  // AI-generated START - 构建顶部标题栏
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // AI-generated START - 左侧标题
          const Text(
            '模板图标',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          // AI-generated END - 左侧标题

          const Spacer(),

          // AI-generated START - 右侧关闭按钮
          IconButton(
            icon: const Icon(
              Icons.close,
              color: Color(0xFF6B7280),
              size: 24.0,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          // AI-generated END - 右侧关闭按钮
        ],
      ),
    );
  }
  // AI-generated END - 构建顶部标题栏

  // AI-generated START - 构建图标网格
  Widget _buildIconGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6, // 一排6个
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: 1.0,
        ),
        itemCount: _iconAssets.length,
        itemBuilder: (context, index) {
          return _buildIconItem(index);
        },
      ),
    );
  }
  // AI-generated END - 构建图标网格

  // AI-generated START - 构建单个图标项
  Widget _buildIconItem(int index) {
    final isSelected = _selectedIndex == index;
    final iconAsset = _iconAssets[index];

    return GestureDetector(
      onTap: _isUploading ? null : () => _onIconTap(index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Stack(
          children: [
            // AI-generated START - 图标
            Center(
              child: iconAsset.image(
                width: 32.0,
                height: 32.0,
                fit: BoxFit.contain,
              ),
            ),
            // AI-generated END - 图标

            // AI-generated START - 选中状态指示
            if (isSelected)
              Positioned(
                top: 4.0,
                right: 4.0,
                child: Container(
                  width: 16.0,
                  height: 16.0,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12.0,
                    color: Colors.white,
                  ),
                ),
              ),
            // AI-generated END - 选中状态指示

            // AI-generated START - 上传中遮罩
            if (_isUploading && isSelected)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
            // AI-generated END - 上传中遮罩
          ],
        ),
      ),
    );
  }
  // AI-generated END - 构建单个图标项

  // AI-generated START - 图标点击处理
  Future<void> _onIconTap(int index) async {
    if (_isUploading) return;

    // 获取本地图片路径
    final assetPath = _iconAssets[index].path;

    // 先创建结果对象，包含本地路径
    final result = IconSelectionResult(localPath: assetPath);

    // 立即返回本地路径，关闭弹窗
    widget.onIconSelected?.call(result);
    Navigator.of(context).pop(result);

    // 然后异步上传图片（在后台进行）
    setState(() {
      _selectedIndex = index;
      _isUploading = true;
    });

    try {
      // 读取 asset 图片的字节数据
      final byteData = await rootBundle.load(assetPath);
      final imageBytes = byteData.buffer.asUint8List();

      // 上传图片到服务端
      final uploadService = MPImageUploadService();
      final imageUrl = await uploadService.uploadMPImageBytes(
        imageBytes,
        'image/png', // 假设都是 PNG 格式
      );

      if (imageUrl != null) {
        // 上传成功，更新结果对象的URL并通知回调
        result.url = imageUrl;
        widget.onIconSelected?.call(result);
      } else {
        // 上传失败
        MPToastUtils.showMessage('上传图标失败');
      }
    } catch (e) {
      debugPrint('上传图标失败: $e');
      MPToastUtils.showMessage('上传图标失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
  // AI-generated END - 图标点击处理
}
// AI-generated END - template_icon_selection_popup.dart
