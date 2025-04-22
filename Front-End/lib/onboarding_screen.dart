import 'package:flutter/material.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            children: const [
              OnboardingPage(
                  image: 'assets/tea1.png',
                  title: 'Scan Leaves',
                  description: 'Easily scan tea leaves to detect diseases.'),
              OnboardingPage(
                  image: 'assets/tea2.png',
                  title: 'AI Analysis',
                  description: 'Get AI-powered disease detection results.'),
              OnboardingPage(
                  image: 'assets/tea3.png',
                  title: 'Instant Reports',
                  description: 'Receive instant reports with solutions.'),
            ],
          ),

          // Back Button Positioned at the Bottom Left
          if (currentIndex > 0)
            Positioned(
              bottom: 40,
              left: 20,
              child: ElevatedButton(
                onPressed: () {
                  _pageController.previousPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.ease);
                },
                child: const Text("Back"),
              ),
            ),

          // Next / Get Started Button Positioned at the Bottom Right
          Positioned(
            bottom: 40,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                if (currentIndex < 2) {
                  _pageController.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.ease);
                } else {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()));
                }
              },
              child: Text(currentIndex == 2 ? "Get Started" : "Next"),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String image;
  final String title;
  final String description;

  const OnboardingPage(
      {super.key,
      required this.image,
      required this.title,
      required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(image, width: 300),
        const SizedBox(height: 20),
        Text(title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
