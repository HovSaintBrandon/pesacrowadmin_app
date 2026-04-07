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
    print('📱 Entering DashboardPage');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();

    if (dash.isLoading && dash.stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dash.error != null && dash.stats == null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off, size: 48, color: Color(0xFF64748B)),
          const SizedBox(height: 16),
          Text(dash.error!, style: const TextStyle(color: Color(0xFF94A3B8))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => dash.fetchReports(),
            child: const Text('Retry'),
          ),
        ]),
      );
    }

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Date range row
        Row(children: [
          const Spacer(),
          _DateRangeChip(
            label: 'This Year',
            onTap: () => dash.fetchReports(
              from: '${DateTime.now().year}-01-01',
              to: '${DateTime.now().year}-12-31',
            ),
          ),
          const SizedBox(width: 8),
          _DateRangeChip(
            label: 'Last 30 Days',
            onTap: () {
              final now = DateTime.now();
              final from = now.subtract(const Duration(days: 30));
              dash.fetchReports(
                from: from.toIso8601String().substring(0, 10),
                to: now.toIso8601String().substring(0, 10),
              );
            },
          ),
          if (dash.isLoading) ...[ const SizedBox(width: 12),
            const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ]),
        const SizedBox(height: 16),

        // KPI Cards
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
              _kpiCard('Revenue', AppUtils.formatKSh(dash.totalRevenue),
                  Icons.attach_money, const Color(0xFF3B82F6)),
              _kpiCard('Active Deals', '${dash.activeDeals}',
                  Icons.handshake_outlined, const Color(0xFFF59E0B)),
              _kpiCard('Open Disputes', '${dash.disputedDeals}',
                  Icons.warning_amber_rounded, const Color(0xFFEF4444)),
            ],
          );
        }),
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Deal Status Distribution',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: dash.statusDistribution.entries.map((e) {
                  final color = AppUtils.getStatusColor(e.key);
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
                        style: TextStyle(
                          color: color, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ]),
                  );
                }).toList(),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return AppUtils.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Flexible(child: Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13))),
          ]),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _statusCard(String label, int count, Color color) {
    return AppUtils.buildCard(
      child: Row(children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ]),
      ]),
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
