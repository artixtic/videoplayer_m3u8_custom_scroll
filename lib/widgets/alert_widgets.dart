import 'package:flutter/material.dart';

import '../models/alert_marker.dart';

/// Alert badge widget showing alert information
/// Can be positioned anywhere in the layout
class AlertBadge extends StatelessWidget {
  final AlertMarker alert;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;
  final bool showIcon;

  const AlertBadge({
    Key? key,
    required this.alert,
    this.backgroundColor,
    this.textColor,
    this.onTap,
    this.showIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Light green background matching the design
    final bgColor = backgroundColor ?? const Color(0xFFA5D6A7);
    final txtColor = textColor ?? Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon && alert.icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(alert.icon, size: 18, color: txtColor),
                ),
              Text(
                _formatAlertTitle(alert.message),
                style: TextStyle(
                  color: txtColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAlertTitle(String message) {
    // Extract key words for badge
    if (message.toLowerCase().contains('parcel')) {
      return 'PARCEL ALERT!';
    } else if (message.toLowerCase().contains('person')) {
      return 'PERSON ALERT!';
    } else if (message.toLowerCase().contains('vehicle')) {
      return 'VEHICLE ALERT!';
    } else if (message.toLowerCase().contains('motion')) {
      return 'MOTION ALERT!';
    }
    return 'ALERT!';
  }
}

/// Timeline showing alerts as badges
class AlertTimeline extends StatelessWidget {
  final List<AlertMarker> alerts;
  final Function(AlertMarker)? onAlertTap;
  final double height;

  const AlertTimeline({
    Key? key,
    required this.alerts,
    this.onAlertTap,
    this.height = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: alerts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final alert = alerts[index];
          return AlertBadge(alert: alert, onTap: () => onAlertTap?.call(alert));
        },
      ),
    );
  }
}

/// Alert indicator that can be overlaid on video
class AlertOverlay extends StatefulWidget {
  final AlertMarker? currentAlert;
  final VoidCallback? onDismiss;

  const AlertOverlay({Key? key, this.currentAlert, this.onDismiss})
    : super(key: key);

  @override
  State<AlertOverlay> createState() => _AlertOverlayState();
}

class _AlertOverlayState extends State<AlertOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
  }

  @override
  void didUpdateWidget(AlertOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentAlert != null && oldWidget.currentAlert == null) {
      _controller.forward(from: 0);
    } else if (widget.currentAlert == null && oldWidget.currentAlert != null) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentAlert == null) {
      return const SizedBox.shrink();
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              widget.currentAlert!.color?.withOpacity(0.95) ??
              const Color(0xFF8BC34A).withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (widget.currentAlert!.icon != null)
              Icon(widget.currentAlert!.icon, size: 32, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.currentAlert!.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: widget.onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
