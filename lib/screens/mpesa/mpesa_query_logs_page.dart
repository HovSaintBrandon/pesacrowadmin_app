import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils.dart';
import '../../providers/mpesa_provider.dart';
import '../../models/mpesa_query_log.dart';

class MpesaQueryLogsPage extends StatefulWidget {
  const MpesaQueryLogsPage({super.key});

  @override
  State<MpesaQueryLogsPage> createState() => _MpesaQueryLogsPageState();
}

class _MpesaQueryLogsPageState extends State<MpesaQueryLogsPage> {
  int _currentPage = 1;
  final int _limit = 50;
  final _searchCtrl = TextEditingController();
  final _receiptCtrl = TextEditingController();
  final _statusIdentifierCtrl = TextEditingController();
  bool _isConversationId = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLogs();
    });
  }

  void _loadLogs() {
    context.read<MpesaProvider>().fetchQueryLogs(
      page: _currentPage,
      limit: _limit,
      identifier: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _receiptCtrl.dispose();
    _statusIdentifierCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mpesa = context.watch<MpesaProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('M-Pesa Transaction Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('View and trigger status queries for M-Pesa transactions.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _showTriggerQueryModal(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Trigger New Query'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Filters
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Filter by Identifier (Receipt or ConversationID)...',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
                onSubmitted: (_) {
                  setState(() => _currentPage = 1);
                  _loadLogs();
                },
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                setState(() => _currentPage = 1);
                _loadLogs();
              },
              child: const Text('Filter'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _currentPage = 1);
                _loadLogs();
              },
              child: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Logs Table
        Expanded(
          child: AppUtils.buildCard(
            padding: EdgeInsets.zero,
            child: mpesa.isLoading && mpesa.queryLogs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : mpesa.queryLogs.isEmpty
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Text('No query logs found.'),
                      ))
                    : Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SingleChildScrollView(
                                child: DataTable(
                                  columnSpacing: 24,
                                  columns: const [
                                    DataColumn(label: Text('Receipt')),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(label: Text('Results')),
                                    DataColumn(label: Text('Conversation ID')),
                                    DataColumn(label: Text('Date')),
                                    DataColumn(label: Text('Actions')),
                                  ],
                                  rows: mpesa.queryLogs.map((log) => DataRow(
                                    cells: [
                                      DataCell(Text(log.receipt ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500))),
                                      DataCell(_statusBadge(log.status ?? 'Pending')),
                                      DataCell(SizedBox(
                                        width: 200,
                                        child: Text(log.resultDesc ?? '-', 
                                          maxLines: 1, 
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      )),
                                      DataCell(Text(log.conversationId ?? '-', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                                      DataCell(Text(AppUtils.formatDateTime(log.createdAt), style: const TextStyle(fontSize: 12))),
                                      DataCell(IconButton(
                                        icon: const Icon(Icons.code, size: 18),
                                        onPressed: () => _showRawResponse(context, log),
                                        tooltip: 'View Raw Response',
                                      )),
                                    ],
                                  )).toList(),
                                ),
                              ),
                            ),
                          ),
                          _pagination(mpesa.totalLogs),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        color = const Color(0xFF10B981);
        break;
      case 'failed':
      case 'error':
        color = const Color(0xFFEF4444);
        break;
      default:
        color = const Color(0xFFF59E0B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _pagination(int total) {
    final maxPages = (total / _limit).ceil();
    if (maxPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1E3A5F))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Showing ${(_currentPage - 1) * _limit + 1} to ${(_currentPage * _limit).clamp(0, total)} of $total items',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1 ? () {
                  setState(() => _currentPage--);
                  _loadLogs();
                } : null,
              ),
              Text('$_currentPage / $maxPages', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < maxPages ? () {
                  setState(() => _currentPage++);
                  _loadLogs();
                } : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRawResponse(BuildContext context, MpesaQueryLog log) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Raw M-Pesa Response'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                const JsonEncoder.withIndent('  ').convert(log.rawResponse ?? {'message': 'No raw data available'}),
                style: const TextStyle(color: Color(0xFF10B981), fontSize: 13, fontFamily: 'monospace'),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showTriggerQueryModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final mpesa = context.watch<MpesaProvider>();
          return AlertDialog(
            title: const Text('Trigger M-Pesa Status Query'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Choose a method to query Safaricom for transaction status.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                const SizedBox(height: 20),
                
                // Method 1: Specific Receipt (GET)
                AppUtils.buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Query by Receipt No.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _receiptCtrl,
                        decoration: const InputDecoration(hintText: 'e.g. RDR34567GH'),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: mpesa.isLoading ? null : () async {
                            if (_receiptCtrl.text.isEmpty) return;
                            final ok = await context.read<MpesaProvider>().queryByReceipt(_receiptCtrl.text);
                            if (mounted) {
                               AppUtils.showSnackBar(context, ok ? 'Query sent successfully' : 'Query failed', isError: !ok);
                               if (ok) Navigator.pop(ctx);
                            }
                          },
                          child: const Text('Query Receipt'),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('OR', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))), Expanded(child: Divider())]),
                const SizedBox(height: 16),

                // Method 2: Generic Status Query (POST)
                AppUtils.buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Trigger Status Query', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _statusIdentifierCtrl,
                        decoration: const InputDecoration(hintText: 'Receipt or ConversationID'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Switch(
                            value: _isConversationId,
                            onChanged: (v) => setModalState(() => _isConversationId = v),
                            activeColor: const Color(0xFF10B981),
                          ),
                          const Text('Is ConversationID?', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: mpesa.isLoading ? null : () async {
                            if (_statusIdentifierCtrl.text.isEmpty) return;
                            final ok = await context.read<MpesaProvider>().queryTransactionStatus(
                                _statusIdentifierCtrl.text, isConversationId: _isConversationId);
                            if (mounted) {
                               AppUtils.showSnackBar(context, ok ? 'Status query triggered' : 'Trigger failed', isError: !ok);
                               if (ok) Navigator.pop(ctx);
                            }
                          },
                          child: const Text('Trigger Query'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ],
          );
        }
      ),
    );
  }
}
