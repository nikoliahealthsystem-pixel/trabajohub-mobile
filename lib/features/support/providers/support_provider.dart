import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod/src/framework.dart';
import '../../../core/cache/cache_provider.dart';
import '../data/api/support_api.dart';
import '../data/models/faq_model.dart';
import '../data/support_repository.dart';
import '../data/support_repository_impl.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  final api = ref.watch(supportApiProvider);
  final cache = ref.watch(appCacheProvider);

  return SupportRepositoryImpl(api, cache);
});

final faqsProvider = StateNotifierProvider<FaqsNotifier, AsyncValue<List<FaqCategory>>>((ref) {
  return FaqsNotifier();
});

class FaqsNotifier extends StateNotifier<AsyncValue<List<FaqCategory>>> {
  FaqsNotifier() : super(const AsyncValue.loading()) {
    _loadStaticFaqs();
  }

  void _loadStaticFaqs() {
    try {
      final List<Map<String, dynamic>> rawData = [
        {
          "category": "Account & Access",
          "icon": "🔐",
          "items": [
            {
              "q": "How do I reset my password?",
              "a": "Go to the login page and click 'Forgot password'. Enter your registered email address and we'll send you a secure reset link valid for 1 hour. If you don't receive it within a few minutes, check your spam folder or contact support.",
            },
            {
              "q": "Why is my account showing as 'Pending'?",
              "a": "New accounts require email verification before activation. Check your inbox for a verification email. If you're a nurse, your profile also needs credential review by our compliance team before your account is fully activated.",
            },
            {
              "q": "How do I enable two-factor authentication?",
              "a": "Navigate to Settings → Security → Two-Factor Authentication. You'll need an authenticator app (Google Authenticator or Authy). Scan the QR code shown, enter the 6-digit code to confirm, and 2FA will be enabled.",
            },
            // {
            //   "q": "Can I manage multiple device sessions?",
            //   "a": "Yes. Under Settings → Security → Active Sessions, you can view all devices currently logged into your account and revoke access to any of them individually, or sign out of all devices at once.",
            // },
          ],
        },
        {
          "category": "Credentials & Compliance",
          "icon": "📋",
          "items": [
            {
              "q": "What documents do I need to upload?",
              "a": "All nurses require at minimum: State Nursing License, CPR Certification, TB Test, Background Check, and Government ID. Some facilities may require additional documents such as OIG/SAM checks, immunisation records, or work authorisation. Check your credential dashboard for a complete list.",
            },
            {
              "q": "How long does credential review take?",
              "a": "Standard review takes 1–3 business days. You'll receive an email and push notification when each document is approved or if any action is required. Urgent cases can be escalated by contacting support.",
            },
            {
              "q": "My credential was rejected — what do I do?",
              "a": "Open the rejected credential in your dashboard to see the specific rejection reason. Common issues include blurry scans, expired documents, or mismatched name fields. Re-upload a clear, updated copy and it will be re-reviewed.",
            },
            {
              "q": "I will receive alerts before my credentials expire?",
              "a": "Yes. You'll receive automated email and push notifications at 60 days, 30 days, 14 days, and 7 days before any approved credential expires. You can upload a renewal at any point and it will be reviewed before the expiry date.",
            },
          ],
        },
        {
          "category": "Shifts & Scheduling",
          "icon": "📅",
          "items": [
            {
              "q": "How does shift booking work?",
              "a": "Open shifts appear on your Marketplace screen filtered to your designation and location. Tap a shift to view full details including pay rate, case notes, and required specialties. Tap 'Book Shift' to claim it instantly — our system prevents double-booking automatically.",
            },
            {
              "q": "Can I cancel a shift I've already booked?",
              "a": "Yes, but please do so as early as possible so the facility can find a replacement. Navigate to My Shifts, select the shift, and tap Cancel. Frequent last-minute cancellations may affect your performance score.",
            },
            {
              "q": "What is the geofence check-in radius?",
              "a": "You must be within 200 metres of the patient's address to check in via GPS. If you're flagged as outside this radius, an override request is automatically sent to the facility administrator for manual approval.",
            },
            {
              "q": "What happens if I miss a check-in?",
              "a": "If you were present but couldn't check in electronically, contact your facility administrator immediately. They can process a manual visit record and approve the override on their dashboard. Always document the reason in your visit notes.",
            },
          ],
        },
        {
          "category": "Payments & Billing",
          "icon": "💳",
          "items": [
            {
              "q": "When do I get paid?",
              "a": "Payouts are processed after each shift is verified and marked complete. Funds typically arrive in your linked bank account within 2–5 business days via Stripe Connect. You can track all pending and settled payouts in your Wallet dashboard.",
            },
            {
              "q": "How do I set up my payout account?",
              "a": "Go to Profile → Wallet → Set Up Payouts. You'll complete a quick Stripe onboarding flow where you link your bank account. This is required before you can accept your first paid shift.",
            },
          ],
        },
      ];

      final categories = rawData.map((json) => FaqCategory.fromJson(json)).toList();

      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void refresh() => _loadStaticFaqs();
}

// Contact Form State
final contactFormProvider = StateNotifierProvider<ContactFormNotifier, ContactFormState>((ref) {
  return ContactFormNotifier(ref.watch(supportRepositoryProvider));
});

class ContactFormState {
  final String name;
  final String email;
  final String category;
  final String message;
  final bool isLoading;
  final String? error;
  final String? ticketNumber;

  ContactFormState({
    this.name = '',
    this.email = '',
    this.category = '',
    this.message = '',
    this.isLoading = false,
    this.error,
    this.ticketNumber,
  });

  ContactFormState copyWith({
    String? name,
    String? email,
    String? category,
    String? message,
    bool? isLoading,
    String? error,
    String? ticketNumber,
  }) {
    return ContactFormState(
      name: name ?? this.name,
      email: email ?? this.email,
      category: category ?? this.category,
      message: message ?? this.message,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      ticketNumber: ticketNumber,
    );
  }
}

class ContactFormNotifier extends StateNotifier<ContactFormState> {
  final SupportRepository _repo;

  ContactFormNotifier(this._repo) : super(ContactFormState());

  void updateField(String field, String value) {
    state = state.copyWith(
      name: field == 'name' ? value : null,
      email: field == 'email' ? value : null,
      category: field == 'category' ? value : null,
      message: field == 'message' ? value : null,
      error: null,
    );
  }

  Future<void> submit(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repo.submitTicket(
        name: state.name.trim(),
        email: state.email.trim(),
        category: state.category,
        message: state.message.trim(),
        userId: userId,
      );

      state = state.copyWith(
        isLoading: false,
        ticketNumber: result.ticketNumber,
      );
    } catch (e) {
      final msg = e is DioException ? (e.message ?? 'Something went wrong') : e.toString();
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  void reset() {
    state = ContactFormState();
  }
}