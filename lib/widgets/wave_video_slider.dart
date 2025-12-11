import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/m3u8_video_controller.dart';
import '../models/alert_marker.dart';

/// Custom video slider with wave format and alert width increase
class WaveVideoSlider extends StatefulWidget {
  final M3u8VideoController controller;
  final Color activeColor;
  final Color inactiveColor;
  final Color markerColor;
  final double height;
  final Function(Duration)? onSeek;
  final Widget Function(AlertMarker)? markerBuilder;
  final double waveAmplitude;
  final double waveFrequency;

  const WaveVideoSlider({
    Key? key,
    required this.controller,
    this.activeColor = Colors.red,
    this.inactiveColor = Colors.grey,
    this.markerColor = Colors.amber,
    this.height = 60,
    this.onSeek,
    this.markerBuilder,
    this.waveAmplitude = 8.0,
    this.waveFrequency = 0.02,
  }) : super(key: key);

  @override
  State<WaveVideoSlider> createState() => _WaveVideoSliderState();
}

class _WaveVideoSliderState extends State<WaveVideoSlider> {
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
            color: Colors.black12,
            child: const Center(
              child: Text(
                'Loading...',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          );
        }

        final maxValue = duration.inMilliseconds.toDouble();
        final currentValue = _isDragging
            ? _dragValue
            : position.inMilliseconds.toDouble();

