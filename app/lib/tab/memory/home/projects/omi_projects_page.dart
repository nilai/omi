import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/common/mp_tristate_page.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_image_loader.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../../../../generated/assets.dart';
import 'card/mp_project_card.dart';
import 'omi_projects_cubit.dart';

/// Memory「Projects」列表页（游标分页 + 下拉刷新 + 上拉加载）
class OmiProjectsPage extends StatelessWidget {
  const OmiProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OmiProjectsCubit()..initData(),
      child: const _OmiProjectsView(),
    );
  }
}

class _OmiProjectsView extends StatefulWidget {
  const _OmiProjectsView();

  @override
  State<_OmiProjectsView> createState() => _OmiProjectsViewState();
}

class _OmiProjectsViewState extends State<_OmiProjectsView> {
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

  /// 距底部约 200px 时加载下一页（与 [OmiAllPage] 一致）
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final ScrollPosition pos = _scrollController.position;
    if (pos.maxScrollExtent <= 0) return;
    if (pos.pixels < pos.maxScrollExtent - 200) return;

    final OmiProjectsCubit cubit = context.read<OmiProjectsCubit>();
    final OmiProjectsState state = cubit.state;
    if (state.phase != OmiProjectsPhase.loaded) return;
    if (state.isLoadingMore || !state.hasMore) return;

    cubit.loadMore();
  }

  Future<void> _onRefresh() async {
    await context.read<OmiProjectsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OmiProjectsCubit, OmiProjectsState>(
      builder: (BuildContext context, OmiProjectsState state) {
        switch (state.phase) {
          case OmiProjectsPhase.loading:
            return const MPTristatePage(type: MPTristateType.loading);
          case OmiProjectsPhase.empty:
            return MPTristatePage(
              type: MPTristateType.empty,
              data: MPTristatePageData(
                icon: OmiImageLoader.localImg(
                  Assets.omiProjects,
                  width: 60,
                  height: 60,
                  color: blueTextColor,
                  fit: BoxFit.cover,
                ),
                title: 'No projects yet',
                description: 'Projects you create will show up here.',
                buttonText: 'Refresh',
                onButtonPressed: () {
                  context.read<OmiProjectsCubit>().retry();
                },
              ),
            );
          case OmiProjectsPhase.noNetwork:
            return MPTristatePage(
              type: MPTristateType.noNetwork,
              data: MPTristatePageData(
                title: 'Unable to load projects',
                onButtonPressed: () {
                  context.read<OmiProjectsCubit>().retry();
                },
              ),
            );
          case OmiProjectsPhase.error:
            return MPTristatePage(
              type: MPTristateType.error,
              data: MPTristatePageData(
                title: 'Unable to load projects',
                description: state.errorMessage ?? '请稍后重试',
                onButtonPressed: () {
                  context.read<OmiProjectsCubit>().retry();
                },
              ),
            );
          case OmiProjectsPhase.loaded:
            return ColoredBox(
              color: pageColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: <InlineSpan>[
                              TextSpan(
                                text: 'Projects',
                                style: OmiTextStyle.create(
                                  fontSize: OmiFontSize.t9_18,
                                  fontWeight: OmiFontWeight.medium,
                                  color: mainTextColor,
                                ),
                              ),
                              TextSpan(
                                text: ' (${state.items.length})',
                                style: OmiTextStyle.create(
                                  fontSize: OmiFontSize.t9_18,
                                  fontWeight: OmiFontWeight.medium,
                                  color: secondTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: 新建项目
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: blueTextColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            '+ New',
                            style: OmiTextStyle.create(
                              fontSize: OmiFontSize.t6_15,
                              fontWeight: OmiFontWeight.medium,
                              color: blueTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: state.items.length +
                            (state.hasMore && state.isLoadingMore ? 1 : 0),
                        itemBuilder: (BuildContext context, int index) {
                          if (index == state.items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }
                          final OmiProjectEntry entry = state.items[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  index < state.items.length - 1 ? 12 : 0,
                            ),
                            child: MPProjectCard(
                              data: entry.data,
                              onTap: () {},
                            ),
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
    );
  }
}
