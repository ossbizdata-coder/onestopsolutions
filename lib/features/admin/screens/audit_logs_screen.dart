import 'package:flutter/material.dart';

class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple.shade700,
        title: const Text('Audit Logs'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.security, size: 64, color: Colors.purple.shade700),
              ),
              const SizedBox(height: 24),
              const Text('Audit Logs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Full system activity trail. View all user actions including logins, transactions, edits, and deletions.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: const Text('API: /api/audit-logs',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.blueAccent)),
              ),
              const SizedBox(height: 32),
              const Chip(
                avatar: Icon(Icons.build_circle_outlined, size: 16),
                label: Text('Full implementation — connect backend API'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

