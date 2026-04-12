import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/mpesa_provider.dart';
import '../../core/utils.dart';
import '../../models/mpesa_balance_snapshot.dart';
import '../../models/mpesa_balance.dart';

class OrgBalancesPage extends StatefulWidget {
  const OrgBalancesPage({super.key});

  @override
  State<OrgBalancesPage> createState() => _OrgBalancesPageState();
}

class _OrgBalancesPageState extends State<OrgBalancesPage> {
  String _selectedAccountForChart = '';
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final provider = context.read<MpesaProvider>();
    await provider.queryBalance('Manual refresh from Org Balances');
    if (!mounted) return;
    setState(() {
      _lastUpdated = DateTime.now();
      if (provider.balances.isNotEmpty) {
        if (_selectedAccountForChart.isEmpty || !provider.balances.any((b) => b.accountType == _selectedAccountForChart)) {
          _selectedAccountForChart = provider.balances.first.accountType;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mpesa = context.watch<MpesaProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(mpesa),
              const SizedBox(height: 32),
              _buildCurrentBalances(mpesa),
              const SizedBox(height: 32),
              if (mpesa.history.isNotEmpty) ...[
                _buildHistoryChart(mpesa.history),
                const SizedBox(height: 32),
                _buildHistoryTable(mpesa.history),
              ] else if (mpesa.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                _buildEmptyState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(MpesaProvider mpesa) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Organization Balances',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Real-time monitoring of M-Pesa business accounts',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
            ),
            if (_lastUpdated != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last updated: ${DateFormat('HH:mm:ss').format(_lastUpdated!)}',
                style: TextStyle(color: const Color(0xFF10B981).withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
        Row(
          children: [
            if (mpesa.isLoading)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ElevatedButton.icon(
              onPressed: mpesa.isLoading ? null : _refreshData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentBalances(MpesaProvider mpesa) {
    final balances = mpesa.balances;
    if (balances.isEmpty && !mpesa.isLoading) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 800 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 2.8,
          ),
          itemCount: balances.isEmpty ? 3 : balances.length,
          itemBuilder: (context, index) {
            if (balances.isEmpty) return _buildBalanceShimmer();
            final balance = balances[index];
            return _buildBalanceCard(balance);
          },
        );
      },
    );
  }

  Widget _buildBalanceCard(MpesaBalance balance) {
    final name = balance.accountType.toLowerCase();
    
    IconData icon = Icons.account_balance_wallet;
    Color color = const Color(0xFF3B82F6); // Default blue

    if (name.contains('working')) {
      icon = Icons.account_balance;
      color = const Color(0xFF10B981); // Green
    } else if (name.contains('utility')) {
      icon = Icons.account_tree;
      color = const Color(0xFFF59E0B); // Amber
    } else if (name.contains('charges')) {
      icon = Icons.payments;
      color = const Color(0xFFEC4899); // Pink
    } else if (name.contains('merchant')) {
      icon = Icons.storefront;
      color = const Color(0xFF8B5CF6); // Purple
    } else if (name.contains('settlement')) {
      icon = Icons.handshake;
      color = const Color(0xFF14B8A6); // Teal
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  balance.accountType.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${balance.currency} ${NumberFormat('#,###.00').format(balance.amount)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceShimmer() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildHistoryChart(List<MpesaBalanceSnapshot> history) {
    if (history.isEmpty) return const SizedBox.shrink();

    // Prepare data points for selected account
    final List<FlSpot> spots = [];
    final reversedHistory = history.reversed.toList();
    
    // Ensure we have a valid selection
    final effectiveSelection = _selectedAccountForChart.isEmpty && history.isNotEmpty && history.first.balances.isNotEmpty 
        ? history.first.balances.first.accountType 
        : _selectedAccountForChart;

    if (effectiveSelection.isEmpty) return const SizedBox.shrink();

    for (int i = 0; i < reversedHistory.length; i++) {
      final snapshot = reversedHistory[i];
      final balance = snapshot.balances.firstWhere(
        (b) => b.accountType == effectiveSelection,
        orElse: () => MpesaBalance(accountType: effectiveSelection, amount: 0, currency: 'KES'),
      );
      spots.add(FlSpot(i.toDouble(), balance.amount));
    }

    return Container(
      height: 400,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Balance Trend',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  if (history.isNotEmpty && _selectedAccountForChart.isNotEmpty)
                    DropdownButton<String>(
                      value: _selectedAccountForChart,
                      dropdownColor: const Color(0xFF1E293B),
                      underline: const SizedBox(),
                      style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedAccountForChart = newValue;
                          });
                        }
                      },
                      items: history.first.balances.map<DropdownMenuItem<String>>((MpesaBalance b) {
                        return DropdownMenuItem<String>(
                          value: b.accountType,
                          child: Text(b.accountType),
                        );
                      }).toList(),
                    ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Last 20 Snapshots',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF10B981),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF10B981).withOpacity(0.3),
                          const Color(0xFF10B981).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTable(List<MpesaBalanceSnapshot> history) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Balance History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                ),
                children: const [
                  Padding(padding: EdgeInsets.all(16), child: Text('TIMESTAMP', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(16), child: Text('WORKING ACCOUNT', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(16), child: Text('UTILITY ACCOUNT', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(16), child: Text('STATUS', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold))),
                ],
              ),
              ...history.map((snapshot) {
                return TableRow(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        DateFormat('MMM dd, yyyy HH:mm:ss').format(snapshot.timestamp),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    ...snapshot.balances.take(2).map((b) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (b.accountType ?? 'Unknown').toUpperCase(),
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                          ),
                          Text(
                            '${b.currency ?? 'KES'} ${NumberFormat('#,###.00').format(b.amount ?? 0)}',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )).toList(),
                    // Fallback for snapshots with fewer than 2 accounts
                    if (snapshot.balances.length < 2) 
                      ...List.generate(
                        (2 - snapshot.balances.length).clamp(0, 2), 
                        (_) => const Padding(padding: EdgeInsets.all(16), child: Text('-'))
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Captured',
                          style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.history_toggle_off, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'No balance history found',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => context.read<MpesaProvider>().fetchLatestBalance(),
            child: const Text('Fetch Initial Data'),
          ),
        ],
      ),
    );
  }
}
