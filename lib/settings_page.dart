import 'package:flutter/material.dart';
import 'app_basecolor.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _darkModeEnabled = false;
  bool _soundEnabled = true;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'USD';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppbaseColor.Primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile section
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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppbaseColor.Primary,
                      child: const Icon(
                        Icons.person,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'USER NAME',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'usermail.com',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '+91 934 567 8900',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _editProfile(context),
                      icon: Icon(
                        Icons.edit,
                        color: AppbaseColor.Primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Account settings
              _buildSettingsSection(
                'Account',
                [
                  _buildSettingItem(
                    Icons.person_outline,
                    'Edit Profile',
                    'Update your personal information',
                    onTap: () => _editProfile(context),
                  ),
                  _buildSettingItem(
                    Icons.payment,
                    'Payment Methods',
                    'Manage your payment options',
                    onTap: () => _managePayments(context),
                  ),
                  _buildSettingItem(
                    Icons.location_on_outlined,
                    'Saved Addresses',
                    'Home, work, and favorite places',
                    onTap: () => _manageSavedAddresses(context),
                  ),
                  _buildSettingItem(
                    Icons.family_restroom,
                    'Family Profile',
                    'Manage family members and riders',
                    onTap: () => _manageFamilyProfile(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // App preferences
              _buildSettingsSection(
                'Preferences',
                [
                  _buildSwitchItem(
                    Icons.notifications_outlined,
                    'Push Notifications',
                    'Receive ride updates and offers',
                    _notificationsEnabled,
                        (value) => setState(() => _notificationsEnabled = value),
                  ),
                  _buildSwitchItem(
                    Icons.location_on_outlined,
                    'Location Services',
                    'Allow location access for better experience',
                    _locationEnabled,
                        (value) => setState(() => _locationEnabled = value),
                  ),
                  _buildSwitchItem(
                    Icons.dark_mode_outlined,
                    'Dark Mode',
                    'Use dark theme for the app',
                    _darkModeEnabled,
                        (value) => setState(() => _darkModeEnabled = value),
                  ),

                ],
              ),

              const SizedBox(height: 24),

              // Support & Legal
              _buildSettingsSection(
                'Support & Legal',
                [
                  _buildSettingItem(
                    Icons.help_outline,
                    'Help Center',
                    'Get answers to common questions',
                    onTap: () => _openHelpCenter(context),
                  ),
                  _buildSettingItem(
                    Icons.headset_mic_outlined,
                    'Contact Support',
                    'Chat with our support team',
                    onTap: () => _contactSupport(context),
                  ),
                  _buildSettingItem(
                    Icons.star_outline,
                    'Rate App',
                    'Rate us on the app store',
                    onTap: () => _rateApp(context),
                  ),
                  _buildSettingItem(
                    Icons.share_outlined,
                    'Share App',
                    'Tell your friends about us',
                    onTap: () => _shareApp(context),
                  ),
                  _buildSettingItem(
                    Icons.description_outlined,
                    'Terms of Service',
                    'Read our terms and conditions',
                    onTap: () => _openTerms(context),
                  ),
                  _buildSettingItem(
                    Icons.privacy_tip_outlined,
                    'Privacy Policy',
                    'Learn how we protect your data',
                    onTap: () => _openPrivacyPolicy(context),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // App info
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
                      Icons.info_outline,
                      size: 32,
                      color: AppbaseColor.Primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'CabBook',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppbaseColor.Primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 2.1.0',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sign out button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showSignOutDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                  ),
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
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
              color: AppbaseColor.Primary,
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
          child: Column(
            children: items.map((item) {
              int index = items.indexOf(item);
              return Column(
                children: [
                  item,
                  if (index < items.length - 1)
                    Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                      indent: 56,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
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
                color: AppbaseColor.Primary,
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
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
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
              color: AppbaseColor.Primary,
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
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor:AppbaseColor.Primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownItem(IconData icon, String title, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Padding(
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
              color: AppbaseColor.Primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: AppbaseColor.Primary),
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _editProfile(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile feature will be implemented')),
    );
  }

  void _managePayments(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment methods management will be implemented')),
    );
  }

  void _manageSavedAddresses(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved addresses management will be implemented')),
    );
  }

  void _manageFamilyProfile(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Family profile management will be implemented')),
    );
  }

  void _openHelpCenter(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening help center...')),
    );
  }

  void _contactSupport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contacting support team...')),
    );
  }

  void _rateApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening app store for rating...')),
    );
  }

  void _shareApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing app with friends...')),
    );
  }

  void _openTerms(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening terms of service...')),
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening privacy policy...')),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signed out successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
