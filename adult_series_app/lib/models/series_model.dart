import 'video_model.dart';

class Series {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String channelTitle;
  final String channelId;
  final String description;
  final int episodeCount;
  final List<Video> episodes;
  final String category;

  Series({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.channelId,
    required this.description,
    required this.episodeCount,
    required this.episodes,
    required this.category,
  });

  // Create Series from JSON
  factory Series.fromJson(Map<String, dynamic> json) {
    return Series(
      id: json['id'] as String,
      title: json['title'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      channelTitle: json['channelTitle'] as String,
      channelId: json['channelId'] as String,
      description: json['description'] as String,
      episodeCount: json['episodeCount'] as int,
      episodes:
          (json['episodes'] as List<dynamic>?)
              ?.map((e) => Video.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      category: json['category'] as String,
    );
  }

  // Convert Series to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'channelTitle': channelTitle,
      'channelId': channelId,
      'description': description,
      'episodeCount': episodeCount,
      'episodes': episodes.map((e) => e.toJson()).toList(),
      'category': category,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Series && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
