import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils.dart';
import '../../models/fee_config.dart';
import '../../providers/fee_provider.dart';

class FeesPage extends StatefulWidget {
  const FeesPage({super.key});
  @override
  State<FeesPage> createState() => _FeesPageState();
}

class _FeesPageState extends State<FeesPage> {
  late TextEditingController _txPct;
  late TextEditingController _txMin;
  late TextEditingController _relPct;
  late TextEditingController _relMin;
  late TextEditingController _inactRate;
  late TextEditingController _graceDays;
  late TextEditingController _bouquet;
  List<FeeTier> _tiers = [];

  @override
  void initState() {
    super.initState();
    final config = context.read<FeeProvider>().config!;
    _txPct = TextEditingController(text: config.transactionFee.percentage.toString());
    _txMin = TextEditingController(text: config.transactionFee.minimum.toString());
    _relPct = TextEditingController(text: config.releaseFee.percentage.toString());
    _relMin = TextEditingController(text: config.releaseFee.minimum.toString());
    _inactRate = TextEditingController(text: config.inactivityFee.ratePerWeek.toString());
    _graceDays = TextEditingController(text: config.inactivityFee.graceDays.toString());
    _bouquet = TextEditingController(text: config.bouquetRevenueShare.toString());
    _tiers = List.from(config.tiers);
  }

  @override
  Widget build(BuildContext context) {
    final feeProvider = context.watch<FeeProvider>();

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Fee Configuration',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        AppUtils.buildCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Base Fees',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _field('Transaction Fee %', _txPct)),
              const SizedBox(width: 12),
              Expanded(child: _field('Minimum (KSh)', _txMin)),
              const SizedBox(width: 12),
              Expanded(child: _field('Release Fee %', _relPct)),
              const SizedBox(width: 12),
              Expanded(child: _field('Minimum (KSh)', _relMin)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _field('Inactivity Rate/Week %', _inactRate)),
              const SizedBox(width: 12),
              Expanded(child: _field('Grace Days', _graceDays)),
              const SizedBox(width: 12),
              Expanded(child: _field('Bouquet Revenue Share', _bouquet)),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ]),
            Row(children: [
              ElevatedButton(
                onPressed: feeProvider.isLoading ? null : () async {
                  final newConfig = FeeConfig(
                    transactionFee: TransactionFeeConfig(percentage: double.tryParse(_txPct.text) ?? 0, minimum: double.tryParse(_txMin.text) ?? 0),
                    releaseFee: ReleaseFeeConfig(percentage: double.tryParse(_relPct.text) ?? 0, minimum: double.tryParse(_relMin.text) ?? 0),
                    inactivityFee: InactivityFeeConfig(ratePerWeek: double.tryParse(_inactRate.text) ?? 0, graceDays: int.tryParse(_graceDays.text) ?? 0),
                    bouquetRevenueShare: double.tryParse(_bouquet.text) ?? 0,
                    tiers: _tiers,
                  );
                  final success = await feeProvider.updateConfig(newConfig);
                  if (success) {
                    AppUtils.showSnackBar(context, 'Full configuration updated (POST)');
                  }
                },
                child: Text(feeProvider.isLoading ? 'Saving…' : 'Save All (POST)'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: feeProvider.isLoading ? null : () async {
                  final success = await feeProvider.patchConfig({
                    "transactionFee": { "percentage": double.tryParse(_txPct.text) ?? 0, "minimum": double.tryParse(_txMin.text) ?? 0 },
                    "releaseFee": { "percentage": double.tryParse(_relPct.text) ?? 0, "minimum": double.tryParse(_relMin.text) ?? 0 },
                    "inactivityFee": { "ratePerWeek": double.tryParse(_inactRate.text) ?? 0, "graceDays": int.tryParse(_graceDays.text) ?? 0 },
                    "bouquetRevenueShare": double.tryParse(_bouquet.text) ?? 0,
                  });
                  if (success) {
                    AppUtils.showSnackBar(context, 'Base fees patched (PATCH)');
                  }
                },
                icon: const Icon(Icons.bolt, size: 16),
                label: const Text('Patch Base Fees'),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 24),
        AppUtils.buildCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Volume Tiers',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              Row(children: [
                OutlinedButton.icon(
                  onPressed: feeProvider.isLoading ? null : () async {
                    final success = await feeProvider.patchConfig({
                      "tiers": _tiers.map((t) => t.toJson()).toList(),
                    });
                    if (success) {
                      AppUtils.showSnackBar(context, 'Tiers patched (PATCH)');
                    }
                  },
                  icon: const Icon(Icons.bolt, size: 16),
                  label: const Text('Patch Tiers'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _tiers.add(
                      FeeTier(minAmount: 0, maxAmount: null, transactionPercentage: 0, releasePercentage: 0))),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Tier'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ]),
            ]),
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(0.8),
                3: FlexColumnWidth(0.8),
                4: FixedColumnWidth(48),
              },
              children: [
                const TableRow(
                  children: [
                    Padding(padding: EdgeInsets.all(8),
                        child: Text('Min Amount', style: TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                    Padding(padding: EdgeInsets.all(8),
                        child: Text('Max (null = ∞)', style: TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                    Padding(padding: EdgeInsets.all(8),
                        child: Text('Tx %', style: TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                    Padding(padding: EdgeInsets.all(8),
                        child: Text('Rel %', style: TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                    SizedBox(),
                  ],
                ),
                ..._tiers.asMap().entries.map((e) {
                  final i = e.key;
                  final t = e.value;
                  return TableRow(children: [
                    _tableField(t.minAmount.toString(), (v) {
                      _tiers[i] = FeeTier(
                        minAmount: double.tryParse(v) ?? 0,
                        maxAmount: t.maxAmount,
                        transactionPercentage: t.transactionPercentage,
                        releasePercentage: t.releasePercentage,
                      );
                    }),
                    _tableField(t.maxAmount?.toString() ?? '', (v) {
                      _tiers[i] = FeeTier(
                        minAmount: t.minAmount,
                        maxAmount: v.isEmpty ? null : double.tryParse(v),
                        transactionPercentage: t.transactionPercentage,
                        releasePercentage: t.releasePercentage,
                      );
                    }, hint: '∞'),
                    _tableField(t.transactionPercentage.toString(), (v) {
                      _tiers[i] = FeeTier(
                        minAmount: t.minAmount,
                        maxAmount: t.maxAmount,
                        transactionPercentage: double.tryParse(v) ?? 0,
                        releasePercentage: t.releasePercentage,
                      );
                    }),
                    _tableField(t.releasePercentage.toString(), (v) {
                      _tiers[i] = FeeTier(
                        minAmount: t.minAmount,
                        maxAmount: t.maxAmount,
                        transactionPercentage: t.transactionPercentage,
                        releasePercentage: double.tryParse(v) ?? 0,
                      );
                    }),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 16, color: Color(0xFFEF4444)),
                      onPressed: () => setState(() => _tiers.removeAt(i)),
                    ),
                  ]);
                }),
              ],
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, isDense: true),
      keyboardType: TextInputType.number,
    );
  }

  Widget _tableField(String value, Function(String) onChanged, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: TextField(
        controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        ),
        style: const TextStyle(fontSize: 13),
        keyboardType: TextInputType.number,
      ),
    );
  }
}
