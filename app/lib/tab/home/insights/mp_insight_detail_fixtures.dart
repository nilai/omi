import '../../../http/schema/mp_data_model.dart';
import '../../../http/schema/mp_insight.dart';
import 'mp_insights_list_cubit.dart';

/// Insight 详情接口（`MPGetInsightDetailResponse`）四类周期的离线测试数据。
///
/// 字段键名与 [MPInsightDetailStruct.fromJson] / 各 `*DetailStruct` 一致；
/// [MPInsightDetailCubit] 在对应分支中于服务端字段为空时回退到此数据。
/// 亦可用于 Widget 测试、`fromJson` 校验。
class MPInsightDetailFixtures {
  MPInsightDetailFixtures._();

  static Map<String, dynamic> _baseRespOk() => <String, dynamic>{
        'code': 0,
        'message': 'ok',
        'logid': 'fixture-log-id',
      };

  static Map<String, dynamic> _basicInfo({
    required String id,
    required int cycleType,
    required String title,
    required String subTitle,
    required String content,
  }) =>
      <String, dynamic>{
        'id': id,
        'cycle_type': cycleType,
        'title': title,
        'sub_title': subTitle,
        'create_at': 1738656000,
        'content': content,
      };

  /// Daily 列表项（与 [dailyDetailResponse] 中 `basic_info.id` 对应）。
  static MPInsightListItem dailyListItem() => MPInsightListItem(
        id: 'fixture-insight-daily-1',
        type: MPInsightCardType.daily,
        periodLabel: 'Feb 4',
        title: 'Daily Insight',
        subtitle: 'End-of-day reflection',
        content: 'You focused on shipping the MVP slice and unblocked the API contract.',
      );

  /// Weekly 列表项。
  static MPInsightListItem weeklyListItem() => MPInsightListItem(
        id: 'fixture-insight-weekly-1',
        type: MPInsightCardType.weekly,
        periodLabel: 'Feb 3–9',
        title: 'Weekly Insight',
        subtitle: 'Week of Feb 3',
        content: 'Strong execution on milestones; watch scope creep mid-week.',
      );

  /// Monthly 列表项。
  static MPInsightListItem monthlyListItem() => MPInsightListItem(
        id: 'fixture-insight-monthly-1',
        type: MPInsightCardType.monthly,
        periodLabel: 'Jan 2026',
        title: 'Monthly Insight',
        subtitle: 'January recap',
        content: 'Attention shifted toward product delivery; collaboration frequency increased.',
      );

  /// Pattern 列表项。
  static MPInsightListItem patternListItem() => MPInsightListItem(
        id: 'fixture-insight-pattern-1',
        type: MPInsightCardType.pattern,
        periodLabel: 'Pattern',
        title: 'Recurring theme',
        subtitle: 'Across recent memories',
        content: 'Repeated late-night planning sessions before deadlines.',
        recurringThemes: <String>['deadline crunch', 'evening planning'],
      );

  /// `daily_detail` 结构化片段（供详情构建）。
  static MPDailyInsightDetailStruct dailyDetailPayload() =>
      dailyDetailResponse().insightDetail.dailyDetail!;

  /// `weekly_detail` 结构化片段。
  static MPWeeklyInsightDetailStruct weeklyDetailPayload() =>
      weeklyDetailResponse().insightDetail.weeklyDetail!;

  /// `monthly_detail` 结构化片段。
  static MPMonthlyInsightDetailStruct monthlyDetailPayload() =>
      monthlyDetailResponse().insightDetail.monthlyDetail!;

  /// `pattern_detail` 结构化片段。
  static MPPatternInsightDetailStruct patternDetailPayload() =>
      patternDetailResponse().insightDetail.patternDetail!;

  /// `insight_type == DAILY`（1）时的完整详情响应。
  static MPGetInsightDetailResponse dailyDetailResponse() {
    return MPGetInsightDetailResponse.fromJson(<String, dynamic>{
      'base_resp': _baseRespOk(),
      'insight_detail': <String, dynamic>{
        'basic_info': _basicInfo(
          id: dailyListItem().id,
          cycleType: MPInsightCycleType.daily,
          title: dailyListItem().title,
          subTitle: dailyListItem().subtitle,
          content: dailyListItem().content,
        ),
        'insight_type': MPInsightCycleType.daily,
        'daily_detail': <String, dynamic>{
          'narrative': <String, dynamic>{
            'content':
                'Today centered on clarifying requirements with design and locking the API schema.',
          },
          'decisions_made': <String, dynamic>{
            'title': 'Decisions made',
            'items': <Map<String, dynamic>>[
              <String, dynamic>{'content': 'Chose REST over GraphQL for v1 launch.'},
              <String, dynamic>{'content': 'Deferred analytics funnel until next sprint.'},
            ],
          },
          'open_questions': <String, dynamic>{
            'title': 'Open questions',
            'items': <Map<String, dynamic>>[
              <String, dynamic>{'content': 'Does the partner need webhook retries in MVP?'},
            ],
          },
          'patterns_emerging': <String, dynamic>{
            'content': 'Meetings cluster after lunch; deep work blocks work better in mornings.',
          },
          'ideas_captured': <String, dynamic>{
            'title': 'Ideas captured',
            'items': <Map<String, dynamic>>[
              <String, dynamic>{'content': 'Prototype voice note → structured task pipeline.'},
            ],
          },
          'tomorrow_focus': <String>[
            'Finalize error codes doc with backend.',
            'Schedule 30m design sync on empty states.',
          ],
        },
      },
    });
  }

