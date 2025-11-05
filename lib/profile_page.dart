import 'package:flutter/material.dart';
import 'ride_history.dart';
import 'safety_page.dart';
import 'settings_page.dart';
import 'authservice.dart';
import 'login_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final storage = FlutterSecureStorage();
  String userName = "name";
  String userEmail = "usermail.com";
  String userPhone = "+1 234 567 8900";
  bool _isLoadingUserData = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();

  }

  Future<void> _loadUserData() async {
    final name = await storage.read(key: 'userName') ?? 'Your Name';
    final email = await storage.read(key: 'userEmail') ?? 'you@example.com';
    final phone = await storage.read(key: 'userPhone') ?? '+1 000 000 0000';

    setState(() {
      userName = name;
      userEmail = email;
      userPhone = phone;
      _isLoadingUserData = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFFF79D39),
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoadingUserData
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF79D39)),
        ),
      )
          : SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),
            // Menu Items
            _buildMenuItems(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFF79D39),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 60,
              color: Color(0xFFF79D39),
            ),
          ),
          SizedBox(height: 15),
          Text(
            userName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            userEmail,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 5),
          Text(
            userPhone,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.history,
            title: 'Ride History',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RideHistoryPage()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.security,
            title: 'Safety',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SafetyPage()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.help,
            title: 'Help & Support',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              _showLogoutDialog();
            },
            isLogout: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isLogout ? Colors.red[50] : Color(0xFFF79D39).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isLogout ? Colors.red : Color(0xFFF79D39),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isLogout ? Colors.red : Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isLogout ? Colors.red : Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 10),
              Text('Logout'),
            ],
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await _handleLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF79D39)),
                ),
                SizedBox(height: 16),
                Text(
                  'Logging out...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Clear auth data
      await AuthService.logout();

      // Small delay for better UX
      await Future.delayed(Duration(milliseconds: 500));

      // Navigate to login page and remove all previous routes
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
              (route) => false,
        );
      }
    } catch (e) {
      // Handle logout error
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
