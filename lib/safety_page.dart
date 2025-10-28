import 'package:flutter/material.dart';

class SafetyPage extends StatelessWidget {
  const SafetyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Safety',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0xFFF79D39),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.security,
                      size: 48,
                      color: Color(0xFFF79D39),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your Safety is Our Priority',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF79D39),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We\'re committed to keeping you safe on every ride',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Emergency button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.emergency,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Emergency Help',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          Text(
                            'Call emergency services immediately',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _showEmergencyDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Call 100'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Safety features
              _buildSafetySection(
                'Safety Features',
                [
                  _buildSafetyItem(
                    Icons.verified_user,
                    'Verified Drivers',
                    'All drivers undergo background checks and vehicle inspections',
                  ),
                  _buildSafetyItem(
                    Icons.location_on,
                    'Real-time Tracking',
                    'Share your trip with family and friends in real-time',
                  ),
                  _buildSafetyItem(
                    Icons.star_rate,
                    'Driver Ratings',
                    'Rate and review drivers to maintain quality standards',
                  ),
                  _buildSafetyItem(
                    Icons.support_agent,
                    '24/7 Support',
                    'Get help anytime with our round-the-clock support team',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Safety tools
              _buildSafetySection(
                'Safety Tools',
                [
                  _buildActionItem(
                    Icons.share_location,
                    'Share Trip',
                    'Share your ride details with trusted contacts',
                        () => _shareTrip(context),
                  ),
                  _buildActionItem(
                    Icons.phone,
                    'Emergency Contacts',
                    'Set up emergency contacts for quick access',
                        () => _manageEmergencyContacts(context),
                  ),
                  _buildActionItem(
                    Icons.report_problem,
                    'Report Issues',
                    'Report safety concerns or incidents',
                        () => _reportIssue(context),
                  ),
                  _buildActionItem(
                    Icons.help_outline,
                    'Safety Guidelines',
                    'Learn about safety best practices',
                        () => _showSafetyGuidelines(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Contact support
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.headset_mic,
                      size: 32,
                      color: Color(0xFFF79D39),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Need Help?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF79D39),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Our support team is here to help 24/7',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _contactSupport(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFF79D39),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Contact Support'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafetySection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF79D39),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSafetyItem(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Color(0xFFF79D39),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, String description,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Color(0xFFF79D39),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text(
              'Emergency Call',
              style: TextStyle(color: Colors.red),
            ),
            content: const Text(
                'This will call emergency services. Only use in case of real emergency.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Implement actual emergency call
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Calling emergency services...')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                    'Call Now', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  void _shareTrip(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip sharing feature will be implemented')),
    );
  }

  void _manageEmergencyContacts(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Emergency contacts management will be implemented')),
    );
  }

  void _reportIssue(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report issue feature will be implemented')),
    );
  }

  void _showSafetyGuidelines(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(
              'Safety Guidelines',
              style: TextStyle(color: Color(0xFFF79D39)),
            ),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      '• Always verify driver and vehicle details before getting in'),
                  SizedBox(height: 8),
                  Text('• Share your trip details with someone you trust'),
                  SizedBox(height: 8),
                  Text('• Sit in the back seat when riding alone'),
                  SizedBox(height: 8),
                  Text('• Keep your phone charged and accessible'),
                  SizedBox(height: 8),
                  Text(
                      '• Trust your instincts - if something feels wrong, speak up'),
                  SizedBox(height: 8),
                  Text('• Rate your driver to help maintain safety standards'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Got it',
                  style: TextStyle(color: Color(0xFFF79D39)),
                ),
              ),
            ],
          ),
    );
  }

  void _contactSupport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contacting support team...')),
    );
  }
}

