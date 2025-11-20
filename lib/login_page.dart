import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taxibooking/app_basecolor.dart';
import 'signup_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'home_page.dart';
import 'authservice.dart';
import 'app_baseurl.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _otpSent = false;
  bool _verifyingOtp = false;
  String? _sessionToken; // Store session token from OTP response

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
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 40),

                  // App Logo and Title
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 250,
                          height: 250,

                          child: Image.asset('assets/images/logo2.png')
                        ),

                      ],
                    ),
                  ),

                  SizedBox(height: 50),

                  // Welcome Text
                  Text(
                    _otpSent ? 'Enter OTP' : 'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _otpSent
                        ? 'We sent a code to ${_emailController.text}'
                        : 'Enter your credentials to continue',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),

                  SizedBox(height: 32),

                  // Login Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (!_otpSent) ...[
                          // Email Field
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
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(fontSize: 15),
                              decoration: InputDecoration(
                                hintText: 'Enter your mobile number',
                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                prefixIcon: Icon(Icons.phone, color: AppbaseColor.Primary),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter mobile number';
                                }
                                // if (!value.contains('@')) {
                                //   return 'Please enter a valid email';
                                // }
                                return null;
                              },
                            ),
                          ),

                          SizedBox(height: 16),

                          // Password Field (Optional for OTP flow)
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

                          ),

                          SizedBox(height: 12),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // Handle forgot password
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],

                        if (_otpSent) ...[
                          // OTP Field
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
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(fontSize: 15, letterSpacing: 4),
                              textAlign: TextAlign.center,
                              maxLength: 7,
                              decoration: InputDecoration(
                                hintText: 'Enter 6-digit OTP',
                                hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 0),
                                prefixIcon: Icon(Icons.sms_outlined, color: AppbaseColor.Primary),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                counterText: '',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter OTP';
                                }
                                if (value.length != 6) {
                                  return 'OTP must be 6 digits';
                                }
                                return null;
                              },
                            ),
                          ),

                          SizedBox(height: 12),

                          // Resend OTP
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading ? null : _resendOtp,
                              child: Text(
                                'Resend OTP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],

                        SizedBox(height: 8),

                        // Login/Verify Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading || _verifyingOtp ? null :
                            _otpSent ? _verifyOtp : _sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppbaseColor.Primary,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              // shadowColor: AppbaseColor.Primary.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading || _verifyingOtp
                                ? SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                                : Text(
                              _otpSent ? 'Verify OTP' : 'Send OTP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                        if (_otpSent) ...[
                          SizedBox(height: 16),
                          // Back to email button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _backToEmail,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
                                backgroundColor: Colors.white.withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Back to Phone',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (!_otpSent) ...[
                    SizedBox(height: 32),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withOpacity(0.3),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withOpacity(0.3),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 32),

                    // Social Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          // Handle Google login
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
                          backgroundColor: Colors.white.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.g_mobiledata, size: 28, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 40),

                  // Sign Up Link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 15,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SignupPage()),
                            );
                          },
                          child: Text(
                            'Sign Up',
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
    );
  }

  void _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String email = _emailController.text.trim();

      var url = Uri.parse('${AppbaseUrl.baseurl}user/two/factor/otp/send');

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': email}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('OTP Sent Successfully: ${response.body}');

        // Store session token if provided in response
        _sessionToken = responseData['data']['token'] ?? responseData['token'];

        setState(() {
          _otpSent = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to your email!'),
            backgroundColor: Colors.green.shade400,
          ),
        );
      } else {
        print('Error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send OTP. Please try again.'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } catch (e) {
      print('Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _verifyOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _verifyingOtp = true;
    });

    try {
      final String email = _emailController.text.trim();
      final String otp = _otpController.text.trim();

      var url = Uri.parse('${AppbaseUrl.baseurl}user/two/factor/otp/verify');

      var requestBody = {
        'phone_number': email,
        'otp': otp,
      };

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('OTP Verified Successfully: ${response.body}');

        final tokenData = responseData['data'];
        print('Token Data: $tokenData');

        await AuthService.saveAuthData(
          accessToken: tokenData['access_token'] ?? '',
          refreshToken: tokenData['refresh_token'] ?? '',
          tokenType: tokenData['token_type'] ?? 'Bearer',
          expiresIn: tokenData['expires_in'] ?? 3600,
          userData: tokenData,
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
              (route) => false,
        );
      }

        else {
        print('Error: ${response.statusCode}');
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? 'Invalid OTP. Please try again.'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } catch (e) {
      print('Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      setState(() {
        _verifyingOtp = false;
      });
    }
  }
  void _resendOtp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String email = _emailController.text.trim();

      var url = Uri.parse('${AppbaseUrl.baseurl}user/otp/login');

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        _sessionToken = responseData['data']['token'] ?? responseData['token'];

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
      print('Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _backToEmail() {
    setState(() {
      _otpSent = false;
      _otpController.clear();
    });
  }



  @override
  void dispose() {
    _carController.dispose();
    _roadController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}

// Animated Background Widget (same as before)
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

          // Second car with different timing
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

// Custom painter for road lines (same as before)
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

    // Draw multiple columns of dashed lines
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

