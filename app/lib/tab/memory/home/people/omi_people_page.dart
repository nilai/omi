import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/common/mp_tristate_page.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_image_loader.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../../../../generated/assets.dart';
import 'card/mp_all_people_card.dart';
import 'card/mp_recently_mentioned_card.dart';
import 'omi_people_cubit.dart';

/// Memory「People」：最近提及 + 下拉刷新（无分页）
class OmiPeoplePage extends StatelessWidget {
  const OmiPeoplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OmiPeopleCubit()..initData(),
      child: const _OmiPeopleView(),
    );
  }
}

class _OmiPeopleView extends StatelessWidget {
  const _OmiPeopleView();

  Future<void> _onRefresh(BuildContext context) async {
    await context.read<OmiPeopleCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OmiPeopleCubit, OmiPeopleState>(
      builder: (BuildContext context, OmiPeopleState state) {
        switch (state.phase) {
          case OmiPeoplePhase.loading:
            return const MPTristatePage(type: MPTristateType.loading);
          case OmiPeoplePhase.empty:
            return MPTristatePage(
              type: MPTristateType.empty,
              data: MPTristatePageData(
                icon: OmiImageLoader.localImg(
                  Assets.omiUsers,
                  width: 60,
                  height: 60,
                  color: blueTextColor,
                  fit: BoxFit.cover,
                ),
                title: 'No people yet',
                description: 'Mentioned contacts will appear here.',
                buttonText: 'Refresh',
                onButtonPressed: () {
                  context.read<OmiPeopleCubit>().retry();
                },
              ),
            );
          case OmiPeoplePhase.noNetwork:
            return MPTristatePage(
              type: MPTristateType.noNetwork,
              data: MPTristatePageData(
                title: 'Unable to load people',
                onButtonPressed: () {
                  context.read<OmiPeopleCubit>().retry();
                },
              ),
            );
          case OmiPeoplePhase.error:
            return MPTristatePage(
              type: MPTristateType.error,
              data: MPTristatePageData(
                title: 'Unable to load people',
                description: state.errorMessage ?? '请稍后重试',
                onButtonPressed: () {
                  context.read<OmiPeopleCubit>().retry();
                },
              ),
            );
          case OmiPeoplePhase.loaded:
            return ColoredBox(
              color: pageColor,
              child: RefreshIndicator(
                onRefresh: () => _onRefresh(context),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    MPRecentlyMentionedCard(
                      data: MPRecentlyMentionedCardData(
                        items: state.items,
                      ),
                    ),
                    const SizedBox(height: 24),
                    MPAllPeopleCard(
                      data: MPAllPeopleCardData(
                        items: state.allPeopleItems,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        children: [
                          Text(
                            'You can label speakers from your recordings.\nNewly identified people will appear here.',
                            textAlign: TextAlign.center,
                            style: OmiTextStyle.create(
                              fontSize: OmiFontSize.t4_13,
                              fontWeight: OmiFontWeight.regular,
                              color: secondTextColor,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
        }
      },
    );
  }
}
