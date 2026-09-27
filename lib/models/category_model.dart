class CategoryModel {
  final String id;
  final String title;
  final String subtitle;
  final String iconEmoji;
  final String assetImage;

  const CategoryModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconEmoji,
    required this.assetImage,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      iconEmoji: json['iconEmoji'] as String? ?? '🔧',
      assetImage: json['assetImage'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'iconEmoji': iconEmoji,
      'assetImage': assetImage,
    };
  }
}
