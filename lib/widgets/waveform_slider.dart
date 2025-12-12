import 'package:flutter/material.dart';

import '../controllers/m3u8_video_controller.dart';
import '../models/alert_marker.dart';

/// Waveform-style slider that matches the design with vertical bars
class WaveformSlider extends StatefulWidget {
  final M3u8VideoController controller;
  final Color activeColor;
  final Color inactiveColor;
  final Color alertColor;
  final Color? backgroundColor;
  final double height;
  final bool showTodayButton;
  final bool showLiveIndicator;
  final VoidCallback? onTodayPressed;
  final Function(Duration)? onSeek;
  final int barsCount;

  const WaveformSlider({
    Key? key,
    required this.controller,
    this.activeColor = const Color(0xFF00BCD4),
    this.inactiveColor = const Color(0xFFE0E0E0),
    this.alertColor = const Color(0xFF8BC34A),
    this.backgroundColor,
    this.height = 100,
    this.showTodayButton = true,
    this.showLiveIndicator = true,
    this.onTodayPressed,
    this.onSeek,
    this.barsCount = 100,
  }) : super(key: key);

  @override
  State<WaveformSlider> createState() => _WaveformSliderState();
}

class _WaveformSliderState extends State<WaveformSlider> {
  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final duration = widget.controller.duration;
        final position = widget.controller.position;

        if (duration.inMilliseconds == 0) {
          return Container(
            height: widget.height,
            color: Colors.white,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final maxValue = duration.inMilliseconds.toDouble();
        final currentValue = _isDragging
            ? _dragValue
            : position.inMilliseconds.toDouble();
        final progress = currentValue / maxValue;

        return Container(
          height: widget.height,
          color: widget.backgroundColor ?? const Color(0xFFE3F2FD), // Light blue background matching design
          child: Stack(
            children: [
              // Waveform bars
              Positioned.fill(
                child: GestureDetector(
                  onTapDown: (details) {
                    _handleSeek(details.localPosition, context);
                  },
                  onHorizontalDragStart: (details) {
                    setState(() {
                      _isDragging = true;
                      _dragValue = _calculateValueFromPosition(
                        details.localPosition.dx,
                        context,
                        maxValue,
                      );
                    });
                  },
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragValue = _calculateValueFromPosition(
                        details.localPosition.dx,
                        context,
                        maxValue,
                      );
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    setState(() {
                      _isDragging = false;
                    });
                    final newPosition = Duration(
                      milliseconds: _dragValue.toInt(),
                    );
                    widget.controller.seekTo(newPosition);
                    widget.onSeek?.call(newPosition);
                  },
                  child: CustomPaint(
                    painter: WaveformPainter(
                      progress: progress,
                      activeColor: widget.activeColor,
                      inactiveColor: widget.inactiveColor,
                      alertColor: widget.alertColor,
                      markers: widget.controller.markers,
                      maxValue: maxValue,
                      barsCount: widget.barsCount,
                    ),
                  ),
                ),
              ),

            ],
          ),
        );
      },
    );
  }

  void _handleSeek(Offset position, BuildContext context) {
    final maxValue = widget.controller.duration.inMilliseconds.toDouble();

    final value = _calculateValueFromPosition(position.dx, context, maxValue);
    final newPosition = Duration(milliseconds: value.toInt());

    widget.controller.seekTo(newPosition);
    widget.onSeek?.call(newPosition);
  }

  double _calculateValueFromPosition(
    double positionX,
    BuildContext context,
    double maxValue,
  ) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return 0.0;

    final width = box.size.width;
    final value = (positionX / width) * maxValue;
    return value.clamp(0.0, maxValue);
  }

  void _jumpToToday() {
    // Jump to current time or latest position
    widget.controller.seekTo(widget.controller.duration);
  }
}

/// Custom painter for waveform-style bars
class WaveformPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final Color alertColor;
  final List<AlertMarker> markers;
  final double maxValue;
  final int barsCount;

  WaveformPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.alertColor,
    required this.markers,
    required this.maxValue,
    required this.barsCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / barsCount;
    final centerY = size.height / 2;

    // Create alert zones map
    final alertZones = <int, AlertMarker>{};
    for (final marker in markers) {
      final markerSeconds = marker.timeInSeconds;
      final maxSeconds = maxValue / 1000.0;
      final normalizedPosition = markerSeconds / maxSeconds;
      final barIndex = (normalizedPosition * barsCount).floor();

      // Debug: First time only
      if (alertZones.isEmpty && markers.isNotEmpty) {
        debugPrint('🎨 Painting waveform:');
        debugPrint('   Total bars: $barsCount');
        debugPrint('   Video duration: ${maxSeconds}s');
        debugPrint('   Markers: ${markers.length}');
      }

      // Add multiple adjacent bars for better visibility
      for (int offset = -2; offset <= 2; offset++) {
        final index = barIndex + offset;
        if (index >= 0 && index < barsCount) {
          alertZones[index] = marker;
          if (offset == 0 && alertZones.length <= markers.length) {
            debugPrint(
              '   Alert at ${markerSeconds}s → bar $index (${(normalizedPosition * 100).toStringAsFixed(1)}%)',
            );
          }
        }
      }
    }

    // Draw tick marks (thin vertical lines) matching the design
    for (int i = 0; i < barsCount; i++) {
      final x = i * barWidth;
      final normalizedPosition = i / barsCount;

      // Determine if this tick is in an alert zone
      final isAlertBar = alertZones.containsKey(i);

      // Tick mark height - taller for alert zones
      final baseHeight = size.height * 0.4; // 40% of total height
      final tickHeight = isAlertBar ? baseHeight * 1.3 : baseHeight;

      // Determine color based on progress and alert
      Color tickColor;
      if (isAlertBar) {
        tickColor = alertColor; // Green for alert zones
      } else if (normalizedPosition <= progress) {
        tickColor = Colors.black87; // Black for played segments
      } else {
        tickColor = Colors.black26; // Light gray for unplayed segments
      }

      final paint = Paint()
        ..color = tickColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      // Draw vertical tick mark
      final startY = centerY - tickHeight / 2;
      final endY = centerY + tickHeight / 2;
      canvas.drawLine(
        Offset(x + barWidth / 2, startY),
        Offset(x + barWidth / 2, endY),
        paint,
      );
    }

    // Draw progress indicator line
    final progressX = progress * size.width;
    final linePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(progressX, 0),
      Offset(progressX, size.height),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.markers.length != markers.length;
  }
}
