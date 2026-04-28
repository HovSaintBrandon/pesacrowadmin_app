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

          AppUtils.buildCard(
            child: provider.isLoading
                ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                : provider.goLiveRequests.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No pending requests found.')))
                    : _buildTable(provider.goLiveRequests, canManage),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<GoLiveRequest> requests, bool canManage) {
    return DataTable(
      columnSpacing: 24,
      columns: const [
        DataColumn(label: Text('Developer')),
        DataColumn(label: Text('Contact')),
        DataColumn(label: Text('Website / Webhook')),
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Actions')),
      ],
      rows: requests.map((req) {
        return DataRow(cells: [
          DataCell(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(req.developerName, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(req.developerEmail, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          )),
          DataCell(Text(req.developerPhone)),
          DataCell(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(req.websiteUrl, style: const TextStyle(fontSize: 12, color: Colors.blueAccent), overflow: TextOverflow.ellipsis),
              Text(req.webhookUrl, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
            ],
          )),
          DataCell(Text(DateFormat('MMM dd, yyyy').format(req.createdAt))),
          DataCell(_buildStatusTag(req.status)),
          DataCell(
            req.status == 'pending' && canManage
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Approve Request?'),
                              content: Text('This will create the platform and email API credentials to ${req.developerName}.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Approve')),
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
                        },
                        tooltip: 'Approve',
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.redAccent),
                        onPressed: () => _showRejectDialog(req.id),
                        tooltip: 'Reject',
                      ),
                    ],
                  )
                : const Text('-'),
          ),
        ]);
      }).toList(),
    );
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
