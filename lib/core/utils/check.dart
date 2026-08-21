import 'package:flutter/material.dart';
import 'package:trabajo_hub/core/constants/app_constants.dart';

class checks extends StatelessWidget {
  const checks({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection: TextDirection.ltr,
        child: MaterialApp(
            debugShowCheckedModeBanner: true,
            theme: ThemeData(
              scaffoldBackgroundColor: const Color.fromARGB(255, 243, 243, 243),
              appBarTheme: const AppBarTheme(
                surfaceTintColor: Color.fromARGB(255, 243, 243, 243),
                centerTitle: true,
                iconTheme: IconThemeData(),
                backgroundColor: Color.fromARGB(255, 243, 243, 243),
              ),
              applyElevationOverlayColor: false,
              fontFamily: 'Poppins',
            ),
            home:Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Icon(
                  Icons.lock_clock_rounded,
                  size: 72,
                  color: accentColor,
                ),
                const SizedBox(height: 24),
                const Text(
                  "Demo Expired",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "This evaluation build is no longer available.\n\n"
                      "Please contact the developer for an updated build.",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    )));
  }
}