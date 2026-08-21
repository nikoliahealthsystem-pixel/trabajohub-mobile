import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../../active_session.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import 'sign_in.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splashState = ref.watch(splashDelayProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      child: splashState.when(
        data: (loggedIn) => loggedIn ? const ActiveSession() : const SignIn(),
        loading: () => const _LoadingView(),
        error: (err, stack) {
          debugPrint('Auth Check Error: $err');
          return const SignIn();
        },
      ),
    );
  }
}


class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: ColorConstants.appGradient),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24),
              child: Lottie.asset(
              'assets/lottie/splash.json',
              repeat: true,
              animate: true,
            ),),
            const SizedBox(height: 20),
            Text(
              "Trabajo Heroes",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 28
              ),
            ),
          ],
        ),
      ),
    );
  }
}