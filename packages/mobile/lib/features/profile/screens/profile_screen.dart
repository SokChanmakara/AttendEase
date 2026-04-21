import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PROFILE',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile Header
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.surface,
              child: Text(
                'MK',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'MAKARA SAM',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'SENIOR SOFTWARE ENGINEER',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 48),
            
            // Info Cards
            _buildSettingsItem(context, 'EMPLOYEE ID', 'EMP-0842', Icons.person_outline),
            _buildSettingsItem(context, 'DEPARTMENT', 'ENGINEERING', Icons.business),
            _buildSettingsItem(context, 'JOIN DATE', 'OCT 12, 2024', Icons.calendar_today),
            
            const SizedBox(height: 24),
            Divider(color: AppColors.border),
            const SizedBox(height: 24),
            
            _buildActionItem(context, 'CHANGE PASSWORD', Icons.vpn_key_outlined),
            _buildActionItem(context, 'PRIVACY POLICY', Icons.shield_outlined),
            _buildActionItem(context, 'SUPPORT', Icons.help_outline),
            
            const SizedBox(height: 48),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.statusRed),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'SIGN OUT',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.statusRed,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: InkWell(
        onTap: () {},
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.accent),
            const SizedBox(width: 20),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
