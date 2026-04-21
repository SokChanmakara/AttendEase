import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../attendance/attendance_service.dart';
import '../../attendance/screens/scanner_screen.dart';
import '../../../core/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<EmployeeContext> _employeeContextFuture;

  @override
  void initState() {
    super.initState();
    _employeeContextFuture = AttendanceService.loadEmployeeContext();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EmployeeContext>(
      future: _employeeContextFuture,
      builder: (context, employeeSnapshot) {
        if (employeeSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (employeeSnapshot.hasError || !employeeSnapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'DASHBOARD',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  employeeSnapshot.error?.toString() ??
                      'Failed to load account.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final employee = employeeSnapshot.data!;
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: AttendanceService.attendanceQuery(
            employee,
          ).limit(20).snapshots(),
          builder: (context, attendanceSnapshot) {
            final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
                [
                  ...(attendanceSnapshot.data?.docs ??
                      <QueryDocumentSnapshot<Map<String, dynamic>>>[]),
                ]..sort((a, b) {
                  final aDate = asDateTime(a.data()['check_in_at']);
                  final bDate = asDateTime(b.data()['check_in_at']);
                  if (aDate == null && bDate == null) return 0;
                  if (aDate == null) return 1;
                  if (bDate == null) return -1;
                  return bDate.compareTo(aDate);
                });
            QueryDocumentSnapshot<Map<String, dynamic>>? openRecord;
            for (final doc in docs) {
              if (doc.data()['check_out_at'] == null) {
                openRecord = doc;
                break;
              }
            }

            final now = DateTime.now();
            final checkInAt = openRecord == null
                ? null
                : asDateTime(openRecord.data()['check_in_at']);
            final liveHoursWorked = checkInAt == null
                ? 0.0
                : now.difference(checkInAt).inMinutes / 60.0;

            final latestHours = docs.isNotEmpty
                ? ((docs.first.data()['hours_worked'] as num?)?.toDouble() ??
                      0.0)
                : 0.0;
            final hoursWorked = openRecord == null
                ? latestHours
                : liveHoursWorked;

            final statusText = openRecord == null
                ? 'CHECKED OUT'
                : 'CHECKED IN';
            final statusColor = openRecord == null
                ? AppColors.statusAmber
                : AppColors.statusGreen;
            final statusTime = _statusTime(
              openRecord?.data(),
              docs.isNotEmpty ? docs.first.data() : null,
            );
            final actionText = openRecord == null
                ? 'SCAN TO CHECK IN'
                : 'SCAN TO CHECK OUT';
            final activity = _recentActivity(docs);

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  'DASHBOARD',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none, size: 20),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TODAY',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hoursWorked.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    Text(
                      'HOURS WORKED',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 48),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CURRENT STATUS',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                Text(
                                  statusText,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              statusTime,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () async {
                        final changed = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ScannerScreen(),
                          ),
                        );
                        if (changed == true && mounted) {
                          setState(() {});
                        }
                      },
                      child: Card(
                        color: AppColors.accent,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.qr_code_scanner,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                actionText,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'RECENT ACTIVITY',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    if (attendanceSnapshot.connectionState ==
                        ConnectionState.waiting)
                      const Center(child: CircularProgressIndicator())
                    else if (activity.isEmpty)
                      Text(
                        'No attendance records yet.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    else
                      ...activity.map(
                        (item) => _buildActivityItem(context, item),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _statusTime(
    Map<String, dynamic>? openData,
    Map<String, dynamic>? latestData,
  ) {
    final format = DateFormat('hh:mm a');
    final openCheckIn = asDateTime(openData?['check_in_at']);
    if (openCheckIn != null) return format.format(openCheckIn);

    final latestCheckOut = asDateTime(latestData?['check_out_at']);
    if (latestCheckOut != null) return format.format(latestCheckOut);
    return '-';
  }

  List<_ActivityItem> _recentActivity(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final formatTime = DateFormat('hh:mm a');
    final now = DateTime.now();
    final items = <_ActivityItem>[];

    for (final doc in docs.take(8)) {
      final data = doc.data();
      final checkIn = asDateTime(data['check_in_at']);
      final checkOut = asDateTime(data['check_out_at']);

      if (checkOut != null) {
        items.add(
          _ActivityItem(
            label: 'CHECK OUT',
            dateLabel: _dateLabel(checkOut, now),
            timeLabel: formatTime.format(checkOut),
          ),
        );
      }
      if (checkIn != null) {
        items.add(
          _ActivityItem(
            label: 'CHECK IN',
            dateLabel: _dateLabel(checkIn, now),
            timeLabel: formatTime.format(checkIn),
          ),
        );
      }
    }

    return items.take(3).toList();
  }

  String _dateLabel(DateTime date, DateTime now) {
    final isSameDay =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (isSameDay) return 'Today';
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
    if (isYesterday) return 'Yesterday';
    return DateFormat('dd MMM').format(date);
  }

  Widget _buildActivityItem(BuildContext context, _ActivityItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.label, style: Theme.of(context).textTheme.bodyLarge),
              Text(
                item.dateLabel,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          Text(item.timeLabel, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.label,
    required this.dateLabel,
    required this.timeLabel,
  });

  final String label;
  final String dateLabel;
  final String timeLabel;
}
