import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
// import 'package:college_app/login.dart';
import 'package:college_app/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: LottieBuilder.asset(
              'assets/lottie/Animation - 1722074579858.json',
              width: MediaQuery.of(context).size.width * 0.9,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20), // Space between animation and text
          Center(
            child: AnimatedTextKit(
              animatedTexts: [
                ColorizeAnimatedText(
                  'Shiksha Hub!',
                  textStyle: const TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold,
                    // color: Colors.deepPurple,
                  ), colors: [Colors.deepPurple,Colors.red, Colors.green, Colors.blue],                 
                ),
              ],
              isRepeatingAnimation: true,
            ),
          ),
        ],
      ),
      splashIconSize: 500,
      backgroundColor: Colors.white,
      nextScreen: const Wrapper(),
    );
  }
}
