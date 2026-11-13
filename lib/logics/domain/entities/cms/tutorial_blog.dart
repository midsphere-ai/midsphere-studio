import '../base/base.dart';

class TutorialBlog extends BaseModel {
  @override
  final String id;
  final String title;
  final String? subtitle;
  final String markdownText;
  final bool asInfoButton;
  final String? image;
  @override
  final DateTime dateCreated;

  TutorialBlog({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.asInfoButton,
    required this.markdownText,
    required this.dateCreated,
  });

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'markdownText': markdownText,
        'as_info_button': asInfoButton,
        'date_created': dateCreated.toIso8601String(),
      };

  factory TutorialBlog.fromJson(Map<String, dynamic> json) {
    return TutorialBlog(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      image: json['image'],
      markdownText: json['markdownText'] ?? "",
      asInfoButton: json['as_info_button'],
      dateCreated: DateTime.parse(json['date_created']),
    );
  }
}
