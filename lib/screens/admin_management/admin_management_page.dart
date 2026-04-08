import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_management_provider.dart';
import '../../models/admin.dart';

class AdminManagementPage extends StatefulWidget {
  const AdminManagementPage({super.key});
  @override
  State<AdminManagementPage> createState() => _AdminManagementPageState();
}

class _AdminManagementPageState extends State<AdminManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    print('📱 Entering AdminManagementPage');
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AdminManagementProvider>();
      p.fetchAdmins();
      p.fetchPermissions();
      p.fetchAuditLogs();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Admin Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => _showCreateAdminDialog(context),
          icon: const Icon(Icons.person_add, size: 16),
          label: const Text('Create Admin'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ]),
      const SizedBox(height: 16),

      // Tabs
      TabBar(
        controller: _tabs,
        labelColor: const Color(0xFF10B981),
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: const Color(0xFF10B981),
        isScrollable: false,
        tabs: const [
          Tab(text: 'Admins'),
          Tab(text: 'Audit Logs'),
          Tab(text: 'My Account'),
        ],
      ),
      const SizedBox(height: 16),

      Expanded(
        child: TabBarView(
          controller: _tabs,
          children: [
            _AdminsTab(),
            _AuditLogsTab(),
            _MyAccountTab(),
          ],
        ),
      ),
    ]);
  }

  void _showCreateAdminDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'admin';
    List<String> selectedPerms = [];

    showDialog(
      context: context,
      builder: (ctx) {
        final provider = context.read<AdminManagementProvider>();
        return StatefulBuilder(
          builder: (ctx, setSt) => AlertDialog(
            backgroundColor: const Color(0xFF141E33),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Create Admin Account'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Expanded(child: _field(nameCtrl, 'Full Name', Icons.person)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(emailCtrl, 'Email', Icons.email)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _field(phoneCtrl, 'Phone (0712…)', Icons.phone)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(passCtrl, 'Temporary Password', Icons.lock,
                        obscure: true)),
                  ]),
                  const SizedBox(height: 12),
                  // Role selector
                  Row(children: [
                    const Text('Role:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                    const SizedBox(width: 12),
                    ...['admin', 'super_admin'].map((r) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(r),
                        selected: role == r,
                        onSelected: (_) => setSt(() => role = r),
                        selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: role == r ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    )),
                  ]),
                  // Permissions
                  if (provider.availablePermissions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Permissions',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: provider.availablePermissions.map((p) {
                        final sel = selectedPerms.contains(p);
                        return FilterChip(
                          label: Text(p, style: const TextStyle(fontSize: 11)),
                          selected: sel,
                          onSelected: (v) => setSt(() =>
                            v ? selectedPerms.add(p) : selectedPerms.remove(p)),
                          selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                          checkmarkColor: const Color(0xFF10B981),
                        );
                      }).toList(),
                    ),
                  ],
                ]),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty ||
                      phoneCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                    AppUtils.showSnackBar(context, 'Fill all required fields', isError: true);
                    return;
                  }
                  Navigator.pop(ctx);
                  final ok = await context.read<AdminManagementProvider>().createAdmin(
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    password: passCtrl.text,
                    role: role,
                  );
                  AppUtils.showSnackBar(context,
                      ok ? 'Admin account created' : 'Failed to create admin',
                      isError: !ok);
                },
                child: const Text('Create'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13),
    );
  }
}

// ─── Admins Tab ────────────────────────────────────────────────────────────────
class _AdminsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AdminManagementProvider>();

    if (p.isLoading && p.admins.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (p.admins.isEmpty) {
      return const Center(
        child: Text('No admins found', style: TextStyle(color: Color(0xFF94A3B8))),
      );
    }

    return AppUtils.buildCard(
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
            Expanded(flex: 2, child: Text('NAME / EMAIL',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B), letterSpacing: 0.5))),
            Expanded(flex: 1, child: Text('PHONE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B), letterSpacing: 0.5))),
            Expanded(flex: 1, child: Text('ROLE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B), letterSpacing: 0.5))),
            Expanded(flex: 3, child: Text('PERMISSIONS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B), letterSpacing: 0.5))),
            SizedBox(width: 96),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: p.admins.length,
            itemBuilder: (ctx, i) => _AdminRow(admin: p.admins[i]),
          ),
        ),
      ]),
    );
  }
}

