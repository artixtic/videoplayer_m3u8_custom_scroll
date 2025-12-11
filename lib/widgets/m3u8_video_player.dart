import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../controllers/m3u8_video_controller.dart';
import '../models/alert_marker.dart';
import 'custom_video_slider.dart';

/// Main video player widget with alert support
class M3u8VideoPlayer extends StatefulWidget {
  final M3u8VideoController controller;
  final bool showControls;
  final Color? controlsColor;
  final Color? backgroundColor;
  final Widget Function(AlertMarker)? alertBuilder;
  final Widget? placeholder;
  final BoxFit fit;

  const M3u8VideoPlayer({
    Key? key,
    required this.controller,
    this.showControls = true,
    this.controlsColor,
    this.backgroundColor,
    this.alertBuilder,
    this.placeholder,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  State<M3u8VideoPlayer> createState() => _M3u8VideoPlayerState();
}

class _M3u8VideoPlayerState extends State<M3u8VideoPlayer> {
  bool _showControls = true;
  bool _isControlsVisible = true;

  @override
  void initState() {
    super.initState();
    _showControls = widget.showControls;
  }

  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        if (!widget.controller.isInitialized) {
          return Container(
            color: widget.backgroundColor ?? Colors.black,
            child: Center(
              child:
                  widget.placeholder ??
                  const CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        return Container(
          color: widget.backgroundColor ?? Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video player
              Center(
                child: AspectRatio(
                  aspectRatio: widget.controller.aspectRatio,
                  child: GestureDetector(
                    onTap: () {
                      if (_showControls) {
                        _toggleControls();
                      }
                      widget.controller.togglePlayPause();
                    },
                    child: VideoPlayer(
                      widget.controller.videoPlayerController!,
                    ),
                  ),
                ),
              ),

              // Alert overlay
              if (widget.controller.currentAlert != null)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: _buildAlertWidget(widget.controller.currentAlert!),
                ),

              // Play/Pause overlay icon
              if (!widget.controller.isPlaying)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Controls
              if (_showControls && _isControlsVisible)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildControls(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertWidget(AlertMarker alert) {
    if (widget.alertBuilder != null) {
      return widget.alertBuilder!(alert);
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: alert.color ?? Colors.orange.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (alert.icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(alert.icon, color: Colors.white, size: 24),
              ),
            Expanded(
              child: Text(
                alert.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: widget.controller.dismissCurrentAlert,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Custom slider with markers
          CustomVideoSlider(
            controller: widget.controller,
            activeColor: widget.controlsColor ?? Colors.red,
            height: 50,
          ),

          // Control buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                // Play/Pause button
                IconButton(
                  icon: Icon(
                    widget.controller.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: widget.controller.togglePlayPause,
                ),

                const SizedBox(width: 8),

                // Skip backward
                IconButton(
                  icon: const Icon(Icons.replay_10, color: Colors.white),
                  onPressed: () {
                    final newPosition =
                        widget.controller.position -
                        const Duration(seconds: 10);
                    widget.controller.seekTo(
                      newPosition < Duration.zero ? Duration.zero : newPosition,
                    );
                  },
                ),

                // Skip forward
                IconButton(
                  icon: const Icon(Icons.forward_10, color: Colors.white),
                  onPressed: () {
                    final newPosition =
                        widget.controller.position +
                        const Duration(seconds: 10);
                    widget.controller.seekTo(
                      newPosition > widget.controller.duration
                          ? widget.controller.duration
                          : newPosition,
                    );
                  },
                ),

                const Spacer(),

                // Speed control
                PopupMenuButton<double>(
                  icon: const Icon(Icons.speed, color: Colors.white),
                  onSelected: (speed) {
                    widget.controller.setPlaybackSpeed(speed);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 0.5, child: Text('0.5x')),
                    const PopupMenuItem(value: 0.75, child: Text('0.75x')),
                    const PopupMenuItem(value: 1.0, child: Text('1.0x')),
                    const PopupMenuItem(value: 1.25, child: Text('1.25x')),
                    const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                    const PopupMenuItem(value: 2.0, child: Text('2.0x')),
                  ],
                ),

                // Fullscreen button (placeholder)
                IconButton(
                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                  onPressed: () {
                    // TODO: Implement fullscreen
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
