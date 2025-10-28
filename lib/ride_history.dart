import 'package:flutter/material.dart';

class RideHistoryPage extends StatelessWidget {
  const RideHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Ride History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0xFFF79D39),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const NoRidesWidget(),
    );
  }
}

class NoRidesWidget extends StatelessWidget {
  const NoRidesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Car icon with circular background
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue.shade600.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_car_outlined,
                size: 60,
                color: Color(0xFFF79D39),
              ),
            ),

            const SizedBox(height: 32),

            // Main heading
            Text(
              'No Rides Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF79D39),
              ),
            ),

            const SizedBox(height: 16),

            // Description text
            Text(
              'You haven\'t taken any rides yet.\nBook your first ride to see your history here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 40),

            // Book Now button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to booking page
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF79D39),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Book Your First Ride',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Secondary action button
            TextButton(
              onPressed: () {
                // Show help or FAQ
                _showHelpDialog(context);
              },
              child: Text(
                'Need Help?',
                style: TextStyle(
                  color: Color(0xFFF79D39),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Need Help?',
            style: TextStyle(
              color: Color(0xFFF79D39),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Contact our support team for assistance with booking rides or any other questions you may have.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Contact Support',
                style: TextStyle(color: Color(0xFFF79D39)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        );
      },
    );
  }
}
