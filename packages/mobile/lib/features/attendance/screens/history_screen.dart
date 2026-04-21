import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../attendance_service.dart';
import '../../../core/theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<EmployeeContext> _employeeContextFuture;

  @override
  void initState() {
    super.initState();
    _employeeContextFuture = AttendanceService.loadEmployeeContext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HISTORY', style: Theme.of(context).textTheme.titleMedium),
      ),
      body: FutureBuilder<EmployeeContext>(
        future: _employeeContextFuture,
        builder: (context, employeeSnapshot) {
          if (employeeSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (employeeSnapshot.hasError || !employeeSnapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  employeeSnapshot.error?.toString() ??
                      'Failed to load history.',
                ),
              ),
            );
          }

          final employee = employeeSnapshot.data!;
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: AttendanceService.attendanceQuery(
              employee,
            ).limit(60).snapshots(),
            builder: (context, attendanceSnapshot) {
              if (attendanceSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = attendanceSnapshot.data?.docs ?? const [];
              final entries = _buildEntries(docs);
              if (entries.isEmpty) {
                return const Center(child: Text('No attendance records yet.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 8.0,
                ),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final shouldShowHeader =
                      index == 0 ||
                      !_isSameDay(entries[index - 1].date, entry.date);
                  final dateStr = DateFormat(
                    'EEE, dd MMM',
                  ).format(entry.date).toUpperCase();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (shouldShowHeader) ...[
                        const SizedBox(height: 24),
                        Text(
                          dateStr,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.accent),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildHistoryCard(context, entry),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  List<_HistoryEntry> _buildEntries(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final entries = <_HistoryEntry>[];
    for (final doc in docs) {
      final data = doc.data();
      final locationId = (data['location_id'] as String?) ?? 'Unknown location';
      final checkIn = asDateTime(data['check_in_at']);
      final checkOut = asDateTime(data['check_out_at']);

      if (checkIn != null) {
        entries.add(
          _HistoryEntry(date: checkIn, locationId: locationId, isCheckIn: true),
        );
      }
      if (checkOut != null) {
        entries.add(
          _HistoryEntry(
            date: checkOut,
            locationId: locationId,
            isCheckIn: false,
          ),
        );
      }
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildHistoryCard(BuildContext context, _HistoryEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: entry.isCheckIn
                      ? AppColors.statusGreen
                      : AppColors.statusAmber,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.isCheckIn ? 'CHECKED IN' : 'CHECKED OUT',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    entry.locationId,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
          Text(
            DateFormat('hh:mm a').format(entry.date),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _HistoryEntry {
  const _HistoryEntry({
    required this.date,
    required this.locationId,
    required this.isCheckIn,
  });

  final DateTime date;
  final String locationId;
  final bool isCheckIn;
}
