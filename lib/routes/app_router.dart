import 'package:go_router/go_router.dart';
import '../features/auth/presentation/sign_in.dart';
import '../features/auth/presentation/splash_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) =>
      const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, __) =>
      const SignIn(),
    ),
    // GoRoute(
    //   path: '/register',
    //   builder: (_, __) =>
    //   const RegisterScreen(),
    // ),
    // GoRoute(
    //   path: '/verify-email',
    //   builder: (_, __) =>
    //   const VerifyEmailScreen(),
    // ),
    // GoRoute(
    //   path: '/forgot-password',
    //   builder: (_, __) =>
    //   const ForgotPasswordScreen(),
    // ),
  ],
);