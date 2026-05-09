import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/activity_service.dart';

class SubmitComplaintScreen extends StatefulWidget {
  final String email;
  const SubmitComplaintScreen({super.key, required this.email});

  @override
  State<SubmitComplaintScreen> createState() => _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends State<SubmitComplaintScreen> {
  String? _selectedCategory;
  String _priority = 'Medium';
  final _subjectCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  bool _isLoading = false;

  final List<String> _categories = [
    'Event Issue',
    'Payment Problem',
    'Technical Bug',
    'General Feedback',
  ];

  Future<void> _submit() async {
    if (_selectedCategory == null || _subjectCtrl.text.isEmpty || _descriptionCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('complaints').add({
        'studentEmail': widget.email,
        'category': _selectedCategory,
        'priority': _priority,
        'subject': _subjectCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      logActivity('Complaint Submitted', 'Subject: ${_subjectCtrl.text}');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint submitted successfully'), backgroundColor: Colors.green),
      );
      
      setState(() {
        _selectedCategory = null;
        _priority = 'Medium';
        _subjectCtrl.clear();
        _descriptionCtrl.clear();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Submit Complaint', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share your concerns with us', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your complaint will be reviewed by the committee and president. We aim to respond within 3-5 business days.',
                      style: TextStyle(color: Colors.blue[900], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text('Category *', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              hint: const Text('Select a category'),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
            const SizedBox(height: 20),

            const Text('Priority Level', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: ['Low', 'Medium', 'High'].map((p) {
                final isSelected = _priority == p;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () => setState(() => _priority = p),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? _getPriorityColor(p) : Colors.white,
                        foregroundColor: isSelected ? Colors.white : Colors.grey,
                        side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                      ),
                      child: Text(p),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            const Text('Subject *', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(hintText: 'Brief summary of your complaint'),
            ),
            const SizedBox(height: 24),

            const Text('Description *', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionCtrl,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Please provide detailed information about your complaint...',
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                label: const Text('Submit Complaint'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String p) {
    if (p == 'High') return Colors.red;
    if (p == 'Medium') return Colors.orange;
    return Colors.green;
  }
}
