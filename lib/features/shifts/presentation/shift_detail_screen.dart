import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../active_session.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/buttons/button_big.dart';
import '../../../core/widgets/buttons/notification_button.dart';
import '../data/models/shift_model.dart';
import '../providers/shifts_provider.dart';

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
        loading: () =>
            Center(child: CircularProgressIndicator(color: accentColor)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/svg/list.svg',
                width: 72,
                height: 72,
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                e is DioException
                    ? (e.message ?? 'Something went wrong')
                    : e.toString(),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Go Back', style: TextStyle(color: accentColor)),
              ),
            ],
          ),
        ),
        data: (shift) => _ShiftDetailBody(
          shift: shift as ShiftModel,
          isBooking: marketplaceState.bookingShiftId == shiftId,
          onBook: () async {
            final success = await ref
                .read(marketplaceProvider.notifier)
                .bookShift(shiftId);

            if (!context.mounted) return;

            final bookingState = ref.read(marketplaceProvider);
            final rawError = bookingState.bookingError?.trim();
            final errorCode = bookingState.bookingErrorCode;
            final missingCredentials =
                bookingState.bookingMissingCredentialTypes;

            if (success) {
              final viewMyShifts = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (dialogContext) {
                  return Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F6F1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF0F6E56),
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Shift booked successfully',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF172B36),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'This shift has been added to My Shifts. Review the shift details before your scheduled start time.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: Color(0xFF667985),
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF0F6E56),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'View My Shifts',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );

              if (!context.mounted) return;

              if (viewMyShifts == true) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const ActiveSession(pageIndex: 1),
                  ),
                  (route) => false,
                );
              }

              return;
            }

            String title = 'Unable to book this shift';

            String message = rawError?.isNotEmpty == true
                ? rawError!
                : 'We could not complete this booking. Please try again.';

            String nextStep = 'Please review the message above and try again.';

            IconData statusIcon = Icons.info_outline_rounded;

            if (errorCode == 'SHIFT_CREDENTIAL_REQUIREMENTS_NOT_MET') {
              title = 'Credentials required';
              statusIcon = Icons.verified_user_outlined;

              if (missingCredentials.isNotEmpty) {
                final formattedCredentials = missingCredentials
                    .map(
                      (item) => item
                          .toString()
                          .replaceAll('_', ' ')
                          .toLowerCase()
                          .split(' ')
                          .where((word) => word.isNotEmpty)
                          .map(
                            (word) =>
                                '${word[0].toUpperCase()}${word.substring(1)}',
                          )
                          .join(' '),
                    )
                    .join(', ');

                message =
                    'This facility requires additional credentials before you can book this shift: $formattedCredentials.';
              }

              nextStep =
                  'Update your credentials in your profile, then return and try booking again.';
            } else {
              final normalized = message.toLowerCase();

              if ((normalized.contains('already') &&
                      normalized.contains('book')) ||
                  normalized.contains('no longer available') ||
                  normalized.contains('not available') ||
                  normalized.contains('filled')) {
                title = 'Shift no longer available';
                statusIcon = Icons.event_busy_outlined;
                nextStep =
                    'Another nurse may have booked this shift. Return to the marketplace and choose another open shift.';
              } else if (normalized.contains('license') ||
                  normalized.contains('credential')) {
                title = 'Credential requirement';
                statusIcon = Icons.verified_user_outlined;
                nextStep =
                    'Review and update your credentials in your profile, then try again.';
              } else if (normalized.contains('network') ||
                  normalized.contains('connection') ||
                  normalized.contains('timeout')) {
                title = 'Connection problem';
                statusIcon = Icons.wifi_off_rounded;
                nextStep =
                    'Check your internet connection and try booking the shift again.';
              }
            }

            await showDialog<void>(
              context: context,
              builder: (dialogContext) {
                return Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 440),
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F0),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                statusIcon,
                                color: const Color(0xFFD94A48),
                                size: 23,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF172B36),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    'Your shift was not booked.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF71828C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7F6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF1D0CD)),
                          ),
                          child: Text(
                            message,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: Color(0xFF6E3735),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F8FA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: Color(0xFF536C79),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  nextStep,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.4,
                                    color: Color(0xFF536C79),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 49,
                          child: FilledButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF536C79),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Got it',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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

  const _ShiftDetailBody({
    required this.shift,
    required this.isBooking,
    required this.onBook,
  });

  double? get _latitude => shift.shiftCase?.latitude;

  double? get _longitude => shift.shiftCase?.longitude;

  bool get _hasMapCoordinates =>
      _latitude != null &&
      _longitude != null &&
      _latitude!.isFinite &&
      _longitude!.isFinite;

  Future<void> _openMaps(BuildContext context) async {
    final latitude = _latitude;
    final longitude = _longitude;

    if (latitude == null || longitude == null) {
      _showMapError(
        context,
        'A precise map location is not available for this shift yet.',
      );
      return;
    }

    try {
      bool launched = false;

      if (Platform.isIOS) {
        final appleMapsUri = Uri.parse(
          'https://maps.apple.com/?daddr=$latitude,$longitude&dirflg=d',
        );

        launched = await launchUrl(
          appleMapsUri,
          mode: LaunchMode.externalApplication,
        );
      } else if (Platform.isAndroid) {
        final googleMapsUri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
        );

        launched = await launchUrl(
          googleMapsUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        final mapsUri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
        );

        launched = await launchUrl(
          mapsUri,
          mode: LaunchMode.externalApplication,
        );
      }

      if (!launched && context.mounted) {
        _showMapError(
          context,
          'We could not open the Maps application on this device.',
        );
      }
    } catch (_) {
      if (!context.mounted) return;

      _showMapError(
        context,
        'We could not open the Maps application on this device.',
      );
    }
  }

  void _showMapError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: const Color(0xFF334D59),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.location_off_outlined,
                color: Colors.white,
                size: 21,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    final durationHrs =
        shift.scheduledEnd.difference(shift.scheduledStart).inMinutes / 60;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _SectionCard(
                  title: 'Schedule',
                  children: [
                    _InfoTile(
                      label: 'Date',
                      value: dateFormat.format(shift.scheduledStart),
                    ),
                    _InfoTile(
                      label: 'Time',
                      value:
                          '${timeFormat.format(shift.scheduledStart)} - ${timeFormat.format(shift.scheduledEnd)}',
                    ),
                    _InfoTile(
                      label: 'Duration',
                      value: '${durationHrs.toStringAsFixed(1)} hours',
                    ),
                    _InfoTile(label: 'Period', value: shift.period),
                    _InfoTile(
                      label: 'Pattern',
                      value: shift.pattern.replaceAll('_', ' '),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Location',
                  children: [
                    _InfoTile(
                      label: 'City / State',
                      value: shift.locationDisplay,
                    ),
                    if (shift.shiftCase != null)
                      _InfoTile(
                        label: 'Case ID',
                        value: shift.shiftCase!.publicIdentifier,
                      ),
                    const SizedBox(height: 8),
                    _MapActionTile(
                      enabled: _hasMapCoordinates,
                      onTap: () => _openMaps(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Requirements',
                  children: [
                    _InfoTile(
                      label: 'Designation',
                      value: shift.requiredDesignation,
                    ),
                    _InfoTile(
                      label: 'Visit type',
                      value: shift.visitType.replaceAll('_', ' '),
                    ),
                    if (shift.specialties.isNotEmpty)
                      _InfoTile(
                        label: 'Specialties',
                        value: shift.specialties.join(', '),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Pay breakdown',
                  children: [
                    _InfoTile(
                      label: 'Pay rate',
                      value: '\$${shift.payRate.toStringAsFixed(2)}/hr',
                      highlight: true,
                    ),
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
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF536C79),
                            height: 1.5,
                          ),
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: ColorConstants.appGradient),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        20,
      ),
      child: Row(
        spacing: 16,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                if (shift.shiftCase != null)
                  Text(
                    '${shift.shiftCase!.publicIdentifier}  |  ${shift.visitType.replaceAll("_", " ")}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  shift.displayTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${shift.payRate.toStringAsFixed(0)}/hr  |  ${shift.requiredDesignation} required',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (shift.isUrgent)
                      _Badge(
                        'Urgent',
                        Colors.orange.shade100,
                        Colors.orange.shade800,
                      ),
                    if (shift.isEmergencyFill)
                      _Badge(
                        'Emergency Fill',
                        Colors.red.shade100,
                        Colors.red.shade800,
                      ),
                    if (shift.allowInstantBook)
                      _Badge(
                        'Instant Book',
                        Colors.green.shade100,
                        Colors.green.shade800,
                      ),
                  ],
                ),
              ],
            ),
          ),
          NotificationsBell(),
        ],
      ),
    );
  }

  Widget _buildBookButton(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        children: [
          Button(
            buttonText: 'Confirm Booking',
            onPressed: isBooking ? null : onBook,
            isLoading: isBooking,
          ),
          const SizedBox(height: 6),
          const Text(
            'Booking is instant. If you need to cancel, the current cancellation policy and any applicable fee will be shown before you confirm.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B4)),
          ),
        ],
      ),
    );
  }
}

class _MapActionTile extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _MapActionTile({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final foreground = enabled
        ? const Color(0xFF0F6E56)
        : const Color(0xFF98A2B3);

    final background = enabled
        ? const Color(0xFFEAF7F3)
        : const Color(0xFFF4F6F8);

    final borderColor = enabled
        ? const Color(0xFFCFE9E0)
        : const Color(0xFFE4E7EC);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.directions_outlined,
                  color: foreground,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enabled ? 'View in Maps' : 'Map location unavailable',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enabled
                          ? 'Open directions to this shift location'
                          : 'Precise coordinates have not been provided',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF71828C),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded, size: 18, color: foreground),
            ],
          ),
        ),
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B4),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _InfoTile({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B4)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: highlight ? accentColor : const Color(0xFF1A2632),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
