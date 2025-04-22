import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          //  Set Background Image (splashscreen.jpg)
          Image.asset(
            'assets/splashscreen.jpg',
            fit: BoxFit.cover,
          ),
          Center(
            child: AnimatedSplashScreen(
              duration: 5000,
              splash: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //  Bold "Tea Plant AI Tool" Text
                  Text(
                    'Welcome to Tea PlantVision',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Ensure visibility on background
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
              nextScreen: const OnboardingScreen(),
              splashTransition: SplashTransition.fadeTransition,
              backgroundColor:
                  Colors.transparent, //  Make background transparent
              centered: true,
            ),
          ),
        ],
      ),
    );
  }
}
