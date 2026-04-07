import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils.dart';
import '../../providers/blacklist_provider.dart';

class BlacklistPage extends StatefulWidget {
  const BlacklistPage({super.key});
  @override
  State<BlacklistPage> createState() => _BlacklistPageState();
}

class _BlacklistPageState extends State<BlacklistPage> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    print('📱 Entering BlacklistPage');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BlacklistProvider>().fetchBlacklist();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BlacklistProvider>();
    final filtered = provider.blacklist.where((b) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return b.phone.contains(q) || b.reason.toLowerCase().contains(q);
    }).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search by phone or reason…',
              prefixIcon: Icon(Icons.search, size: 20),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _showBanDialog(context),
          icon: const Icon(Icons.block, size: 16),
          label: const Text('Ban Phone'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: () => provider.fetchBlacklist(),
        ),
      ]),
      const SizedBox(height: 16),

      if (provider.isLoading)
        const Expanded(child: Center(child: CircularProgressIndicator()))
      else if (filtered.isEmpty)
        Expanded(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF10B981)),
              const SizedBox(height: 12),
              Text(provider.error ?? 'No banned numbers',
                  style: const TextStyle(color: Color(0xFF94A3B8))),
            ]),
          ),
        )
      else
        Expanded(
          child: AppUtils.buildCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  border: Border(bottom: BorderSide(color: Color(0xFF1E3A5F))),
                ),
                child: const Row(children: [
                  Expanded(flex: 2, child: Text('PHONE',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B), letterSpacing: 0.5))),
                  Expanded(flex: 4, child: Text('REASON',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B), letterSpacing: 0.5))),
                  Expanded(flex: 2, child: Text('BANNED AT',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B), letterSpacing: 0.5))),
                  SizedBox(width: 80),
                ]),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final b = filtered[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFF1E3A5F))),
                      ),
                      child: Row(children: [
                        Expanded(flex: 2, child: Text(AppUtils.formatPhone(b.phone),
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
                        Expanded(flex: 4, child: Text(b.reason,
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13))),
                        Expanded(flex: 2, child: Text(b.bannedAt,
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                        SizedBox(
                          width: 80,
                          child: TextButton(
                            onPressed: () => _confirmUnban(context, b.phone, provider),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: const Text('Unban', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ]),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
    ]);
  }

  void _showBanDialog(BuildContext context) {
    final phoneCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Ban Phone Number'),
        content: SizedBox(
          width: 400,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: phoneCtrl,
                decoration: const InputDecoration(
                    hintText: 'Phone number e.g. 0712345678',
                    prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 12),
            TextField(controller: reasonCtrl, maxLines: 3,
                decoration: const InputDecoration(
                    hintText: 'Reason for ban…',
                    alignLabelWithHint: true)),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final phone = phoneCtrl.text.trim();
              final reason = reasonCtrl.text.trim();
              if (phone.isEmpty || reason.isEmpty) return;
              Navigator.pop(ctx);
              final ok = await context.read<BlacklistProvider>().banPhone(phone, reason);
              AppUtils.showSnackBar(context,
                  ok ? 'Phone $phone banned successfully' : 'Failed to ban phone',
                  isError: !ok);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Ban'),
          ),
        ],
      ),
    );
  }

  void _confirmUnban(BuildContext context, String phone, BlacklistProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Unban Phone Number'),
        content: Text(
            'Remove ${AppUtils.formatPhone(phone)} from the blacklist? '
            'They will be able to create transactions again.',
            style: const TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await provider.unbanPhone(phone);
              AppUtils.showSnackBar(context,
                  ok ? 'Phone $phone unbanned' : 'Failed to unban phone',
                  isError: !ok);
            },
            child: const Text('Unban'),
          ),
        ],
      ),
    );
  }
}
