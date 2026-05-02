import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:onestopsolutions/core/network/api_client.dart';

class AllUsersScreen extends StatefulWidget {
  const AllUsersScreen({super.key});
  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  List<dynamic> users = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final res = await ApiClient.get('/api/auth/all-users');
      if (res.statusCode == 200) {
        if (!mounted) return;
        setState(() { users = jsonDecode(res.body); loading = false; });
      } else {
        if (!mounted) return;
        setState(() { error = 'Failed to load users (${res.statusCode})'; loading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { error = 'Network error: $e'; loading = false; });
    }
  }

  Color _roleColor(String role) {
    switch (role.toUpperCase()) {
      case 'SUPERADMIN': return Colors.purple;
      case 'ADMIN': return Colors.blue;
      case 'STAFF': return Colors.green;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Users'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : users.isEmpty
                  ? const Center(child: Text('No users found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      itemBuilder: (context, i) {
                        final u = users[i];
                        final role = u['role']?.toString() ?? 'STAFF';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _roleColor(role).withOpacity(0.15),
                              child: Text(
                                (u['name']?.toString() ?? '?').substring(0, 1).toUpperCase(),
                                style: TextStyle(fontWeight: FontWeight.bold, color: _roleColor(role)),
                              ),
                            ),
                            title: Text(u['name']?.toString() ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(u['email']?.toString() ?? ''),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _roleColor(role).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _roleColor(role).withOpacity(0.4)),
                              ),
                              child: Text(role,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _roleColor(role))),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
