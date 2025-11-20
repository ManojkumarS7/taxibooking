import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'authservice.dart';
import 'app_baseurl.dart';
import 'app_basecolor.dart';

class RideHistoryPage extends StatefulWidget {
  const RideHistoryPage({Key? key}) : super(key: key);

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  List<dynamic> rideHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRideHistory();
  }

  Future<void> fetchRideHistory() async {
    try {
      // ✅ Get the full bearer token header
      final authHeader = await AuthService.getAuthHeader();

      print("token $authHeader");

      if (authHeader == null) {
        print("⚠️ No token found, please log in again");
        setState(() => isLoading = false);
        return;
      }

      final url = Uri.parse('${AppbaseUrl.baseurl}user/booking/history');

      final response = await http.get(
        url,
        headers: {
          'Authorization': authHeader,
          'Content-Type': 'application/json',
        },
      );

      print("📡 Ride History Response: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        setState(() {
          rideHistory = jsonData['data'] ?? [];
          isLoading = false;
        });
      } else {
        print("❌ Failed to fetch ride history: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("❌ Error fetching ride history: $e");
      setState(() => isLoading = false);
    }
  }

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
        backgroundColor:  AppbaseColor.Primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppbaseColor.Primary),
      )
          : rideHistory.isEmpty
          ? const NoRidesWidget()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rideHistory.length,
        itemBuilder: (context, index) {
          final ride = rideHistory[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const Icon(Icons.local_taxi, color: AppbaseColor.Primary),
              title: Text(
                "From: ${ride['pick_up_location'] ?? 'N/A'}",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                "To: ${ride['drop_up_location'] ?? 'N/A'}\nPassenger Name: ${ride['user_name'] ?? ''}",
              ),
              trailing: Text(
                "₹${ride['total_fare'] ?? '300'}",
                style: const TextStyle(
                    color: AppbaseColor.Primary,
                    fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
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
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue.shade600.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car_outlined,
                size: 60,
                color: AppbaseColor.Primary,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Rides Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppbaseColor.Primary,
              ),
            ),
            const SizedBox(height: 16),
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
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppbaseColor.Primary,
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
          ],
        ),
      ),
    );
  }
}
