import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memo_pin/utils/omi_color_utils.dart';
import 'package:memo_pin/utils/omi_font_utils.dart';
import 'package:memo_pin/utils/omi_textstyle.dart';

import '../../../common/mp_custom_nav_bar.dart';
import 'mp_memory_search_cubit.dart';

/// 搜索页：Search memories（按设计稿）。
class MPMemorySearchPage extends StatelessWidget {
  const MPMemorySearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MPMemorySearchCubit>(
      create: (_) => MPMemorySearchCubit()..initData(),
      child: const _MPMemorySearchView(),
    );
  }
}

class _MPMemorySearchView extends StatefulWidget {
  const _MPMemorySearchView();

  @override
  State<_MPMemorySearchView> createState() => _MPMemorySearchViewState();
}

class _MPMemorySearchViewState extends State<_MPMemorySearchView> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MPCustomNavBar(
                title: 'Search memories',
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _SearchField(
                  controller: _controller,
                  hintText: 'Search by people, topic, or keywords...',
                  onChanged: (String v) =>
                      context.read<MPMemorySearchCubit>().setQuery(v),
                ),
              ),
              Expanded(
                child: BlocBuilder<MPMemorySearchCubit, MPMemorySearchState>(
                  builder: (BuildContext context, MPMemorySearchState state) {
                    switch (state.phase) {
                      case MPMemorySearchPhase.loading:
                        return const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      case MPMemorySearchPhase.error:
                        return _ErrorView(
                          message: state.errorMessage ?? 'Couldn\'t load.',
                          onRetry: () =>
                              context.read<MPMemorySearchCubit>().retry(),
                        );
                      case MPMemorySearchPhase.loaded:
                        return _SuggestionsList(
                          items: state.filteredSuggestions,
                        );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.title,
    required this.onBack,
    required this.onClose,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: <Widget>[
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: mainTextColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: OmiTextStyle.create(
                fontSize: OmiFontSize.t8_17,
                fontWeight: OmiFontWeight.bold,
                color: mainTextColor,
              ),
            ),
          ),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(
                Icons.close_rounded,
                size: 22,
                color: secondTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.search_rounded, size: 20, color: secondTextColor),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: OmiTextStyle.create(
                fontSize: OmiFontSize.t5_14,
                fontWeight: OmiFontWeight.regular,
                color: mainTextColor,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: OmiTextStyle.create(
                  fontSize: OmiFontSize.t5_14,
                  fontWeight: OmiFontWeight.regular,
                  color: secondTextColor.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionsList extends StatelessWidget {
  const _SuggestionsList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'SUGGESTIONS',
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t3_12,
              fontWeight: OmiFontWeight.regular,
              color: secondTextColor.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int i) {
                return InkWell(
                  onTap: () {
                    // TODO: 点击 suggestion 后跳转结果页 / 触发搜索
                    FocusScope.of(context).unfocus();
                  },
                  child: Row(
                    children: <Widget>[
                      Text(
                        '•',
                        style: OmiTextStyle.create(
                          fontSize: OmiFontSize.t5_14,
                          height: 1,
                          color: secondTextColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          items[i],
                          style: OmiTextStyle.create(
                            fontSize: OmiFontSize.t6_15,
                            fontWeight: OmiFontWeight.regular,
                            color: mainTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            message,
            style: OmiTextStyle.create(
              fontSize: OmiFontSize.t7_16,
              fontWeight: OmiFontWeight.medium,
              color: secondTextColor,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: OmiTextStyle.create(
                fontSize: OmiFontSize.t6_15,
                fontWeight: OmiFontWeight.medium,
                color: blueTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
