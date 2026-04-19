import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/system_provider.dart';
import '../../core/utils.dart';
import '../../core/notifications.dart';

class SystemConfigPage extends StatefulWidget {
  const SystemConfigPage({super.key});

  @override
  State<SystemConfigPage> createState() => _SystemConfigPageState();
}

class _SystemConfigPageState extends State<SystemConfigPage> {
  final TextEditingController _webhookController = TextEditingController();
  final TextEditingController _otpPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SystemProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final systemProvider = context.watch<SystemProvider>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('System Configuration', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Manage platform endpoints, security governance, and system health.', style: TextStyle(color: Color(0xFF64748B))),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => systemProvider.fetchAll(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh All'),
              ),
            ],
          ),
          const SizedBox(height: 32),

          if (systemProvider.isLoading && systemProvider.webhookConfig == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            // Webhooks Section
            _buildSectionHeader('Webhook Configuration', Icons.link),
            const SizedBox(height: 16),
            AppUtils.buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Primary Callback URL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _webhookController..text = systemProvider.webhookConfig?.primaryUrl ?? '',
                          decoration: const InputDecoration(hintText: 'https://api.yourdomain.com/webhooks/mpesa'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          final ok = await systemProvider.updateWebhooks({'primaryUrl': _webhookController.text});
                          if (ok) {
                            AppNotifications.showSuccess(context, 'Webhook updated');
                          } else {
                            AppNotifications.showError(context, systemProvider.error ?? 'Failed to update webhook');
                          }
                        },
                        child: const Text('Update'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('B2C Result URL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 8),
                  Text(systemProvider.webhookConfig?.b2cResultUrl ?? 'None configured', style: const TextStyle(color: Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  const Text('B2C Timeout URL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 8),
                  Text(systemProvider.webhookConfig?.b2cTimeoutUrl ?? 'None configured', style: const TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // OTP Section
            _buildSectionHeader('OTP & Governance', Icons.security),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppUtils.buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Administrator Phone (2FA)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _otpPhoneController..text = systemProvider.otpConfig?.adminPhone ?? '',
                                decoration: const InputDecoration(hintText: '2541...'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () async {
                                final ok = await systemProvider.updateOtp({'adminPhone': _otpPhoneController.text});
                                if (ok) {
                                  AppNotifications.showSuccess(context, 'Admin phone updated');
                                } else {
                                  AppNotifications.showError(context, systemProvider.error ?? 'Failed to update phone');
                                }
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('This device receives all manual disbursement OTPs. Ensure it is secure and online.', 
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: AppUtils.buildCard(
                    child: Column(
                      children: [
                        const Text('Device Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
                        const SizedBox(height: 20),
                        _buildStatusRow('Connection', systemProvider.otpConfig?.isOnline == true ? 'ONLINE' : 'OFFLINE', systemProvider.otpConfig?.isOnline == true ? Colors.greenAccent : Colors.redAccent),
                        const SizedBox(height: 16),
                        _buildStatusRow('Battery', '${systemProvider.otpConfig?.batteryStatus ?? "N/A"}%', (systemProvider.otpConfig?.batteryStatus ?? 0) > 20 ? Colors.greenAccent : Colors.orangeAccent),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Health Section
            _buildSectionHeader('System Health Metrics', Icons.monitor_heart),
            const SizedBox(height: 16),
            AppUtils.buildCard(
              child: systemProvider.health == null 
                ? const Center(child: Text('Health metrics not available'))
                : Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildHealthMetric('Status', systemProvider.health!.status.toUpperCase(), 
                              systemProvider.health!.status == 'healthy' ? Colors.greenAccent : Colors.orangeAccent),
                          _buildHealthMetric('Database', systemProvider.health!.dbStatus.toUpperCase(), 
                              systemProvider.health!.dbStatus == 'connected' ? Colors.greenAccent : Colors.redAccent),
                          _buildHealthMetric('Daraja (M-Pesa)', systemProvider.health!.darajaStatus.toUpperCase(), 
                              systemProvider.health!.darajaStatus == 'reachable' ? Colors.greenAccent : Colors.redAccent),
                          _buildHealthMetric('SMS Service', systemProvider.health!.smsConfigured ? 'ON' : 'OFF', 
                              systemProvider.health!.smsConfigured ? Colors.greenAccent : Colors.redAccent),
                        ],
                      ),
                      const Divider(height: 32, color: Color(0xFF1E3A5F)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildHealthMetric('System Uptime', systemProvider.health!.humanUptime, Colors.purpleAccent),
                          _buildHealthMetric('Platform Liquidity', 'KES ${AppUtils.formatCurrency(systemProvider.health!.withdrawableBalance)}', Colors.amberAccent),
                          _buildHealthMetric('Memory (Heap)', '${systemProvider.health!.heapUsedMB.toStringAsFixed(1)} MB', Colors.blueAccent),
                          _buildHealthMetric('Last Checked', 'Just now', const Color(0xFF64748B)),
                        ],
                      ),
                    ],
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF10B981)),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFE2E8F0))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildHealthMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
