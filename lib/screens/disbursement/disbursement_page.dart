import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/disbursement_provider.dart';

class DisbursementPage extends StatefulWidget {
  const DisbursementPage({super.key});
  @override
  State<DisbursementPage> createState() => _DisbursementPageState();
}

class _DisbursementPageState extends State<DisbursementPage> {
  String _channel = 'b2c';
  bool _isCompanyExpense = false;
  final _amount = TextEditingController();
  final _phone = TextEditingController();
  final _remarks = TextEditingController();
  final _accountRef = TextEditingController();

  static const _channels = [
    {'id': 'b2c', 'label': 'B2C (Wallet)', 'icon': Icons.person_outline, 'desc': 'Personal M-Pesa wallet'},
    {'id': 'pochi', 'label': 'Pochi la Biashara', 'icon': Icons.store_outlined, 'desc': 'Pochi wallet'},
    {'id': 'buygoods', 'label': 'Buy Goods / Till', 'icon': Icons.point_of_sale_outlined, 'desc': 'Till number'},
    {'id': 'paybill', 'label': 'PayBill', 'icon': Icons.business_outlined, 'desc': 'Business shortcode'},
  ];

  String get _phoneLabel {
    switch (_channel) {
      case 'buygoods': return 'Till Number';
      case 'paybill': return 'Shortcode';
      default: return 'Phone (254…)';
    }
  }

  @override
  void initState() {
    super.initState();
    print('📱 Entering DisbursementPage');
  }

