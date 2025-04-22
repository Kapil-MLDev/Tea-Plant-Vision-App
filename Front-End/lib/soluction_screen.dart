import 'package:flutter/material.dart';

class SolutionScreen extends StatelessWidget {
  const SolutionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Solution Screen"),
        backgroundColor: Colors.green[700],
      ),
      body: const Center(
        child: Text(
          "This is the Solution Screen",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
