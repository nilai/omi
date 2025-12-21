import 'dart:io';

import 'package:flutter/material.dart';
import 'package:omi/pages/mp_custom_utils/mp_toast_utils.dart';
import 'package:omi/pages/mp_home/mp_home_card.dart';
import 'package:omi/services/mp_audio_upload.dart';
import 'package:provider/provider.dart';

import '../../backend/http/mp_api/mp_memory.dart';
import '../../backend/schema/mp/mp_memory.dart';
import '../../utils/audio_picker_utils.dart';
import '../../utils/other/temp.dart';
import '../chat/widgets/voice_recorder_widget.dart';
import '../mp_canlendar/widgets/calendar_popup.dart';
import '../mp_popup/import_audio_dialog.dart';
import '../mp_popup/mp_center_popup.dart';
import '../mp_popup/record_audio_option_card.dart';
import '../onboarding/find_device/page.dart';
import 'mp_home_upload_widget.dart';
import 'provider/mp_page_provider.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MPHomePageProvider>();
      _scrollController.addListener(() {
        if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
          provider.loadMore();
        }
      });
      provider.refresh();
    });
  }

  @override
  void dispose() {
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
                      const Text(
                        '记忆记录',
                        style: TextStyle(
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: MPHomeUploadWidget(
                    title: provider.uploadTitle,
                    transferredCount: provider.uploadedCount,
                    totalCount: provider.totalCount,
                    percent: provider.uploadPercent,
                    speedText: provider.speedText,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: provider.refresh,
                    color: const Color(0xFF306CFF),
                    backgroundColor: Colors.white,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 60 &&
                            notification is ScrollUpdateNotification) {
                          provider.loadMore();
                        }
                        return false;
                      },
                      child: ListView.separated(
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
                            onMorePressed: () => provider.onCardMore(item),
                            onViewDetail: () => provider.onCardViewDetail(item),
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
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).colorScheme.primary,
      systemOverlayStyle: getSystemUiOverlayStyle(context),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left circular icon button
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FindDevicesPage(
                          isFromOnboarding: false,
                          goNext: () {},
                          onSkip: () {},
                          includeSkip: false,
                        )),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE0E0E0),
              ),
              child: const Icon(
                Icons.circle,
                color: Color(0xFF757575),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Centered date selector
          Expanded(
            child: Center(
              child: InkWell(
                onTap: () => _showDatePicker(context, provider),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        provider.formatDateToMonthDay(provider.selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF111111),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Search icon
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF111111)),
            // onPressed: provider.onSearchTap,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => VoiceRecorderWidget(onTranscriptReady: (value) {}, onClose: () {})),
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
      elevation: 0,
      centerTitle: true,
    );
  }

  Future<void> _showDatePicker(BuildContext context, MPHomePageProvider provider) async {
    MPCenterPopup.show(
      context: context,
      contentWidget: CalendarPopup(
        onDateSelected: (date) {
          print(date);
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
      onStartRecording: () {},
    );
  }

  void _showImportAudioDialog(BuildContext context) {
    ImportAudioDialog.show(
      context: context,
      onImportFromFile: () async {
        final file = await AudioPickerUtils.pickAudioFromFile();
        debugPrint('pickAudioFromFile file: $file');
        await _uploadAudioFile(context, file);
      },
      onImportFromAlbum: () async {
        final file = await AudioPickerUtils.pickAudioFromAlbum();
        debugPrint('pickAudioFromAlbum file: $file');
        await _uploadAudioFile(context, file);
      },
      onImportFromOtherApp: () async {
        MPToastUtils.showMessage('暂不支持从其他App导入音频');
      },
    );
  }

  Future<void> _uploadAudioFile(BuildContext context, File? file) async {
    // 保存 uri 到本地数据库或其他存储方式
    if (file != null) {
      final uri = await MPAudioUploadService().uploadMPAudio(file);
      if (uri != null) {
        // 保存 uri 到本地数据库或其他存储方式
        final req = MPCreateRecordRequest(
          recordFile: uri,
          createAt: DateTime.now().millisecondsSinceEpoch,
          duration: 0,
        );
        final res = await createRecord(req);
        if (res != null) {
          // 保存 res 到本地数据库或其他存储方式
          // 刷新页面
          final provider = context.read<MPHomePageProvider>();
          await provider.refresh();
        }
      }
    }
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
}
