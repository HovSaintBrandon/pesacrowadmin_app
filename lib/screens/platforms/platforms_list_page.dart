import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/platform_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils.dart';
import '../../core/notifications.dart';
import '../../models/platform.dart';

class PlatformsListPage extends StatefulWidget {
  const PlatformsListPage({super.key});

  @override
  State<PlatformsListPage> createState() => _PlatformsListPageState();
}

class _PlatformsListPageState extends State<PlatformsListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlatformProvider>().fetchPlatforms();
    });
  }

  void _showEditDialog(Platform platform) {
    final platformPhoneController = TextEditingController(text: platform.phone);
    final settlementPhoneController = TextEditingController(text: platform.settlementPhone);
    final webhookController = TextEditingController(text: platform.webhookUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: Text('Edit Platform: ${platform.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: platformPhoneController,
              decoration: const InputDecoration(labelText: 'Platform Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: settlementPhoneController,
              decoration: const InputDecoration(labelText: 'Settlement Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: webhookController,
              decoration: const InputDecoration(labelText: 'Webhook URL'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final ok = await context.read<PlatformProvider>().updatePlatform(platform.id, {
                'platformPhone': platformPhoneController.text,
                'settlementPhone': settlementPhoneController.text,
                'webhookUrl': webhookController.text,
              });
              Navigator.pop(ctx);
              if (ok) {
                AppNotifications.showSuccess(context, 'Platform updated');
              } else {
                AppNotifications.showError(context, context.read<PlatformProvider>().error ?? 'Update failed');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmRotateKey(Platform platform) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text('Rotate API Key?'),
          ],
        ),
        content: const Text(
          'WARNING: This will immediately invalidate the current API key. The developer\'s integration will break until they update their code with the new key.',
          style: TextStyle(color: Color(0xFFCBD5E1)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () async {
              final ok = await context.read<PlatformProvider>().rotatePlatformKey(platform.id);
              Navigator.pop(ctx);
              if (ok) {
                AppNotifications.showSuccess(context, 'API Key rotated successfully. New key emailed to developer.');
              } else {
                AppNotifications.showError(context, context.read<PlatformProvider>().error ?? 'Rotation failed');
              }
            },
            child: const Text('Rotate Key'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Platform platform) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Delete Platform?'),
        content: Text('Are you sure you want to permanently delete "${platform.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final ok = await context.read<PlatformProvider>().deletePlatform(platform.id);
              Navigator.pop(ctx);
              if (ok) {
                AppNotifications.showSuccess(context, 'Platform deleted');
              } else {
                AppNotifications.showError(context, context.read<PlatformProvider>().error ?? 'Deletion failed');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlatformProvider>();
    final canManage = context.watch<AuthProvider>().hasPermission('manage_platforms');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Active Platforms', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Manage production-ready developer integrations.', style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 24),

          if (provider.isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (provider.platforms.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No active platforms found.')))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.platforms.length,
              itemBuilder: (ctx, i) {
                final p = provider.platforms[i];
                return _buildPlatformCard(p, canManage);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPlatformCard(Platform p, bool canManage) {
    return AppUtils.buildCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: p.isActive ? Colors.greenAccent.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                child: Icon(
                  p.isActive ? Icons.business_rounded : Icons.business_outlined,
                  color: p.isActive ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(p.email, style: const TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              ),
              if (canManage)
                Switch(
                  value: p.isActive,
                  onChanged: (val) async {
                    final ok = await context.read<PlatformProvider>().togglePlatformFreeze(p.id);
                    if (!ok) {
                      AppNotifications.showError(context, context.read<PlatformProvider>().error ?? 'Action failed');
                    }
                  },
                  activeColor: Colors.greenAccent,
                ),
            ],
          ),
          const Divider(height: 32, color: Color(0xFF1E293B)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildDetailItem(Icons.phone_rounded, p.phone, 'Platform Phone')),
              const SizedBox(width: 16),
              Expanded(child: _buildDetailItem(Icons.account_balance_wallet_rounded, p.settlementPhone, 'Settlement Phone')),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailItem(Icons.webhook_rounded, p.webhookUrl, 'Webhook URL', isUrl: true),
          const Divider(height: 32, color: Color(0xFF1E293B)),
          Row(
            children: [
              if (canManage) ...[
                TextButton.icon(
                  onPressed: () => _showEditDialog(p),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Details'),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () => _confirmRotateKey(p),
                  icon: const Icon(Icons.key_outlined, size: 18, color: Colors.orangeAccent),
                  label: const Text('Rotate Key', style: TextStyle(color: Colors.orangeAccent)),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _confirmDelete(p),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  tooltip: 'Delete Platform',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label, {bool isUrl = false}) {
    final displayValue = value.isEmpty ? 'Not Set' : value;
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
}
