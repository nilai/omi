import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omi/common/mp_custom_nav_bar.dart';
import 'package:omi/common/mp_tristate_page.dart';
import 'package:omi/tab/home/insights/mp_daily_insight_detail_page.dart';
import 'package:omi/tab/home/insights/mp_monthly_insight_detail_page.dart';
import 'package:omi/tab/home/insights/mp_pattern_insight_detail_page.dart';
import 'package:omi/tab/home/insights/mp_weekly_insight_detail_page.dart';
import 'package:omi/utils/omi_color_utils.dart';
import 'package:omi/utils/omi_font_utils.dart';
import 'package:omi/utils/omi_textstyle.dart';

import 'mp_insights_list_cubit.dart';

/// Insights 列表（对齐 react `AllInsightsListPage`）：
/// - 后台拉取数据（mock）
/// - 下拉刷新
/// - 上拉更多
/// - 四种卡片类型点击后进入不同详情页
class MPHomeInsightsListPage extends StatelessWidget {
  const MPHomeInsightsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MPInsightsListCubit>(
      create: (_) => MPInsightsListCubit()..initData(),
      child: const _MPHomeInsightsListView(),
    );
  }
}

class _MPHomeInsightsListView extends StatefulWidget {
  const _MPHomeInsightsListView();

  @override
  State<_MPHomeInsightsListView> createState() => _MPHomeInsightsListViewState();
}

