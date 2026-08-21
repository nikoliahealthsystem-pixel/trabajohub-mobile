import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/support_provider.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // prefill after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillUserData();
    });
  }

  void _prefillUserData() {
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user != null) {
      final notifier = ref.read(contactFormProvider.notifier);

      notifier.updateField('name', user.displayName?? '');
      notifier.updateField('email', user.email ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(contactFormProvider);
    final authState = ref.watch(authProvider);
    final notifier = ref.read(contactFormProvider.notifier);

    // Re-prefill if user changes (rare but safe)
    if (authState.user != null &&
        (formState.name.isEmpty || formState.email.isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prefillUserData();
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),

              if (formState.ticketNumber != null) ...[
                _buildSuccessScreen(formState.ticketNumber!, notifier),
              ] else ...[
                _buildContactForm(formState, notifier, authState.user),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Container(
    width: double.maxFinite,
    decoration: const BoxDecoration(gradient: ColorConstants.appGradient),
    padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 24),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need Help?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Our team typically responds within 24 hours.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildContactForm(
      ContactFormState state,
      ContactFormNotifier notifier,
      dynamic currentUser, // your user object
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Name (Read Only)
          _buildReadOnlyField(
            label: 'Full Name',
            value: state.name,
          ),
          const SizedBox(height: 16),

          // Email (Read Only)
          _buildReadOnlyField(
            label: 'Email Address',
            value: state.email,
          ),
          const SizedBox(height: 16),

          _buildCategoryDropdown(state, notifier),
          const SizedBox(height: 16),

          _buildTextField(
            label: 'Message',
            value: state.message,
            onChanged: (v) => notifier.updateField('message', v),
            validator: (v) => v!.length < 20 ? 'Please provide more details' : null,
            maxLines: 6,
          ),

          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(state.error!, style: const TextStyle(color: Colors.red)),
            ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: state.isLoading
                  ? null
                  : () {
                if (_formKey.currentState!.validate()) {
                final user = ref.read(authProvider).user;
                  notifier.submit(user?.id??"");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: state.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send Message',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // New Read-Only Field
  Widget _buildReadOnlyField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFF8FAFC),
          ),
          child: Text(
            value.isNotEmpty ? value : "—",
            style: const TextStyle(fontSize: 15, color: Color(0xFF334155)),
          ),
        ),
      ],
    );
  }

  // Keep your existing _buildTextField for Message
  Widget _buildTextField({
    required String label,
    required String value,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    int? maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  // Your existing success screen...
  Widget _buildSuccessScreen(String ticketNumber, ContactFormNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Color(0xFF10B981)),
            const SizedBox(height: 24),
            const Text('Message Received!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Ticket Reference: $ticketNumber', style: const TextStyle(fontFamily: 'monospace')),
            const SizedBox(height: 32),
            TextButton.icon(
              onPressed: () => notifier.reset(),
              icon: const Icon(Icons.refresh),
              label: const Text('Submit Another Ticket'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(ContactFormState state, ContactFormNotifier notifier) {
    const categories = {
      'account': 'Account & Access',
      'credentials': 'Credentials & Compliance',
      'shifts': 'Shifts & Scheduling',
      'payments': 'Payments & Billing',
      'technical': 'Technical Issue',
      'other': 'Other',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: state.category.isEmpty ? null : state.category,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          items: categories.entries.map((e) {
            return DropdownMenuItem(value: e.key, child: Text(e.value));
          }).toList(),
          onChanged: (val) => notifier.updateField('category', val ?? ''),
        ),
      ],
    );
  }
}