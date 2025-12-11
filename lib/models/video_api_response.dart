/// Model for video API response data
class VideoApiResponse {
  final String fileUrl;
  final int duration; // in seconds
  final List<AiAlert> aiAlert;
  final DateTime fileStartTime; // UTC
  final DateTime fileEndTime; // UTC

  VideoApiResponse({
    required this.fileUrl,
    required this.duration,
    required this.aiAlert,
    required this.fileStartTime,
    required this.fileEndTime,
  });

  /// Create VideoApiResponse from JSON
  factory VideoApiResponse.fromJson(Map<String, dynamic> json) {
    return VideoApiResponse(
      fileUrl: json['fileUrl'] as String,
      duration: json['duration'] as int,
      aiAlert: (json['aiAlert'] as List<dynamic>)
          .map((e) => AiAlert.fromJson(e as Map<String, dynamic>))
          .toList(),
      fileStartTime: DateTime.parse(json['fileStartTime'] as String),
      fileEndTime: DateTime.parse(json['fileEndTime'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'fileUrl': fileUrl,
      'duration': duration,
      'aiAlert': aiAlert.map((e) => e.toJson()).toList(),
      'fileStartTime': fileStartTime.toIso8601String(),
      'fileEndTime': fileEndTime.toIso8601String(),
    };
  }
}

/// Model for AI alert data
class AiAlert {
  final int id;
  final String deviceId;
  final String entityId;
  final DateTime createdAt; // UTC
  final String title;
  final String image;
  final String text;

  AiAlert({
    required this.id,
    required this.deviceId,
    required this.entityId,
    required this.createdAt,
    required this.title,
    required this.image,
    required this.text,
  });

  /// Create AiAlert from JSON
  factory AiAlert.fromJson(Map<String, dynamic> json) {
    return AiAlert(
      id: json['id'] as int,
      deviceId: json['device_id'] as String,
      entityId: json['entity_id'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      title: json['title'] as String,
      image: json['image'] as String,
      text: json['text'] as String,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'entity_id': entityId,
      'created_at': createdAt.toIso8601String(),
      'title': title,
      'image': image,
      'text': text,
    };
  }

  @override
  String toString() {
    return 'AiAlert(id: $id, title: $title, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AiAlert && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
