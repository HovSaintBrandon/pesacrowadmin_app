import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils.dart';
import '../../models/deal.dart';
import '../../providers/deal_provider.dart';
import '../../providers/auth_provider.dart';

class DisputesPage extends StatefulWidget {
  const DisputesPage({super.key});
  @override
  State<DisputesPage> createState() => _DisputesPageState();
}

class _DisputesPageState extends State<DisputesPage> {
  @override
  void initState() {
    super.initState();
    print('📱 Entering DisputesPage');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DealProvider>().fetchDeals(status: 'disputed');
    });
  }

  @override
  Widget build(BuildContext context) {
    final dealProvider = context.watch<DealProvider>();
    final disputes = dealProvider.deals.where((d) => d.status == 'disputed').toList();
    final auth = context.watch<AuthProvider>();

    if (dealProvider.isLoading && disputes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('${disputes.length} Open Disputes',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(
          onPressed: () => context.read<DealProvider>().fetchDeals(status: 'disputed'),
          icon: const Icon(Icons.refresh, size: 20),
        ),
      ]),
      const SizedBox(height: 16),
      if (disputes.isEmpty)
        const Expanded(
          child: Center(
            child: Text('No open disputes found',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
        )
      else
        Expanded(
          child: ListView.builder(
            itemCount: disputes.length,
            itemBuilder: (ctx, i) {
              final d = disputes[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: AppUtils.buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Row(children: [
                        Text(d.transactionId,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        AppUtils.buildStatusBadge(d.status),
                        const Spacer(),
                        Text(AppUtils.formatKSh(d.amount),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 8),
                      Text(d.description,
                          style: const TextStyle(color: Color(0xFF94A3B8))),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text('Seller: ${AppUtils.formatPhone(d.sellerPhone)}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        const SizedBox(width: 16),
                        const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text('Buyer: ${AppUtils.formatPhone(d.buyerPhone)}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ]),
                      if (d.disputeReason != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                          ),
                          child: Text(d.disputeReason!,
                              style: const TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (auth.hasPermission('resolve_disputes'))
                        Row(children: [
                          ElevatedButton.icon(
                            onPressed: () => _showResolveDialog(context, d, 'release'),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Release'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _showResolveDialog(context, d, 'refund'),
                            icon: const Icon(Icons.undo, size: 16, color: Color(0xFFF59E0B)),
                            label: const Text('Refund',
                                style: TextStyle(color: Color(0xFFF59E0B))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFF59E0B)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _showDisputeDetail(context, d),
                          icon: const Icon(Icons.visibility),
                          label: const Text('View Evidence & Notes'),
                        ),
                      ]),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
    ]);
  }

  void _showDisputeDetail(BuildContext context, Deal deal) async {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<Map<String, dynamic>>(
        future: context.read<DealProvider>().fetchDisputeDetail(deal.transactionId),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!['data'] ?? {};
          final notes = data['notes'] as List? ?? [];
          final proofs = deal.proofs;

          return AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            title: Text('Dispute: ${deal.transactionId}'),
            content: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Administrative Evidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    if (proofs.isEmpty)
                      const Text('No uploaded evidence found.', style: TextStyle(color: Color(0xFF64748B), fontStyle: FontStyle.italic))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: proofs.map((p) => InkWell(
                          onTap: () { /* Image view logic */ },
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A5F),
                              borderRadius: BorderRadius.circular(8),
                              image: p['url'] != null ? DecorationImage(image: NetworkImage(p['url']!), fit: BoxFit.cover) : null,
                            ),
                            child: p['url'] == null ? const Icon(Icons.insert_drive_file, color: Colors.white54) : null,
                          ),
                        )).toList(),
                      ),
                    const Divider(height: 32, color: Color(0xFF1E3A5F)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Internal Admin Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (context.watch<AuthProvider>().hasPermission('resolve_disputes'))
                          IconButton(
                            icon: const Icon(Icons.add_comment, size: 20, color: Color(0xFF10B981)),
                            onPressed: () => _showAddNoteDialog(context, deal),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (notes.isEmpty)
                      const Text('No internal notes recorded.', style: TextStyle(color: Color(0xFF64748B)))
                    else
                      ...notes.map((n) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n['adminName'] ?? 'Unknown Admin', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF10B981))),
                            Text(n['note'] ?? '', style: const TextStyle(fontSize: 14)),
                            Text(AppUtils.formatDateTime(DateTime.parse(n['createdAt'])), style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ],
          );
        },
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, Deal deal) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141E33),
        title: const Text('Add Internal Note'),
        content: TextField(
          controller: noteCtrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Enter your observation or findings...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final ok = await context.read<DealProvider>().addDisputeNote(deal.transactionId, noteCtrl.text);
              Navigator.pop(ctx);
              if (ok) {
                AppUtils.showSnackBar(context, 'Note added');
                Navigator.pop(context); // Close detail dialog to refresh
                _showDisputeDetail(context, deal);
              } else {
                AppUtils.showSnackBar(context, context.read<DealProvider>().error ?? 'Failed to add note', isError: true);
              }
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(BuildContext context, Deal deal, String decision) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141E33),
        title: Text('Resolve as ${decision.toUpperCase()}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This will ${decision == 'release' ? 'pay the seller' : 'refund the buyer'} the full amount.', 
                 style: const TextStyle(color: Color(0xFF94A3B8))),
            const SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Explain the resolution (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await context.read<DealProvider>().resolveDispute(deal.transactionId, decision, noteCtrl.text);
              if (ok) {
                AppUtils.showSnackBar(context, 'Dispute resolved successfully');
                context.read<DealProvider>().fetchDeals(status: 'disputed');
              } else {
                AppUtils.showSnackBar(context, context.read<DealProvider>().error ?? 'Failed to resolve dispute', isError: true);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
