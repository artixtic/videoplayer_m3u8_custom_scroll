import 'package:flutter/material.dart';
import 'package:video_player_m3u8_alerts/video_player_m3u8_alerts.dart';

/// A pre-built video player screen with API data integration
/// Video player at top, custom slider below
class ApiVideoPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> apiData;
  final Color? sliderActiveColor;
  final Color? sliderInactiveColor;
  final Color? sliderMarkerColor;
  final Color? backgroundColor;
  final String? title;
  final Widget Function(AlertMarker)? alertBuilder;
  final VoidCallback? onError;
  final bool useWaveSlider;

  const ApiVideoPlayerScreen({
    Key? key,
    required this.apiData,
    this.sliderActiveColor,
    this.sliderInactiveColor,
    this.sliderMarkerColor,
    this.backgroundColor,
    this.title,
    this.alertBuilder,
    this.onError,
    this.useWaveSlider = true, // Default to wave slider
  }) : super(key: key);

  @override
  State<ApiVideoPlayerScreen> createState() => _ApiVideoPlayerScreenState();
}

class _ApiVideoPlayerScreenState extends State<ApiVideoPlayerScreen> {
  late M3u8VideoController _controller;
  bool _isLoading = true;
  String _errorMessage = '';
  List<AlertMarker> _markers = [];

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      // Parse API response
      final videoResponse = VideoApiResponse.fromJson(widget.apiData);

      // Convert alerts to markers with automatic offset detection
      // Use full timeline parsing to account for gaps in recording
      // This is more accurate for videos with discontinuities
      // If alerts are still off, try adjusting manualOffsetSeconds:
      // - If alerts appear too early: use positive value (e.g., 480.0 for 8 min)
      // - If alerts appear too late: use negative value (e.g., -480.0 for 8 min)
      _markers = await AlertConverter.fromVideoApiResponseAsync(
        videoResponse,
        detectTimelineOffset: true,
        useSimpleOffsetCalculation: false, // Use full timeline parsing to handle gaps
        manualOffsetSeconds: 0.0, // Adjust this if alerts are still misaligned
      );

      // Initialize controller
      _controller = M3u8VideoController();
      await _controller.initialize(videoResponse.fileUrl, markers: _markers);

      if (mounted) {
        setState(() => _isLoading = false);
      }

      debugPrint('Loaded video with ${_markers.length} alert markers');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load video: $e';
        });
      }
      widget.onError?.call();
      debugPrint('Error loading video: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: widget.title != null
          ? AppBar(
              title: Text(widget.title!),
              backgroundColor: bgColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    'Loading video...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
          ? _buildErrorWidget()
          : _buildVideoPlayer(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = '';
                  _isLoading = true;
                });
                _loadVideo();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Column(
      children: [
        // Video Player (no slider)
        Expanded(
          child: M3u8VideoPlayerNoSlider(
            controller: _controller,
            backgroundColor: widget.backgroundColor ?? Colors.black,
            alertBuilder: widget.alertBuilder,
          ),
        ),

        // Alert Timeline Badges
        if (_markers.isNotEmpty)
          Container(
            color: widget.backgroundColor ?? Colors.black,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: AlertTimeline(
              alerts: _markers,
              onAlertTap: (alert) {
                _controller.seekTo(
                  Duration(seconds: alert.timeInSeconds.toInt()),
                );
              },
            ),
          ),

        // Controls and Slider Section
        Container(
          color: widget.backgroundColor ?? Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.replay_10,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      final newPosition =
                          _controller.position - const Duration(seconds: 10);
                      _controller.seekTo(
                        newPosition < Duration.zero
                            ? Duration.zero
                            : newPosition,
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: widget.sliderActiveColor ?? Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) => Icon(
                          _controller.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      onPressed: _controller.togglePlayPause,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(
                      Icons.forward_10,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      final newPosition =
                          _controller.position + const Duration(seconds: 10);
                      _controller.seekTo(
                        newPosition > _controller.duration
                            ? _controller.duration
                            : newPosition,
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Wave or Custom Video Slider
              widget.useWaveSlider
                  ? WaveformSlider(
                      controller: _controller,
                      activeColor: widget.sliderActiveColor ?? Colors.black87,
                      inactiveColor: widget.sliderInactiveColor ?? Colors.black26,
                      alertColor: widget.sliderMarkerColor ?? const Color(0xFF8BC34A),
                      backgroundColor: const Color(0xFFE3F2FD), // Light blue background
                      height: 100,
                      showTodayButton: false,
                      showLiveIndicator: false,
                      barsCount: 120,
                    )
                  : CustomVideoSlider(
                      controller: _controller,
                      activeColor: widget.sliderActiveColor ?? Colors.orange,
                      inactiveColor: widget.sliderInactiveColor ?? Colors.grey,
                      markerColor: widget.sliderMarkerColor ?? Colors.amber,
                      height: 60,
                    ),

              const SizedBox(height: 8),

              // Video Info
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_markers.length} Alert${_markers.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatDuration(_controller.position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatDuration(_controller.duration),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}
