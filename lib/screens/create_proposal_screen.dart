import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../theme/app_theme.dart';
import '../services/activity_service.dart';

class CreateProposalScreen extends StatefulWidget {
  final String email;
  const CreateProposalScreen({super.key, required this.email});

  @override
  State<CreateProposalScreen> createState() => _CreateProposalScreenState();
}

class _CreateProposalScreenState extends State<CreateProposalScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form Controllers
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _objectivesCtrl = TextEditingController();
  final _audienceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _participantsCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController(text: '0.00');
  final _breakdownCtrl = TextEditingController();
  final _materialsCtrl = TextEditingController();
  final _facNameCtrl = TextEditingController();
  final _facEmailCtrl = TextEditingController();
  final _facPhoneCtrl = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Signature Controller
  final SignatureController _sigCtrl = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _objectivesCtrl.dispose();
    _audienceCtrl.dispose();
    _durationCtrl.dispose();
    _locationCtrl.dispose();
    _participantsCtrl.dispose();
    _budgetCtrl.dispose();
    _breakdownCtrl.dispose();
    _materialsCtrl.dispose();
    _facNameCtrl.dispose();
    _facEmailCtrl.dispose();
    _facPhoneCtrl.dispose();
    _sigCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      _showError('Please select date and time');
      return;
    }
    if (_sigCtrl.isEmpty) {
      _showError('Signature is required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Export signature as Base64 (Simplest for Sprint 2 prototype)
      final sigBytes = await _sigCtrl.toPngBytes();
      final sigBase64 = base64Encode(sigBytes!);

      final combinedDateTime = DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
        _selectedTime!.hour, _selectedTime!.minute,
      );

      // 2. Save to Firestore
      await FirebaseFirestore.instance.collection('proposals').add({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'objectives': _objectivesCtrl.text.trim(),
        'targetAudience': _audienceCtrl.text.trim(),
        'date': Timestamp.fromDate(combinedDateTime),
        'duration': _durationCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'expectedParticipants': int.tryParse(_participantsCtrl.text) ?? 0,
        'totalBudget': double.tryParse(_budgetCtrl.text) ?? 0.0,
        'budgetBreakdown': _breakdownCtrl.text.trim(),
        'requiredMaterials': _materialsCtrl.text.trim(),
        'facilitatorName': _facNameCtrl.text.trim(),
        'facilitatorEmail': _facEmailCtrl.text.trim(),
        'facilitatorPhone': _facPhoneCtrl.text.trim(),
        'signature': sigBase64,
        'status': 'Pending',
        'submittedBy': widget.email,
        'submittedByUid': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      logActivity('Proposal Submitted', 'Workshop: ${_titleCtrl.text}');

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proposal submitted successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Submission failed: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CREATE PROPOSAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Workshop Proposal Form', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildSection('Basic Information', [
                _buildField('Workshop Title *', _titleCtrl, 'e.g., PCB Soldering Workshop'),
                _buildField('Description *', _descCtrl, 'Brief overview...', maxLines: 3),
                _buildField('Learning Objectives *', _objectivesCtrl, 'What will participants learn?', maxLines: 3),
                _buildField('Target Audience *', _audienceCtrl, 'e.g., Engineering students, All years'),
              ]),
              const SizedBox(height: 20),
              _buildSection('Event Details', [
                Row(
                  children: [
                    Expanded(child: _buildDatePicker()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTimePicker()),
                  ],
                ),
                const SizedBox(height: 16),
                _buildField('Duration (hours) *', _durationCtrl, 'e.g., 3', keyboardType: TextInputType.number),
                _buildField('Location *', _locationCtrl, 'e.g., Engineering Lab 3'),
                _buildField('Expected Participants *', _participantsCtrl, '50', keyboardType: TextInputType.number),
              ]),
              const SizedBox(height: 20),
              _buildSection('Budget & Resources', [
                _buildField('Total Budget (RM) *', _budgetCtrl, '0.00', keyboardType: TextInputType.number),
                _buildField('Budget Breakdown *', _breakdownCtrl, 'List itemized expenses...', maxLines: 3),
                _buildField('Required Materials *', _materialsCtrl, 'List all equipment needed', maxLines: 3),
              ]),
              const SizedBox(height: 20),
              _buildSection('Contact Information', [
                _buildField('Facilitator Name *', _facNameCtrl, 'Primary person in charge'),
                _buildField('Contact Email *', _facEmailCtrl, 'email@example.com', keyboardType: TextInputType.emailAddress),
                _buildField('Contact Phone *', _facPhoneCtrl, '+60 12-345-6789'),
              ]),
              const SizedBox(height: 20),
              
              // Digital Signature Section
              Container(
                padding: const EdgeInsets.all(20),
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
                        const Text('Digital Signature *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () => _sigCtrl.clear(),
                          child: const Text('Clear', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_note, size: 16, color: Colors.grey),
                                SizedBox(width: 8),
                                Text('Sign below with your mouse or finger', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          Signature(
                            controller: _sigCtrl,
                            height: 150,
                            backgroundColor: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Submit Proposal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true, 
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (v) => v!.isEmpty ? 'Field is required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
            if (date != null) setState(() => _selectedDate = date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_selectedDate == null ? 'mm/dd/yyyy' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}', style: TextStyle(color: _selectedDate == null ? Colors.grey.shade400 : Colors.black, fontSize: 13)),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Time *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
            if (time != null) setState(() => _selectedTime = time);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_selectedTime == null ? '--:-- --' : _selectedTime!.format(context), style: TextStyle(color: _selectedTime == null ? Colors.grey.shade400 : Colors.black, fontSize: 13)),
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
