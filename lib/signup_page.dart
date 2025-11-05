import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taxibooking/login_page.dart';
import 'signup_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'home_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final storage = FlutterSecureStorage();

  bool _isLoading = false;
  bool _termsAccepted = false;
  bool _isGettingLocation = false;

  // Location variables
  String _latitude = '';
  String _longitude = '';

  late AnimationController _carController;
  late AnimationController _roadController;
  late Animation<double> _carAnimation;

  @override
  void initState() {
    super.initState();

    // Car animation - moves horizontally
    _carController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _carAnimation = Tween<double>(begin: -0.3, end: 1.3).animate(
      CurvedAnimation(parent: _carController, curve: Curves.easeInOut),
    );

    // Road lines animation - moves vertically
    _roadController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Get current location when page loads
    _getCurrentLocation();
  }

  // Function to get current location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location services are disabled. Please enable them.'),
            backgroundColor: Colors.orange.shade400,
          ),
        );
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location permissions are denied.'),
              backgroundColor: Colors.orange.shade400,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location permissions are permanently denied. Please enable them in app settings.'),
            backgroundColor: Colors.orange.shade400,
          ),
        );
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude.toString();
        _longitude = position.longitude.toString();
      });

      print('Location obtained: Lat: $_latitude, Long: $_longitude');

    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get current location. Please check permissions.'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBackground(
            carAnimation: _carAnimation,
            roadController: _roadController,
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Join QuickRide and start your journey',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),

                        SizedBox(height: 32),

                        // Signup Form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Full Name Field
                              _buildInputField(
                                controller: _nameController,
                                hintText: 'Full Name',
                                prefixIcon: Icons.person_outline,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your full name';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 16),

                              // Email Field
                              _buildInputField(
                                controller: _emailController,
                                hintText: 'Email Address',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                      .hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 16),

                              // Phone Number Field
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 15,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: TextStyle(fontSize: 15),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: 'Phone Number',
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    prefixIcon: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.phone_outlined,
                                              color: Color(0xFFF79D39)),
                                          SizedBox(width: 8),
                                          Text(
                                            '+91',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Container(
                                            width: 1,
                                            height: 24,
                                            color: Colors.grey.shade300,
                                          ),
                                        ],
                                      ),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 18),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your phone number';
                                    }
                                    if (value.length != 10) {
                                      return 'Please enter a valid 10-digit phone number';
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              SizedBox(height: 16),

                              // Address Field
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 15,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _addressController,
                                  keyboardType: TextInputType.streetAddress,
                                  style: TextStyle(fontSize: 15),
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    hintText: 'Full Address',
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    prefixIcon: Icon(Icons.location_on_outlined,
                                        color: Color(0xFFF79D39)),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 18),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your address';
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              SizedBox(height: 16),

                              // Location Status
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    _isGettingLocation
                                        ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(Color(0xFFF79D39)),
                                      ),
                                    )
                                        : Icon(
                                      _latitude.isNotEmpty ? Icons.check_circle : Icons.location_off,
                                      color: _latitude.isNotEmpty ? Colors.green : Colors.orange,
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _isGettingLocation
                                                ? 'Getting your location...'
                                                : _latitude.isNotEmpty
                                                ? 'Location obtained successfully'
                                                : 'Location not available',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (_latitude.isNotEmpty) ...[
                                            SizedBox(height: 4),
                                            Text(
                                              'Lat: $_latitude, Long: $_longitude',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (!_isGettingLocation && _latitude.isEmpty)
                                      TextButton(
                                        onPressed: _getCurrentLocation,
                                        child: Text(
                                          'Retry',
                                          style: TextStyle(
                                            color: Color(0xFFF79D39),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 20),

                              // Terms and Conditions
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _termsAccepted,
                                      onChanged: (value) {
                                        setState(() {
                                          _termsAccepted = value ?? false;
                                        });
                                      },
                                      activeColor: Color(0xFFF79D39),
                                      checkColor: Colors.white,
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          text: 'I agree to the ',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 13,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'Terms of Service',
                                              style: TextStyle(
                                                color: Color(0xFFF79D39),
                                                fontWeight: FontWeight.w600,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                            TextSpan(text: ' and '),
                                            TextSpan(
                                              text: 'Privacy Policy',
                                              style: TextStyle(
                                                color: Color(0xFFF79D39),
                                                fontWeight: FontWeight.w600,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 24),

                              // Sign Up Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: (_isLoading || !_termsAccepted || _latitude.isEmpty)
                                      ? null
                                      : _signup,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFF79D39),
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    shadowColor: Color(0xFFF79D39).withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    disabledBackgroundColor: Colors.grey.shade600,
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                      : Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 30),

                        // Login Link
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 15,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Log In',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(prefixIcon, color: Color(0xFFF79D39)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        validator: validator,
      ),
    );
  }

  void _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String phoneno = _phoneController.text.trim();
    final String address = _addressController.text.trim();

    await storage.write(key: 'name', value: _nameController.text);
    await storage.write(key: 'email', value: _emailController.text);
    await storage.write(key: 'phoneno', value: _phoneController.text);


    try {
      var url = Uri.parse('https://cabnew.staging-rdegi.com/api/user/register');

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone_number': phoneno,
          'address': address,
          'latitude': _latitude,
          'longitude': _longitude,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Success: ${response.body}');

        // Navigate to OTP verification page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationPage(
              email: email,
              sessionToken: responseData['data']['token'] ?? responseData['token'],
            ),
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? 'Registration failed. Please try again.'),
            backgroundColor: Colors.red.shade400,
          ),
        );
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error. Please check your connection.'),
          backgroundColor: Colors.red.shade400,
        ),
      );
      print('Exception: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _carController.dispose();
    _roadController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}

