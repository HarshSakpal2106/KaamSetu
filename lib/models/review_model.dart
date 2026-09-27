class ReviewModel {
  final String reviewerName;
  final double rating;
  final String comment;
  final String date;

  const ReviewModel({
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      reviewerName: json['reviewerName'] as String? ?? 'Verified Customer',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      comment: json['comment'] as String? ?? '',
      date: json['date'] as String? ?? 'Recently',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewerName': reviewerName,
      'rating': rating,
      'comment': comment,
      'date': date,
    };
  }
}
