import 'package:flutter/material.dart';
import '../../core/dimension.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Dimension.init(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        title: Text(
          'Privacy & Security',
          style: TextStyle(
            fontSize: Dimension.font(18),
            fontWeight: FontWeight.w400,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Dimension.width(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              'Privacy Policy',
              'Last updated: January 6, 2026',
            ),
            SizedBox(height: Dimension.height(16)),
            _buildContentSection(
              context,
              '1. Information We Collect',
              'We collect information you provide directly to us, including your name, email address, phone number, and booking details. We also collect information about your device and how you use our app.',
            ),
            SizedBox(height: Dimension.height(16)),
            _buildContentSection(
              context,
              '2. How We Use Your Information',
              'We use the information we collect to:\n• Process your bookings and payments\n• Send you booking confirmations and updates\n• Improve our services and user experience\n• Communicate with you about promotions and offers\n• Ensure the security of our platform',
            ),
            SizedBox(height: Dimension.height(16)),
            _buildContentSection(
              context,
              '3. Information Sharing',
              'We do not sell, trade, or rent your personal information to third parties. We may share your information with:\n• Futsal ground owners for booking purposes\n• Payment processors for transaction processing\n• Service providers who assist in our operations',
            ),
            SizedBox(height: Dimension.height(16)),
            _buildContentSection(
              context,
              '4. Data Security',
              'We implement appropriate security measures to protect your personal information. However, no method of transmission over the internet is 100% secure, and we cannot guarantee absolute security.',
            ),
            SizedBox(height: Dimension.height(16)),
            _buildContentSection(
              context,
              '5. Your Rights',
              'You have the right to:\n• Access your personal information\n• Correct inaccurate data\n• Request deletion of your data\n• Opt-out of marketing communications\n• Withdraw consent at any time',
            ),
            SizedBox(height: Dimension.height(16)),
            _buildContentSection(
              context,
              '6. Cookies and Tracking',
              'We use cookies and similar tracking technologies to improve your experience, analyze usage patterns, and provide personalized content.',
            ),
            SizedBox(height: Dimension.height(16)),
            _buildContentSection(
              context,
              '7. Children\'s Privacy',
              'Our service is not intended for children under 13. We do not knowingly collect personal information from children under 13.',
            ),
            SizedBox(height: Dimension.height(16)),
            _buildContentSection(
              context,
              '8. Changes to Privacy Policy',
              'We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page.',
            ),
            SizedBox(height: Dimension.height(16)),
            _buildContentSection(
              context,
              '9. Contact Us',
              'If you have any questions about this privacy policy, please contact us at:\n\nEmail: info@zenithdigitalsolution.com.np\nPhone: +977-XXX-XXXXXXX\nAddress: Kathmandu, Nepal',
            ),
            SizedBox(height: Dimension.height(24)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: Dimension.font(20),
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: Dimension.height(8)),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: Dimension.font(12),
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection(
    BuildContext context,
    String title,
    String content,
  ) {
    return Container(
      padding: EdgeInsets.all(Dimension.width(16)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimension.width(12)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.06),
            blurRadius: Dimension.width(10),
            offset: const Offset(0, 2),
            spreadRadius: Dimension.width(2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: Dimension.font(16),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: Dimension.height(12)),
          Text(
            content,
            style: TextStyle(
              fontSize: Dimension.font(14),
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
