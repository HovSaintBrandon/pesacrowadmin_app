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
import '../mpesa/mpesa_query_logs_page.dart';
import '../disbursement/disbursement_page.dart';
import '../admin_management/admin_management_page.dart';
import '../audit_logs/audit_logs_page.dart';
import '../users/users_page.dart';
import '../financials/financials_page.dart';
import '../announcements/announcements_page.dart';
import '../config/system_config_page.dart';
import '../platforms/go_live_queue_page.dart';
import '../platforms/platforms_list_page.dart';


class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;
  bool _sidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final permissions = currentUser?.permissions ?? [];

    final allTabs = [
      {'item': const _NavItem(Icons.dashboard_outlined, 'Dashboard'), 'page': const DashboardPage(), 'perm': 'view_dashboard'},
      {'item': const _NavItem(Icons.account_balance_outlined, 'Org Balances'), 'page': const OrgBalancesPage(), 'perm': 'view_mpesa_balance'},
      {'item': const _NavItem(Icons.insights_outlined, 'Finance'), 'page': const FinancialsPage(), 'perm': 'view_revenue'},
      {'item': const _NavItem(Icons.group_outlined, 'Users'), 'page': const UsersPage(), 'perm': 'freeze_account'},
      {'item': const _NavItem(Icons.queue_play_next_outlined, 'Go-Live Queue'), 'page': const GoLiveQueuePage(), 'perm': 'manage_go_live'},
      {'item': const _NavItem(Icons.business_center_outlined, 'Platforms'), 'page': const PlatformsListPage(), 'perm': 'view_platforms'},
      {'item': const _NavItem(Icons.receipt_long_outlined, 'Transactions'), 'page': const TransactionsPage(), 'perm': 'manage_transactions'},
      {'item': const _NavItem(Icons.gavel_outlined, 'Disputes'), 'page': const DisputesPage(), 'perm': 'resolve_disputes'},
      {'item': const _NavItem(Icons.campaign_outlined, 'Announcements'), 'page': const AnnouncementsPage(), 'perm': 'manage_announcements'},
      {'item': const _NavItem(Icons.tune_outlined, 'Fee Management'), 'page': const FeesPage(), 'perm': 'manage_fees'},
      {'item': const _NavItem(Icons.block_outlined, 'Blacklist'), 'page': const BlacklistPage(), 'perm': 'manage_blacklist'},
      {'item': const _NavItem(Icons.phone_android_outlined, 'M-Pesa Tools'), 'page': const MpesaToolsPage(), 'perm': 'manage_mpesa'},
      {'item': const _NavItem(Icons.list_alt_outlined, 'M-Pesa Logs'), 'page': const MpesaQueryLogsPage(), 'perm': 'manage_mpesa'},
      {'item': const _NavItem(Icons.send_outlined, 'Disbursement'), 'page': const DisbursementPage(), 'perm': 'manual_payouts'},
      {'item': const _NavItem(Icons.admin_panel_settings_outlined, 'Admin Management'), 'page': const AdminManagementPage(), 'perm': 'manage_admins'},
      {'item': const _NavItem(Icons.settings_outlined, 'System Settings'), 'page': const SystemConfigPage(), 'perm': 'manage_webhooks'},
      {'item': const _NavItem(Icons.history_outlined, 'Audit Logs'), 'page': const AuditLogsPage(), 'perm': 'audit_logs'},
    ];

    // Some items might share permissions or have multiple valid ones
    final availableTabs = allTabs.where((t) {
      if (permissions.contains('*') || currentUser?.role == 'super_admin') return true;
      
      final p = t['perm'] as String;
      if (p == 'manage_webhooks') {
         return permissions.contains('manage_webhooks') || permissions.contains('configure_otp') || permissions.contains('view_system_health');
      }
      if (p == 'view_platforms' || p == 'manage_go_live') {
        return permissions.contains('view_platforms') || 
               permissions.contains('manage_platforms') || 
               permissions.contains('manage_go_live');
      }
      
      return permissions.contains(p);
    }).toList();

    if (availableTabs.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('You have no permissions assigned. Please contact the administrator.',
                  style: TextStyle(color: Colors.redAccent, fontSize: 16)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.read<AuthProvider>().logout(),
                child: const Text('Logout'),
              )
            ],
          ),
        ),
      );
    }

    if (_selectedIndex >= availableTabs.length) {
      // Defer state update to avoid 'setState() or markNeedsBuild() called during build'
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = 0);
      });
    }

    final activeIndex = _selectedIndex >= availableTabs.length ? 0 : _selectedIndex;
    final pages = availableTabs.map((t) => t['page'] as Widget).toList();
    final navItems = availableTabs.map((t) => t['item'] as _NavItem).toList();


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
                itemCount: navItems.length,
                itemBuilder: (ctx, i) {
                  final item = navItems[i];
                  final selected = activeIndex == i;
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
                Text(navItems[activeIndex].label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                if (currentUser != null) ...[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(currentUser.name, 
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      Text(currentUser.role.replaceAll('_', ' ').toUpperCase(), 
                          style: const TextStyle(fontSize: 10, color: Color(0xFF10B981))),
                    ],
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF1E3A5F),
                    child: Text(
                      currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Builder(builder: (ctx) {
                  print('🧭 AdminShell: Switching to \${navItems[activeIndex].label}');
                  return pages[activeIndex];
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
