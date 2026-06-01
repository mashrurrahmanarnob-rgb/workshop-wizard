import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

class EventRegistrationScreen extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;
  const EventRegistrationScreen({super.key, required this.eventId, required this.eventData});

  @override
  State<EventRegistrationScreen> createState() => _EventRegistrationScreenState();
}

class _EventRegistrationScreenState extends State<EventRegistrationScreen> {
  int _step = 1;
  bool _submitting = false;

  // Step 1 controllers
  final _nameCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _department;

  // Step 2
  String? _receiptBase64;
  final _picker = ImagePicker();

  final _departments = [
    'Electrical Engineering',
    'Mechanical Engineering',
    'Civil Engineering',
    'Chemical Engineering',
    'Computer Science',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill email from auth
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) _emailCtrl.text = user!.email!;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _studentIdCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool get _step1Valid =>
      _nameCtrl.text.trim().isNotEmpty &&
      _studentIdCtrl.text.trim().isNotEmpty &&
      _emailCtrl.text.trim().isNotEmpty &&
      _phoneCtrl.text.trim().isNotEmpty &&
      _department != null;

  bool get _step2Valid => _receiptBase64 != null || _isFreeEvent;

  bool get _isFreeEvent {
    final fee = (widget.eventData['fee'] as num?)?.toDouble() ?? 0;
    final isFree = widget.eventData['isFree'] as bool? ?? (fee == 0);
    return isFree || fee == 0;
  }