class _MPHomeInsightsListViewState extends State<_MPHomeInsightsListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 距离底部约 200px 触发下一页（与项目其它游标分页一致）
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final ScrollPosition pos = _scrollController.position;
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels < pos.maxScrollExtent - 200) return;

    final MPInsightsListCubit cubit = context.read<MPInsightsListCubit>();
    final MPInsightsListState state = cubit.state;
    if (state.phase != MPInsightsListPhase.loaded) return;
    if (state.isLoadingMore || !state.hasMore) return;
    cubit.loadMore();
  }

  Future<void> _onRefresh() => context.read<MPInsightsListCubit>().load();

  void _onCardTap(MPInsightListItem item) {
    switch (item.type) {
      case MPInsightCardType.daily:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MPDailyInsightDetailPage(item: item)));
        break;
      case MPInsightCardType.weekly:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MPWeeklyInsightDetailPage(item: item)));
        break;
      case MPInsightCardType.monthly:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MPMonthlyInsightDetailPage(item: item)));
        break;
      case MPInsightCardType.pattern:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MPPatternInsightDetailPage(item: item)));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageColor,
      appBar: PreferredSize(
        preferredSize: MPCustomNavBar.preferredSizeOf(context),
        child: MPCustomNavBar(
          title: 'Insights',
          backgroundColor: pageColor,
          onBack: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: BlocBuilder<MPInsightsListCubit, MPInsightsListState>(
        builder: (BuildContext context, MPInsightsListState state) {
          switch (state.phase) {
            case MPInsightsListPhase.loading:
              return const MPTristatePage(type: MPTristateType.loading);
            case MPInsightsListPhase.empty:
              return MPTristatePage(
                type: MPTristateType.empty,
                data: MPTristatePageData(
                  title: 'No insights yet',
                  description: 'Record more memories and MemoPin will discover patterns.',
                  buttonText: 'Refresh',
                  onButtonPressed: () => context.read<MPInsightsListCubit>().load(),
                ),
              );
            case MPInsightsListPhase.error:
              return MPTristatePage(
                type: MPTristateType.error,
                data: MPTristatePageData(
                  title: 'Unable to load insights',
                  description: state.errorMessage ?? '请稍后重试',
                  buttonText: 'Retry',
                  onButtonPressed: () => context.read<MPInsightsListCubit>().load(),
                ),
              );
            case MPInsightsListPhase.loaded:
              return ColoredBox(
                color: pageColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: state.items.length + (state.hasMore && state.isLoadingMore ? 1 : 0),
                          itemBuilder: (BuildContext context, int index) {
                            if (index == state.items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              );
                            }
                            final MPInsightListItem item = state.items[index];
                            return Padding(
                              padding: EdgeInsets.only(bottom: index < state.items.length - 1 ? 12 : 0),
                              child: _MPInsightCard(item: item, onTap: () => _onCardTap(item)),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
          }
        },
      ),
    );
  }
}

class _MPInsightCard extends StatelessWidget {
  const _MPInsightCard({required this.item, required this.onTap});

  final MPInsightListItem item;
  final VoidCallback onTap;

  Color _accentColor() {
    switch (item.type) {
      case MPInsightCardType.daily:
        return const Color(0xFF7C3AED);
      case MPInsightCardType.weekly:
        return const Color(0xFFEA6A1C);
      case MPInsightCardType.monthly:
        return const Color(0xFF2EA0E8);
      case MPInsightCardType.pattern:
        return const Color(0xFFF59E1A);
    }
  }

  Color _cardBgColor() {
    switch (item.type) {
      case MPInsightCardType.daily:
        return const Color(0xFFE8E4F1);
      case MPInsightCardType.weekly:
        return const Color(0xFFF1DBBE);
      case MPInsightCardType.monthly:
        return const Color(0xFFD4E8F3);
      case MPInsightCardType.pattern:
        return const Color(0xFFF3E0A8);
    }
  }

  Color _cardBorderColor() {
    switch (item.type) {
      case MPInsightCardType.daily:
        return const Color(0xFFDDD6EF);
      case MPInsightCardType.weekly:
        return const Color(0xFFEBC89D);
      case MPInsightCardType.monthly:
        return const Color(0xFF9DD3F5);
      case MPInsightCardType.pattern:
        return const Color(0xFFE8B25B);
    }
  }

  IconData _iconData() {
    switch (item.type) {
      case MPInsightCardType.daily:
        return Icons.nightlight_round;
      case MPInsightCardType.weekly:
        return Icons.bar_chart;
      case MPInsightCardType.monthly:
        return Icons.calendar_month;
      case MPInsightCardType.pattern:
        return Icons.auto_awesome;
    }
  }

  String _typeLabel() {
    switch (item.type) {
      case MPInsightCardType.daily:
        return 'Daily';
      case MPInsightCardType.weekly:
        return 'Weekly';
      case MPInsightCardType.monthly:
        return 'Monthly';
      case MPInsightCardType.pattern:
        return 'Pattern';
    }
  }

  List<String> _bullets() {
    if (item.bullets.isNotEmpty) return item.bullets;
    return <String>[
      if (item.decisionsCount != null) '${item.decisionsCount} decisions made',
      if (item.followUpsCount != null) '${item.followUpsCount} follow-ups pending',
      if (item.risksCount != null) '${item.risksCount} risk to watch',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = _accentColor();
    final IconData icon = _iconData();
    final Color cardBg = _cardBgColor();
    final Color borderColor = _cardBorderColor();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Stack(
            children: <Widget>[
              if (item.type == MPInsightCardType.pattern)
                Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 4, color: accent)),
              Padding(
                padding: EdgeInsets.only(
                  left: item.type == MPInsightCardType.pattern ? 8 : 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Icon(icon, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                width: double.infinity,
                                child: Stack(
                                  children: <Widget>[
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 44),
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: Text.rich(
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
                                          TextSpan(
                                            children: <InlineSpan>[
                                              TextSpan(
                                                text: item.periodLabel,
                                                style: OmiTextStyle.create(
                                                  color: const Color(0xFF1F2937),
                                                  fontSize: OmiFontSize.t9_18,
                                                  fontWeight: OmiFontWeight.bold,
                                                  height: 1.2,
                                                ),
                                              ),
                                              TextSpan(
                                                text: '  ·  ${_typeLabel()}',
                                                style: OmiTextStyle.create(
                                                  color: const Color(0xFF8A8A93),
                                                  fontSize: OmiFontSize.t6_15,
                                                  fontWeight: OmiFontWeight.medium,
                                                  height: 1.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: Icon(
                                        Icons.chevron_right_rounded,
                                        size: 24,
                                        color: accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.subtitle,
                                style: OmiTextStyle.create(
                                  color: const Color(0xFF7B7E86),
                                  fontSize: OmiFontSize.t6_15,
                                  fontWeight: OmiFontWeight.medium,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Text(
                      item.summary,
                      style: OmiTextStyle.create(
                        color: const Color(0xFF2F3542),
                        fontSize: OmiFontSize.t9_18,
                        fontWeight: OmiFontWeight.regular,
                        height: 1.45,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    ..._bullets().map((String b) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(top: 9),
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(999)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                b,
                                style: OmiTextStyle.create(
                                  color: const Color(0xFF2F3542),
                                  fontSize: OmiFontSize.t8_17,
                                  fontWeight: OmiFontWeight.regular,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
