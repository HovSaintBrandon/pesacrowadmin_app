import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils.dart';
import '../../providers/admin_management_provider.dart';
import '../../providers/auth_provider.dart';

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminManagementProvider>().fetchAuditLogs(limit: 50);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<AdminManagementProvider>().fetchAuditLogs(
            limit: 50,
            action: query.trim().toUpperCase(),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AdminManagementProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Audit Logs',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by Action (e.g. LOGIN, BAN_PHONE)',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF141E33),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: () => context.read<AdminManagementProvider>().fetchAuditLogs(
                    limit: 50,
                    action: _searchController.text.trim().toUpperCase(),
                  ),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () async {
                 final url = await context.read<AdminManagementProvider>().exportAuditLogs();
                 if (url != null) {
                   AppUtils.showSnackBar(context, 'Export generated');
                 } else {
                   AppUtils.showSnackBar(context, context.read<AdminManagementProvider>().error ?? 'Export failed', isError: true);
                 }
              },
              icon: const Icon(Icons.download, size: 16, color: Color(0xFF10B981)),
              label: const Text('Export CSV', style: TextStyle(color: Color(0xFF10B981))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF10B981)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: AppUtils.buildCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    border: Border(bottom: BorderSide(color: Color(0xFF1E3A5F))),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text('ACTION',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('PERFORMED BY',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text('DETAILS',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('TIME',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5)),
                      ),
                      const SizedBox(width: 40), // Space for delete icon
                    ],
                  ),
                ),
                Expanded(
                  child: p.isLoading && p.auditLogs.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : p.auditLogs.isEmpty
                          ? const Center(
                              child: Text('No audit logs found',
                                  style: TextStyle(color: Color(0xFF94A3B8))))
                          : RefreshIndicator(
                              onRefresh: () =>
                                  context.read<AdminManagementProvider>().fetchAuditLogs(
                                        limit: 50,
                                        action: _searchController.text.trim().toUpperCase(),
                                      ),
                              child: ListView.builder(
                                itemCount: p.auditLogs.length,
                                itemBuilder: (ctx, i) {
                                  final log = p.auditLogs[i];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    decoration: const BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(color: Color(0xFF1E3A5F))),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3B82F6).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: Text(log.action,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF3B82F6),
                                                    fontWeight: FontWeight.w600)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 2,
                                          child: Text(log.performedBy,
                                              style: const TextStyle(
                                                  fontSize: 13, color: Color(0xFF94A3B8))),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            log.details?.toString() ?? '—',
                                            style: const TextStyle(
                                                fontSize: 12, color: Color(0xFF64748B)),
                                            maxLines: 6,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '${log.createdAt.hour.toString().padLeft(2, '0')}:${log.createdAt.minute.toString().padLeft(2, '0')} · '
                                            '${log.createdAt.day}/${log.createdAt.month}/${log.createdAt.year}',
                                            style: const TextStyle(
                                                fontSize: 11, color: Color(0xFF64748B)),
                                          ),
                                        ),
                                        if (context.read<AuthProvider>().currentUser?.role == 'super_admin')
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                                            onPressed: () async {
                                              final ok = await p.deleteAuditLog(log.id);
                                              if (ok) {
                                                AppUtils.showSnackBar(context, 'Log deleted');
                                              } else {
                                                AppUtils.showSnackBar(context, p.error ?? 'Failed to delete log', isError: true);
                                              }
                                            },
                                          )
                                        else
                                          const SizedBox(width: 40),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
