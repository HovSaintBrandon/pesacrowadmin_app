import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/platform_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils.dart';
import '../../core/notifications.dart';
import '../../models/go_live_request.dart';
import 'package:intl/intl.dart';

class GoLiveQueuePage extends StatefulWidget {
  const GoLiveQueuePage({super.key});

  @override
  State<GoLiveQueuePage> createState() => _GoLiveQueuePageState();
}

class _GoLiveQueuePageState extends State<GoLiveQueuePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlatformProvider>().fetchGoLiveRequests();
    });
  }

  void _showRejectDialog(String id) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Reject Go-Live Request'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'e.g. Invalid webhook URL',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                AppNotifications.showError(context, 'Please provide a reason');
                return;
              }
              final ok = await context.read<PlatformProvider>().rejectGoLiveRequest(id, reasonController.text);
              Navigator.pop(ctx);
              if (ok) {
                AppNotifications.showSuccess(context, 'Request rejected');
              } else {
                AppNotifications.showError(context, context.read<PlatformProvider>().error ?? 'Failed to reject request');
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlatformProvider>();
    final canManage = context.watch<AuthProvider>().hasPermission('manage_go_live');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Go-Live Queue', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Review and approve production access requests from developers.', style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 24),

          if (provider.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (provider.goLiveRequests.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No active requests found.')))
          else
            _buildList(provider.goLiveRequests, canManage),
        ],
      ),
    );
  }

  Widget _buildList(List<GoLiveRequest> requests, bool canManage) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requests.length,
      itemBuilder: (ctx, i) {
        final req = requests[i];
        return _buildRequestCard(req, canManage);
      },
    );
  }

  Widget _buildRequestCard(GoLiveRequest req, bool canManage) {
    return AppUtils.buildCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req.developerName.isEmpty ? 'Unknown Developer' : req.developerName, 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(req.developerEmail, style: const TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              ),
              _buildStatusTag(req.status),
            ],
          ),
          const Divider(height: 32, color: Color(0xFF1E293B)),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoItem(Icons.phone_rounded, req.developerPhone, 'Phone'),
                        const SizedBox(height: 12),
                        _buildInfoItem(Icons.language_rounded, req.websiteUrl, 'Website', isUrl: true),
                      ],
                    ),
                  ),
                  if (isWide) const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoItem(Icons.calendar_today_rounded, DateFormat('MMM dd, yyyy').format(req.createdAt), 'Submitted'),
                        const SizedBox(height: 12),
                        _buildInfoItem(Icons.webhook_rounded, req.webhookUrl, 'Webhook', isUrl: true),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          if (req.status == 'pending' && canManage) ...[
            const Divider(height: 32, color: Color(0xFF1E293B)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showRejectDialog(req.id),
                  icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
                  label: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _confirmApproval(req),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: const Text('Approve & Go Live'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
          if (req.status == 'rejected' && req.rejectionReason != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rejection Reason: ${req.rejectionReason}',
                      style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label, {bool isUrl = false}) {
    final displayValue = value.isEmpty ? 'N/A' : value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayValue,
                style: TextStyle(
                  fontSize: 13,
                  color: isUrl && value.isNotEmpty ? Colors.blueAccent : const Color(0xFFCBD5E1),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmApproval(GoLiveRequest req) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Approve Request?'),
        content: Text('This will create the platform and email API credentials to ${req.developerName}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final ok = await context.read<PlatformProvider>().approveGoLiveRequest(req.id);
      if (ok) {
        AppNotifications.showSuccess(context, 'Request approved successfully');
      } else {
        AppNotifications.showError(context, context.read<PlatformProvider>().error ?? 'Approval failed');
      }
    }
  }

  Widget _buildStatusTag(String status) {
    Color color = Colors.grey;
    if (status == 'approved') color = Colors.greenAccent;
    if (status == 'rejected') color = Colors.redAccent;
    if (status == 'pending') color = Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
