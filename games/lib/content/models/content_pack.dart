import '../../core/models/game_item.dart';

class RoutineStepItem {
  final String id;
  final int stepOrder;
  final String title;
  final String? subtitle;
  final String? iconName;

  const RoutineStepItem({
    required this.id,
    required this.stepOrder,
    required this.title,
    this.subtitle,
    this.iconName,
  });

  factory RoutineStepItem.fromJson(Map<String, dynamic> json) => RoutineStepItem(
        id: json['id'] as String,
        stepOrder: (json['step_order'] as num?)?.toInt() ?? 1,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String?,
        iconName: json['icon_name'] as String?,
      );

  GameItem toGameItem() => GameItem(
        id: id,
        title: title,
        subtitle: subtitle,
        category: 'routine',
        customData: {'step_order': stepOrder, 'icon_name': iconName},
      );
}

class ContentPack {
  final String regionId;
  final String regionName;
  final String languageCode;
  final List<GameItem> items;
  final List<RoutineStepItem> routineSteps;

  const ContentPack({
    required this.regionId,
    required this.regionName,
    required this.languageCode,
    required this.items,
    required this.routineSteps,
  });

  factory ContentPack.fromJson(Map<String, dynamic> json) {
    return ContentPack(
      regionId: json['region_id'] as String? ?? 'generic',
      regionName: json['region_name'] as String? ?? 'Default',
      languageCode: json['language_code'] as String? ?? 'en',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => GameItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      routineSteps: (json['routine_steps'] as List<dynamic>?)
              ?.map((step) =>
                  RoutineStepItem.fromJson(step as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
