/// Insights 类型
enum MPInsightType {
  daily,
  weekly,
  monthly,
}

/// Insights 数据模型
class MPInsightModel {
  final String id;
  final MPInsightType type;
  final String title;
  final String timeText;
  final String period;
  final String description;
  final DateTime timestamp;

  MPInsightModel({
    required this.id,
    required this.type,
    required this.title,
    required this.timeText,
    required this.period,
    required this.description,
    required this.timestamp,
  });
}

