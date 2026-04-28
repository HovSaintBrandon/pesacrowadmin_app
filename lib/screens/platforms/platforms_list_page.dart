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
    final phoneController = TextEditingController(text: platform.settlementPhone);
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
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Settlement Phone'),
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
                'settlementPhone': phoneController.text,
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
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(Icons.phone, p.phone),
                        const SizedBox(width: 12),
                        _buildInfoChip(Icons.account_balance_wallet_outlined, 'Settlement: ${p.settlementPhone}'),
                      ],
                    ),
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
            children: [
              Text('Webhook: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              Expanded(
                child: Text(
                  p.webhookUrl,
                  style: const TextStyle(fontSize: 12, color: Colors.blueAccent),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canManage) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showEditDialog(p),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () => _confirmRotateKey(p),
                  icon: const Icon(Icons.key, size: 16, color: Colors.orangeAccent),
                  label: const Text('Rotate Key', style: TextStyle(color: Colors.orangeAccent)),
                ),
                IconButton(
                  onPressed: () => _confirmDelete(p),
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                  tooltip: 'Delete Platform',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
      ],
    );
  }
}