        return Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onHorizontalDragStart: (details) {
                  setState(() {
                    _isDragging = true;
                    _dragValue = _calculateValueFromPosition(
                      details.localPosition.dx,
                      constraints.maxWidth,
                      maxValue,
                    );
                  });
                },
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _dragValue = _calculateValueFromPosition(
                      details.localPosition.dx,
                      constraints.maxWidth,
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
                onTapDown: (details) {
                  final value = _calculateValueFromPosition(
                    details.localPosition.dx,
                    constraints.maxWidth,
                    maxValue,
                  );
                  final newPosition = Duration(milliseconds: value.toInt());
                  widget.controller.seekTo(newPosition);
                  widget.onSeek?.call(newPosition);
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, widget.height),
                  painter: WaveSliderPainter(
                    currentValue: currentValue,
                    maxValue: maxValue,
                    activeColor: widget.activeColor,
                    inactiveColor: widget.inactiveColor,
                    markerColor: widget.markerColor,
                    markers: widget.controller.markers,
                    waveAmplitude: widget.waveAmplitude,
                    waveFrequency: widget.waveFrequency,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  double _calculateValueFromPosition(
    double position,
    double width,
    double maxValue,
  ) {
    final value = (position / width) * maxValue;
    return value.clamp(0.0, maxValue);
  }
}

/// Custom painter for wave slider with alert width increase
class WaveSliderPainter extends CustomPainter {
  final double currentValue;
  final double maxValue;
  final Color activeColor;
  final Color inactiveColor;
  final Color markerColor;
  final List<AlertMarker> markers;
  final double waveAmplitude;
  final double waveFrequency;

  WaveSliderPainter({
    required this.currentValue,
    required this.maxValue,
    required this.activeColor,
    required this.inactiveColor,
    required this.markerColor,
    required this.markers,
    required this.waveAmplitude,
    required this.waveFrequency,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    // Convert markers to positions and create alert zones
    final alertZones = _createAlertZones(size.width);

    // Draw inactive wave (full length)
    _drawWave(
      canvas,
      size,
      centerY,
      0,
      size.width,
      inactiveColor.withOpacity(0.3),
      alertZones,
      false,
    );

    // Draw active wave (up to current position)
    final currentX = (currentValue / maxValue) * size.width;
    _drawWave(
      canvas,
      size,
      centerY,
      0,
      currentX,
      activeColor,
      alertZones,
      true,
    );

    // Draw alert markers
    _drawAlertMarkers(canvas, size, centerY, alertZones);

    // Draw position indicator (thumb)
    _drawThumb(canvas, currentX, centerY);
  }

  List<AlertZone> _createAlertZones(double width) {
    final zones = <AlertZone>[];

    for (final marker in markers) {
      final markerSeconds = marker.timeInSeconds;
      final maxSeconds = maxValue / 1000.0;
      final centerX = (markerSeconds / maxSeconds) * width;

      // Calculate zone width - base width + 15% increase at alert
      final baseWidth = width * 0.02; // 2% of total width as base
      final alertWidth = baseWidth * 1.15; // 15% increase

      zones.add(AlertZone(centerX: centerX, width: alertWidth, marker: marker));
    }

    return zones;
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double centerY,
    double startX,
    double endX,
    Color color,
    List<AlertZone> alertZones,
    bool isActive,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Start from bottom left
    path.moveTo(startX, size.height);

    // Draw wave to bottom edge
    for (double x = startX; x <= endX; x += 1) {
      final normalizedX = x / size.width;

      // Check if we're in an alert zone
      double heightMultiplier = 1.0;
      for (final zone in alertZones) {
        if (x >= zone.startX && x <= zone.endX) {
          // Smoothly increase height at alert zones
          final distanceFromCenter = (x - zone.centerX).abs();
          final zoneRadius = zone.width / 2;
          if (distanceFromCenter <= zoneRadius) {
            // Use cosine curve for smooth transition
            final factor = math.cos(
              (distanceFromCenter / zoneRadius) * math.pi / 2,
            );
            heightMultiplier = 1.0 + (0.15 * factor); // 15% increase at center
          }
        }
      }

      // Wave calculation
      final wave =
          math.sin(normalizedX * size.width * waveFrequency) *
          waveAmplitude *
          heightMultiplier;
      final y = centerY + wave;

      path.lineTo(x, y);
    }

    // Complete the path
    path.lineTo(endX, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Draw wave outline
    final outlinePath = Path();
    outlinePath.moveTo(startX, centerY);

    for (double x = startX; x <= endX; x += 1) {
      final normalizedX = x / size.width;

      double heightMultiplier = 1.0;
      for (final zone in alertZones) {
        if (x >= zone.startX && x <= zone.endX) {
          final distanceFromCenter = (x - zone.centerX).abs();
          final zoneRadius = zone.width / 2;
          if (distanceFromCenter <= zoneRadius) {
            final factor = math.cos(
              (distanceFromCenter / zoneRadius) * math.pi / 2,
            );
            heightMultiplier = 1.0 + (0.15 * factor);
          }
        }
      }

      final wave =
          math.sin(normalizedX * size.width * waveFrequency) *
          waveAmplitude *
          heightMultiplier;
      final y = centerY + wave;

      outlinePath.lineTo(x, y);
    }

    final outlinePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(outlinePath, outlinePaint);
  }

  void _drawAlertMarkers(
    Canvas canvas,
    Size size,
    double centerY,
    List<AlertZone> alertZones,
  ) {
    for (final zone in alertZones) {
      final x = zone.centerX;

      if (x < 0 || x > size.width) continue;

      // Draw marker line with increased width
      final markerPaint = Paint()
        ..color = zone.marker.color ?? markerColor
        ..style = PaintingStyle.fill;

      // Increased width for alert marker
      final markerWidth = 4.0 * 1.15; // 15% wider

      final markerRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, centerY),
          width: markerWidth,
          height: size.height * 0.8,
        ),
        const Radius.circular(2),
      );

      canvas.drawRRect(markerRect, markerPaint);

      // Draw glow effect for alerts
      final glowPaint = Paint()
        ..color = (zone.marker.color ?? markerColor).withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawRRect(markerRect, glowPaint);

      // Draw icon if available
      if (zone.marker.icon != null) {
        final iconPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(zone.marker.icon!.codePoint),
            style: TextStyle(
              fontSize: 16,
              fontFamily: zone.marker.icon!.fontFamily,
              color: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        iconPainter.layout();
        iconPainter.paint(
          canvas,
          Offset(x - iconPainter.width / 2, centerY - size.height * 0.45),
        );
      }
    }
  }

  void _drawThumb(Canvas canvas, double x, double centerY) {
    // Outer circle
    final outerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, centerY), 8, outerPaint);

    // Inner circle
    final innerPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, centerY), 6, innerPaint);

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(Offset(x, centerY), 8, shadowPaint);
  }

  @override
  bool shouldRepaint(WaveSliderPainter oldDelegate) {
    return oldDelegate.currentValue != currentValue ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.markers.length != markers.length;
  }
}

/// Helper class to define alert zones with increased width
class AlertZone {
  final double centerX;
  final double width;
  final AlertMarker marker;

  AlertZone({required this.centerX, required this.width, required this.marker});

  double get startX => centerX - (width / 2);
  double get endX => centerX + (width / 2);
}
