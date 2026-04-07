import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils.dart';
import '../../providers/mpesa_provider.dart';

class MpesaToolsPage extends StatefulWidget {
  const MpesaToolsPage({super.key});
  @override
  State<MpesaToolsPage> createState() => _MpesaToolsPageState();
}

class _MpesaToolsPageState extends State<MpesaToolsPage> {
  // C2B Simulate
  final _c2bAmount = TextEditingController();
  final _c2bMsisdn = TextEditingController();
  final _c2bBillRef = TextEditingController();

  // B2B
  final _b2bAmount = TextEditingController();
  final _b2bShortcode = TextEditingController();
  final _b2bAccountRef = TextEditingController(text: 'Settlement');
  final _b2bRemarks = TextEditingController(text: 'Weekly settlement transfer');

  // Balance query
  final _balRemarks = TextEditingController(text: 'Balance check');

  // Status query
  final _statusIdentifier = TextEditingController();
  bool _isConversationId = false;

  // Pull register
  final _pullNominated = TextEditingController();
  final _pullCallback = TextEditingController();

  // Pull query
  final _pullStart = TextEditingController();
  final _pullEnd = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('📱 Entering MpesaToolsPage');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MpesaProvider>().fetchLatestBalance();
    });
  }

  @override
  void dispose() {
    for (final c in [
      _c2bAmount, _c2bMsisdn, _c2bBillRef,
      _b2bAmount, _b2bShortcode, _b2bAccountRef, _b2bRemarks,
      _balRemarks, _statusIdentifier, _pullNominated, _pullCallback,
      _pullStart, _pullEnd,
    ]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mpesa = context.watch<MpesaProvider>();

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('M-Pesa Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Admin tools for managing M-Pesa integrations.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          ]),
          const Spacer(),
          if (mpesa.isLoading)
            const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2)),
        ]),
        const SizedBox(height: 20),

        // Balance banner
        if (mpesa.balances.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
            ),
            child: Row(children: [
              const Icon(Icons.account_balance_wallet, color: Color(0xFF10B981), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(spacing: 24, children: mpesa.balances.map((b) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(b.accountType, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    Text('${b.currency} ${b.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                )).toList()),
              ),
            ]),
          ),

        LayoutBuilder(builder: (ctx, c) {
          final cols = c.maxWidth > 900 ? 2 : 1;
          return GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: cols == 2 ? 1.55 : 2.2,
            children: [
              // ── Register C2B
              _card(
                title: 'Register C2B URLs',
                desc: 'Register validation & confirmation URLs with Safaricom. Run once per environment.',
                icon: Icons.app_registration,
                color: const Color(0xFF3B82F6),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: mpesa.isLoading ? null : () async {
                      final ok = await mpesa.registerC2B();
                      _snack(context, ok, 'C2B URLs registered', 'Registration failed');
                    },
                    child: const Text('Register URLs'),
                  ),
                ),
              ),

              // ── Simulate C2B
              _card(
                title: 'Simulate C2B Payment',
                desc: 'Sandbox only. BillRefNumber must match an existing transactionId.',
                icon: Icons.payment,
                color: const Color(0xFF10B981),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _tf(_c2bAmount, 'Amount (e.g. 1500)', type: TextInputType.number),
                  const SizedBox(height: 8),
                  _tf(_c2bMsisdn, 'Phone / MSISDN (254…)'),
                  const SizedBox(height: 8),
                  _tf(_c2bBillRef, 'Bill Ref / Transaction ID'),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity,
                    child: ElevatedButton(
                      onPressed: mpesa.isLoading ? null : () async {
                        final amt = double.tryParse(_c2bAmount.text);
                        if (amt == null || _c2bMsisdn.text.isEmpty || _c2bBillRef.text.isEmpty) {
                          _snack(context, false, '', 'Fill all fields');
                          return;
                        }
                        final ok = await mpesa.simulateC2B(amt, _c2bMsisdn.text, _c2bBillRef.text);
                        _snack(context, ok, 'C2B payment simulated', 'Simulation failed');
                      },
                      child: const Text('Simulate'),
                    ),
                  ),
                ]),
              ),

              // ── B2B Paybill
              _card(
                title: 'B2B PayBill',
                desc: 'Admin-initiated business-to-business M-Pesa payment.',
                icon: Icons.business,
                color: const Color(0xFF06B6D4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: _tf(_b2bAmount, 'Amount', type: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: _tf(_b2bShortcode, 'Destination Shortcode')),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _tf(_b2bAccountRef, 'Account Ref')),
                    const SizedBox(width: 8),
                    Expanded(child: _tf(_b2bRemarks, 'Remarks')),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity,
                    child: ElevatedButton(
                      onPressed: mpesa.isLoading ? null : () async {
                        final amt = double.tryParse(_b2bAmount.text);
                        if (amt == null || _b2bShortcode.text.isEmpty) {
                          _snack(context, false, '', 'Fill required fields');
                          return;
                        }
                        final ok = await mpesa.b2bPaybill(
                          amount: amt,
                          destinationShortcode: _b2bShortcode.text,
                          accountReference: _b2bAccountRef.text,
                          remarks: _b2bRemarks.text,
                        );
                        _snack(context, ok, 'B2B payment initiated', 'B2B payment failed');
                      },
                      child: const Text('Send B2B Payment'),
                    ),
                  ),
                ]),
              ),

              // ── Balance Query + Fetch
              _card(
                title: 'Account Balance',
                desc: 'Query M-Pesa B2C balance. Result logged asynchronously via webhook.',
                icon: Icons.account_balance_wallet,
                color: const Color(0xFFF59E0B),
                child: Column(children: [
                  _tf(_balRemarks, 'Remarks'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: ElevatedButton(
                      onPressed: mpesa.isLoading ? null : () async {
                        final ok = await mpesa.queryBalance(_balRemarks.text.isEmpty ? 'Balance check' : _balRemarks.text);
                        _snack(context, ok, 'Balance query sent', 'Query failed');
                      },
                      child: const Text('Query Balance'),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(
                      onPressed: mpesa.isLoading ? null : () => mpesa.fetchLatestBalance(),
                      child: const Text('Get Latest'),
                    )),
                  ]),
                ]),
              ),

              // ── Query Transaction Status
              _card(
                title: 'Query Transaction Status',
                desc: 'Check status of an M-Pesa transaction by receipt or ConversationID.',
                icon: Icons.search,
                color: const Color(0xFF8B5CF6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _tf(_statusIdentifier, 'Receipt No. or ConversationID'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Switch(
                      value: _isConversationId,
                      onChanged: (v) => setState(() => _isConversationId = v),
                      activeColor: const Color(0xFF8B5CF6),
                    ),
                    const Text('Is ConversationID?',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                  ]),
                  const SizedBox(height: 8),
                  SizedBox(width: double.infinity,
                    child: ElevatedButton(
                      onPressed: mpesa.isLoading ? null : () async {
                        if (_statusIdentifier.text.isEmpty) return;
                        final ok = await mpesa.queryTransactionStatus(
                            _statusIdentifier.text, isConversationId: _isConversationId);
                        _snack(context, ok, 'Status query sent', 'Query failed');
                      },
                      child: const Text('Query Status'),
                    ),
                  ),
                ]),
              ),

              // ── Pull Transactions Register
              _card(
                title: 'Register Pull Transactions',
                desc: '⚠ One-time setup. Registers shortcode with Safaricom Pull API.',
                icon: Icons.cloud_sync,
                color: const Color(0xFFEC4899),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _tf(_pullNominated, 'Nominated Number (254…)'),
                  const SizedBox(height: 8),
                  _tf(_pullCallback, 'Callback URL'),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity,
                    child: ElevatedButton(
                      onPressed: mpesa.isLoading ? null : () async {
                        if (_pullNominated.text.isEmpty || _pullCallback.text.isEmpty) {
                          _snack(context, false, '', 'Fill all fields');
                          return;
                        }
                        final ok = await mpesa.registerPullTransactions(
                          nominatedNumber: _pullNominated.text,
                          callbackUrl: _pullCallback.text,
                        );
                        _snack(context, ok, 'Pull registration sent', 'Registration failed');
                      },
                      child: const Text('Register Pull'),
                    ),
                  ),
                ]),
              ),

              // ── Pull Transactions Query
              _card(
                title: 'Query Pull Transactions',
                desc: 'Fetch missed C2B transactions within a time window (max 48 hrs).',
                icon: Icons.history,
                color: const Color(0xFF14B8A6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: _tf(_pullStart, 'Start (YYYY-MM-DD HH:MM:SS)')),
                    const SizedBox(width: 8),
                    Expanded(child: _tf(_pullEnd, 'End (YYYY-MM-DD HH:MM:SS)')),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity,
                    child: ElevatedButton(
                      onPressed: mpesa.isLoading ? null : () async {
                        if (_pullStart.text.isEmpty || _pullEnd.text.isEmpty) {
                          _snack(context, false, '', 'Enter date range');
                          return;
                        }
                        final ok = await mpesa.queryPullTransactions(
                          startDate: _pullStart.text,
                          endDate: _pullEnd.text,
                        );
                        _snack(context, ok, 'Pull query sent', 'Query failed');
                      },
                      child: const Text('Query Pull Transactions'),
                    ),
                  ),
                ]),
              ),
            ],
          );
        }),
      ]),
    );
  }

  Widget _card({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return AppUtils.buildCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        ]),
        const SizedBox(height: 8),
        Text(desc, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }

  Widget _tf(TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  void _snack(BuildContext context, bool ok, String success, String fail) {
    AppUtils.showSnackBar(context, ok ? success : fail, isError: !ok);
  }
}
