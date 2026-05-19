import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'event_registration_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;
  final Map<String, dynamic> data;
  const EventDetailScreen({super.key, required this.eventId, required this.data});

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'Date TBC';
    final d = ts.toDate();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? '(Untitled)';
    final description = data['description'] as String? ?? '';
    final objectives = data['objectives'] as String? ?? '';
    final location = data['location'] as String? ?? '';
    final time = data['time'] as String? ?? '';
    final duration = data['duration'] as String? ?? '';
    final targetAudience = data['targetAudience'] as String? ?? '';
    final fee = (data['fee'] as num?)?.toDouble() ?? 0;
    final isFree = data['isFree'] as bool? ?? (fee == 0);
    final maxPart = data['maxParticipants'] as int? ?? 0;
    final regCount = data['registrationCount'] as int? ?? 0;
    final dateStr = _formatDate(data['date'] as Timestamp?);
    final feeLabel = isFree || fee == 0 ? 'Free' : 'RM ${fee.toStringAsFixed(2)}';
    final isSoldOut = maxPart > 0 && regCount >= maxPart;
    final spotsLeft = maxPart > 0 ? maxPart - regCount : 0;
    final progress = maxPart > 0 ? regCount / maxPart : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.student, Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                        child: const Text('Technical', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Text(feeLabel, style: const TextStyle(color: AppColors.student, fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Availability card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$regCount / $maxPart registered', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                              if (isSoldOut)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.admin.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                                  child: const Text('Sold Out', style: TextStyle(color: AppColors.admin, fontSize: 12, fontWeight: FontWeight.w700)),
                                )
                              else
                                Text('$spotsLeft spots left', style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: AppColors.divider,
                              valueColor: AlwaysStoppedAnimation<Color>(isSoldOut ? AppColors.admin : AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Details
                    _sectionHeader('About'),
                    const SizedBox(height: 8),
                    Text(description, style: const TextStyle(fontSize: 14, color: AppColors.textMedium, height: 1.5)),
                    const SizedBox(height: 20),

                    if (objectives.isNotEmpty) ...[
                      _sectionHeader('Objectives'),
                      const SizedBox(height: 8),
                      Text(objectives, style: const TextStyle(fontSize: 14, color: AppColors.textMedium, height: 1.5)),
                      const SizedBox(height: 20),
                    ],

                    _sectionHeader('Event Details'),
                    const SizedBox(height: 12),
                    _detailRow(Icons.calendar_today_outlined, 'Date', dateStr),
                    _detailRow(Icons.access_time, 'Time', time),
                    _detailRow(Icons.timer_outlined, 'Duration', duration),
                    _detailRow(Icons.location_on_outlined, 'Location', location),
                    if (targetAudience.isNotEmpty)
                      _detailRow(Icons.people_outline, 'Target Audience', targetAudience),
                    const SizedBox(height: 20),

                    _sectionHeader('Registration Fee'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.payments_outlined, color: AppColors.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Amount', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                                Text(feeLabel, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom register button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSoldOut ? null : () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => EventRegistrationScreen(eventId: eventId, eventData: data),
                  )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSoldOut ? AppColors.textLight : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(isSoldOut ? 'Sold Out' : 'Register Now', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) => Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark));

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.student),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
