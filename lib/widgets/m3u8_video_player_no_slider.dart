import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../controllers/m3u8_video_controller.dart';
import '../models/alert_marker.dart';

/// Video player widget without built-in slider (slider rendered separately)
class M3u8VideoPlayerNoSlider extends StatefulWidget {
  final M3u8VideoController controller;
  final Color? backgroundColor;
  final Widget Function(AlertMarker)? alertBuilder;
  final Widget? placeholder;
  final BoxFit fit;
  final bool showPlayPauseButton;

  const M3u8VideoPlayerNoSlider({
    Key? key,
    required this.controller,
    this.backgroundColor,
    this.alertBuilder,
    this.placeholder,
    this.fit = BoxFit.contain,
    this.showPlayPauseButton = true,
  }) : super(key: key);

  @override
  State<M3u8VideoPlayerNoSlider> createState() =>
      _M3u8VideoPlayerNoSliderState();
}

class _M3u8VideoPlayerNoSliderState extends State<M3u8VideoPlayerNoSlider> {
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
                    onTap: widget.controller.togglePlayPause,
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
              if (widget.showPlayPauseButton && !widget.controller.isPlaying)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
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
}
