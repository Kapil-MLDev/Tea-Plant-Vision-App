import 'package:flutter_test/flutter_test.dart';
import 'package:tea_plant_vision/main.dart';
import 'package:tea_plant_vision/screens/animated_splash_screen.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const MyApp());

    // Verify the app starts with AnimatedSplashScreen
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}