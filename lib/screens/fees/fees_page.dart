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
  bool _isEditing = false;

  // Controllers for edit mode
  late TextEditingController _txPct;
  late TextEditingController _txMin;
  late TextEditingController _relPct;
  late TextEditingController _relMin;
  late TextEditingController _inactRate;
  late TextEditingController _graceDays;
  late TextEditingController _bouquet;
  late TextEditingController _holdPct;
  late TextEditingController _holdFlat;
  late TextEditingController _dispFlat;
  late TextEditingController _dispPct;
  late TextEditingController _dispCap;
  List<FeeTier> _tiers = [];

  void _startEditing(FeeConfig config) {
    _txPct = TextEditingController(text: config.transactionFee.percentage.toString());
    _txMin = TextEditingController(text: config.transactionFee.minimum.toString());
    _relPct = TextEditingController(text: config.releaseFee.percentage.toString());
    _relMin = TextEditingController(text: config.releaseFee.minimum.toString());
    _inactRate = TextEditingController(text: config.inactivityFee.ratePerWeek.toString());
    _graceDays = TextEditingController(text: config.inactivityFee.graceDays.toString());
    _bouquet = TextEditingController(text: config.bouquetRevenueShare.toString());
    _holdPct = TextEditingController(text: config.holdingFee.percentage.toString());
    _holdFlat = TextEditingController(text: config.holdingFee.flatAdmin.toString());
    _dispFlat = TextEditingController(text: config.disputeFee.flat.toString());
    _dispPct = TextEditingController(text: config.disputeFee.percentage.toString());
    _dispCap = TextEditingController(text: config.disputeFee.cap.toString());
    
    // Deep copy tiers to prevent modifying the provider's active model unexpectedly
    _tiers = config.tiers.map((t) => FeeTier(
      minAmount: t.minAmount,
      maxAmount: t.maxAmount,
      transactionPercentage: t.transactionPercentage,
      releasePercentage: t.releasePercentage,
      transactionFlat: t.transactionFlat,
      releaseFlat: t.releaseFlat,
    )).toList();

    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final feeProvider = context.watch<FeeProvider>();
    final config = feeProvider.config;

    if (config == null || feeProvider.isLoading && !_isEditing) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Fee Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (!_isEditing)
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => feeProvider.fetchConfig(),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _startEditing(config),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Config'),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _cancelEditing,
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Cancel Edit'),
              )
          ],
        ),
        const SizedBox(height: 20),
        if (!_isEditing) _buildReadOnlyView(config),
        if (_isEditing) _buildEditForm(feeProvider),
      ]),
    );
  }

  // --- READ-ONLY VIEW --- //
  Widget _buildReadOnlyView(FeeConfig config) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AppUtils.buildCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Base Fees (Current)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF10B981))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _infoField('Transaction Fee %', config.transactionFee.percentage.toString())),
            const SizedBox(width: 12),
            Expanded(child: _infoField('Minimum (KSh)', config.transactionFee.minimum.toString())),
            const SizedBox(width: 12),
            Expanded(child: _infoField('Release Fee %', config.releaseFee.percentage.toString())),
            const SizedBox(width: 12),
            Expanded(child: _infoField('Minimum (KSh)', config.releaseFee.minimum.toString())),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _infoField('Inactivity Rate/Week %', config.inactivityFee.ratePerWeek.toString())),
            const SizedBox(width: 12),
            Expanded(child: _infoField('Grace Days', config.inactivityFee.graceDays.toString())),
            const SizedBox(width: 12),
            Expanded(child: _infoField('Bouquet Revenue Share', config.bouquetRevenueShare.toString())),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _infoField('Holding Fee %', config.holdingFee.percentage.toString())),
            const SizedBox(width: 12),
            Expanded(child: _infoField('Holding Flat Admin', config.holdingFee.flatAdmin.toString())),
            const SizedBox(width: 12),
            Expanded(child: _infoField('Dispute Flat', config.disputeFee.flat.toString())),
            const SizedBox(width: 12),
            Expanded(child: _infoField('Dispute Fee %', config.disputeFee.percentage.toString())),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _infoField('Dispute Cap', config.disputeFee.cap.toString())),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ]),
        ]),
      ),
      const SizedBox(height: 24),
      AppUtils.buildCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Volume Tiers (Current)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF10B981))),
          const SizedBox(height: 12),
          if (config.tiers.isEmpty)
            const Text('No volume tiers configured.', style: TextStyle(color: Color(0xFF64748B)))
          else
            Table(
              border: TableBorder.all(color: const Color(0xFF1E3A5F)),
              children: [
                const TableRow(decoration: BoxDecoration(color: Color(0xFF1E293B)), children: [
                  Padding(padding: EdgeInsets.all(8), child: Text('Min Amount', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Max Amount', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Tx %', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Rel %', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Tx Flat', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Rel Flat', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold))),
                ]),
                ...config.tiers.map((t) => TableRow(children: [
                  Padding(padding: const EdgeInsets.all(8), child: Text(t.minAmount.toString())),
                  Padding(padding: const EdgeInsets.all(8), child: Text(t.maxAmount?.toString() ?? '∞')),
                  Padding(padding: const EdgeInsets.all(8), child: Text(t.transactionPercentage.toString())),
                  Padding(padding: const EdgeInsets.all(8), child: Text(t.releasePercentage.toString())),
                  Padding(padding: const EdgeInsets.all(8), child: Text(t.transactionFlat?.toString() ?? '-')),
                  Padding(padding: const EdgeInsets.all(8), child: Text(t.releaseFlat?.toString() ?? '-')),
                ]))
              ],
            )
        ]),
      ),
    ]);
  }

  Widget _infoField(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      const SizedBox(height: 4),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFF1E3A5F))),
        child: Text(value, style: const TextStyle(fontSize: 14)),
      ),
    ]);
  }

  // --- EDIT FORM --- //
  Widget _buildEditForm(FeeProvider feeProvider) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.1), border: Border.all(color: const Color(0xFFF59E0B)), borderRadius: BorderRadius.circular(8)),
        child: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
          SizedBox(width: 8),
          Expanded(child: Text('Edit Mode Active. You can submit full configuration changes via POST, or targeted updates via PATCH.', style: TextStyle(color: Color(0xFFFCD34D), fontSize: 13))),
        ]),
      ),
      AppUtils.buildCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Base Fees (Edit)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _field('Holding Fee %', _holdPct)),
            const SizedBox(width: 12),
            Expanded(child: _field('Holding Flat Admin', _holdFlat)),
            const SizedBox(width: 12),
            Expanded(child: _field('Dispute Flat', _dispFlat)),
            const SizedBox(width: 12),
            Expanded(child: _field('Dispute Fee %', _dispPct)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _field('Dispute Cap', _dispCap)),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ]),
          const SizedBox(height: 24),
          Row(children: [
            ElevatedButton(
              onPressed: feeProvider.isLoading ? null : () async {
                final newConfig = FeeConfig(
                  transactionFee: TransactionFeeConfig(percentage: double.tryParse(_txPct.text) ?? 0, minimum: double.tryParse(_txMin.text) ?? 0),
                  releaseFee: ReleaseFeeConfig(percentage: double.tryParse(_relPct.text) ?? 0, minimum: double.tryParse(_relMin.text) ?? 0),
                  holdingFee: HoldingFeeConfig(percentage: double.tryParse(_holdPct.text) ?? 0, flatAdmin: double.tryParse(_holdFlat.text) ?? 0),
                  inactivityFee: InactivityFeeConfig(ratePerWeek: double.tryParse(_inactRate.text) ?? 0, graceDays: int.tryParse(_graceDays.text) ?? 0),
                  disputeFee: DisputeFeeConfig(flat: double.tryParse(_dispFlat.text) ?? 0, percentage: double.tryParse(_dispPct.text) ?? 0, cap: double.tryParse(_dispCap.text) ?? 0),
                  bouquetRevenueShare: double.tryParse(_bouquet.text) ?? 0,
                  tiers: _tiers,
                );
                final success = await feeProvider.updateConfig(newConfig);
                if (success) {
                  AppUtils.showSnackBar(context, 'Full configuration updated (POST)');
                  _cancelEditing();
                }
              },
              child: Text(feeProvider.isLoading ? 'Saving…' : 'Save All Fees & Tiers (POST)'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: feeProvider.isLoading ? null : () async {
                final success = await feeProvider.patchConfig({
                  "transactionFee": { "percentage": double.tryParse(_txPct.text) ?? 0, "minimum": double.tryParse(_txMin.text) ?? 0 },
                  "releaseFee": { "percentage": double.tryParse(_relPct.text) ?? 0, "minimum": double.tryParse(_relMin.text) ?? 0 },
                  "holdingFee": { "percentage": double.tryParse(_holdPct.text) ?? 0, "flatAdmin": double.tryParse(_holdFlat.text) ?? 0 },
                  "inactivityFee": { "ratePerWeek": double.tryParse(_inactRate.text) ?? 0, "graceDays": int.tryParse(_graceDays.text) ?? 0 },
                  "disputeFee": { "flat": double.tryParse(_dispFlat.text) ?? 0, "percentage": double.tryParse(_dispPct.text) ?? 0, "cap": double.tryParse(_dispCap.text) ?? 0 },
                  "bouquetRevenueShare": double.tryParse(_bouquet.text) ?? 0,
                });
                if (success) {
                  AppUtils.showSnackBar(context, 'Base fees patched successfully (PATCH)');
                  _cancelEditing();
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
            const Text('Volume Tiers (Edit)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            Row(children: [
              OutlinedButton.icon(
                onPressed: feeProvider.isLoading ? null : () async {
                  final success = await feeProvider.patchConfig({
                    "tiers": _tiers.map((t) => t.toJson()).toList(),
                  });
                  if (success) {
                    AppUtils.showSnackBar(context, 'Tiers patched successfully (PATCH)');
                    _cancelEditing(); // Return to read view on success
                  }
                },
                icon: const Icon(Icons.bolt, size: 16),
                label: const Text('Patch Tiers'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => setState(() => _tiers.add( FeeTier(minAmount: 0, maxAmount: null, transactionPercentage: 0, releasePercentage: 0, transactionFlat: null, releaseFlat: null))),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Tier'),
              ),
            ]),
          ]),
          const SizedBox(height: 12),
          Table(
            columnWidths: const { 0: FlexColumnWidth(1.0), 1: FlexColumnWidth(1.0), 2: FlexColumnWidth(0.7), 3: FlexColumnWidth(0.7), 4: FlexColumnWidth(0.8), 5: FlexColumnWidth(0.8), 6: FixedColumnWidth(48) },
            children: [
              const TableRow(
                children: [
                  Padding(padding: EdgeInsets.all(8), child: Text('Min Amount', style: TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Max (null = ∞)', style: TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Tx %', style: TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Rel %', style: TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Tx Flat', style: TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Rel Flat', style: TextStyle(color: Color(0xFF64748B), fontSize: 12))),
                  SizedBox(),
                ],
              ),
              ..._tiers.asMap().entries.map((e) {
                final i = e.key;
                final t = e.value;
                return TableRow(children: [
                  _tableField(t.minAmount.toString(), (v) { _tiers[i] = FeeTier(minAmount: double.tryParse(v) ?? 0, maxAmount: _tiers[i].maxAmount, transactionPercentage: _tiers[i].transactionPercentage, releasePercentage: _tiers[i].releasePercentage, transactionFlat: _tiers[i].transactionFlat, releaseFlat: _tiers[i].releaseFlat); }),
                  _tableField(t.maxAmount?.toString() ?? '', (v) { _tiers[i] = FeeTier(minAmount: _tiers[i].minAmount, maxAmount: v.isEmpty ? null : double.tryParse(v), transactionPercentage: _tiers[i].transactionPercentage, releasePercentage: _tiers[i].releasePercentage, transactionFlat: _tiers[i].transactionFlat, releaseFlat: _tiers[i].releaseFlat); }, hint: '∞'),
                  _tableField(t.transactionPercentage.toString(), (v) { _tiers[i] = FeeTier(minAmount: _tiers[i].minAmount, maxAmount: _tiers[i].maxAmount, transactionPercentage: double.tryParse(v) ?? 0, releasePercentage: _tiers[i].releasePercentage, transactionFlat: _tiers[i].transactionFlat, releaseFlat: _tiers[i].releaseFlat); }),
                  _tableField(t.releasePercentage.toString(), (v) { _tiers[i] = FeeTier(minAmount: _tiers[i].minAmount, maxAmount: _tiers[i].maxAmount, transactionPercentage: _tiers[i].transactionPercentage, releasePercentage: double.tryParse(v) ?? 0, transactionFlat: _tiers[i].transactionFlat, releaseFlat: _tiers[i].releaseFlat); }),
                  _tableField(t.transactionFlat?.toString() ?? '', (v) { _tiers[i] = FeeTier(minAmount: _tiers[i].minAmount, maxAmount: _tiers[i].maxAmount, transactionPercentage: _tiers[i].transactionPercentage, releasePercentage: _tiers[i].releasePercentage, transactionFlat: v.isEmpty ? null : double.tryParse(v), releaseFlat: _tiers[i].releaseFlat); }, hint: 'Null'),
                  _tableField(t.releaseFlat?.toString() ?? '', (v) { _tiers[i] = FeeTier(minAmount: _tiers[i].minAmount, maxAmount: _tiers[i].maxAmount, transactionPercentage: _tiers[i].transactionPercentage, releasePercentage: _tiers[i].releasePercentage, transactionFlat: _tiers[i].transactionFlat, releaseFlat: v.isEmpty ? null : double.tryParse(v)); }, hint: 'Null'),
                  IconButton(icon: const Icon(Icons.delete, size: 16, color: Color(0xFFEF4444)), onPressed: () => setState(() => _tiers.removeAt(i))),
                ]);
              }),
            ],
          ),
        ]),
      ),
    ]);
  }

  Widget _field(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, isDense: true),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }
}
