/// Generic representation of an object, person, food, or activity card.
/// Decouples visual and semantic content from the game engine logic.
class GameItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? imageAsset;       // Asset path or local file path
  final String? audioPrompt;      // Audio path for multilingual pronunciation/hint
  final String category;          // e.g., 'family', 'produce', 'craft', 'routine'
  final Map<String, dynamic> customData;

  const GameItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageAsset,
    this.audioPrompt,
    this.category = 'general',
    this.customData = const {},
  });

  factory GameItem.fromJson(Map<String, dynamic> json) {
    return GameItem(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      imageAsset: json['image_asset'] as String?,
      audioPrompt: json['audio_prompt'] as String?,
      category: json['category'] as String? ?? 'general',
      customData: json['custom_data'] is Map
          ? Map<String, dynamic>.from(json['custom_data'] as Map)
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'image_asset': imageAsset,
      'audio_prompt': audioPrompt,
      'category': category,
      'custom_data': customData,
    };
  }
}
