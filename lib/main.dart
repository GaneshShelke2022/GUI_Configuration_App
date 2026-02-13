import 'package:flutter/material.dart';
import 'login/login_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});



  @override 
  Widget build(BuildContext context) { 
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // Use builder to overlay the company logo on top-left of every page
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            Positioned(
              top: 2,
              left: 10,
              
              child: SafeArea(
                child: IgnorePointer(
                  // IgnorePointer lets taps pass through the overlaid logo
                  // so dropdowns and other interactive widgets beneath it remain usable.
                  child: Image.asset(
                    'assets/images/logo4.png',
                    width: 240,
                    height: 45,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      home: const LoginView(),
    );
  }
}
