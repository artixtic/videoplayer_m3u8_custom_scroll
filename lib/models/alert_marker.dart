/// Model class for alert markers to be displayed on the video timeline
class AlertMarker {
  /// The time in the video (in seconds) where the marker should appear
  final double timeInSeconds;

  /// The message or alert text to display
  final String message;

  /// Optional widget to display instead of default message
  final dynamic customWidget;

  /// Background color for the marker
  final dynamic color;

  /// Icon to show on the marker (optional)
  final dynamic icon;

  /// Duration to show the alert popup (in milliseconds)
  final int displayDuration;

  AlertMarker({
    required this.timeInSeconds,
    required this.message,
    this.customWidget,
    this.color,
    this.icon,
    this.displayDuration = 3000,
  });

  /// Create a copy with modified properties
  AlertMarker copyWith({
    double? timeInSeconds,
    String? message,
    dynamic customWidget,
    dynamic color,
    dynamic icon,
    int? displayDuration,
  }) {
    return AlertMarker(
      timeInSeconds: timeInSeconds ?? this.timeInSeconds,
      message: message ?? this.message,
      customWidget: customWidget ?? this.customWidget,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      displayDuration: displayDuration ?? this.displayDuration,
    );
  }

  @override
  String toString() {
    return 'AlertMarker(timeInSeconds: $timeInSeconds, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AlertMarker &&
        other.timeInSeconds == timeInSeconds &&
        other.message == message;
  }

  @override
  int get hashCode => timeInSeconds.hashCode ^ message.hashCode;
}
