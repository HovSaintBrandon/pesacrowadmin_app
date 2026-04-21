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
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AdminManagementProvider>();
      p.fetchAdmins();
      p.fetchPermissions();
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
          Tab(text: 'My Account'),
        ],
      ),
      const SizedBox(height: 16),

      Expanded(
        child: TabBarView(
          controller: _tabs,
          children: [
            _AdminsTab(),
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
                  if (ok) {
                    AppUtils.showSnackBar(context, 'Admin account created');
                  } else {
                    AppUtils.showSnackBar(context, context.read<AdminManagementProvider>().error ?? 'Failed to create admin', isError: true);
                  }
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
              if (ok) {
                AppUtils.showSnackBar(context, 'Admin deleted successfully');
              } else {
                AppUtils.showSnackBar(context, context.read<AdminManagementProvider>().error ?? 'Failed to delete admin', isError: true);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPermissionsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental closing during sync
      builder: (ctx) => _PermissionsDialog(admin: admin),
    );
  }
}

class _PermissionsDialog extends StatefulWidget {
  final Admin admin;
  const _PermissionsDialog({required this.admin});

  @override
  State<_PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends State<_PermissionsDialog> {
  late List<String> _selected;
  final Set<String> _syncing = {};

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.admin.permissions);
  }

  Map<String, List<String>> _groupPermissions(List<String> perms) {
    final Map<String, List<String>> groups = {
      'General & Dashboard': [],
      'Transactions & Deals': [],
      'Users & Blacklist': [],
      'M-Pesa Operations': [],
      'System & Config': [],
      'Others': [],
    };

    for (var p in perms) {
      if (p.contains('dashboard') || p.contains('audit')) {
        groups['General & Dashboard']!.add(p);
      } else if (p.contains('transaction') || p.contains('dispute') || p.contains('fee')) {
        groups['Transactions & Deals']!.add(p);
      } else if (p.contains('user') || p.contains('blacklist') || p.contains('phone')) {
        groups['Users & Blacklist']!.add(p);
      } else if (p.contains('mpesa') || p.contains('disbursement') || p.contains('payout')) {
        groups['M-Pesa Operations']!.add(p);
      } else if (p.contains('config') || p.contains('webhook') || p.contains('otp') || p.contains('health') || p.contains('admin')) {
        groups['System & Config']!.add(p);
      } else {
        groups['Others']!.add(p);
      }
    }
    groups.removeWhere((k, v) => v.isEmpty);
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminManagementProvider>();
    final groups = _groupPermissions(provider.availablePermissions);

    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1E3A5F)),
      ),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF1E3A5F))),
        ),
        child: Row(
          children: [
            const Icon(Icons.security, color: Color(0xFF10B981), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Permissions — ${widget.admin.name}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(widget.admin.email,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.normal)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF64748B)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 520,
        height: 600,
        child: provider.isLoading && provider.availablePermissions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: groups.entries.map((entry) => _buildGroup(entry.key, entry.value)).toList(),
              ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      actions: [
        if (_syncing.isNotEmpty)
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 10),
              Text('Syncing changes...', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            ],
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildGroup(String title, List<String> permissions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              )),
        ),
        ...permissions.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (i * 50)),
            curve: Curves.easeOutCubic,
            builder: (ctx, val, child) => Transform.translate(
              offset: Offset(0, 20 * (1 - val)),
              child: Opacity(opacity: val, child: child),
            ),
            child: _buildPermissionItem(p),
          );
        }).toList(),
        const Divider(color: Color(0xFF1E3A5F), height: 32, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildPermissionItem(String p) {
    final isSelected = _selected.contains(p);
    final isSyncing = _syncing.contains(p);
    
    String label = p.replaceAll('_', ' ');
    label = label[0].toUpperCase() + label.substring(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: isSyncing ? null : () => _togglePermission(p),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10B981).withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                        )),
                    Text(p, style: const TextStyle(fontSize: 10, color: Color(0xFF475569))),
                  ],
                ),
              ),
              if (isSyncing)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              else
                Switch(
                  value: isSelected,
                  onChanged: (v) => _togglePermission(p),
                  activeColor: const Color(0xFF10B981),
                  activeTrackColor: const Color(0xFF10B981).withOpacity(0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _togglePermission(String p) async {
    final isAdding = !_selected.contains(p);
    
    setState(() {
      if (isAdding) {
        _selected.add(p);
      } else {
        _selected.remove(p);
      }
      _syncing.add(p);
    });

    final provider = context.read<AdminManagementProvider>();
    final ok = await provider.updateAdminPermissions(widget.admin.id, _selected);

    if (mounted) {
      setState(() {
        _syncing.remove(p);
        if (!ok) {
          // Revert if failed
          if (isAdding) {
            _selected.remove(p);
          } else {
            _selected.add(p);
          }
          AppUtils.showSnackBar(context, provider.error ?? 'Failed to update permission', isError: true);
        }
      });
    }
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
                  AppUtils.showSnackBar(context, 'Password updated successfully');
                } else {
                  AppUtils.showSnackBar(context, p.error ?? 'Failed to update password', isError: true);
                }
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
