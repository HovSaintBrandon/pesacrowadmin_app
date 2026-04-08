import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/utils.dart';
import '../../providers/deal_provider.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});
  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _search = '';
  String _statusFilter = 'all';
  String _fromDate = '';
  String _toDate = '';

  final _searchCtrl = TextEditingController();

  final List<String> _statuses = [
    'pending_payment', 'held', 'delivered', 'approved',
    'released', 'disputed', 'refunded', 'cancelled', 'failed',
  ];

  @override
  void initState() {
    super.initState();
    print('📱 Entering TransactionsPage');
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDeals());
  }

  void _loadDeals({int page = 1}) {
    context.read<DealProvider>().fetchDeals(
      status: _statusFilter == 'all' ? null : _statusFilter,
      search: _search.isEmpty ? null : _search,
      fromDate: _fromDate.isEmpty ? null : _fromDate,
      toDate: _toDate.isEmpty ? null : _toDate,
      page: page,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dealProvider = context.watch<DealProvider>();
    final deals = dealProvider.deals;

    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Filters row
          Wrap(spacing: 8, runSpacing: 8, children: [
            SizedBox(
              width: 260,
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search ID, phone, description…',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _search = '');
                            _loadDeals();
                          })
                      : null,
                ),
                onSubmitted: (v) {
                  setState(() => _search = v);
                  _loadDeals();
                },
              ),
            ),
            _filterDropdown(),
            _dateChip('From', _fromDate, (d) { setState(() => _fromDate = d); _loadDeals(); }),
            _dateChip('To', _toDate, (d) { setState(() => _toDate = d); _loadDeals(); }),
            ElevatedButton.icon(
              onPressed: () {
                setState(() { _search = ''; _statusFilter = 'all'; _fromDate = ''; _toDate = ''; });
                _searchCtrl.clear();
                _loadDeals();
              },
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              border: Border(bottom: BorderSide(color: Color(0xFF1E3A5F))),
            ),
            child: const Row(children: [
              Expanded(flex: 2, child: Text('TRANSACTION ID',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.5))),
              Expanded(flex: 2, child: Text('DESCRIPTION',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.5))),
              Expanded(flex: 1, child: Text('AMOUNT',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.5))),
              Expanded(flex: 1, child: Text('DATE',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.5))),
              Expanded(flex: 1, child: Text('STATUS',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B), letterSpacing: 0.5))),
            ]),
          ),

          // Table body
          Expanded(
            child: dealProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : deals.isEmpty
                    ? _empty(dealProvider.error)
                    : AppUtils.buildCard(
                        padding: EdgeInsets.zero,
                        child: ListView.builder(
                          itemCount: deals.length,
                          itemBuilder: (ctx, i) {
                            final d = deals[i];
                            final isSelected = dealProvider.selectedDeal?.transactionId == d.transactionId;
                            return InkWell(
                              onTap: () => dealProvider.selectDeal(isSelected ? null : d),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF10B981).withOpacity(0.05) : null,
                                  border: const Border(bottom: BorderSide(color: Color(0xFF1E3A5F))),
                                ),
                                child: Row(children: [
                                  Expanded(flex: 2, child: Text(d.transactionId,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                                  Expanded(flex: 2, child: Text(d.description,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)))),
                                  Expanded(flex: 1, child: Text(AppUtils.formatKSh(d.amount),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13))),
                                  Expanded(flex: 1, child: Text(DateFormat('MMM d').format(d.createdAt),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                                  Expanded(flex: 1, child: Center(child: AppUtils.buildStatusBadge(d.status))),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
          ),

          // Pagination
          if (!dealProvider.isLoading && deals.isNotEmpty)
            _pagination(dealProvider),
        ]),
      ),

      // Detail panel
      if (dealProvider.selectedDeal != null) ...[
        const SizedBox(width: 16),
        SizedBox(
          width: 360,
          child: AppUtils.buildCard(
            child: _DetailPanel(dealProvider: dealProvider),
          ),
        ),
      ],
    ]);
  }

  Widget _filterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF1E3A5F)),
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF0F172A),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statusFilter,
          dropdownColor: const Color(0xFF141E33),
          style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13),
          items: ['all', ..._statuses].map((s) => DropdownMenuItem(
            value: s,
            child: Text(s == 'all' ? 'All Statuses' : s.replaceAll('_', ' ')),
          )).toList(),
          onChanged: (v) {
            setState(() => _statusFilter = v ?? 'all');
            _loadDeals();
          },
        ),
      ),
    );
  }

  Widget _dateChip(String label, String value, void Function(String) onPick) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value.isNotEmpty ? DateTime.tryParse(value) ?? DateTime.now() : DateTime.now(),
          firstDate: DateTime(2023),
          lastDate: DateTime(2028),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: const Color(0xFF10B981))),
            child: child!,
          ),
        );
        if (picked != null) onPick(picked.toIso8601String().substring(0, 10));
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: value.isNotEmpty
              ? const Color(0xFF10B981)
              : const Color(0xFF1E3A5F)),
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF0F172A),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calendar_today, size: 14,
              color: value.isNotEmpty ? const Color(0xFF10B981) : const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(value.isEmpty ? label : value,
              style: TextStyle(
                fontSize: 13,
                color: value.isNotEmpty ? const Color(0xFF10B981) : const Color(0xFF64748B),
              )),
        ]),
      ),
    );
  }

  Widget _empty(String? error) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(error != null ? Icons.cloud_off : Icons.receipt_long,
            size: 48, color: const Color(0xFF64748B)),
        const SizedBox(height: 12),
        Text(error ?? 'No transactions found',
            style: const TextStyle(color: Color(0xFF94A3B8))),
        if (error != null) ...[
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loadDeals, child: const Text('Retry')),
        ],
      ]),
    );
  }

  Widget _pagination(DealProvider p) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        Text('Page ${p.currentPage} of ${p.totalPages} · ${p.totalCount} total',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: p.currentPage > 1
              ? () => _loadDeals(page: p.currentPage - 1)
              : null,
          iconSize: 20,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: p.currentPage < p.totalPages
              ? () => _loadDeals(page: p.currentPage + 1)
              : null,
          iconSize: 20,
        ),
      ]),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  final DealProvider dealProvider;
  const _DetailPanel({required this.dealProvider});

  @override
  Widget build(BuildContext context) {
    final d = dealProvider.selectedDeal!;
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(d.transactionId,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => dealProvider.selectDeal(null),
          ),
        ]),
        const SizedBox(height: 8),
        AppUtils.buildStatusBadge(d.status),
        const SizedBox(height: 20),
        _row('Description', d.description),
        _row('Amount', AppUtils.formatKSh(d.amount)),
        _row('Transaction Fee', AppUtils.formatKSh(d.transactionFee)),
        _row('Release Fee', AppUtils.formatKSh(d.releaseFee)),
        _row('Seller', AppUtils.formatPhone(d.sellerPhone)),
        _row('Buyer', AppUtils.formatPhone(d.buyerPhone)),
        if (d.mpesaReceipt != null) _row('M-Pesa Receipt', d.mpesaReceipt!),
        if (d.disputeReason != null) ...[
          const SizedBox(height: 12),
          const Text('Dispute Reason', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          const SizedBox(height: 4),
          Text(d.disputeReason!,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
        ],
        const SizedBox(height: 20),
        const Text('Status History',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        ...d.statusHistory.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: AppUtils.getStatusColor(e['status'] ?? ''),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text((e['status'] ?? '').replaceAll('_', ' '),
                style: const TextStyle(fontSize: 13)),
            const Spacer(),
            Text(
              e['timestamp'] != null
                  ? DateFormat('MMM d, HH:mm').format(DateTime.parse(e['timestamp']!))
                  : '',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ]),
        )),
        const SizedBox(height: 16),
        // Action buttons
        if (['failed', 'approved'].contains(d.status))
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final ok = await dealProvider.retryPayout(d.transactionId);
                AppUtils.showSnackBar(context,
                    ok ? 'Payout retry initiated' : 'Retry failed', isError: !ok);
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry Payout'),
            ),
          ),
        if (['held', 'delivered'].contains(d.status)) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showReversalDialog(context, d.transactionId),
              icon: const Icon(Icons.undo, size: 16, color: Color(0xFFEF4444)),
              label: const Text('Trigger Reversal',
                  style: TextStyle(color: Color(0xFFEF4444))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
        if (['pending_payment', 'held'].contains(d.status)) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCancelDialog(context, d.transactionId),
              icon: const Icon(Icons.cancel, size: 16, color: Color(0xFFFACC15)),
              label: const Text('Cancel Deal',
                  style: TextStyle(color: Color(0xFFFACC15))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFACC15)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        Flexible(child: Text(value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  void _showReversalDialog(BuildContext context, String txId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Trigger M-Pesa Reversal'),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: ctrl,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Remarks / reason…'),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await dealProvider.triggerReversal(txId, ctrl.text);
              AppUtils.showSnackBar(context,
                  ok ? 'Reversal initiated' : 'Reversal failed', isError: !ok);
            },
            child: const Text('Confirm Reversal'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String txId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Cancel Deal'),
        content: const Text('Are you sure you want to cancel this deal? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No, Keep')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await dealProvider.cancelDeal(txId);
              AppUtils.showSnackBar(context,
                  ok ? 'Deal cancelled successfully' : 'Failed to cancel deal', isError: !ok);
              if (ok) {
                dealProvider.selectDeal(null);
              }
            },
            child: const Text('Yes, Cancel Deal'),
          ),
        ],
      ),
    );
  }
}
