import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../core/utils.dart';
import '../../core/notifications.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchFrozenUsers();
    });
  }

  void _searchUser() {
    final phone = _searchController.text.trim();
    if (phone.isEmpty) return;
    context.read<UserProvider>().lookupUser(phone);
  }

  void _showFreezeDialog(String phone) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Freeze Account'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for freezing',
            hintText: 'e.g. Unusual activity',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final ok = await context.read<UserProvider>().freezeUser(phone, reasonController.text);
              Navigator.pop(ctx);
              if (ok) {
                AppNotifications.showSuccess(context, 'Account frozen successfully');
              } else {
                final error = context.read<UserProvider>().error;
                AppNotifications.showError(context, error ?? 'Failed to freeze account');
              }
            },
            child: const Text('Freeze'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('User Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Search users and manage account status.', style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 24),

          // Search Card
          AppUtils.buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('User Lookup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Enter phone number (e.g. 0712...)',
                          prefixIcon: Icon(Icons.search, size: 20),
                        ),
                        onSubmitted: (_) => _searchUser(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: userProvider.isLoading ? null : _searchUser,
                      child: const Text('Search'),
                    ),
                  ],
                ),
                if (userProvider.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (userProvider.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(userProvider.error!, style: const TextStyle(color: Colors.redAccent)),
                  ),
                if (userProvider.searchedUser != null) ...[
                  const SizedBox(height: 24),
                  _buildUserResult(userProvider.searchedUser!),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Text('Frozen Accounts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (userProvider.frozenUsers.isEmpty && !userProvider.isLoading)
            const Text('No frozen accounts found.', style: TextStyle(color: Color(0xFF64748B)))
          else
            _buildFrozenList(userProvider.frozenUsers),
        ],
      ),
    );
  }

  Widget _buildUserResult(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
            child: const Icon(Icons.person_outline, color: Color(0xFF10B981), size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(user.phone, style: const TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildTag('Deals: ${user.dealCount}', Colors.blueAccent),
                    const SizedBox(width: 8),
                    _buildTag(user.isFrozen ? 'FROZEN' : 'ACTIVE', user.isFrozen ? Colors.redAccent : Colors.greenAccent),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              if (user.isFrozen)
                ElevatedButton(
                  onPressed: () async {
                    final ok = await context.read<UserProvider>().unfreezeUser(user.phone);
                    if (ok) {
                      AppNotifications.showSuccess(context, 'Account unfrozen');
                      context.read<UserProvider>().fetchFrozenUsers();
                    } else {
                      AppNotifications.showError(context, context.read<UserProvider>().error ?? 'Failed to unfreeze');
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                  child: const Text('Unfreeze'),
                )
              else
                ElevatedButton(
                  onPressed: () => _showFreezeDialog(user.phone),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  child: const Text('Freeze Account'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrozenList(List<dynamic> users) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (ctx, i) {
        final user = users[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.block, color: Colors.redAccent),
            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${user.phone} • ${user.freezeReason ?? "No reason provided"}'),
            trailing: TextButton(
              onPressed: () async {
                final ok = await context.read<UserProvider>().unfreezeUser(user.phone);
                if (ok) {
                  AppNotifications.showSuccess(context, 'Account unfrozen');
                  context.read<UserProvider>().fetchFrozenUsers();
                } else {
                  AppNotifications.showError(context, context.read<UserProvider>().error ?? 'Failed to unfreeze');
                }
              },
              child: const Text('Unfreeze'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
