import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils.dart';
import '../../providers/dashboard_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchReports();
    });
  }

  void _pickDate(bool isFrom) async {
    final dash = context.read<DashboardProvider>();
    final initial = isFrom ? DateTime.tryParse(dash.fromDate) : DateTime.tryParse(dash.toDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2028),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF10B981), onPrimary: Colors.white, surface: Color(0xFF1E293B)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final dateStr = picked.toIso8601String().substring(0, 10);
      if (isFrom) {
        dash.fetchReports(from: dateStr);
      } else {
        dash.fetchReports(to: dateStr);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();

    if (dash.isLoading && dash.stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Centering requested
        children: [
          // Header with Date Pickers and Presets
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDateButton('From: ${dash.fromDate}', () => _pickDate(true)),
              const SizedBox(width: 8),
              _buildDateButton('To: ${dash.toDate}', () => _pickDate(false)),
              const SizedBox(width: 16),
              _buildPresetButtons(dash),
              if (dash.isLoading) ...[
                const SizedBox(width: 16),
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Primary metrics
          LayoutBuilder(builder: (ctx, constraints) {
            final crossCount = constraints.maxWidth > 800 ? 4 : 2;
            return GridView.count(
              crossAxisCount: crossCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _kpiCard('Total Volume', AppUtils.formatKSh(dash.totalVolume),
                    Icons.trending_up, const Color(0xFF10B981)),
                _kpiCard('Total Earned', AppUtils.formatKSh(dash.totalEarned),
                    Icons.attach_money, const Color(0xFF3B82F6)),
                _kpiCard('Total Deals', '${dash.totalDeals}',
                    Icons.receipt_long, const Color(0xFF8B5CF6)),
                _kpiCard('Disputes', '${dash.disputedDeals}',
                    Icons.warning_amber_rounded, const Color(0xFFEF4444)),
              ],
            );
          }),
          const SizedBox(height: 24),

          // Detailed Fee Breakdown
          AppUtils.buildCard(
            child: Column(children: [
              const Text('Revenue Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _feeItem('Transaction Fees', dash.transactionFees, const Color(0xFF10B981)),
                  _feeItem('Release Fees', dash.releaseFees, const Color(0xFF3B82F6)),
                  _feeItem('Holding Fees', dash.holdingFees, const Color(0xFFF59E0B)),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // Status grid
          LayoutBuilder(builder: (ctx, c) {
            final cols = c.maxWidth > 800 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.8,
              children: [
                _statusCard('Pending', dash.pendingDeals, const Color(0xFFF59E0B)),
                _statusCard('Completed', dash.completedDeals, const Color(0xFF10B981)),
                _statusCard('Disputed', dash.disputedDeals, const Color(0xFFEF4444)),
                _statusCard('Active', dash.activeDeals, const Color(0xFF3B82F6)),
              ],
            );
          }),

          if (dash.statusDistribution.isNotEmpty) ...[
            const SizedBox(height: 24),
            AppUtils.buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Deal Status Distribution',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: dash.statusDistribution.entries.map((e) {
                      final color = AppUtils.getStatusColor(e.key);
                      if (e.value == 0 && e.key != 'active') return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${e.key.replaceAll('_', ' ')}: ${e.value}',
                            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ]),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today, size: 14, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _buildPresetButtons(DashboardProvider dash) {
    return Row(children: [
      _presetChip('Last 24h', () {
        final now = DateTime.now();
        dash.fetchReports(
          from: now.subtract(const Duration(hours: 24)).toIso8601String().substring(0, 10),
          to: now.toIso8601String().substring(0, 10),
        );
      }),
      const SizedBox(width: 8),
      _presetChip('Last 7d', () {
        final now = DateTime.now();
        dash.fetchReports(
          from: now.subtract(const Duration(days: 7)).toIso8601String().substring(0, 10),
          to: now.toIso8601String().substring(0, 10),
        );
      }),
      const SizedBox(width: 8),
      _presetChip('Last 30d', () {
        final now = DateTime.now();
        dash.fetchReports(
          from: now.subtract(const Duration(days: 30)).toIso8601String().substring(0, 10),
          to: now.toIso8601String().substring(0, 10),
        );
      }),
    ]);
  }

  Widget _presetChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: onTap,
      backgroundColor: const Color(0xFF1E293B),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return AppUtils.buildCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _feeItem(String label, double amount, Color color) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
      const SizedBox(height: 4),
      Text(AppUtils.formatKSh(amount), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
    ]);
  }

  Widget _statusCard(String label, int count, Color color) {
    return AppUtils.buildCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          const SizedBox(height: 4),
          Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _DateRangeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateRangeChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF141E33),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF1E3A5F)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
      ),
    );
  }
}
