import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/alert_marker.dart';

/// Controller for managing M3U8 video playback with alert markers
class M3u8VideoController extends ChangeNotifier {
  VideoPlayerController? _videoPlayerController;
  List<AlertMarker> _markers = [];
  AlertMarker? _currentAlert;
  Timer? _alertCheckTimer;
  bool _isInitialized = false;
  bool _isDisposed = false;

  /// Get the underlying video player controller
  VideoPlayerController? get videoPlayerController => _videoPlayerController;

  /// Check if the controller is initialized
  bool get isInitialized => _isInitialized;

  /// Get all alert markers
  List<AlertMarker> get markers => List.unmodifiable(_markers);

  /// Get the current alert being displayed
  AlertMarker? get currentAlert => _currentAlert;

  /// Get current video position
  Duration get position =>
      _videoPlayerController?.value.position ?? Duration.zero;

  /// Get total video duration
  Duration get duration =>
      _videoPlayerController?.value.duration ?? Duration.zero;

  /// Check if video is playing
  bool get isPlaying => _videoPlayerController?.value.isPlaying ?? false;

  /// Get video aspect ratio
  double get aspectRatio => _videoPlayerController?.value.aspectRatio ?? 16 / 9;

  /// Initialize the video player with M3U8 URL
  Future<void> initialize(String m3u8Url, {List<AlertMarker>? markers}) async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(m3u8Url),
      );

      await _videoPlayerController!.initialize();

      if (markers != null) {
        _markers = markers;
      }

      _isInitialized = true;

      // Start checking for alerts
      _startAlertCheck();

      // Listen to position changes
      _videoPlayerController!.addListener(_onVideoPositionChanged);

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to initialize video player: $e');
    }
  }

  /// Add a marker to the timeline
  void addMarker(AlertMarker marker) {
    _markers.add(marker);
    _markers.sort((a, b) => a.timeInSeconds.compareTo(b.timeInSeconds));
    notifyListeners();
  }

  /// Remove a marker from the timeline
  void removeMarker(AlertMarker marker) {
    _markers.remove(marker);
    notifyListeners();
  }

  /// Clear all markers
  void clearMarkers() {
    _markers.clear();
    notifyListeners();
  }

  /// Update markers list
  void updateMarkers(List<AlertMarker> markers) {
    _markers = markers;
    _markers.sort((a, b) => a.timeInSeconds.compareTo(b.timeInSeconds));
    notifyListeners();
  }

  /// Play the video
  Future<void> play() async {
    await _videoPlayerController?.play();
    notifyListeners();
  }

  /// Pause the video
  Future<void> pause() async {
    await _videoPlayerController?.pause();
    notifyListeners();
  }

  /// Seek to a specific position
  Future<void> seekTo(Duration position) async {
    await _videoPlayerController?.seekTo(position);
    notifyListeners();
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    await _videoPlayerController?.setPlaybackSpeed(speed);
    notifyListeners();
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _videoPlayerController?.setVolume(volume);
    notifyListeners();
  }

  /// Start checking for alerts at the current position
  void _startAlertCheck() {
    _alertCheckTimer?.cancel();
    _alertCheckTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) => _checkForAlerts(),
    );
  }

  /// Check if any marker should trigger an alert
  void _checkForAlerts() {
    if (_videoPlayerController == null || !_isInitialized || _isDisposed) {
      return;
    }

    final currentPosition = position.inSeconds.toDouble();

    for (final marker in _markers) {
      // Check if we're within 0.5 seconds of a marker
      if ((currentPosition - marker.timeInSeconds).abs() < 0.5) {
        if (_currentAlert?.timeInSeconds != marker.timeInSeconds) {
          _currentAlert = marker;
          notifyListeners();

          // Auto-dismiss alert after specified duration
          Future.delayed(Duration(milliseconds: marker.displayDuration), () {
            if (_currentAlert == marker) {
              _currentAlert = null;
              notifyListeners();
            }
          });
        }
        return;
      }
    }
  }

  /// Dismiss the current alert
  void dismissCurrentAlert() {
    _currentAlert = null;
    notifyListeners();
  }

  /// Callback when video position changes
  void _onVideoPositionChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _alertCheckTimer?.cancel();
    _videoPlayerController?.removeListener(_onVideoPositionChanged);
    _videoPlayerController?.dispose();
    super.dispose();
  }
}
