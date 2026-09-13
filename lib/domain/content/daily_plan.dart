import 'content_item.dart';

class DailyPlan {
  final DateTime date;
  final List<ContentItem> recommendedActivities;

  const DailyPlan({
    required this.date,
    required this.recommendedActivities,
  });
}