  /// `insight_type == WEEKLY`（2）时的完整详情响应。
  static MPGetInsightDetailResponse weeklyDetailResponse() {
    return MPGetInsightDetailResponse.fromJson(<String, dynamic>{
      'base_resp': _baseRespOk(),
      'insight_detail': <String, dynamic>{
        'basic_info': _basicInfo(
          id: weeklyListItem().id,
          cycleType: MPInsightCycleType.weekly,
          title: weeklyListItem().title,
          subTitle: weeklyListItem().subtitle,
          content: weeklyListItem().content,
        ),
        'insight_type': MPInsightCycleType.weekly,
        'weekly_detail': <String, dynamic>{
          'header': <String, dynamic>{
            'title': 'Week of Feb 3',
            'sub_title': 'Execution & scope',
            'summary': 'Shipped two milestones; mid-week scope discussions slowed downstream QA.',
          },
          'week_summary': <String, dynamic>{
            'title': 'Week summary',
            'focus_areas': 'Deep work blocks Tue/Thu; collaborative spikes Mon/Wed.',
            'key_metrics': <Map<String, dynamic>>[
              <String, dynamic>{'label': 'Meetings', 'value': 12},
              <String, dynamic>{'label': 'Deep work hrs', 'value': 18},
              <String, dynamic>{'label': 'Tasks closed', 'value': 23},
            ],
          },
          'accomplishments': <Map<String, dynamic>>[
            <String, dynamic>{
              'title': 'MVP API freeze',
              'description': 'Contract reviewed with backend; breaking changes documented.',
            },
            <String, dynamic>{
              'title': 'Design handoff',
              'description': 'Empty states and loading specs delivered to implementation.',
            },
          ],
          'challenges_and_learnings': <Map<String, dynamic>>[
            <String, dynamic>{
              'title': 'Scope creep',
              'description': 'Two nice-to-have requests slipped into sprint without estimation.',
            },
            <String, dynamic>{
              'title': 'Learning',
              'description': 'Time-boxing spike work avoided rabbit holes on integration.',
            },
          ],
          'pending_items': <Map<String, dynamic>>[
            <String, dynamic>{'content': 'Confirm webhook SLA with partner ops.'},
            <String, dynamic>{'content': 'Backfill integration tests for auth refresh.'},
          ],
          'next_week_priorities': <Map<String, dynamic>>[
            <String, dynamic>{
              'title': 'Cut beta release branch',
              'sub_title': 'Target Wed EOD',
            },
            <String, dynamic>{
              'title': 'Load test staging',
              'sub_title': 'Before partner demo',
            },
          ],
          'expert_weekly_feedback': <Map<String, dynamic>>[
            <String, dynamic>{
              'expert_name': 'Coach Alex',
              'feedback': 'Protect two mornings for implementation; batch decisions in one sync.',
            },
          ],
        },
      },
    });
  }

