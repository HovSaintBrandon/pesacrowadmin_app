import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/announcement_provider.dart';
import '../../core/utils.dart';
import '../../core/notifications.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final TextEditingController _messageController = TextEditingController();
  String _selectedTarget = 'all';
  String _selectedVia = 'sms';

  void _sendBroadcast() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      AppNotifications.showError(context, 'Please enter a message');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Confirm Broadcast'),
        content: Text('Are you sure you want to send this message to "$_selectedTarget" via $_selectedVia?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send Message')),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await context.read<AnnouncementProvider>().sendAnnouncement(
        target: _selectedTarget,
        message: message,
        via: _selectedVia,
      );
      if (success) {
        AppNotifications.showSuccess(context, 'Announcement sent successfully');
        _messageController.clear();
      } else {
        AppNotifications.showError(context, 'Failed to send announcement');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnnouncementProvider>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Broadcast Announcements', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Send targeted SMS or In-App alerts to PesaCrow users.', style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 32),

          AppUtils.buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New Announcement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                
                // Target Selection
                const Text('Target Audience', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
                const SizedBox(height: 8),
                _buildRadioRow([
                  {'label': 'All Users', 'value': 'all'},
                  {'label': 'Active Sellers', 'value': 'sellers'},
                  {'label': 'Active Buyers', 'value': 'buyers'},
                ], _selectedTarget, (val) => setState(() => _selectedTarget = val!)),
                
                const SizedBox(height: 24),

                // Channel Selection
                const Text('Delivery Channel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
                const SizedBox(height: 8),
                _buildRadioRow([
                  {'label': 'SMS', 'value': 'sms'},
                  {'label': 'In-App', 'value': 'in_app'},
                ], _selectedVia, (val) => setState(() => _selectedVia = val!)),

                const SizedBox(height: 24),

                // Message Text
                const Text('Message Content', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Type your announcement here...',
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: provider.isSending ? null : _sendBroadcast,
                    child: provider.isSending 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('Send Broadcast'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          // History Placeholder
          const Text('Broadcast History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AppUtils.buildCard(
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Column(
                  children: [
                    Icon(Icons.history, size: 48, color: Color(0xFF1E3A5F)),
                    SizedBox(height: 16),
                    Text('No previous broadcasts recorded.', style: TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioRow(List<Map<String, String>> options, String groupValue, Function(String?) onChanged) {
    return Row(
      children: options.map((opt) => Padding(
        padding: const EdgeInsets.only(right: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<String>(
              value: opt['value']!,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: const Color(0xFF10B981),
            ),
            Text(opt['label']!, style: const TextStyle(fontSize: 14)),
          ],
        ),
      )).toList(),
    );
  }
}
