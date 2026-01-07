import 'dart:async';

import 'package:flutter/material.dart';
import 'package:omi/pages/mp_custom_utils/mp_toast_utils.dart';
import 'package:omi/pages/mp_home/widgets/mp_home_card.dart';
import 'package:omi/services/mp_home_refresh_event_service.dart';
import 'package:provider/provider.dart';

import '../../providers/device_provider.dart';
import '../../services/connectivity_service.dart';
import '../../utils/audio_picker_utils.dart';
import '../../utils/other/temp.dart';
import '../home/widgets/mp_battery_info_widget.dart';
import '../memories/mp_memory_page_client.dart';
import '../mp_audio_record/mp_audio_record_page.dart';
import '../mp_canlendar/widgets/calendar_popup.dart';
import '../mp_popup/import_audio_dialog.dart';
import '../mp_popup/mp_center_popup.dart';
import '../mp_popup/record_audio_option_card.dart';
import 'mp_search_page.dart';
import 'provider/mp_page_provider.dart';
import 'widgets/mp_home_top_import_sd_audio_widget.dart';
import 'widgets/mp_home_upload_widget.dart';

class MPPage extends StatefulWidget {
  const MPPage({super.key});

  @override
  State<MPPage> createState() => _MPPageState();
}

class _MPPageState extends State<MPPage> with AutomaticKeepAliveClientMixin {
  late final MPHomePageProvider _provider;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _provider = MPHomePageProvider();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important! Call super.build
    return ChangeNotifierProvider.value(
      value: _provider,
      child: const MPPageContent(),
    );
  }
}

class MPPageContent extends StatefulWidget {
  const MPPageContent({super.key});

  @override
  State<MPPageContent> createState() => _MPPageContentState();
}

class _MPPageContentState extends State<MPPageContent> {
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<MPHomeRefreshEvent>? _refreshEventSubscription;
  DeviceProvider? _deviceProvider;
  bool? _previousConnectedState;

  @override
  void initState() {
    super.initState();
    // 监听首页刷新事件
    _refreshEventSubscription = MPHomeRefreshEventService().events.listen((event) {
      if (event.type == MPHomeRefreshEventType.refresh && mounted) {
        final provider = context.read<MPHomePageProvider>();
        provider.refresh();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MPHomePageProvider>();
      _scrollController.addListener(() {
        if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
          provider.loadMore();
        }
      });
      provider.refresh();
      if (mounted) {
        final deviceProvider = context.read<DeviceProvider>();
        _deviceProvider = deviceProvider;
        _previousConnectedState = deviceProvider.isConnected;

        // 监听设备连接状态变化
        deviceProvider.addListener(_onDeviceConnectionChanged);

        deviceProvider.periodicConnect(
          'coming from HomePageWrapper',
          boundDeviceOnly: true,
        );
      }

      // Stream<bool> get onConnectionChange => _connectionChangeController.stream;
      ConnectivityService().onConnectionChange.listen((isConnected) {
        debugPrint('-----hj----- onConnectionChange: $isConnected');
        if (isConnected && provider.items.isEmpty) {
          provider.refresh();
        }
      });
    });
  }

  /// 处理设备连接状态变化
  void _onDeviceConnectionChanged() {
    if (!mounted || _deviceProvider == null) return;

    final currentConnectedState = _deviceProvider!.isConnected;

    // 只在状态真正变化时执行操作
    if (_previousConnectedState != currentConnectedState) {
      _previousConnectedState = currentConnectedState;

      if (currentConnectedState) {
        // 设备已连接时的操作
        _handleDeviceConnected();
      } else {
        // 设备断开连接时的操作
        _handleDeviceDisconnected();
      }
    }
  }

  /// 设备连接时的处理逻辑
  void _handleDeviceConnected() {
    // MPDeviceFileUtil.instance.testExportAllFiles(onFileListCount: (count) {
    //   final provider = context.read<MPHomePageProvider>();
    //   debugPrint('-----hj----- _handleDeviceConnected count: $count');
    //   provider.updateSDRecordCountAndIndex(value: count, index: 0);
    // }, onExportProgress: (index, progress, speed) {
    //   // 将 progress (0.0~1.0) 转为百分比 (0~100)
    //   final percent = (progress * 100);
    //   debugPrint('-----hj----- _handleDeviceConnected index: $index, progress: $progress, speed: $speed');
    //   final provider = context.read<MPHomePageProvider>();
    //   provider.updateSDRecordSpeed(speed);
    //   provider.updateUploadPercent(percent);
    //   provider.updateSDRecordIndex(index);
    // }, onFileExported: (index, fileDetail) async {
    //   debugPrint('-----hj----- _handleDeviceConnected index: $index, fileDetail: $fileDetail');

    //   // 传完后， 更新本地，
    //   final provider = context.read<MPHomePageProvider>();
    //   provider.updateImportAudioType(MPHomeImportAudioType.none);
    //   await provider.addLocalRecord(fileDetail.localPath ?? '',
    //       duration: fileDetail.durationSeconds, fileName: fileDetail.name, source: 'MemoPin');
    //   provider.uploadLocalRecords();
    // });
  }

