import 'dart:math';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:college_app/auth/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(const Duration(milliseconds: 800)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return AnimatedSplashScreen(
            splash: const SplashContent(),
            splashIconSize: double.infinity,
            duration: 6000,
            backgroundColor: const Color(0xFF1A1B41), // Dark blue background
            splashTransition: SplashTransition.fadeTransition,
            nextScreen: const Wrapper(),
          );
        } else {
          return Container(
            color: const Color(0xFF1A1B41),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF16F4D0), // Bright cyan for loader
              ),
            ),
          );
        }
      },
    );
  }
}

class SplashContent extends StatefulWidget {
  const SplashContent({super.key});

  @override
  State<SplashContent> createState() => _SplashContentState();
}

class _SplashContentState extends State<SplashContent> with TickerProviderStateMixin {
  late final AnimationController _lottieController;
  late final AnimationController _rotationController;
  late final AnimationController _scaleController;
  late final AnimationController _slideController;
  late final AnimationController _particleController;
  late final AnimationController _fadeController;
  late final AnimationController _visibilityController;

  // Particle colors
  final List<Color> particleColors = [
    const Color(0xFF16F4D0), // Cyan
    const Color(0xFFFF595E), // Coral
    const Color(0xFFFFCA3A), // Yellow
    const Color(0xFF8AC926), // Green
  ];

  @override
  void initState() {
    super.initState();
    
    _visibilityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _lottieController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Start the animation sequence with delay
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    
    // Start animations in sequence
    await _visibilityController.forward();
    _lottieController.forward();
    _scaleController.forward();
    _slideController.forward();
    _fadeController.forward();
  }


  @override
  void dispose() {
    _visibilityController.dispose();
    _lottieController.dispose();
    _rotationController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _particleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Widget _buildParticle(double left, double top, int index) {
    final random = Random(index);
    final baseSize = 4.0 + random.nextDouble() * 4;
    final color = particleColors[index % particleColors.length];
    
    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          final t = _particleController.value;
          final wave = sin(t * 2 * pi + index);
          final scale = 0.8 + 0.2 * wave;
          
          return Transform(
            transform: Matrix4.identity()
              ..translate(
                30 * cos(t * 2 * pi + index * 0.8),
                30 * sin(t * 2 * pi + index * 1.2),
              )
              ..scale(scale),
            child: Container(
              width: baseSize,
              height: baseSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.8),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: baseSize * 2,
                    spreadRadius: baseSize * 0.5,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1B41), // Dark blue
            Color(0xFF222456), // Slightly lighter blue
          ],
        ),
      ),
      child: Stack(
        children: [
          // Animated Background Glow
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..rotateZ(_rotationController.value * pi / 6),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [
                        const Color(0xFF16F4D0).withOpacity(0.15),
                        Colors.transparent,
                      ],
                      stops: const [0.2, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // Enhanced Particles Layer
          ...List.generate(40, (index) {
            final random = Random(index);
            final left = random.nextDouble() * size.width;
            final top = random.nextDouble() * size.height;
            return _buildParticle(left, top, index);
          }),

          // Main Content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Lottie Animation with fade-in and full screen responsiveness
                    AnimatedBuilder(
                      animation: Listenable.merge([_scaleController, _visibilityController]),
                      builder: (context, child) {
                        return Opacity(
                          opacity: _visibilityController.value,
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.002)
                              ..scale(0.9 + _scaleController.value * 0.15)
                              ..rotateX(_scaleController.value * 0.03)
                              ..rotateY(_scaleController.value * 0.02),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF16F4D0).withOpacity(0.2),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              // Updated Lottie dimensions to be fully responsive
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  // Calculate the maximum available space
                                  double maxWidth = size.width;
                                  double maxHeight = size.height * 0.6; // 60% of screen height
                                  
                                  // Maintain aspect ratio while filling available space
                                  double aspectRatio = 1.0; // Adjust this based on your Lottie file's aspect ratio
                                  double width = maxWidth;
                                  double height = width / aspectRatio;
                                  
                                  if (height > maxHeight) {
                                    height = maxHeight;
                                    width = height * aspectRatio;
                                  }
                                  
                                  return LottieBuilder.asset(
                                    'assets/lottie/splash.json',
                                    width: width,
                                    height: height,
                                    fit: BoxFit.contain,
                                    controller: _lottieController,
                                    animate: true,
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30), // Reduced spacing

                    // Enhanced Animated Text with single line responsiveness
                    AnimatedBuilder(
                      animation: _slideController,
                      builder: (context, child) {
                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..translate(
                              0.0,
                              40.0 * (1.0 - _slideController.value),
                              _slideController.value * 50,
                            ),
                          child: Opacity(
                            opacity: _slideController.value,
                            child: Container(
                              width: size.width * 0.9, // Responsive width
                              padding: EdgeInsets.symmetric(
                                horizontal: size.width * 0.05, // Responsive padding
                                vertical: size.height * 0.02,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF16F4D0).withOpacity(0.15),
                                    const Color(0xFFFF595E).withOpacity(0.15),
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(0xFF16F4D0).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: AnimatedTextKit(
                                  animatedTexts: [
                                    ColorizeAnimatedText(
                                      'Ignite Your Learning!',
                                      textStyle: TextStyle(
                                        fontSize: size.width * 0.06, // Responsive font size
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Poppins',
                                        letterSpacing: 1.0,
                                        height: 1.2,
                                      ),
                                      colors: const [
                                        Color(0xFF16F4D0), // Cyan
                                        Color(0xFFFFCA3A), // Yellow
                                        Color(0xFFFF595E), // Coral
                                        Color(0xFF16F4D0), // Cyan
                                      ],
                                      speed: const Duration(milliseconds: 200),
                                    ),
                                  ],
                                  isRepeatingAnimation: true,
                                  totalRepeatCount: 3,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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
}