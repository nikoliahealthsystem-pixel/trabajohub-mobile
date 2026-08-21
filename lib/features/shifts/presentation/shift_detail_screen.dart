import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/buttons/button_big.dart';
import '../../../core/widgets/buttons/notification_button.dart';
import '../data/models/shift_model.dart';
import '../providers/shifts_provider.dart';
import '../state/marketplace_state.dart';

class ShiftDetailScreen extends ConsumerWidget {
  final String shiftId;
  const ShiftDetailScreen({super.key, required this.shiftId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncShift = ref.watch(shiftDetailProvider(shiftId));
    final marketplaceState = ref.watch(marketplaceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: asyncShift.when(
        loading: () =>  Center(child: CircularProgressIndicator(color: accentColor)),
        error: (e, _) => Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/svg/list.svg',
              width: 72,
              height: 72,
              color: Colors.grey,
            ),
          SizedBox(height: 24),
          Text(e is DioException ? (e.message ?? 'Something went wrong') : e.toString()),
            TextButton(onPressed:()=>Navigator.pop(context), child: Text("Go Back",style: TextStyle(color: accentColor),))
        ],)),
        data: (shift) => _ShiftDetailBody(
          shift: shift as ShiftModel,
          isBooking: marketplaceState.bookingShiftId == shiftId,
          onBook: () async {
            final success = await ref.read(marketplaceProvider.notifier).bookShift(shiftId);
            final errorMessage = await ref.read(marketplaceProvider).bookingError;
            if (!context.mounted) return;
            if (success) Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? 'Shift booked!' : errorMessage!.length  < 50 ? "${errorMessage}" : "Booking Failed"),
                backgroundColor: success ? const Color(0xFF0F6E56) : Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ShiftDetailBody extends StatelessWidget {
  final ShiftModel shift;
  final bool isBooking;
  final VoidCallback onBook;

  const _ShiftDetailBody({required this.shift, required this.isBooking, required this.onBook});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final durationHrs = shift.scheduledEnd.difference(shift.scheduledStart).inMinutes / 60;

    return Scaffold(

        body:  Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _SectionCard(
                title: 'Schedule',
                children: [
                  _InfoTile(label: 'Date', value: dateFormat.format(shift.scheduledStart)),
                  _InfoTile(
                    label: 'Time',
                    value: '${timeFormat.format(shift.scheduledStart)} – ${timeFormat.format(shift.scheduledEnd)}',
                  ),
                  _InfoTile(label: 'Duration', value: '${durationHrs.toStringAsFixed(1)} hours'),
                  _InfoTile(label: 'Period', value: shift.period),
                  _InfoTile(label: 'Pattern', value: shift.pattern.replaceAll('_', ' ')),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Location',
                children: [
                  _InfoTile(label: 'City / State', value: shift.locationDisplay),
                  if (shift.shiftCase != null)
                    _InfoTile(label: 'Case ID', value: shift.shiftCase!.publicIdentifier),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Requirements',
                children: [
                  _InfoTile(label: 'Designation', value: shift.requiredDesignation),
                  _InfoTile(label: 'Visit type', value: shift.visitType.replaceAll('_', ' ')),
                  if (shift.specialties.isNotEmpty)
                    _InfoTile(label: 'Specialties', value: shift.specialties.join(', ')),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Pay breakdown',
                children: [
                  _InfoTile(label: 'Pay rate', value: '\$${shift.payRate.toStringAsFixed(2)}/hr', highlight: true),
                  _InfoTile(label: 'Billing type', value: shift.billingType),
                  _InfoTile(
                    label: 'Estimated total',
                    value: '\$${shift.estimatedEarnings.toStringAsFixed(2)}',
                    highlight: true,
                  ),
                ],
              ),
              if (shift.description != null) ...[
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Description',
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        shift.description!,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF536C79), height: 1.5),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (shift.status == 'OPEN') _buildBookButton(context),
      ],
    ));
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: ColorConstants.appGradient,
      ),
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 20),
      child: Row(
        spacing: 16,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              if (shift.shiftCase != null)
                Text(
                  '${shift.shiftCase!.publicIdentifier}  ·  ${shift.visitType.replaceAll("_", " ")}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 0.4),
                ),
              const SizedBox(height: 4),
              Text(
                shift.displayTitle,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${shift.payRate.toStringAsFixed(0)}/hr  ·  ${shift.requiredDesignation} required',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  if (shift.isUrgent) _Badge('Urgent', Colors.orange.shade100, Colors.orange.shade800),
                  if (shift.isEmergencyFill) _Badge('Emergency Fill', Colors.red.shade100, Colors.red.shade800),
                  if (shift.allowInstantBook) _Badge('Instant Book', Colors.green.shade100, Colors.green.shade800),
                ],
              ),
            ],
          )),
          NotificationsBell()
        ],
      ),
    );
  }

  Widget _buildBookButton(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Column(
        children: [
          Button(
              buttonText: "Confirm Booking",
              onPressed: isBooking ? null : onBook,
              isLoading:isBooking
          ),
          const SizedBox(height: 6),
          const Text(
            'Booking is instant. You can cancel up to 2 hours before the shift.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B4)),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Badge(this.label, this.bg, this.fg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8EDF2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B4), letterSpacing: 0.6,
            )),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _InfoTile({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B4))),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: highlight ? accentColor : const Color(0xFF1A2632),
          ),
        ),
      ],
    ),
  );
}