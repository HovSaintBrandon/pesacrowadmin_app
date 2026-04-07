import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils.dart';
import '../../models/deal.dart';
import '../../providers/deal_provider.dart';

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
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                    Row(children: [
                      ElevatedButton.icon(
                        onPressed: () => _showResolveDialog(context, d, 'release'),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Release to Seller'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showResolveDialog(context, d, 'refund'),
                        icon: const Icon(Icons.undo, size: 16, color: Color(0xFFF59E0B)),
                        label: const Text('Refund Buyer',
                            style: TextStyle(color: Color(0xFFF59E0B))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFF59E0B)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ]),
                  ]),
                ),
              );
            },
          ),
        ),
    ]);
  }

  void _showResolveDialog(BuildContext context, Deal deal, String decision) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(decision == 'release' ? 'Release to Seller' : 'Refund Buyer'),
        content: SizedBox(
          width: 400,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${deal.transactionId} — ${AppUtils.formatKSh(deal.amount)}',
                style: const TextStyle(color: Color(0xFF94A3B8))),
            const SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Resolution note…',
                alignLabelWithHint: true,
              ),
            ),
          ]),
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
              AppUtils.showSnackBar(context,
                  ok ? 'Dispute resolved successfully' : 'Failed to resolve dispute',
                  isError: !ok);
              if (ok) {
                context.read<DealProvider>().fetchDeals(status: 'disputed');
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
