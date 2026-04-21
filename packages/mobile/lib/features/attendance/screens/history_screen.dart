import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'HISTORY',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        itemCount: 10,
        itemBuilder: (context, index) {
          // Dummy data
          final date = DateTime.now().subtract(Duration(days: index));
          final dateStr = DateFormat('EEE, dd MMM').format(date).toUpperCase();
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (index == 0 || index % 3 == 0) ...[
                const SizedBox(height: 24),
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildHistoryCard(context, index % 2 == 0),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, bool isCheckIn) {
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
                  color: isCheckIn ? AppColors.statusGreen : AppColors.statusAmber,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCheckIn ? 'CHECKED IN' : 'CHECKED OUT',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    'HQ Main Entrance',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
          Text(
            isCheckIn ? '09:00 AM' : '05:32 PM',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
