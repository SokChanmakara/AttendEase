import 'package:flutter/material.dart';
import '../../attendance/screens/scanner_screen.dart';
import '../../../core/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              '08:42',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            Text(
              'HOURS WORKED',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 48),
            
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.statusGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CURRENT STATUS',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'CHECKED IN',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '09:00 AM',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Action Card
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScannerScreen()),
                );
              },
              child: Card(
                color: AppColors.accent,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_scanner, color: Colors.black),
                      const SizedBox(width: 12),
                      Text(
                        'SCAN TO CHECK OUT',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.black,
                        ),
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
            ...List.generate(3, (index) => _buildActivityItem(context, index)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, int index) {
    final labels = ['Check In', 'Check Out', 'Check In'];
    final times = ['09:00 AM', '05:32 PM', '08:55 AM'];
    final dates = ['Today', 'Yesterday', '20 Apr'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                labels[index].toUpperCase(),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                dates[index],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          Text(
            times[index],
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}
