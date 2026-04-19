import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/financials_provider.dart';
import '../../core/utils.dart';

class FinancialsPage extends StatefulWidget {
  const FinancialsPage({super.key});

  @override
  State<FinancialsPage> createState() => _FinancialsPageState();
}

class _FinancialsPageState extends State<FinancialsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinancialsProvider>().fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final financialsProvider = context.watch<FinancialsProvider>();
    final stats = financialsProvider.stats;

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
                  Text('Financial Analytics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Monitor platform revenue and realized assets.', style: TextStyle(color: Color(0xFF64748B))),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => financialsProvider.fetchStats(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 32),

          if (financialsProvider.isLoading && stats == null)
            const Center(child: CircularProgressIndicator())
          else if (stats != null) ...[
            // KPI Grid
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              shrinkWrap: true,
              childAspectRatio: 2.5,
              children: [
                _buildFinanceCard('Total Fees Earned', stats.totalFees, Icons.account_balance_wallet_outlined, const Color(0xFF10B981)),
                _buildFinanceCard('Realized Revenue', stats.realizedRevenue, Icons.done_all_outlined, const Color(0xFF3B82F6)),
                _buildFinanceCard('Withdrawable Balance', stats.withdrawableBalance, Icons.file_download_outlined, const Color(0xFF8B5CF6)),
              ],
            ),
            const SizedBox(height: 32),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: AppUtils.buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Revenue Integrity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        _buildDetailRow('Held Fees (Pending)', stats.pendingFees),
                        const Divider(height: 32, color: Color(0xFF1E3A5F)),
                        _buildDetailRow('Total Expected', stats.totalFees + stats.pendingFees),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Color(0xFF10B981), size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Realized revenue only includes fees from deals that have been successfully released or completed.',
                                  style: TextStyle(fontSize: 13, color: Color(0xFFE2E8F0)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Placeholder for Chart or additional data
                Expanded(
                  flex: 1,
                  child: AppUtils.buildCard(
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 40),
                        Icon(Icons.pie_chart_outline, size: 64, color: Color(0xFF1E3A5F)),
                        SizedBox(height: 20),
                        Text('Historical Trends', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Chart visualization coming soon', style: TextStyle(color: Color(0xFF64748B))),
                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinanceCard(String label, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A5F)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
              Text(
                'KES ${AppUtils.formatCurrency(value)}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8))),
        Text('KES ${AppUtils.formatCurrency(value)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