  double get _eventFee => (widget.eventData['fee'] as num?)?.toDouble() ?? 0;

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1024,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected image is too large. Please choose a file under 5MB.')),
          );
        }
        return;
      }
      setState(() {
        _receiptBase64 = base64Encode(bytes);
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload payment image: $error')),
        );
      }
    }
  }

  void _removeImage() => setState(() { _receiptBase64 = null; });

  Future<void> _submit() async {
    if (!_step2Valid) return;
    setState(() => _submitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final batch = FirebaseFirestore.instance.batch();

      // Create registration doc
      final regRef = FirebaseFirestore.instance.collection('event_registrations').doc();
      batch.set(regRef, {
        'eventId': widget.eventId,
        'eventName': widget.eventData['title'] as String? ?? '',
        'userId': uid,
        'studentName': _nameCtrl.text.trim(),
        'studentId': _studentIdCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'department': _department,
        'amount': _eventFee,
        'paymentProofUrl': _receiptBase64 ?? '',
        'status': 'pending',
        'paymentStatus': _isFreeEvent ? 'free' : 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Also write to payments collection for treasurer compatibility
      final payRef = FirebaseFirestore.instance.collection('payments').doc();
      batch.set(payRef, {
        'eventId': widget.eventId,
        'eventName': widget.eventData['title'] as String? ?? '',
        'workshopName': widget.eventData['title'] as String? ?? '',
        'studentName': _nameCtrl.text.trim(),
        'studentId': _studentIdCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'department': _department,
        'amount': _eventFee,
        'paymentProofUrl': _receiptBase64 ?? '',
        'status': 'pending',
        'userId': uid,
        'matrixNo': _studentIdCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Increment event registration count
      final eventRef = FirebaseFirestore.instance.collection('events').doc(widget.eventId);
      batch.update(eventRef, {'registrationCount': FieldValue.increment(1)});

      await batch.commit();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.primary),
                SizedBox(width: 10),
                Text('Registration Submitted'),
              ],
            ),
            content: const Text('Your registration has been submitted successfully. You will receive a confirmation once your payment is verified.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // close registration
                  Navigator.pop(context); // close event detail
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.admin),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventTitle = widget.eventData['title'] as String? ?? '(Untitled)';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back, color: AppColors.textDark),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_step == 1 ? 'Event Registration' : 'Payment', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            Text('Step $_step of 2', style: const TextStyle(fontSize: 12, color: AppColors.textMedium, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _stepDot(1, 'Info'),
                  Expanded(child: Divider(color: _step >= 2 ? AppColors.primary : AppColors.divider, thickness: 2)),
                  _stepDot(2, 'Payment'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _step == 1 ? _buildStep1() : _buildStep2(eventTitle),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _step == 1
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _step1Valid ? () => setState(() => _step = 2) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Continue to Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _step = 1),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textMedium,
                              side: const BorderSide(color: AppColors.divider),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _submitting || !_step2Valid ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _submitting
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Submit Registration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepDot(int step, String label) {
    final isActive = _step >= step;
    return Column(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.divider,
            shape: BoxShape.circle,
          ),
          child: Center(child: Text('$step', style: TextStyle(color: isActive ? Colors.white : AppColors.textMedium, fontSize: 13, fontWeight: FontWeight.w700))),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: isActive ? AppColors.primary : AppColors.textMedium, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 16),
        _label('Full Name *'),
        _textField(_nameCtrl, 'Enter your full name', Icons.person_outline),
        const SizedBox(height: 14),
        _label('Student ID *'),
        _textField(_studentIdCtrl, 'e.g., A12345678', Icons.badge_outlined),
        const SizedBox(height: 14),
        _label('Email *'),
        _textField(_emailCtrl, 'your.email@example.com', Icons.email_outlined, keyboard: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _label('Phone Number *'),
        _textField(_phoneCtrl, '+60 12-345-6789', Icons.phone_outlined, keyboard: TextInputType.phone),
        const SizedBox(height: 14),
        _label('Department *'),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _department,
            hint: const Text('Select your department', style: TextStyle(color: AppColors.textLight)),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (v) => setState(() => _department = v),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStep2(String eventTitle) {
    if (_isFreeEvent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.celebration, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(child: Text('This event is free! No payment required.', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _infoCard('Event', eventTitle),
          const SizedBox(height: 12),
          _infoCard('Amount', 'Free'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.student.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.student.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Payment Instructions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 8),
              Text('1. Transfer RM ${_eventFee.toStringAsFixed(2)} to the account below', style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.6)),
              const Text('2. Take a screenshot or photo of the payment receipt', style: TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.6)),
              const Text('3. Upload the proof of payment below', style: TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.6)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Bank details
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bank Transfer Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 12),
              _bankRow('Bank Name', 'Maybank'),
              _bankRow('Account Name', 'IEEE PES UTM Student Chapter'),
              _bankRow('Account Number', '1234567890'),
              _bankRow('Amount', 'RM ${_eventFee.toStringAsFixed(2)}', isAmount: true),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Upload area
        _label('Upload Payment Proof *'),
        const SizedBox(height: 8),
        if (_receiptBase64 != null) ...[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: [
                Image.memory(base64Decode(_receiptBase64!), fit: BoxFit.cover, width: double.infinity),
                const Divider(height: 1),
                TextButton.icon(
                  onPressed: _removeImage,
                  icon: const Icon(Icons.delete_outline, color: AppColors.admin, size: 18),
                  label: const Text('Remove and upload different image', style: TextStyle(color: AppColors.admin)),
                ),
              ],
            ),
          ),
        ] else
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: AppColors.student.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.student.withValues(alpha: 0.3), style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.student.withValues(alpha: 0.6)),
                  const SizedBox(height: 10),
                  const Text('Click to upload payment receipt', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('PNG or JPG only (Max 5MB)', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark));

  Widget _textField(TextEditingController ctrl, String hint, IconData icon, {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textLight),
        prefixIcon: Icon(icon, color: AppColors.textLight, size: 20),
        filled: true,
        fillColor: AppColors.inputBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _bankRow(String label, String value, {bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 15, fontWeight: isAmount ? FontWeight.w800 : FontWeight.w700, color: isAmount ? AppColors.primary : AppColors.textDark)),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        ],
      ),
    );
  }
}
