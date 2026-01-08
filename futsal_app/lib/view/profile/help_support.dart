import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/dimension.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
          'Help & Support',
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
            Text(
              'How can we help you?',
              style: TextStyle(
                fontSize: Dimension.font(20),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: Dimension.height(8)),
            Text(
              'Get quick answers to your questions',
              style: TextStyle(
                fontSize: Dimension.font(14),
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            SizedBox(height: Dimension.height(24)),
            _buildContactCard(
              context,
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'info@zenithdigitalsolution.com.np',
              description:
                  'Send us an email and we\'ll respond within 24 hours',
              onTap: () => _launchEmail(),
            ),
            SizedBox(height: Dimension.height(16)),
            _buildContactCard(
              context,
              icon: Icons.phone_outlined,
              title: 'Phone Support',
              subtitle: '+977-XXX-XXXXXXX',
              description: 'Call us Mon-Fri, 9 AM - 6 PM',
              onTap: () => _launchPhone('+977XXXXXXXXX'),
            ),
            SizedBox(height: Dimension.height(24)),
            Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: Dimension.font(18),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: Dimension.height(16)),
            _buildFAQItem(
              context,
              'How do I book a futsal court?',
              'Browse available courts, select your preferred date and time, and confirm your booking. You\'ll receive a confirmation notification.',
            ),
            SizedBox(height: Dimension.height(12)),
            _buildFAQItem(
              context,
              'Can I cancel my booking?',
              'Yes, you can cancel bookings from the Bookings screen. Cancellation policies may vary by venue.',
            ),
            SizedBox(height: Dimension.height(12)),
            _buildFAQItem(
              context,
              'How do I make a payment?',
              'Payment can be made through the app using various payment methods including cards and digital wallets.',
            ),
            SizedBox(height: Dimension.height(12)),
            _buildFAQItem(
              context,
              'What if I face technical issues?',
              'Contact our support team via email or phone. We\'re here to help resolve any issues you encounter.',
            ),
            SizedBox(height: Dimension.height(12)),
            _buildFAQItem(
              context,
              'How do I update my profile?',
              'Go to Profile > Edit Profile to update your personal information, photo, and contact details.',
            ),
            SizedBox(height: Dimension.height(24)),
            Container(
              padding: EdgeInsets.all(Dimension.width(16)),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Dimension.width(12)),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).primaryColor,
                    size: Dimension.width(24),
                  ),
                  SizedBox(width: Dimension.width(12)),
                  Expanded(
                    child: Text(
                      'For urgent issues, please contact us directly via phone or email.',
                      style: TextStyle(
                        fontSize: Dimension.font(12),
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Dimension.height(24)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimension.width(12)),
      child: Container(
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
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(Dimension.width(12)),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Dimension.width(10)),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: Dimension.width(24),
              ),
            ),
            SizedBox(width: Dimension.width(16)),
            Expanded(
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
                  SizedBox(height: Dimension.height(4)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: Dimension.font(13),
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: Dimension.height(4)),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: Dimension.font(12),
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: Dimension.width(16),
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
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
            question,
            style: TextStyle(
              fontSize: Dimension.font(14),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: Dimension.height(8)),
          Text(
            answer,
            style: TextStyle(
              fontSize: Dimension.font(13),
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'info@zenithdigitalsolution.com.np',
      query: 'subject=Futsal App Support Request',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch email';
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch phone';
      }
    } catch (e) {
      debugPrint('Error launching phone: $e');
    }
  }
}
