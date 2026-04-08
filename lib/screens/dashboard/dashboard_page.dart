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
          colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10B981), onPrimary: Colors.white, surface: Color(0xFF1E293B)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final dateStr = picked.toIso8601String().substring(0, 10);
      if (isFrom) dash.fetchReports(from: dateStr);
      else dash.fetchReports(to: dateStr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();

    if (dash.isLoading && dash.stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Date Range Controls ─────────────────────────────────────────
          _DateRangeBar(dash: dash, onPickDate: _pickDate),
          const SizedBox(height: 24),

          // ── Top KPI Cards ───────────────────────────────────────────────
          LayoutBuilder(builder: (ctx, c) {
            final cols = c.maxWidth > 900 ? 4 : (c.maxWidth > 600 ? 2 : 1);
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.6,
              children: [
                _KpiCard(
                  title: 'Total Volume',
                  value: AppUtils.formatKSh(dash.totalVolume),
                  icon: Icons.show_chart,
                  color: const Color(0xFF10B981),
                  subtitle: 'All deal values combined',
                ),
                _KpiCard(
                  title: 'Total Earned',
                  value: AppUtils.formatKSh(dash.totalEarned),
                  icon: Icons.account_balance_wallet_outlined,
                  color: const Color(0xFF3B82F6),
                  subtitle: 'Collected platform fees',
                ),
                _KpiCard(
                  title: 'Total Deals',
                  value: '${dash.totalDeals}',
                  icon: Icons.receipt_long_outlined,
                  color: const Color(0xFF8B5CF6),
                  subtitle: 'Across all statuses',
                ),
                _KpiCard(
                  title: 'Disputes',
                  value: '${dash.disputedDeals}',
                  icon: Icons.gavel_outlined,
                  color: const Color(0xFFEF4444),
                  subtitle: 'Open dispute cases',
                ),
              ],
            );
          }),
          const SizedBox(height: 24),

          // ── Volume Breakdown ────────────────────────────────────────────
          AppUtils.buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(icon: Icons.bar_chart, title: 'Volume Breakdown'),
                const SizedBox(height: 16),
                LayoutBuilder(builder: (ctx, c) {
                  final wrap = c.maxWidth < 600;
                  final items = [
                    _VolumeItem('Total Volume', dash.totalVolume, const Color(0xFF10B981)),
                    _VolumeItem('Paid Volume', (_data(dash)['paidVolume'] ?? 0).toDouble(), const Color(0xFF3B82F6)),
                    _VolumeItem('Pending Volume', (_data(dash)['pendingVolume'] ?? 0).toDouble(), const Color(0xFFF59E0B)),
                  ];
                  if (wrap) {
                    return Column(children: items.expand((i) => [i, const SizedBox(height: 12)]).toList()..removeLast());
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: items,
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Fee Revenue Breakdown ───────────────────────────────────────
          AppUtils.buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(icon: Icons.attach_money, title: 'Fee Revenue Breakdown'),
                const SizedBox(height: 16),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(1.5),
                    3: FlexColumnWidth(1.5),
                  },
                  children: [
                    _tableHeader(['Fee Type', 'Total', 'Paid', 'Pending']),
                    _feeRow(dash, 'Transaction Fees', 'transactionFees', 'paidTransactionFees', 'pendingTransactionFees', const Color(0xFF10B981)),
                    _feeRow(dash, 'Release Fees', 'releaseFees', 'paidReleaseFees', 'pendingReleaseFees', const Color(0xFF3B82F6)),
                    _feeRow(dash, 'Holding Fees', 'holdingFees', 'paidHoldingFees', 'expectedHoldingFees', const Color(0xFFF59E0B)),
                  ],
                ),
                const Divider(height: 24, color: Color(0xFF1E3A5F)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _earningsChip('Currently Earned', (_data(dash)['currentlyEarned'] ?? 0).toDouble(), const Color(0xFF10B981)),
                    _earningsChip('Expected Earnings', (_data(dash)['expectedEarnings'] ?? 0).toDouble(), const Color(0xFFF59E0B)),
                    _earningsChip('Total Earned', (_data(dash)['totalEarned'] ?? 0).toDouble(), const Color(0xFF3B82F6)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Deal Status Grid ────────────────────────────────────────────
          AppUtils.buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(icon: Icons.donut_large_outlined, title: 'Deal Status Distribution'),
                const SizedBox(height: 16),
                LayoutBuilder(builder: (ctx, c) {
                  final cols = c.maxWidth > 900 ? 6 : (c.maxWidth > 600 ? 3 : 2);
                  return GridView.count(
                    crossAxisCount: cols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _StatusCountCard('Active', dash.activeDeals, const Color(0xFF3B82F6)),
                      _StatusCountCard('Pending', dash.pendingDeals, const Color(0xFFF59E0B)),
                      _StatusCountCard('Completed', dash.completedDeals, const Color(0xFF10B981)),
                      _StatusCountCard('Refunded', (_data(dash)['refundedCount'] ?? 0), const Color(0xFF8B5CF6)),
                      _StatusCountCard('Cancelled', (_data(dash)['cancelledCount'] ?? 0), const Color(0xFF64748B)),
                      _StatusCountCard('Disputes', dash.disputedDeals, const Color(0xFFEF4444)),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _data(DashboardProvider dash) => dash.stats?['data'] ?? dash.stats ?? {};

  TableRow _tableHeader(List<String> labels) {
    return TableRow(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF1E3A5F)))),
      children: labels.map((l) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(l, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.5)),
      )).toList(),
    );
  }

  TableRow _feeRow(DashboardProvider dash, String label, String totalKey, String paidKey, String pendingKey, Color color) {
    final data = _data(dash);
    final total = (data[totalKey] ?? 0).toDouble();
    final paid = (data[paidKey] ?? 0).toDouble();
    final pending = (data[pendingKey] ?? 0).toDouble();
    return TableRow(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ),
      Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(AppUtils.formatKSh(total), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))),
      Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(AppUtils.formatKSh(paid), style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)))),
      Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(AppUtils.formatKSh(pending), style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)))),
    ]);
  }

  Widget _earningsChip(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        Text(AppUtils.formatKSh(value), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _DateRangeBar extends StatelessWidget {
  final DashboardProvider dash;
  final Function(bool) onPickDate;
  const _DateRangeBar({required this.dash, required this.onPickDate});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _dateBtn('From: ${dash.fromDate}', () => onPickDate(true)),
        _dateBtn('To: ${dash.toDate}', () => onPickDate(false)),
        _presetChip('Last 24h', () {
          final now = DateTime.now();
          dash.fetchReports(
            from: now.subtract(const Duration(hours: 24)).toIso8601String().substring(0, 10),
            to: now.toIso8601String().substring(0, 10),
          );
        }),
        _presetChip('Last 7d', () {
          final now = DateTime.now();
          dash.fetchReports(
            from: now.subtract(const Duration(days: 7)).toIso8601String().substring(0, 10),
            to: now.toIso8601String().substring(0, 10),
          );
        }),
        _presetChip('Last 30d', () {
          final now = DateTime.now();
          dash.fetchReports(
            from: now.subtract(const Duration(days: 30)).toIso8601String().substring(0, 10),
            to: now.toIso8601String().substring(0, 10),
          );
        }),
        _presetChip('This Year', () {
          final now = DateTime.now();
          dash.fetchReports(
            from: '${now.year}-01-01',
            to: '${now.year}-12-31',
          );
        }),
        if (dash.isLoading)
          const SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
          ),
      ],
    );
  }

  Widget _dateBtn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.calendar_today, size: 13, color: Color(0xFF10B981)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ]),
      ),
    );
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
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: const Color(0xFF10B981)),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
    ]);
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  const _KpiCard({required this.title, required this.value, required this.icon, required this.color, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return AppUtils.buildCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
          ]),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(subtitle, style: const TextStyle(color: Color(0xFF475569), fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

class _VolumeItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _VolumeItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ]),
        const SizedBox(height: 4),
        Text(AppUtils.formatKSh(value), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _StatusCountCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatusCountCard(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}
