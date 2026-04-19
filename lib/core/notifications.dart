import 'dart:async';
import 'package:flutter/material.dart';
import 'theme.dart';

class AppNotifications {
  static OverlayEntry? _currentEntry;

  static void _show(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
    Color iconColor,
  ) {
    if (_currentEntry != null && _currentEntry!.mounted) {
      _currentEntry!.remove();
    }
    _currentEntry = null;

    final overlayState = Overlay.of(context);
    if (overlayState == null) return;

    final entry = OverlayEntry(
      builder: (context) => _NotificationWidget(
        message: message,
        backgroundColor: backgroundColor,
        icon: icon,
        iconColor: iconColor,
        onDismissed: () {
          if (_currentEntry != null && _currentEntry!.mounted) {
            _currentEntry!.remove();
          }
          _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, AppTheme.card, Icons.check_circle, AppTheme.primary);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, AppTheme.danger, Icons.error_outline, Colors.white);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, AppTheme.card, Icons.info_outline, AppTheme.info);
  }
}

class _NotificationWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onDismissed;

  const _NotificationWidget({
    Key? key,
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.onDismissed,
  }) : super(key: key);

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    _timer = Timer(const Duration(seconds: 3), () {
      close();
    });
  }

  void close() {
    if (mounted && _controller.status != AnimationStatus.reverse) {
      _timer?.cancel();
      _controller.reverse().then((_) {
        if (mounted) {
          widget.onDismissed();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: widget.backgroundColor == AppTheme.card 
                  ? Border.all(color: AppTheme.border) 
                  : null,
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: widget.iconColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: close,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.close, color: Colors.white60, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
