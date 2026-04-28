import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/activity_service.dart';

// ─── Available roles ───────────────────────────────────────────────────────────

const _roles = [
  'student',
  'committee',
  'treasurer',
  'president'
];

// ─── Badge color helper ────────────────────────────────────────────────────────

Color _badgeColor(String role) {
  switch (role.toLowerCase()) {
    case 'student':   return AppColors.student;
    case 'committee': return AppColors.committee;
    case 'president': return AppColors.president;
    case 'treasurer': return AppColors.primary;
    case 'admin':     return AppColors.admin;
    default:          return AppColors.primary; // approver / other
  }
}

String _roleLabel(String role) =>
    role.isEmpty ? role : role[0].toUpperCase() + role.substring(1).toLowerCase();

// ─── Screen ───────────────────────────────────────────────────────────────────

class RoleManagementScreen extends StatefulWidget {
  final bool showBackButton;
  const RoleManagementScreen({super.key, this.showBackButton = false});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Custom header ──────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('IEEE PES UTM',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w500)),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shield_outlined,
                            color: AppColors.primary, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Back + title row
                  Row(
                    children: [
                      if (widget.showBackButton)                        // ← only show when pushed
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back,
                              color: AppColors.textDark, size: 22),
                        ),
                      if (widget.showBackButton) const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Role Management',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                          Text('Assign user roles and permissions', style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Green accent line
                  Container(height: 3, color: AppColors.primary),
                ],
              ),
            ),

            // ── Search bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                decoration: InputDecoration(
                  hintText: 'Search by name or email',
                  hintStyle: const TextStyle(
                      color: AppColors.textLight, fontSize: 14),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textMedium, size: 20),
                  filled: true,
                  fillColor: AppColors.inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Firestore user list ────────────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text('Error: ${snap.error}',
                          style: const TextStyle(color: AppColors.textMedium)),
                    );
                  }

                  // Filter out the current admin and apply search
                  final q = _query.toLowerCase();
                  final docs = (snap.data?.docs ?? []).where((doc) {
                    if (doc.id == adminUid) return false;
                    final d = doc.data() as Map<String, dynamic>;
                    final name  = (d['fullName'] as String? ?? '').toLowerCase();
                    final email = (d['email']    as String? ?? '').toLowerCase();
                    if (q.isEmpty) return true;
                    return name.contains(q) || email.contains(q);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No users found',
                          style: TextStyle(color: AppColors.textMedium)),
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 4),
                    itemCount: docs.length,
                    separatorBuilder: (_, idx) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final doc  = docs[i];
                      final data = doc.data() as Map<String, dynamic>;
                      return _UserCard(
                        docId: doc.id,
                        fullName: data['fullName'] as String? ?? '(No Name)',
                        email:    data['email']    as String? ?? '',
                        role:     data['role']     as String? ?? 'student',
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
}

// ─── User Card ─────────────────────────────────────────────────────────────────

class _UserCard extends StatefulWidget {
  final String docId;
  final String fullName;
  final String email;
  final String role;

  const _UserCard({
    required this.docId,
    required this.fullName,
    required this.email,
    required this.role,
  });

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  late String _currentRole;

  @override
  void initState() {
    super.initState();
    _currentRole = widget.role.toLowerCase();
    // Normalise to one of the 3 dropdown options; fallback to 'student'
    if (!_roles.contains(_currentRole)) _currentRole = 'student';
  }

  Future<void> _updateRole(String newRole) async {
    setState(() => _currentRole = newRole);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.docId)
          .update({'role': newRole});
      logActivity('Role updated', '${widget.fullName} changed to ${_roleLabel(newRole)}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Role updated successfully',
                    style: TextStyle(fontSize: 13, color: Colors.white)),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Roll back on error
      if (mounted) {
        setState(() => _currentRole = widget.role.toLowerCase());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e',
                style: const TextStyle(fontSize: 13, color: Colors.white)),
            backgroundColor: AppColors.admin,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.fullName.isNotEmpty
        ? widget.fullName[0].toUpperCase()
        : '?';
    final color = _badgeColor(_currentRole);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: AppColors.primary, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name row
            Row(
              children: [
                // Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(initial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                // Name + email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.fullName,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                      const SizedBox(height: 2),
                      Text(widget.email,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMedium)),
                    ],
                  ),
                ),
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(_roleLabel(_currentRole),
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Role dropdown
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _currentRole,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: AppColors.textMedium, size: 20),
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500),
                  items: _roles
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Row(
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _badgeColor(r),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(_roleLabel(r)),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (newRole) {
                    if (newRole != null && newRole != _currentRole) {
                      _updateRole(newRole);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