  /// `insight_type == MONTHLY`（3）时的完整详情响应。
  static MPGetInsightDetailResponse monthlyDetailResponse() {
    return MPGetInsightDetailResponse.fromJson(<String, dynamic>{
      'base_resp': _baseRespOk(),
      'insight_detail': <String, dynamic>{
        'basic_info': _basicInfo(
          id: monthlyListItem().id,
          cycleType: MPInsightCycleType.monthly,
          title: monthlyListItem().title,
          subTitle: monthlyListItem().subtitle,
          content: monthlyListItem().content,
        ),
        'insight_type': MPInsightCycleType.monthly,
        'monthly_detail': <String, dynamic>{
          'overview': <String, dynamic>{
            'title': 'Month overview',
            'content_md':
                'January leaned heavily into **delivery** with steady cross-team syncs; fewer solo research blocks than December.',
          },
          'attention_distribution': <String, dynamic>{
            'title': 'Attention distribution',
            'summary': 'Product and engineering dominated; ops stayed flat.',
            'items': <Map<String, dynamic>>[
              <String, dynamic>{'name': 'Product', 'value': 42},
              <String, dynamic>{'name': 'Engineering', 'value': 35},
              <String, dynamic>{'name': 'Ops', 'value': 15},
              <String, dynamic>{'name': 'Personal', 'value': 8},
            ],
          },
          'key_people': <String, dynamic>{
            'title': 'Key people this month',
            'summary': 'Pairing concentrated with design lead and backend owner.',
            'items': <Map<String, dynamic>>[
              <String, dynamic>{'name': 'Sam (Design)', 'value': 28},
              <String, dynamic>{'name': 'Jordan (Backend)', 'value': 22},
              <String, dynamic>{'name': 'Riley (PM)', 'value': 18},
            ],
          },
          'topics_resurfacing': <String, dynamic>{
            'title': 'Topics resurfacing',
            'summary': 'Auth reliability and onboarding friction appeared across weeks.',
            'items': <Map<String, dynamic>>[
              <String, dynamic>{'name': 'Onboarding friction', 'value': 65},
              <String, dynamic>{'name': 'Auth edge cases', 'value': 52},
              <String, dynamic>{'name': 'Performance budget', 'value': 40},
            ],
          },
          'open_threads': <String, dynamic>{
            'title': 'Long-running open threads',
            'summary': 'Partner SLA still unsigned; affects webhook rollout.',
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'content': 'Legal review of data processing addendum (week 3 carry-over).',
              },
              <String, dynamic>{
                'content': 'Decision on retention policy for voice artifacts.',
              },
            ],
          },
          'month_to_month_trend': <String>[
            'Meeting load ↑ vs December.',
            'Deep work blocks ↓ slightly on Thu/Fri.',
            'Shipping cadence ↑ two consecutive weeks.',
          ],
          'decisions': <String, dynamic>{
            'title': 'Decisions that cannot slip again',
            'intro': 'These commitments appeared multiple times; missing them blocked downstream work.',
            'items': <String>[
              'Finalize API error taxonomy before client integration freeze.',
              'Lock analytics event names before marketing UTM campaign.',
            ],
          },
          'suggested_focus_next_month': <String>[
            'Book weekly 45m “scope guard” with PM before sprint planning.',
            'Reserve Fri AM for tech debt paydown.',
          ],
        },
      },
    });
  }

  /// `insight_type == PATTERN`（4）时的完整详情响应。
  static MPGetInsightDetailResponse patternDetailResponse() {
    return MPGetInsightDetailResponse.fromJson(<String, dynamic>{
      'base_resp': _baseRespOk(),
      'insight_detail': <String, dynamic>{
        'basic_info': _basicInfo(
          id: patternListItem().id,
          cycleType: MPInsightCycleType.pattern,
          title: patternListItem().title,
          subTitle: patternListItem().subtitle,
          content: patternListItem().content,
        ),
        'insight_type': MPInsightCycleType.pattern,
        'pattern_detail': <String, dynamic>{
          'banner_title': 'Late-night planning before deadlines',
          'detected': <String, dynamic>{
            'section_title': 'Pattern detected',
            'content_md':
                'Across **8 memories** in the last 30 days, you repeatedly planned deliverables after 22:00 when a milestone was within 48 hours.',
          },
          'appeared_items': <Map<String, dynamic>>[
            <String, dynamic>{
              'memory_id': 'mem-a1',
              'title': 'Sprint prep voice note',
              'sub_title': 'Jan 28 · 23:10',
              'create_at': 1738108200,
            },
            <String, dynamic>{
              'memory_id': 'mem-b2',
              'title': 'Partner demo checklist',
              'sub_title': 'Feb 1 · 22:40',
              'create_at': 1738366800,
            },
          ],
          'where_this_appeared': <String, dynamic>{
            'intro_text': 'Appeared in recent memories:',
            'items': <String>[
              'planning · Sprint prep voice note',
              'demo · Partner demo checklist',
            ],
            'summary_text': 'Appeared in 2 conversations',
          },
          'why_this_matters':
              'Compressing planning into late hours correlates with rushed decisions and weaker recovery the next day.',
          'next_step': <String>[
            'Try a 15m “plan tomorrow” block at 18:00 on milestone weeks.',
            'Ask AI to turn tonight’s notes into a minimal checklist before 21:00.',
          ],
        },
      },
    });
  }

  /// 解析后的 [MPBaseResp]，便于断言 code == 0。
  static MPBaseResp okBaseResp() => MPBaseResp.fromJson(_baseRespOk());
}