  @override
  void dispose() {
    _amount.dispose();
    _phone.dispose();
    _remarks.dispose();
    _accountRef.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disb = context.watch<DisbursementProvider>();

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Manual Disbursement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Two-step process: Initiate → OTP Confirmation',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.warning_amber, size: 14, color: Color(0xFFEF4444)),
              SizedBox(width: 6),
              Text('Admin Only — OTP Protected',
                  style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
            ]),
          ),
        ]),
        const SizedBox(height: 24),

        // Type Selector
        _buildTypeSelector(context, disb),
        const SizedBox(height: 24),

        // Channel selector
        Row(children: _channels.map((c) {
          final sel = _channel == c['id'];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _channel = c['id'] as String),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFF141E33),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? const Color(0xFF10B981) : const Color(0xFF1E3A5F),
                  ),
                ),
                child: Column(children: [
                  Icon(c['icon'] as IconData,
                      color: sel ? const Color(0xFF10B981) : const Color(0xFF64748B), size: 24),
                  const SizedBox(height: 8),
                  Text(c['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                        color: sel ? const Color(0xFFE2E8F0) : const Color(0xFF64748B),
                      )),
                  const SizedBox(height: 4),
                  Text(c['desc'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
                ]),
              ),
            ),
          );
        }).toList()),
        const SizedBox(height: 24),

        // OTP waiting state banner
        if (disb.awaitingOtp)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Disbursement Initiated!',
                      style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('OTP sent to ${disb.sentToPhone ?? "admin phone"}. Enter below to confirm.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                ]),
              ),
              TextButton(
                onPressed: () => context.read<DisbursementProvider>().cancelPending(),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
              ),
            ]),
          ),

        // Error
        if (disb.error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(disb.error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
          ),

        // Form
        AppUtils.buildCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Disbursement Details',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextField(controller: _amount,
                  decoration: const InputDecoration(labelText: 'Amount (KSh)'),
                  keyboardType: TextInputType.number,
                  enabled: !disb.awaitingOtp)),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _phone,
                  decoration: InputDecoration(labelText: _phoneLabel),
                  enabled: !disb.awaitingOtp)),
            ]),
            if (_channel == 'paybill') ...[
              const SizedBox(height: 12),
              TextField(controller: _accountRef,
                  decoration: const InputDecoration(labelText: 'Account Reference'),
                  enabled: !disb.awaitingOtp),
            ],
            const SizedBox(height: 12),
            TextField(controller: _remarks, maxLines: 2,
                decoration: const InputDecoration(labelText: 'Remarks'),
                enabled: !disb.awaitingOtp),
            const SizedBox(height: 20),
            if (!disb.awaitingOtp)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: disb.isLoading ? null : () => _initiate(context),
                  child: disb.isLoading
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Initiate Disbursement'),
                ),
              ),
          ]),
        ),

        // OTP confirmation
        if (disb.awaitingOtp) ...[
          const SizedBox(height: 16),
          AppUtils.buildCard(
            child: _OtpSection(disbursementProvider: disb),
          ),
        ],
      ]),
    );
  }

  Future<void> _initiate(BuildContext context) async {
    final amount = double.tryParse(_amount.text);
    if (amount == null || amount <= 0) {
      AppUtils.showSnackBar(context, 'Enter a valid amount', isError: true);
      return;
    }
    if (_phone.text.trim().isEmpty) {
      AppUtils.showSnackBar(context, 'Enter a phone/shortcode', isError: true);
      return;
    }

    await context.read<DisbursementProvider>().initiate(
      channel: _channel,
      amount: amount,
      phone: _phone.text.trim(),
      remarks: _remarks.text.trim().isEmpty ? 'Manual disbursement' : _remarks.text.trim(),
      accountReference: _channel == 'paybill' ? _accountRef.text.trim() : null,
      isCompanyExpense: _isCompanyExpense,
    );
    
    // Show notification if error occurred
    final p = context.read<DisbursementProvider>();
    if (p.error != null) {
      AppUtils.showSnackBar(context, p.error!, isError: true);
    }
  }

  Widget _buildTypeSelector(BuildContext context, DisbursementProvider disb) {
    if (disb.awaitingOtp) return const SizedBox();
    
    final auth = context.watch<AuthProvider>();
    final hasCompanyPerm = auth.currentUser?.permissions.contains('manage_company_disbursement') ?? false;

    return Row(children: [
      Expanded(
        child: _typeCard(
          label: 'Operational Payout',
          icon: Icons.swap_horiz,
          desc: 'Refunds, claims, settlements',
          selected: !_isCompanyExpense,
          onTap: () => setState(() => _isCompanyExpense = false),
        ),
      ),
      if (hasCompanyPerm) ...[
        const SizedBox(width: 12),
        Expanded(
          child: _typeCard(
            label: 'Company Expense',
            icon: Icons.business_center_outlined,
            desc: 'Salaries, office, profit withdrawal',
            selected: _isCompanyExpense,
            onTap: () => setState(() => _isCompanyExpense = true),
          ),
        ),
      ],
    ]);
  }

  Widget _typeCard({
    required String label,
    required IconData icon,
    required String desc,
    required bool selected,
    bool locked = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3B82F6).withOpacity(0.1) : const Color(0xFF141E33),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF3B82F6) : const Color(0xFF1E3A5F),
          ),
        ),
        child: Row(children: [
          Icon(icon, color: selected ? const Color(0xFF3B82F6) : const Color(0xFF64748B), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(label, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF94A3B8)
                )),
                if (locked) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.lock, size: 12, color: Color(0xFF64748B)),
                ],
              ]),
              Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
            ]),
          ),
          if (selected) const Icon(Icons.check_circle, size: 16, color: Color(0xFF3B82F6)),
        ]),
      ),
    );
  }
}

class _OtpSection extends StatefulWidget {
  final DisbursementProvider disbursementProvider;
  const _OtpSection({required this.disbursementProvider});

  @override
  State<_OtpSection> createState() => _OtpSectionState();
}

class _OtpSectionState extends State<_OtpSection> {
  final _otpCtrl = TextEditingController();

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disb = widget.disbursementProvider;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('OTP Confirmation',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      const SizedBox(height: 8),
      const Text('Enter the 6-digit OTP sent to the admin phone.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
      const SizedBox(height: 16),
      TextField(
        controller: _otpCtrl,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          hintText: '• • • • • •',
          counterText: '',
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: disb.isLoading ? null : () async {
            if (_otpCtrl.text.length < 4) {
              AppUtils.showSnackBar(context, 'Enter the OTP', isError: true);
              return;
            }
            final ok = await disb.confirm(_otpCtrl.text);
            AppUtils.showSnackBar(context,
                ok ? '✅ Disbursement confirmed & processing' : 'Invalid OTP or failed',
                isError: !ok);
          },
          child: disb.isLoading
              ? const SizedBox(height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirm & Disburse'),
        ),
      ),
    ]);
  }
}
