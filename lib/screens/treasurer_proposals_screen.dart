import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../theme/app_theme.dart';
import '../services/activity_service.dart';

// Local date formatter replicated from proposals_screen.dart
String _formatDate(Timestamp? ts) {
  if (ts == null) return 'Not submitted';
  final d = ts.toDate();
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

class TreasurerProposalsScreen extends StatefulWidget {
  final String role;
  const TreasurerProposalsScreen({super.key, required this.role});

  @override
  State<TreasurerProposalsScreen> createState() => _TreasurerProposalsScreenState();
}

class _TreasurerProposalsScreenState extends State<TreasurerProposalsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      primary: false,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('IEEE PES UTM', style: TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500)),
                  SizedBox(height: 6),
                  Text('Proposals', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  Text('Sign proposals as Treasurer', style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('proposals')
                    .where('status', isEqualTo: 'in_review')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) return const Center(child: Text('No proposals to sign'));
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: docs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (c, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final id = docs[i].id;
                      final title = d['title'] as String? ?? '(Untitled)';
                      final budget = (d['budget'] as num?)?.toStringAsFixed(2) ?? '0.00';
                      final date = _formatDate(d['date'] as Timestamp? ?? d['createdAt'] as Timestamp?);
                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark))),
                              Text('RM $budget', style: const TextStyle(color: AppColors.textMedium)),
                            ]),
                            const SizedBox(height: 8),
                            Text(date, style: const TextStyle(color: AppColors.textMedium)),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _openSignDialog(id, title),
                                  child: const Text('Sign as Treasurer'),
                                ),
                              ),
                            ])
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSignDialog(String id, String title) async {
    final SignatureController controller = SignatureController(penStrokeWidth: 2, penColor: Colors.black, exportBackgroundColor: Colors.white);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Treasurer Signature'),
        content: SizedBox(
          width: double.maxFinite,
          height: 240,
          child: Column(
            children: [
              Expanded(child: Signature(controller: controller, backgroundColor: Colors.white)),
              Row(children: [
                TextButton(onPressed: () => controller.clear(), child: const Text('Clear')),
                const Spacer(),
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
              ])
            ],
          ),
        ),
      ),
    );

    if (saved != true) return;
    try {
      final png = await controller.toPngBytes();
      if (png == null) return;
      final sig = base64Encode(png);
      await FirebaseFirestore.instance.collection('proposals').doc(id).update({
        'treasurerSignature': sig,
        'treasurerSignedBy': FirebaseAuth.instance.currentUser?.uid,
        'treasurerSignedAt': FieldValue.serverTimestamp(),
        'status': 'treasurer_signed',
      });
      await logActivity('Proposal signed by Treasurer', title);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed as Treasurer')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
