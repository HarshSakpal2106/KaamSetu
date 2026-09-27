class WorkPhotoModel {
  final String title;
  final String imagePath; // Can be an asset path or remote https:// URL

  const WorkPhotoModel({
    required this.title,
    required this.imagePath,
  });

  factory WorkPhotoModel.fromJson(Map<String, dynamic> json) {
    return WorkPhotoModel(
      title: json['title'] as String? ?? 'Work Sample',
      imagePath: json['imagePath'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'imagePath': imagePath,
    };
  }

  bool get isRemoteUrl => imagePath.startsWith('http://') || imagePath.startsWith('https://');
}
