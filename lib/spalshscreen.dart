import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimatedSplashScreen extends StatefulWidget {
  final Widget nextScreen;
  final Duration duration;

  const AnimatedSplashScreen({
    Key? key,
    required this.nextScreen,
    this.duration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _carController;
  late AnimationController _roadController;
  late AnimationController _logoController;
  late Animation<double> _carAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Set status bar color
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Car animation controller
    _carController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _carAnimation = Tween<double>(begin: -0.2, end: 1.2).animate(
      CurvedAnimation(parent: _carController, curve: Curves.linear),
    );

    // Road animation controller
    _roadController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    // Logo animation controller
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    // Start logo animation
    _logoController.forward();

    // Navigate to next screen after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => widget.nextScreen),
        );
      }
    });
  }

  @override
  void dispose() {
    _carController.dispose();
    _roadController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedBackground(
            carAnimation: _carAnimation,
            roadController: _roadController,
          ),

          // Logo and app name in center
          Center(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoFadeAnimation.value,
                  child: Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Icon/Logo
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF79D39),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF79D39).withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_taxi,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // App Name
                        const Text(
                          'Taxi Booking',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Tagline
                        Text(
                          'Your Ride, Your Way',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Loading indicator at bottom
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoFadeAnimation.value,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF79D39)),
                      strokeWidth: 3,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Your AnimatedBackground class
class AnimatedBackground extends StatelessWidget {
  final Animation<double> carAnimation;
  final AnimationController roadController;

  const AnimatedBackground({
    Key? key,
    required this.carAnimation,
    required this.roadController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
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
                    color: const Color(0xFFF79D39).withOpacity(0.3),
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
                    color: const Color(0xFFF79D39).withOpacity(0.2),
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

// Example usage in main.dart:
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: AnimatedSplashScreen(
//         nextScreen: const HomeScreen(), // Your home screen
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }
// }