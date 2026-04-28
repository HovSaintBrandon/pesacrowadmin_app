import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'notifications.dart';

class AppUtils {
  static String formatKSh(double amount) =>
      'KSh ${NumberFormat('#,###').format(amount.round())}';

  static String formatCurrency(double amount) =>
      NumberFormat('#,###.##').format(amount);

  static String formatDateTime(DateTime dateTime) =>
      DateFormat('MMM d, yyyy HH:mm').format(dateTime);

  static String formatPhone(String phone) {
    if (phone.startsWith('254')) return '+$phone';
    if (phone.startsWith('0')) return '+254${phone.substring(1)}';
    return phone;
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case 'released':
      case 'approved':
        return const Color(0xFF10B981);
      case 'held':
      case 'pending_payment':
        return const Color(0xFFF59E0B);
      case 'delivered':
        return const Color(0xFF3B82F6);
      case 'disputed':
      case 'failed':
        return const Color(0xFFEF4444);
      case 'refunded':
        return const Color(0xFF8B5CF6);
      case 'cancelled':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF64748B);
    }
  }

  static Widget buildStatusBadge(String status) {
    final color = getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    if (isError) {
      AppNotifications.showError(context, message);
    } else {
      AppNotifications.showSuccess(context, message);
    }
  }

  static Widget buildCard({required Widget child, EdgeInsets? padding, EdgeInsets? margin}) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141E33),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      child: child,
    );
  }
}