class _AdminRow extends StatelessWidget {
  final Admin admin;
  const _AdminRow({required this.admin});

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = admin.role == 'super_admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E3A5F))),
      ),
      child: Row(children: [
        Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(admin.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          Text(admin.email, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        ])),
        Expanded(flex: 1, child: Text(AppUtils.formatPhone(admin.phone),
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)))),
        Expanded(flex: 1, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSuperAdmin
                ? const Color(0xFFEF4444).withOpacity(0.12)
                : const Color(0xFF3B82F6).withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            admin.role.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5,
              color: isSuperAdmin ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
            ),
          ),
        )),
        Expanded(flex: 3, child: Wrap(
          spacing: 4, runSpacing: 4,
          children: <Widget>[
            ...admin.permissions.take(3).map((perm) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(perm, style: const TextStyle(fontSize: 10, color: Color(0xFF10B981))),
            )),
            if (admin.permissions.length > 3)
              Text('+${admin.permissions.length - 3} more',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        )),
        SizedBox(
          width: 96,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                tooltip: 'Edit Permissions',
                onPressed: () => _showPermissionsDialog(context),
              ),
              _buildDeleteButton(context),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final me = auth.currentUser;
    if (me == null) return const SizedBox();

    // Guard: Self-deletion only — you cannot delete your own account
    if (admin.id == me.id) return const SizedBox(width: 40);

    return IconButton(
      icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
      tooltip: 'Delete Admin',
      onPressed: () => _confirmDelete(context),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141E33),
        title: const Text('Delete Admin Account?'),
        content: Text('Are you sure you want to permanently delete ${admin.name} (${admin.email})? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await context.read<AdminManagementProvider>().deleteAdmin(admin.id);
              AppUtils.showSnackBar(context, ok ? 'Admin deleted successfully' : 'Failed to delete admin', isError: !ok);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPermissionsDialog(BuildContext context) {
    final p = context.read<AdminManagementProvider>();
    List<String> selected = List.from(admin.permissions);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: const Color(0xFF141E33),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Permissions — ${admin.name}'),
          content: SizedBox(
            width: 480,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(admin.email, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              const SizedBox(height: 16),
              if (p.availablePermissions.isEmpty)
                const Text('No permissions available',
                    style: TextStyle(color: Color(0xFF94A3B8)))
              else
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: p.availablePermissions.map((perm) {
                    final sel = selected.contains(perm);
                    return FilterChip(
                      label: Text(perm, style: const TextStyle(fontSize: 11)),
                      selected: sel,
                      onSelected: (v) => setSt(() =>
                        v ? selected.add(perm) : selected.remove(perm)),
                      selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                      checkmarkColor: const Color(0xFF10B981),
                    );
                  }).toList(),
                ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await context.read<AdminManagementProvider>()
                    .updateAdminPermissions(admin.id, selected);
                AppUtils.showSnackBar(context,
                    ok ? 'Permissions updated' : 'Failed to update permissions',
                    isError: !ok);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Audit Logs Tab ────────────────────────────────────────────────────────────
class _AuditLogsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AdminManagementProvider>();

    if (p.isLoading && p.auditLogs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (p.auditLogs.isEmpty) {
      return const Center(
        child: Text('No audit logs', style: TextStyle(color: Color(0xFF94A3B8))),
      );
    }

    return AppUtils.buildCard(
      padding: EdgeInsets.zero,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            border: Border(bottom: BorderSide(color: Color(0xFF1E3A5F))),
          ),
          child: const Row(children: [
            Expanded(flex: 2, child: Text('ACTION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B), letterSpacing: 0.5))),
            Expanded(flex: 2, child: Text('PERFORMED BY',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B), letterSpacing: 0.5))),
            Expanded(flex: 3, child: Text('DETAILS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B), letterSpacing: 0.5))),
            Expanded(flex: 1, child: Text('TIME',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B), letterSpacing: 0.5))),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: p.auditLogs.length,
            itemBuilder: (ctx, i) {
              final log = p.auditLogs[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF1E3A5F))),
                ),
                child: Row(children: [
                  Expanded(flex: 2, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(log.action,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w600)),
                  )),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: Text(log.performedBy,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)))),
                  Expanded(flex: 3, child: Text(
                    log.details?.toString() ?? '—',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  )),
                  Expanded(flex: 1, child: Text(
                    '${log.createdAt.hour.toString().padLeft(2, '0')}:${log.createdAt.minute.toString().padLeft(2, '0')}\n'
                    '${log.createdAt.day}/${log.createdAt.month}/${log.createdAt.year}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  )),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ─── My Account Tab ────────────────────────────────────────────────────────────
class _MyAccountTab extends StatefulWidget {
  @override
  State<_MyAccountTab> createState() => _MyAccountTabState();
}

class _MyAccountTabState extends State<_MyAccountTab> {
  final _oldPass = TextEditingController();
  final _newPass = TextEditingController();
  final _confirmPass = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _oldPass.dispose();
    _newPass.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AdminManagementProvider>();

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppUtils.buildCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Change Password',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 20),
            _passField(_oldPass, 'Current Password', _obscureOld,
                () => setState(() => _obscureOld = !_obscureOld)),
            const SizedBox(height: 12),
            _passField(_newPass, 'New Password', _obscureNew,
                () => setState(() => _obscureNew = !_obscureNew)),
            const SizedBox(height: 12),
            _passField(_confirmPass, 'Confirm New Password', _obscureNew, null),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: p.isLoading ? null : () async {
                if (_oldPass.text.isEmpty || _newPass.text.isEmpty) {
                  AppUtils.showSnackBar(context, 'Fill all fields', isError: true);
                  return;
                }
                if (_newPass.text != _confirmPass.text) {
                  AppUtils.showSnackBar(context, 'Passwords do not match', isError: true);
                  return;
                }
                if (_newPass.text.length < 8) {
                  AppUtils.showSnackBar(context, 'Password must be at least 8 characters', isError: true);
                  return;
                }
                final ok = await p.changePassword(_oldPass.text, _newPass.text);
                if (ok) {
                  _oldPass.clear(); _newPass.clear(); _confirmPass.clear();
                }
                AppUtils.showSnackBar(context,
                    ok ? 'Password updated successfully' : 'Failed to update password',
                    isError: !ok);
              },
              child: p.isLoading
                  ? const SizedBox(height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Update Password'),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _passField(TextEditingController ctrl, String label, bool obscure, VoidCallback? onToggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, size: 18),
        suffixIcon: onToggle != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 18),
                onPressed: onToggle)
            : null,
      ),
    );
  }
}
