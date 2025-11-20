
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'home_map.dart';
import 'profile_page.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:taxibooking/app_baseurl.dart';
import 'app_basecolor.dart';
// Animated Background Widget
class AnimatedBackground extends StatelessWidget {
  final Animation carAnimation;
  final AnimationController roadController;

  const AnimatedBackground({
    required this.carAnimation,
    required this.roadController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3c3c3c),
            Color(0xFF1e1e1e),
            Color(0xFF111111),
          ],
        ),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: roadController,
            builder: (context, child) {
              return CustomPaint(
                painter: RoadLinesPainter(roadController.value),
                size: Size.infinite,
              );
            },
          ),
          AnimatedBuilder(
            animation: carAnimation,
            builder: (context, child) {
              return Positioned(
                left: MediaQuery.of(context).size.width * carAnimation.value,
                top: 150,
                child: Transform.scale(
                  scale: 0.8,
                  child: Icon(
                    Icons.local_taxi,
                    size: 40,
                    color: AppbaseColor.Primary.withOpacity(0.2)
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: carAnimation,
            builder: (context, child) {
              double reversedValue = 1.3 - carAnimation.value;
              return Positioned(
                left: MediaQuery.of(context).size.width * reversedValue,
                top: 400,
                child: Transform.scale(
                  scale: 0.6,
                  child: Icon(
                    Icons.local_taxi,
                    size: 40,
                    color: Color(0xFFFF9900).withOpacity(0.2),
                  ),
                ),
              );
            },
          ),
          ...List.generate(20, (index) {
            return Positioned(
              left: (index * 50.0) % MediaQuery.of(context).size.width,
              top: (index * 80.0) % MediaQuery.of(context).size.height,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class RoadLinesPainter extends CustomPainter {
  final double animationValue;

  RoadLinesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    double dashHeight = 30;
    double dashSpace = 20;
    double startY = -dashHeight + (animationValue * (dashHeight + dashSpace));

    for (int col = 0; col < 3; col++) {
      double x = size.width * (0.25 + col * 0.25);
      double y = startY;

      while (y < size.height) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, y + dashHeight),
          paint,
        );
        y += dashHeight + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(RoadLinesPainter oldDelegate) => true;
}

class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
  final double? latitude;
  final double? longitude;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
    this.latitude,
    this.longitude,
  });

  factory PlacePrediction.fromNewApiJson(Map<String, dynamic> json) {
    final displayName = json['displayName']?['text'] ?? '';
    final formattedAddress = json['formattedAddress'] ?? '';
    final location = json['location'];

    double? lat;
    double? lng;

    if (location != null) {
      lat = location['latitude'] is double
          ? location['latitude']
          : (location['latitude'] as num?)?.toDouble();
      lng = location['longitude'] is double
          ? location['longitude']
          : (location['longitude'] as num?)?.toDouble();
    }

    return PlacePrediction(
      placeId: json['id'] ?? '',
      description: displayName.isNotEmpty ? displayName : formattedAddress,
      mainText: displayName.split(',').first, // Get the primary name
      secondaryText: formattedAddress,
      latitude: lat,
      longitude: lng,
    );
  }
}

// Main Home Page
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin {
  late AnimationController _carController;
  late AnimationController _roadController;
  late Animation<double> _carAnimation;

  String _currentLocationName = 'Fetching location...';
  String _destinationName = 'Select destination';
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  bool _cabBooked = false;
  bool _showBookingCard = false;

  // Search related
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<PlacePrediction> _placePredictions = [];
  bool _showPredictions = false;
  Timer? _debounce;
  bool _isSearching = false;
  bool _isBookingCab = false;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _phonenoController = TextEditingController();
  final TextEditingController _passengerController = TextEditingController();
  String? selectedBookingType;
  String? selectedRentalHours;
  Map<String, dynamic>? _bookingDetails;

  late Razorpay _razorpay;

  final List<String> bookingTypes = [
    'Ride Now',
    'Schedule Later',
    'Rental',
    'Outstation'
  ];


  final List<String> carTypes = [
    'SUV (5-7 seats)',
    'Sedan (5 seats)',
    'Hatchback (4-5 seats)',
    'Coupe (2-4 seats)',
    'Convertible (2-4 seats)',
    'Wagon (5-7 seats)',
    'Pickup Truck (2-6 seats)',
    'Van (7-15 seats)',
    'Minivan (7-8 seats)',
    'Crossover (5-7 seats)'
  ];

  String? selectedCarType;

  static const String _apiKey = 'AIzaSyBPhbqYM6ypaRkOSJgKxrthxQQN5rUWDYA';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchCurrentLocation();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }




  void _setupAnimations() {
    _carController = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _roadController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _carAnimation = Tween<double>(begin: 0, end: 1).animate(_carController);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty &&
          _searchController.text.length > 2) {
        _getPlacePredictions(_searchController.text);
      } else {
        setState(() {
          _placePredictions.clear();
          _showPredictions = false;
        });
      }
    });
  }

  void _onFocusChanged() {
    if (_searchFocusNode.hasFocus) {
      if (_placePredictions.isNotEmpty) {
        setState(() {
          _showPredictions = true;
        });
      }
    }
  }

