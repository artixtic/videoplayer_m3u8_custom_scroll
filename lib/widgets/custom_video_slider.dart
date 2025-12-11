import 'package:flutter/material.dart';

import '../controllers/m3u8_video_controller.dart';
import '../models/alert_marker.dart';

/// Custom video slider with markers for alerts
class CustomVideoSlider extends StatefulWidget {
  final M3u8VideoController controller;
  final Color activeColor;
  final Color inactiveColor;
  final Color markerColor;
  final double height;
  final Function(Duration)? onSeek;
  final Widget Function(AlertMarker)? markerBuilder;

  const CustomVideoSlider({
    Key? key,
    required this.controller,
    this.activeColor = Colors.red,
    this.inactiveColor = Colors.grey,
    this.markerColor = Colors.amber,
    this.height = 40.0,
    this.onSeek,
    this.markerBuilder,
  }) : super(key: key);

  @override
  State<CustomVideoSlider> createState() => _CustomVideoSliderState();
}

class _CustomVideoSliderState extends State<CustomVideoSlider> {
  double? _dragPosition;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final duration = widget.controller.duration;
        final position = widget.controller.position;

        if (duration == Duration.zero) {
          return Container(
            height: widget.height,
            color: Colors.black12,
            child: const Center(
              child: Text(
                'Loading...',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          );
        }

        final double currentValue = _isDragging
            ? _dragPosition!
            : position.inMilliseconds.toDouble();
        final double maxValue = duration.inMilliseconds.toDouble();

        return Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Stack(
            children: [
              // Background track
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: widget.inactiveColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Progress track
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: currentValue / maxValue,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: widget.activeColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),

              // Markers
              ...widget.controller.markers.map((marker) {
                return _buildMarker(marker, maxValue);
              }).toList(),

              // Slider
              Positioned.fill(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16,
                    ),
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    thumbColor: widget.activeColor,
                    overlayColor: widget.activeColor.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: currentValue.clamp(0.0, maxValue),
                    min: 0.0,
                    max: maxValue,
                    onChangeStart: (value) {
                      setState(() {
                        _isDragging = true;
                        _dragPosition = value;
                      });
                    },
                    onChanged: (value) {
                      setState(() {
                        _dragPosition = value;
                      });
                    },
                    onChangeEnd: (value) {
                      setState(() {
                        _isDragging = false;
                        _dragPosition = null;
                      });
                      final newPosition = Duration(milliseconds: value.toInt());
                      widget.controller.seekTo(newPosition);
                      widget.onSeek?.call(newPosition);
                    },
                  ),
                ),
              ),

              // Time labels
              Positioned(
                left: 8,
                bottom: 2,
                child: Text(
                  _formatDuration(
                    _isDragging
                        ? Duration(milliseconds: _dragPosition!.toInt())
                        : position,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 2,
                child: Text(
                  _formatDuration(duration),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMarker(AlertMarker marker, double maxValue) {
    final markerPosition = marker.timeInSeconds * 1000;
    final percentage = markerPosition / maxValue;

    return Positioned(
      left: percentage * (MediaQuery.of(context).size.width - 16),
      top: 0,
      bottom: 0,
      child: GestureDetector(
        onTap: () {
          widget.controller.seekTo(
            Duration(seconds: marker.timeInSeconds.toInt()),
          );
        },
        child:
            widget.markerBuilder?.call(marker) ?? _defaultMarkerWidget(marker),
      ),
    );
  }

  Widget _defaultMarkerWidget(AlertMarker marker) {
    return Container(
      width: 3,
      decoration: BoxDecoration(
        color: marker.color ?? widget.markerColor,
        borderRadius: BorderRadius.circular(1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 2),
        ],
      ),
      child: marker.icon != null
          ? Center(child: Icon(marker.icon, size: 12, color: Colors.white))
          : null,
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
