import 'package:flutter/material.dart';
import 'package:omi/pages/memories/mp_memory_page_client.dart';
import 'package:omi/pages/mp_home/provider/mp_search_provider.dart';
import 'package:omi/pages/mp_home/widgets/mp_home_card.dart';
import 'package:provider/provider.dart';

/// 搜索页面
/// 包含两种状态：输入状态（显示最近搜索）和搜索结果状态（显示搜索结果卡片列表）
/// 打开页面默认是输入状态
class MPSearchPage extends StatefulWidget {
  const MPSearchPage({super.key});

  @override
  State<MPSearchPage> createState() => _MPSearchPageState();
}

class _MPSearchPageState extends State<MPSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  late final MPSearchProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = MPSearchProvider();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context),
        body: SafeArea(
          child: Consumer<MPSearchProvider>(
            builder: (context, provider, _) {
              // 如果显示搜索结果，显示搜索结果列表
              if (provider.showResults) {
                return _buildSearchResults(provider);
              }
              // 否则显示输入状态（最近搜索）
              return _buildInputState(provider);
            },
          ),
        ),
      ),
    );
  }

  /// 构建输入状态（最近搜索）
  /// @param provider 搜索 Provider
  /// @returns 输入状态组件
  Widget _buildInputState(MPSearchProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // 最近搜索
          if (provider.recentSearches.isNotEmpty) ...[
            _buildSectionTitle('最近搜索'),
            const SizedBox(height: 12),
            _buildRecentSearches(provider),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  /// 构建搜索结果列表
  /// @param provider 搜索 Provider
  /// @returns 搜索结果列表组件
  Widget _buildSearchResults(MPSearchProvider provider) {
    if (provider.isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (provider.searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off,
                size: 64,
                color: Color(0xFFCCCCCC),
              ),
              const SizedBox(height: 16),
              const Text(
                '未找到相关结果',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF999999),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '关键词: ${provider.currentKeyword}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFCCCCCC),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final item = provider.searchResults[index];
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
          onViewDetail: () => MPMemoryPageClient.navigateToDetailPage(context, item.memory),
          isUploading: item.isUploading,
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
    );
  }

  /// 构建 AppBar
  /// @param context 上下文
  /// @returns AppBar 组件
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF111111)),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: _buildSearchBar(),
      titleSpacing: 0,
    );
  }

  /// 构建搜索框
  /// @returns 搜索框组件
  Widget _buildSearchBar() {
    return Consumer<MPSearchProvider>(
      builder: (context, provider, _) {
        return Container(
          height: 40,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: false,
            cursorColor: Colors.black,
            decoration: InputDecoration(
              hintText: '搜索记忆内容、标题、日期...',
              hintStyle: const TextStyle(
                color: Color(0xFF999999),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFF999999),
                size: 20,
              ),
              suffixIcon: provider.showResults
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Color(0xFF999999),
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        provider.clearSearch();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF111111),
            ),
            onChanged: (value) {
              // 如果清空输入框，返回输入状态
              if (value.trim().isEmpty && provider.showResults) {
                provider.clearSearch();
              }
            },
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                _onSearch(value.trim());
              }
            },
          ),
        );
      },
    );
  }

  /// 构建章节标题
  /// @param title 标题文本
  /// @returns 标题组件
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111111),
      ),
    );
  }

  /// 构建最近搜索列表
  /// @param provider 搜索 Provider
  /// @returns 最近搜索列表组件
  Widget _buildRecentSearches(MPSearchProvider provider) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.recentSearches.length,
      itemBuilder: (context, index) {
        final keyword = provider.recentSearches[index];
        return _buildRecentSearchItem(keyword, provider);
      },
      separatorBuilder: (context, index) => const SizedBox(height: 0),
    );
  }

  /// 构建最近搜索项
  /// @param keyword 搜索关键词
  /// @param provider 搜索 Provider
  /// @returns 最近搜索项组件
  Widget _buildRecentSearchItem(String keyword, MPSearchProvider provider) {
    return InkWell(
      onTap: () => _onSearch(keyword),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.access_time,
              size: 16,
              color: Color(0xFF666666),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                keyword,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF111111),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Color(0xFF999999),
            ),
          ],
        ),
      ),
    );
  }

  /// 执行搜索
  /// @param keyword 搜索关键词
  /// @returns 无返回值
  void _onSearch(String keyword) {
    if (keyword.trim().isEmpty) return;

    // 更新搜索框
    _searchController.text = keyword;

    // 添加到搜索历史
    _provider.addSearchHistory(keyword);

    // 执行搜索操作
    _provider.search(keyword);
  }
}
