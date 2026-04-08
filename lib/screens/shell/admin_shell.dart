import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../dashboard/dashboard_page.dart';
import '../transactions/transactions_page.dart';
import '../disputes/disputes_page.dart';
import '../fees/fees_page.dart';
import '../blacklist/blacklist_page.dart';
import '../mpesa/mpesa_tools_page.dart';
import '../mpesa/org_balances_page.dart';
import '../disbursement/disbursement_page.dart';
import '../admin_management/admin_management_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;
  bool _sidebarExpanded = true;

  static const _navItems = [
    _NavItem(Icons.dashboard_outlined, 'Dashboard'),
    _NavItem(Icons.account_balance_outlined, 'Org Balances'),
    _NavItem(Icons.receipt_long_outlined, 'Transactions'),
    _NavItem(Icons.gavel_outlined, 'Disputes'),
    _NavItem(Icons.tune_outlined, 'Fee Management'),
    _NavItem(Icons.block_outlined, 'Blacklist'),
    _NavItem(Icons.phone_android_outlined, 'M-Pesa Tools'),
    _NavItem(Icons.send_outlined, 'Disbursement'),
    _NavItem(Icons.admin_panel_settings_outlined, 'Admin Management'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardPage(),
      const OrgBalancesPage(),
      const TransactionsPage(),
      const DisputesPage(),
      const FeesPage(),
      const BlacklistPage(),
      const MpesaToolsPage(),
      const DisbursementPage(),
      const AdminManagementPage(),
    ];

    return Scaffold(
      body: Row(children: [
        // Sidebar
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: _sidebarExpanded ? 240 : 64,
          decoration: const BoxDecoration(
            color: Color(0xFF0B1120),
            border: Border(right: BorderSide(color: Color(0xFF1E3A5F))),
          ),
          child: Column(children: [
            // Logo
            Container(
              height: 56,
              padding: EdgeInsets.symmetric(horizontal: _sidebarExpanded ? 16 : 12),
              child: Row(children: [
                Image.asset(
                  'assets/mpesacrowlogo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
                if (_sidebarExpanded) ...[
                  const SizedBox(width: 10),
                  const Text('PesaCrow',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ]),
            ),
            const Divider(height: 1, color: Color(0xFF1E3A5F)),
            // Nav items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _navItems.length,
                itemBuilder: (ctx, i) {
                  final item = _navItems[i];
                  final selected = _selectedIndex == i;
                  return Tooltip(
                    message: _sidebarExpanded ? '' : item.label,
                    child: InkWell(
                      onTap: () => setState(() => _selectedIndex = i),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        padding: EdgeInsets.symmetric(
                            horizontal: _sidebarExpanded ? 12 : 0, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF10B981).withOpacity(0.1) : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: _sidebarExpanded
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          children: [
                            Icon(item.icon, size: 20,
                                color: selected
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF64748B)),
                            if (_sidebarExpanded) ...[
                              const SizedBox(width: 12),
                              Text(item.label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: selected
                                        ? const Color(0xFFE2E8F0)
                                        : const Color(0xFF64748B),
                                    fontWeight:
                                        selected ? FontWeight.w600 : FontWeight.normal,
                                  )),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Logout
            const Divider(height: 1, color: Color(0xFF1E3A5F)),
            InkWell(
              onTap: () => context.read<AuthProvider>().logout(),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: _sidebarExpanded ? 20 : 0, vertical: 16),
                child: Row(
                  mainAxisAlignment: _sidebarExpanded
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, size: 20, color: Color(0xFF64748B)),
                    if (_sidebarExpanded) ...[
                      const SizedBox(width: 12),
                      const Text('Logout',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                    ],
                  ],
                ),
              ),
            ),
          ]),
        ),
        // Main content
        Expanded(
          child: Column(children: [
            Container(
              height: 48,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1E3A5F))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                IconButton(
                  icon: Icon(_sidebarExpanded ? Icons.menu_open : Icons.menu,
                      color: const Color(0xFF64748B), size: 20),
                  onPressed: () =>
                      setState(() => _sidebarExpanded = !_sidebarExpanded),
                ),
                const SizedBox(width: 8),
                Text(_navItems[_selectedIndex].label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Builder(builder: (ctx) {
                  print('🧭 AdminShell: Switching to ${_navItems[_selectedIndex].label}');
                  return pages[_selectedIndex];
                }),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