// OTP Verification Page

// OTP Verification Page
class OTPVerificationPage extends StatefulWidget {
  final String email;
  final String? sessionToken;

  const OTPVerificationPage({Key? key, required this.email, this.sessionToken}) : super(key: key);

  @override
  _OTPVerificationPageState createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage>
    with TickerProviderStateMixin {
  final List<TextEditingController> _otpControllers =
  List.generate(5, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (index) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;

  late AnimationController _carController;
  late AnimationController _roadController;
  late Animation<double> _carAnimation;

  @override
  void initState() {
    super.initState();

    _carController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _carAnimation = Tween<double>(begin: -0.3, end: 1.3).animate(
      CurvedAnimation(parent: _carController, curve: Curves.easeInOut),
    );

    _roadController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  void _handleVerifyOTP() async {
    String otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter complete 5-digit OTP'),
          backgroundColor: Colors.orange.shade400,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var url = Uri.parse('https://cabnew.staging-rdegi.com/api/user/otp/login');

      var requestBody = {
        'email': widget.email,
        'otp': otp,
      };
      //


      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('OTP Verified Successfully: ${response.body}');

        // Navigate to home page or next screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
              (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account verified successfully!'),
            backgroundColor: Colors.green.shade400,
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? 'Invalid OTP. Please try again.'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleResendOTP() async {
    setState(() {
      _isResending = true;
    });

    try {
      var url = Uri.parse('https://cabnew.staging-rdegi.com/api/user/otp/login');

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New OTP sent to your email!'),
            backgroundColor: Colors.green.shade400,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend OTP. Please try again.'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBackground(
            carAnimation: _carAnimation,
            roadController: _roadController,
          ),

          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          'Verify Email',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            text: 'Code sent to ',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            children: [
                              TextSpan(
                                text: widget.email,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 40),

                        // OTP Input Fields - 5 digits
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(5, (index) {
                            return SizedBox(
                              width: 55,
                              height: 60,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _otpControllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(1),
                                  ],
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    counterText: '',
                                  ),
                                  onChanged: (value) {
                                    if (value.length == 1 && index < 4) {
                                      _focusNodes[index + 1].requestFocus();
                                    } else if (value.isEmpty && index > 0) {
                                      _focusNodes[index - 1].requestFocus();
                                    }

                                    // Auto-submit when last digit is entered
                                    if (index == 4 && value.isNotEmpty) {
                                      _handleVerifyOTP();
                                    }
                                  },
                                ),
                              ),
                            );
                          }),
                        ),

                        SizedBox(height: 30),

                        // Verify Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleVerifyOTP,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFF79D39),
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: Color(0xFFF79D39).withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                                : Text(
                              'Verify',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 30),

                        // Resend Code
                        Center(
                          child: _isResending
                              ? CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Color(0xFFF79D39)),
                          )
                              : GestureDetector(
                            onTap: _handleResendOTP,
                            child: Text(
                              'Resend Code',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _carController.dispose();
    _roadController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
// Animated Background Widget
class AnimatedBackground extends StatelessWidget {
  final Animation<double> carAnimation;
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
          // Animated road lines
          AnimatedBuilder(
            animation: roadController,
            builder: (context, child) {
              return CustomPaint(
                painter: RoadLinesPainter(roadController.value),
                size: Size.infinite,
              );
            },
          ),

          // Animated taxi cars
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
                    color: Color(0xFFF79D39).withOpacity(0.3),
                  ),
                ),
              );
            },
          ),

          // Second car
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
                    color: Color(0xFFF79D39).withOpacity(0.2),
                  ),
                ),
              );
            },
          ),

          // Decorative dots
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

// Custom painter for road lines
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
