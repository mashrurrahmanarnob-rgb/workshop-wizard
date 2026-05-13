import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

// ─── Data model ────────────────────────────────────────────────────────────────

class _ProfileData {
  final String fullName;
  final String email;
  final String role;
  final String memberSince;
  final String phoneNumber;
  final int workshopsAttended;
  final int proposalsSubmitted;

  const _ProfileData({
    required this.fullName,
    required this.email,
    required this.role,
    required this.memberSince,
    required this.phoneNumber,
    required this.workshopsAttended,
    required this.proposalsSubmitted,
  });
}

String _formatMemberSince(Timestamp? ts) {
  if (ts == null) return '—';
  final d = ts.toDate();
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return '${months[d.month - 1]} ${d.year}';
}

// ─── Screen ────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  final String role;
  final String email;

  const ProfileScreen({super.key, required this.role, required this.email});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<_ProfileData>? _future;
  int _refreshKey = 0; // ← forces FutureBuilder to fully rebuild on refresh

  @override
  void initState() {
    super.initState();
    _future = _fetchProfile();
  }

  Future<_ProfileData> _fetchProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not logged in');

    final fs = FirebaseFirestore.instance;

    final results = await Future.wait([
      fs.collection('users').doc(user.uid).get(),
      fs.collection('registrations').where('userId', isEqualTo: user.uid).count().get(),
      fs.collection('proposals').where('createdBy', isEqualTo: user.uid).count().get(),
    ]);

    final userDoc   = results[0] as DocumentSnapshot;
    final regCount  = (results[1] as AggregateQuerySnapshot).count ?? 0;
    final propCount = (results[2] as AggregateQuerySnapshot).count ?? 0;

    final data = userDoc.exists
        ? userDoc.data() as Map<String, dynamic>
        : <String, dynamic>{};

    return _ProfileData(
      fullName:           data['fullName']    as String? ?? widget.email.split('@').first,
      email:              data['email']       as String? ?? widget.email,
      role:               data['role']        as String? ?? widget.role,
      memberSince:        _formatMemberSince(data['createdAt'] as Timestamp?),
      phoneNumber:        data['phoneNumber'] as String? ?? '',
      workshopsAttended:  regCount,
      proposalsSubmitted: propCount,
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
      );
    }
  }

  Future<void> _showEditDialog(_ProfileData profile) async {
    final nameCtrl  = TextEditingController(text: profile.fullName);
    final phoneCtrl = TextEditingController(text: profile.phoneNumber);
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Edit Profile',
                style: TextStyle(fontWeight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                  setDlg(() => saving = true);
                  try {
                    final uid = FirebaseAuth.instance.currentUser!.uid;
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({
                      'fullName':    nameCtrl.text.trim(),
                      'phoneNumber': phoneCtrl.text.trim(),
                    });
                    // Just close dialog — parent handles refresh
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    setDlg(() => saving = false);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('Error saving: $e',
                              style: const TextStyle(color: Colors.white)),
                          backgroundColor: AppColors.admin,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  }
                },
                child: saving
                    ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    // Dialog fully closed — force complete FutureBuilder rebuild with new key
    if (mounted) {
      setState(() {
        _refreshKey++;
        _future = _fetchProfile();
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProfileData>(
      key: ValueKey(_refreshKey), // ← new key forces fresh rebuild each refresh
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            primary: false,
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final profile = snap.data ??
            _ProfileData(
              fullName:           widget.email.split('@').first,
              email:              widget.email,
              role:               widget.role,
              memberSince:        '—',
              phoneNumber:        '',
              workshopsAttended:  0,
              proposalsSubmitted: 0,
            );

        final roleColor = AppTheme.roleColor(profile.role);
        final initial   = profile.fullName.isNotEmpty
            ? profile.fullName[0].toUpperCase()
            : '?';

        return Scaffold(
          primary: false,
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // ── Header ────────────────────────────────────────────────
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Green top band
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.75),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('IEEE PES UTM',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500)),
                                  Text('My Profile',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white)),
                                  Text('Manage your account',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.settings_outlined,
                                    color: Colors.white, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // White profile card
                      Positioned(
                        top: 100, left: 20, right: 20,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 55, 20, 20),
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.07),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(profile.fullName,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark)),
                              const SizedBox(height: 4),
                              Text(profile.email,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textMedium)),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: roleColor.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_user,
                                        size: 14, color: roleColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${profile.role[0].toUpperCase()}${profile.role.substring(1)} Member',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: roleColor,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Avatar
                      Positioned(
                        top: 75,
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(initial,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 240),

                  // ── Account Information ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Account Information',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark)),
                        const SizedBox(height: 14),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _InfoTile(
                                  icon: Icons.person_outline,
                                  label: 'Full Name',
                                  value: profile.fullName),
                              const Divider(
                                  height: 1,
                                  indent: 52,
                                  color: AppColors.divider),
                              _InfoTile(
                                  icon: Icons.email_outlined,
                                  label: 'Email Address',
                                  value: profile.email),
                              const Divider(
                                  height: 1,
                                  indent: 52,
                                  color: AppColors.divider),
                              _InfoTile(
                                  icon: Icons.badge_outlined,
                                  label: 'Role',
                                  value:
                                  '${profile.role[0].toUpperCase()}${profile.role.substring(1)} Member'),
                              const Divider(
                                  height: 1,
                                  indent: 52,
                                  color: AppColors.divider),
                              _InfoTile(
                                  icon: Icons.calendar_today_outlined,
                                  label: 'Member Since',
                                  value: profile.memberSince),
                              if (profile.phoneNumber.isNotEmpty) ...[
                                const Divider(
                                    height: 1,
                                    indent: 52,
                                    color: AppColors.divider),
                                _InfoTile(
                                    icon: Icons.phone_outlined,
                                    label: 'Phone',
                                    value: profile.phoneNumber),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Edit Profile button ───────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await _showEditDialog(profile);
                            },
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit Profile'),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Logout button ─────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout,
                                size: 18, color: AppColors.admin),
                            label: const Text('Logout'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.admin,
                              side: const BorderSide(
                                  color: AppColors.admin, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Helpers ───────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMedium),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark)),
            ],
          ),
        ],
      ),
    );
  }
}