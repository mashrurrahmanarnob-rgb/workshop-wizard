import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FeedbackListScreen extends StatefulWidget {
  const FeedbackListScreen({super.key});

  @override
  State<FeedbackListScreen> createState() => _FeedbackListScreenState();
}

class _FeedbackListScreenState extends State<FeedbackListScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Student Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: ['All', 'Pending', 'Resolved', 'Rejected'].map((f) {
                final isSelected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _filter = f),
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getStream(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const _EmptyState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return _FeedbackCard(id: docs[i].id, data: data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getStream() {
    Query query = FirebaseFirestore.instance.collection('feedback').orderBy('createdAt', descending: true);
    if (_filter != 'All') {
      query = query.where('status', isEqualTo: _filter);
    }
    return query.snapshots();
  }
}

class _FeedbackCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  const _FeedbackCard({required this.id, required this.data});

  @override
  Widget build(BuildContext context) {
    final subject = data['subject'] ?? 'No Subject';
    final email = data['studentEmail'] ?? 'Anonymous';
    final status = data['status'] ?? 'Pending';
    final priority = data['priority'] ?? 'Medium';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(priority).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(priority, style: TextStyle(color: _getPriorityColor(priority), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Text(status, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (status == 'Pending')
                TextButton(
                  onPressed: () {
                    FirebaseFirestore.instance.collection('feedback').doc(id).update({'status': 'Resolved'});
                  },
                  child: const Text('Resolve'),
                ),
            ],
          )
        ],
      ),
    );
  }

  Color _getPriorityColor(String p) {
    if (p == 'High') return Colors.red;
    if (p == 'Medium') return Colors.orange;
    return Colors.green;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No feedback found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('No feedback has been submitted yet', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