  /// 设备断开连接时的处理逻辑
  void _handleDeviceDisconnected() {}

  @override
  void dispose() {
    _deviceProvider?.removeListener(_onDeviceConnectionChanged);
    _refreshEventSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MPHomePageProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primary,
          appBar: _buildAppBar(context, provider),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.selectedDate == null
                            ? '记忆记录'
                            : '${provider.formatDateToMonthDay(provider.selectedDate!)} 的记忆',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            '共',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showEditRecordCountDialog(context, provider),
                            child: Text(
                              '${provider.recordCount}',
                              style: const TextStyle(
                                color: Color(0xFF306CFF),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Text(
                            ' 条记录',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildImportAudioTypeWidget(context, provider),
                const SizedBox(height: 12),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: provider.refresh,
                    color: const Color(0xFF306CFF),
                    backgroundColor: Colors.white,
                    child: provider.items.isEmpty && !provider.loading
                        ? _buildEmptyState(context, provider)
                        : NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 60 &&
                                  notification is ScrollUpdateNotification) {
                                provider.loadMore();
                              }
                              return false;
                            },
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: provider.items.length + (provider.loadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= provider.items.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                  );
                                }
                                final item = provider.items[index];
                                return MPHomeCard(
                                  dateText: item.dateText,
                                  tagText: item.tagText,
                                  tagBackgroundColor: item.tagColor,
                                  headerText: item.headerText,
                                  timeText: item.timeText,
                                  secondsText: item.secondsText,
                                  description: item.description,
                                  onShare: () => provider.onCardShare(context, item),
                                  onDelete: () => provider.onCardDelete(context, item),
                                  onViewDetail: () {
                                    if (item.isUploading == true) {
                                      MPToastUtils.showMessage('正在上传，请稍后再试');
                                      return;
                                    }
                                    MPMemoryPageClient.navigateToDetailPage(context, item.memory);
                                  },
                                  isUploading: item.isUploading,
                                  source: item.source,
                                );
                              },
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, MPHomePageProvider provider) {
    final hasSelectedDate = provider.selectedDate != null;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).colorScheme.primary,
      systemOverlayStyle: getSystemUiOverlayStyle(context),
      title: Stack(
        alignment: Alignment.center,
        children: [
          // 左右两侧的图标，使用 Row 布局
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left circular icon button
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  MPBatteryInfoWidget.pushToFindDevicesPage(context);
                },
                child: const MPBatteryInfoWidget(),
              ),
              // Right side icons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search icon
                  IconButton(
                    icon: const Icon(Icons.search, color: Color(0xFF111111)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MPSearchPage(),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  // Add icon
                  IconButton(
                    icon: const Icon(Icons.add, color: Color(0xFF111111)),
                    onPressed: () => _showAddRecordDialog(context, provider),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          // 居中的日期选择器或"返回全部"按钮
          hasSelectedDate
              ? InkWell(
                  onTap: () => provider.clearSelectedDate(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF306CFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Color(0xFF306CFF),
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '返回全部',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF306CFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : InkWell(
                  onTap: () => _showDatePicker(context, provider),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Color(0xFF111111),
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF111111),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
      elevation: 0,
      centerTitle: true,
    );
  }

  Widget _buildImportAudioTypeWidget(BuildContext context, MPHomePageProvider provider) {
    debugPrint('-----hj----- _buildImportAudioTypeWidget type: ${provider.importAudioType}');
    if (provider.importAudioType == MPHomeImportAudioType.none) {
      return const SizedBox.shrink();
    }
    if (provider.importAudioType == MPHomeImportAudioType.local) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: MPHomeUploadWidget(
          title: '音频导入中',
          subtitle: '正在处理音频文件...',
          // transferredCount: provider.uploadedCount,
          // totalCount: provider.totalCount,
          percent: provider.uploadPercent,
        ),
      );
    }
    if (provider.importAudioType == MPHomeImportAudioType.sdCard) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: MPHomeTopImportSdAudioWidget(
            title: '正在从 MemoPin 传输录音至 APP...',
            percent: provider.uploadPercent,
            speedText: provider.sdRecordSpeed.toStringAsFixed(2),
            transferredCount: provider.sdRecordIndex,
            totalCount: provider.sdRecordCount),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _showDatePicker(BuildContext context, MPHomePageProvider provider) async {
    MPCenterPopup.show(
      context: context,
      contentWidget: CalendarPopup(
        onDateSelected: (date) {
          provider.updateSelectedDate(date);
        },
      ),
    );
  }

  Future<void> _showAddRecordDialog(BuildContext context, MPHomePageProvider provider) async {
    RecordAudioOptionCard.show(
      context: context,
      onImportAudio: () {
        _showImportAudioDialog(context);
      },
      onRecordAudio: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MPAudioRecordPage(onSave: (model) async {
              await provider.addLocalRecordModel(model);
              provider.uploadLocalRecords();
            }),
          ),
        );
      },
    );
  }

  void _showImportAudioDialog(BuildContext context) {
    ImportAudioDialog.show(
      context: context,
      onImportFromFile: () async {
        final provider = context.read<MPHomePageProvider>();
        provider.updateImportAudioType(MPHomeImportAudioType.local);
        provider.updateUploadPercent(0);
        final path = await AudioPickerUtils.pickAudioFromFileAndSync(onProgress: (progress, copiedBytes, totalBytes) {
          provider.updateUploadPercent(progress);
        });
        provider.updateUploadPercent(100);
        provider.updateImportAudioType(MPHomeImportAudioType.none);
        debugPrint('pickAudioFromFileAndSync file: $path');
        if (path != null) {
          // /// 记录信息到本地，更新列表数据，刷新页面
          // /// 文件名、时间戳、时长
          // /// 上传文件，上传完成删除记录信息
          // await _uploadAudioFile(context, File(path));

          await provider.addLocalRecord(path, source: 'MobilePhone');
          provider.uploadLocalRecords();
        }
      },
      onImportFromAlbum: () async {
        final provider = context.read<MPHomePageProvider>();
        provider.updateImportAudioType(MPHomeImportAudioType.local);
        provider.updateUploadPercent(0);
        final path = await AudioPickerUtils.pickAudioFromAlbumAndSync(onProgress: (progress, copiedBytes, totalBytes) {
          provider.updateUploadPercent(progress);
        });
        provider.updateUploadPercent(100);
        provider.updateImportAudioType(MPHomeImportAudioType.none);
        debugPrint('pickAudioFromAlbumAndSync file: $path');
        if (path != null) {
          // /// 记录信息到本地，更新列表数据，刷新页面
          // /// 文件名、时间戳、时长
          // /// 上传文件，上传完成删除记录信息
          // await _uploadAudioFile(context, File(path));

          await provider.addLocalRecord(path, source: 'MobilePhone');
          provider.uploadLocalRecords();
        }
      },
      onImportFromOtherApp: () async {
        MPToastUtils.showMessage('暂不支持从其他App导入音频');
      },
    );
  }

  Future<void> _showEditRecordCountDialog(BuildContext context, MPHomePageProvider provider) async {
    final controller = TextEditingController(text: provider.recordCount.toString());
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('修改记录数'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            cursorColor: Colors.black,
            decoration: const InputDecoration(hintText: '请输入记录条数'),
            onSubmitted: (value) {
              final parsed = int.tryParse(value);
              if (parsed != null) {
                provider.updateRecordCount(parsed);
              }
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text);
                if (parsed != null) {
                  provider.updateRecordCount(parsed);
                }
                Navigator.of(context).pop();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  /// 构建空数据页面
  Widget _buildEmptyState(BuildContext context, MPHomePageProvider provider) {
    final hasSelectedDate = provider.selectedDate != null;
    final dateText = hasSelectedDate ? provider.formatDateToMonthDay(provider.selectedDate!) : null;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 日历图标
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF8D8D8D),
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              // 主文本
              const Text(
                '暂无记忆',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 8),
              // 次文本
              Text(
                hasSelectedDate && dateText != null ? '$dateText 还没有记录任何记忆' : '还没有记录任何记忆',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              // 底部按钮（仅在选择日期时显示）
              if (hasSelectedDate) ...[
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => provider.clearSelectedDate(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF306CFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '查看全部记忆',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