// Updated _getPlacePredictions method
  Future<void> _getPlacePredictions(String input) async {
    if (input.isEmpty || input.length < 3) {
      setState(() {
        _placePredictions.clear();
        _showPredictions = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    const String url = 'https://places.googleapis.com/v1/places:searchText';

    try {
      final Map<String, dynamic> requestBody = {
        "textQuery": input,
        "maxResultCount": 10,
      };

      // Add location bias if current position is available
      if (_currentPosition != null) {
        requestBody["locationBias"] = {
          "circle": {
            "center": {
              "latitude": _currentPosition!.latitude,
              "longitude": _currentPosition!.longitude,
            },
            "radius": 50000.0 // 50km radius
          }
        };
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,places.location',
        },
        body: json.encode(requestBody),
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['places'] != null && data['places'] is List) {
          final List places = data['places'];
          print('Found ${places.length} places');

          setState(() {
            _placePredictions = places.map((place) {
              try {
                return PlacePrediction.fromNewApiJson(place);
              } catch (e) {
                print('Error parsing place: $e');
                // Return a fallback prediction
                return PlacePrediction(
                  placeId: place['id'] ?? '',
                  description: place['displayName']?['text'] ?? 'Unknown place',
                  mainText: place['displayName']?['text']?.split(',').first ?? 'Unknown',
                  secondaryText: place['formattedAddress'] ?? '',
                );
              }
            }).toList();
            _showPredictions = true;
          });
        } else {
          print('No places found in response');
          setState(() {
            _placePredictions.clear();
            _showPredictions = false;
          });
        }
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        setState(() {
          _placePredictions.clear();
          _showPredictions = false;
        });
      }
    } catch (e) {
      print('Error fetching predictions: $e');
      setState(() {
        _placePredictions.clear();
        _showPredictions = false;
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

// Also update the _selectPlace method to handle the selection better:
  void _selectPlace(PlacePrediction prediction) {
    setState(() {
      _destinationName = prediction.mainText;
      _searchController.text = prediction.mainText;
      _showPredictions = false;
      _showBookingCard = true;
    });
    _searchFocusNode.unfocus();

    // Print for debugging
    print('Selected place: ${prediction.mainText}');
    print('Latitude: ${prediction.latitude}, Longitude: ${prediction.longitude}');
  }


  Future<void> _fetchCurrentLocation() async {
    try {
      PermissionStatus permission = await Permission.location.request();

      if (permission.isGranted) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
          if (placemarks.isNotEmpty) {
            _currentLocationName =
            '${placemarks[0].street}, ${placemarks[0].locality}';
          }
        });
      } else {
        setState(() {
          _isLoadingLocation = false;
          _currentLocationName = 'Permission denied';
        });
      }
    } catch (e) {
      print('Error fetching location: $e');
      setState(() {
        _isLoadingLocation = false;
        _currentLocationName = 'Error fetching location';
      });
    }
  }

  void _navigateToMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPage(),
      ),
    ).then((selectedLocation) {
      if (selectedLocation != null) {
        setState(() {
          _destinationName = selectedLocation['name'];
          _showBookingCard = true;
          _searchController.text = selectedLocation['name'];
        });
      }
    });
  }

  Future<void> _bookCab() async {
    // Validation checks
    if (selectedBookingType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a ride type')),
      );
      return;
    }

    if (_phonenoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your mobile number')),
      );
      return;
    }

    // Validation for Schedule Later and Outstation
    if (selectedBookingType == 'Schedule Later' || selectedBookingType == 'Outstation') {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a date')),
        );
        return;
      }

      if (_selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a time')),
        );
        return;
      }
    }

    // Validation for Rental
    if (selectedBookingType == 'Rental') {
      if (selectedRentalHours == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select rental duration')),
        );
        return;
      }
    }

    if (selectedCarType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a car type')),
      );
      return;
    }

    // Set loading state
    setState(() {
      _isBookingCab = true;
    });

    try {
      // Prepare pickup datetime
      String pickupDatetime;
      if (selectedBookingType == 'Ride Now' || selectedBookingType == 'Rental') {
        // For Ride Now and Rental, use current datetime
        final now = DateTime.now();
        pickupDatetime = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      } else {
        // For Schedule Later and Outstation
        pickupDatetime = '${_selectedDate!.day.toString().padLeft(2, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.year} ${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
      }

      // Map ride types - FIXED: rental should be 'hourly' or 'package'
      String ridesType;
      String tripType = 'one way';

      switch (selectedBookingType) {
        case 'Ride Now':
          ridesType = 'local';
          break;
        case 'Schedule Later':
          ridesType = 'local';
          break;
        case 'Rental':
          ridesType = 'hourly';  // FIXED: Changed from 'rental' to 'hourly'
          break;
        case 'Outstation':
          ridesType = 'outstation';
          break;
        default:
          ridesType = 'local';
      }

      // Prepare API request body
      final Map<String, dynamic> requestBody = {
        "rides_type": ridesType,
        "trip_type": tripType,
        "pickup_location": _currentLocationName,
        "drop_latitude": "",
        "drop_location": _destinationName,
        "drop_longitude": "",
        "pickup_datetime": pickupDatetime,
        "pickup_latitude": _currentPosition?.latitude.toString() ?? "",
        "pickup_longitude": _currentPosition?.longitude.toString() ?? "",
        "phone_number": _phonenoController.text,
      };

      // Add rental hours if applicable - Extract just the number
      if (selectedBookingType == 'Rental' && selectedRentalHours != null) {
        // Extract number from "4 Hours" -> "4"
        String hoursNumber = selectedRentalHours!.split(' ')[0];
        requestBody["rental_hours"] = hoursNumber;
      }

      print('=== Booking Request ===');
      print('Booking Type: $selectedBookingType');
      print('Mapped rides_type: $ridesType');
      print('URL: https://cabnew.staging-rdegi.com/api/taxi/booking');
      print('Body: ${json.encode(requestBody)}');
      if (selectedBookingType == 'Rental') {
        print('Rental Hours Selected: $selectedRentalHours');
        print('Rental Hours Sent: ${requestBody["rental_hours"]}');
      }

      // Make API call without Accept-Encoding to avoid gzip issues
      final response = await http.post(
        Uri.parse('${AppbaseUrl.baseurl}taxi/booking'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Connection': 'keep-alive',
        },
        body: json.encode(requestBody),
      );

      print('Response Status: ${response.statusCode}');

      // Stop loading immediately after getting response
      setState(() {
        _isBookingCab = false;
      });

      // Check for success status codes (200, 201)
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Booking successful!');

        // Try to log response body safely (optional)
        try {
          print('Response Body: ${response.body}');
        } catch (e) {
          print('Could not log response body: $e');
        }

        // Update booking state
        setState(() {
          _cabBooked = true;
          _bookingDetails = {
            'rideType': selectedBookingType,
            'pickupLocation': _currentLocationName,
            'dropLocation': _destinationName,
            'carType': selectedCarType,
            'phoneNumber': _phonenoController.text,
            'passengerCount': _passengerController.text.isNotEmpty
                ? _passengerController.text
                : 'N/A',
            'pickupDate': _selectedDate != null
                ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                : 'Now',
            'pickupTime': _selectedTime != null
                ? _selectedTime!.format(context)
                : 'Immediate',
            'rentalHours': selectedRentalHours,
            'bookingTime': DateTime.now(),
          };
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cab booked successfully! OTP sent to your phone.'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.green,
            ),
          );

          // Show arriving message after delay
          Future.delayed(Duration(seconds: 3), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Your cab is arriving soon...'),
                  duration: Duration(seconds: 2),
                  backgroundColor: AppbaseColor.Primary,
                ),
              );
            }
          });
        }

        // Success - exit the function
        return;
      }

      // Handle error responses (status codes other than 200/201)
      print('❌ Booking failed with status: ${response.statusCode}');

      String errorMessage = 'Failed to book cab. Please try again.';

      // Try to parse error message from response
      try {
        print('Attempting to parse error response...');
        final errorData = json.decode(response.body);
        print('Error response data: $errorData');

        if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        } else if (errorData['msg'] != null) {
          errorMessage = errorData['msg'];
        } else if (errorData['error'] != null) {
          errorMessage = errorData['error'];
        }
        print('Error message: $errorMessage');
      } catch (e) {
        print('Could not parse error response: $e');
        // Try to show raw response if parsing fails
        try {
          print('Raw response body: ${response.body}');
        } catch (e2) {
          print('Could not read raw response: $e2');
        }
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: Duration(seconds: 4),
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (e, stackTrace) {
      // Stop loading
      setState(() {
        _isBookingCab = false;
      });

      print('=== Network/Exception Error ===');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: $stackTrace');

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: ${e.toString().split(':').first}. Please try again.'),
            duration: Duration(seconds: 4),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Payment successful
    print("Payment Success: ${response.paymentId}");
    print("Order ID: ${response.orderId}");
    print("Signature: ${response.signature}");

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Successful!'),
        backgroundColor: Colors.green,
      ),
    );

    // TODO: Verify payment on your backend and update order status
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    // Payment failed
    print("Payment Error: ${response.code} - ${response.message}");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Failed: ${response.message}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // External wallet selected
    print("External Wallet: ${response.walletName}");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External Wallet: ${response.walletName}'),
      ),
    );
  }

  void openRazorpayCheckout() {
    var options = {
      'key': 'rzp_live_8QVaxzxdOrEnkw',
      'amount': 10000, // Amount in paise (e.g., 10000 paise = ₹100)
      'name': 'Your Company Name',
      'description': 'Payment for Order',
      'order_id': '', // Generate order_id from your backend
      'prefill': {
        'contact': '9876543210',
        'email': 'customer@example.com'
      },
      'theme': {
        'color': '#2E7D32'
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  void dispose() {
    _carController.dispose();
    _roadController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    _passengerController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  @override

  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: AppbaseColor.Primary,
        elevation: 0,
        title: Text(
          'Taxi Booking',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppbaseColor.Primary,AppbaseColor.Primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
              icon: Icon(Icons.person, color: Colors.white),
              iconSize: 26,
            ),
          )
        ],
        centerTitle: true,
        shadowColor: AppbaseColor.Primary.withOpacity(0.5),
        toolbarHeight: 65,
      ),
      body: Stack(

        children: [
          // Animated background
          AnimatedBackground(
            carAnimation: _carAnimation,
            roadController: _roadController,
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Book Now',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                      ],
                    ),
                    SizedBox(height: 24),

                    // Current Location Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppbaseColor.Primary,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Location',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _currentLocationName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Search Destination Bar with Predictions
                    Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: 'Select destination',
                              hintStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(
                                Icons.share_location_rounded,
                                color: Colors.grey,
                              ),
                              suffixIcon: _isSearching
                                  ? Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        // Predictions List
                        if (_showPredictions && _placePredictions.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.98),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            constraints: BoxConstraints(maxHeight: 300),
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: _placePredictions.length,
                              itemBuilder: (context, index) {
                                final prediction = _placePredictions[index];
                                return InkWell(
                                  onTap: () => _selectPlace(prediction),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: index <
                                          _placePredictions.length - 1
                                          ? Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                      )
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                prediction.mainText,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              if (prediction
                                                  .secondaryText.isNotEmpty)
                                                Padding(
                                                  padding:
                                                  EdgeInsets.only(top: 4),
                                                  child: Text(
                                                    prediction.secondaryText,
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                    TextOverflow.ellipsis,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Select on Map Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToMap,
                        icon: Icon(Icons.map),
                        label: Text('Select on Map'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppbaseColor.Primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 100),

                    Container(

                      width: 280,
                      height: 280,
                      child: Image.asset('assets/images/logo2.png')
                    ),
                    

                    SizedBox(height: 24),
                    // Booking Card
                    if (_showBookingCard && !_cabBooked)

                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF3c3c3c),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Book Your Cab',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.directions_car, color: AppbaseColor.Primary),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ride to $_destinationName',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Estimated fare: ₹500-700',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),

                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.call, color: AppbaseColor.Primary, size: 20),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _phonenoController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: 'Enter Your Mobile Number',
                                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      style: TextStyle(fontSize: 14, color: Colors.white70),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 16),

                            // Ride Type Selection
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdownField(
                                      label: 'Ride Type',
                                      value: selectedBookingType,
                                      items: bookingTypes,
                                      icon: Icons.local_taxi,
                                      hint: 'Select ride type',
                                      onChanged: (value) {
                                        setState(() {
                                          selectedBookingType = value;
                                          // Reset fields when switching ride types
                                          _selectedDate = null;
                                          _selectedTime = null;
                                          selectedRentalHours = null;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12),

                            // Fields for "Ride Now"
                            if (selectedBookingType == 'Ride Now') ...[
                              // Car Type
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildDropdownField(
                                        label: 'Car Type',
                                        value: selectedCarType,
                                        items: carTypes,
                                        icon: Icons.car_rental,
                                        hint: 'Select car type',
                                        onChanged: (value) {
                                          setState(() {
                                            selectedCarType = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12),
                              InkWell(
                                onTap: () async {
                                  final TimeOfDay? picked = await showTimePicker(
                                    context: context,
                                    initialTime: _selectedTime ?? TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _selectedTime = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time, color: AppbaseColor.Primary, size: 20),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _selectedTime == null
                                              ? 'Select Time'
                                              : _selectedTime!.format(context),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _selectedTime == null ? Colors.grey : Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),
                              // Passenger Count Field
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.person, color: AppbaseColor.Primary, size: 20),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _passengerController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: 'Number of Passengers',
                                          hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        style: TextStyle(fontSize: 14, color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Fields for "Schedule Later"
                            if (selectedBookingType == 'Schedule Later') ...[
                              // Date Picker Field
                              InkWell(
                                onTap: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _selectedDate = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, color: AppbaseColor.Primary, size: 20),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _selectedDate == null
                                              ? 'Select Date'
                                              : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _selectedDate == null ? Colors.grey : Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),

                              // Time Picker Field
                              InkWell(
                                onTap: () async {
                                  final TimeOfDay? picked = await showTimePicker(
                                    context: context,
                                    initialTime: _selectedTime ?? TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _selectedTime = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time, color: AppbaseColor.Primary, size: 20),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _selectedTime == null
                                              ? 'Select Time'
                                              : _selectedTime!.format(context),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _selectedTime == null ? Colors.grey : Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),

                              // Car Type
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildDropdownField(
                                        label: 'Car Type',
                                        value: selectedCarType,
                                        items: carTypes,
                                        icon: Icons.car_rental,
                                        hint: 'Select car type',
                                        onChanged: (value) {
                                          setState(() {
                                            selectedCarType = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12),

                              // Passenger Count Field
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.person, color: AppbaseColor.Primary, size: 20),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _passengerController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: 'Number of Passengers',
                                          hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        style: TextStyle(fontSize: 14, color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Fields for "Rental"
                            if (selectedBookingType == 'Rental') ...[
                              // Rental Hours Selection
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildDropdownField(
                                        label: 'Rental Duration',
                                        value: selectedRentalHours,
                                        items: ['4 Hours', '6 Hours', '8 Hours', '12 Hours', '24 Hours'],
                                        icon: Icons.schedule,
                                        hint: 'Select duration',
                                        onChanged: (value) {
                                          setState(() {
                                            selectedRentalHours = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12),

                              // Car Type
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildDropdownField(
                                        label: 'Car Type',
                                        value: selectedCarType,
                                        items: carTypes,
                                        icon: Icons.car_rental,
                                        hint: 'Select car type',
                                        onChanged: (value) {
                                          setState(() {
                                            selectedCarType = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12),

                              // Passenger Count Field
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.person, color: AppbaseColor.Primary, size: 20),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _passengerController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: 'Number of Passengers',
                                          hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        style: TextStyle(fontSize: 14, color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Fields for "Outstation"
                            if (selectedBookingType == 'Outstation') ...[
                              // Date Picker Field
                              InkWell(
                                onTap: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _selectedDate = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, color: AppbaseColor.Primary, size: 20),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _selectedDate == null
                                              ? 'Select Pickup Date'
                                              : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _selectedDate == null ? Colors.grey : Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),

                              // Time Picker Field
                              InkWell(
                                onTap: () async {
                                  final TimeOfDay? picked = await showTimePicker(
                                    context: context,
                                    initialTime: _selectedTime ?? TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _selectedTime = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time, color: AppbaseColor.Primary, size: 20),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _selectedTime == null
                                              ? 'Select Pickup Time'
                                              : _selectedTime!.format(context),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _selectedTime == null ? Colors.grey : Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),

                              // Car Type
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildDropdownField(
                                        label: 'Car Type',
                                        value: selectedCarType,
                                        items: carTypes,
                                        icon: Icons.car_rental,
                                        hint: 'Select car type',
                                        onChanged: (value) {
                                          setState(() {
                                            selectedCarType = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12),

                              // Passenger Count Field
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.person, color: AppbaseColor.Primary, size: 20),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _passengerController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: 'Number of Passengers',
                                          hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                        style: TextStyle(fontSize: 14, color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _bookCab,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppbaseColor.Primary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Book Cab',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),




                    if (_cabBooked && _bookingDetails != null)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Booking Confirmed!',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Your cab will arrive soon',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 24),

                            // Divider
                            Container(
                              height: 1,
                              color: Colors.white.withOpacity(0.3),
                            ),

                            SizedBox(height: 20),

                            // Booking Details Header
                            Text(
                              'Booking Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),

                            SizedBox(height: 16),

                            // Ride Type
                            _buildDetailRow(
                              icon: Icons.local_taxi,
                              label: 'Ride Type',
                              value: _bookingDetails!['rideType'] ?? 'N/A',
                            ),

                            SizedBox(height: 12),

                            // Pickup Location
                            _buildDetailRow(
                              icon: Icons.location_on,
                              label: 'Pickup Location',
                              value: _bookingDetails!['pickupLocation'] ?? 'N/A',
                              maxLines: 2,
                            ),

                            SizedBox(height: 12),

                            // Drop Location
                            _buildDetailRow(
                              icon: Icons.place,
                              label: 'Drop Location',
                              value: _bookingDetails!['dropLocation'] ?? 'N/A',
                              maxLines: 2,
                            ),

                            SizedBox(height: 12),

                            // Car Type
                            if (_bookingDetails!['carType'] != null)
                              Column(
                                children: [
                                  _buildDetailRow(
                                    icon: Icons.directions_car,
                                    label: 'Car Type',
                                    value: _bookingDetails!['carType'],
                                  ),
                                  SizedBox(height: 12),
                                ],
                              ),

                            // Pickup Date & Time
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailRow(
                                    icon: Icons.calendar_today,
                                    label: 'Date',
                                    value: _bookingDetails!['pickupDate'] ?? 'N/A',
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _buildDetailRow(
                                    icon: Icons.access_time,
                                    label: 'Time',
                                    value: _bookingDetails!['pickupTime'] ?? 'N/A',
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 12),

                            // Rental Hours (if applicable)
                            if (_bookingDetails!['rentalHours'] != null)
                              Column(
                                children: [
                                  _buildDetailRow(
                                    icon: Icons.schedule,
                                    label: 'Rental Duration',
                                    value: _bookingDetails!['rentalHours'],
                                  ),
                                  SizedBox(height: 12),
                                ],
                              ),

                            // Phone Number
                            _buildDetailRow(
                              icon: Icons.phone,
                              label: 'Contact Number',
                              value: _bookingDetails!['phoneNumber'] ?? 'N/A',
                            ),

                            SizedBox(height: 20),

                            // Divider
                            Container(
                              height: 1,
                              color: Colors.white.withOpacity(0.3),
                            ),

                            SizedBox(height: 20),

                            // Status Info
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'You will receive an OTP on your registered mobile number',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.95),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 16),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // Track cab functionality
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Track Cab feature coming soon!'),
                                          backgroundColor: AppbaseColor.Primary,
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.my_location, size: 20),
                                    label: Text('Track Cab'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Color(0xFF2E7D32),
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {

                                      openRazorpayCheckout;
                                    },
                                    icon: Icon(Icons.payments_outlined, size: 20),
                                    label: Text('Pay Now'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Color(0xFF2E7D32),
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      // Cancel booking functionality
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('Cancel Booking?'),
                                          content: Text('Are you sure you want to cancel this booking?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: Text('No'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  _cabBooked = false;
                                                  _bookingDetails = null;
                                                  _showBookingCard = false;
                                                });
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Booking cancelled'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              },
                                              child: Text('Yes', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.cancel_outlined, size: 20),
                                    label: Text('Cancel'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: BorderSide(color: Colors.white, width: 2),
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required String hint,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppbaseColor.Primary),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(
                icon,
                color: AppbaseColor.Primary,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            dropdownColor: Colors.white,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: (value) {
              onChanged(value);
              setState(() {});
            },
          ),
        ),
      ],
    );
  }
}

