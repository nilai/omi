import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:omi/pages/mp_home/provider/mp_search_provider.dart';

/// 搜索中间页面
/// 显示最近搜索和热门搜索
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
                    // // 热门搜索
                    // _buildSectionTitle('热门搜索'),
                    // const SizedBox(height: 12),
                    // _buildPopularSearches(provider),
                  ],
                ),
              );
            },
          ),
        ),
      ),
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
        decoration: const InputDecoration(
          hintText: '搜索记忆内容、标题、日期...',
          hintStyle: TextStyle(
            color: Color(0xFF999999),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Color(0xFF999999),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF111111),
        ),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            _onSearch(value.trim());
          }
        },
      ),
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

  /// 构建热门搜索标签
  /// @param provider 搜索 Provider
  /// @returns 热门搜索标签组件
  Widget _buildPopularSearches(MPSearchProvider provider) {
    if (provider.loadingPopularSearches) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (provider.popularSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: provider.popularSearches.map((keyword) {
        return _buildPopularSearchTag(keyword);
      }).toList(),
    );
  }

  /// 构建热门搜索标签
  /// @param keyword 搜索关键词
  /// @returns 热门搜索标签组件
  Widget _buildPopularSearchTag(String keyword) {
    return InkWell(
      onTap: () => _onSearch(keyword),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF306CFF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          keyword,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
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

    // TODO: 执行搜索操作，跳转到搜索结果页面
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => MPSearchResultPage(keyword: keyword),
    //   ),
    // );
  }
}
