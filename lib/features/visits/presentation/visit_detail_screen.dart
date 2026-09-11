import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:trabajo_hub/features/surveys/presentation/survey_screen.dart';

import '../../../core/constants/app_constants.dart';
import '../data/models/visit_model.dart';
import '../providers/visits_provider.dart';

import 'widgets/evv_action_button.dart';

class VisitDetailScreen extends ConsumerWidget {
  final String visitId;

  const VisitDetailScreen({super.key, required this.visitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(visitDetailProvider(visitId));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: async.when(
        loading: () => const _VisitLoadingScreen(),
        error: (error, _) => _VisitErrorScreen(
          message: error is DioException
              ? (error.message ?? 'Something went wrong')
              : error.toString(),
          onBack: () => Navigator.pop(context),
          onRetry: () {
            ref.invalidate(visitDetailProvider(visitId));
          },
        ),
        data: (raw) => _VisitDetailBody(visit: raw as VisitModel),
      ),
    );
  }
}

class VisitDetailFromState extends ConsumerWidget {
  final VisitModel visit;

  const VisitDetailFromState({super.key, required this.visit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsState = ref.watch(visitsProvider);

    final liveVisit = visitsState.visits.firstWhere(
      (item) => item.id == visit.id,
      orElse: () => visit,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: _VisitDetailBody(visit: liveVisit),
    );
  }
}

class _VisitDetailBody extends ConsumerStatefulWidget {
  final VisitModel visit;

  const _VisitDetailBody({required this.visit});

  @override
  ConsumerState<_VisitDetailBody> createState() => _VisitDetailBodyState();
}

class _VisitDetailBodyState extends ConsumerState<_VisitDetailBody> {
  final _notesController = TextEditingController();

  static const Color _background = Color(0xFFF6F8FB);
  static const Color _heading = Color(0xFF101828);
  static const Color _body = Color(0xFF667085);
  static const Color _border = Color(0xFFE4E7EC);

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    final method = await _promptVerificationMethod(isCheckIn: true);

    if (method == null || !mounted) return;

    String? qrCode;
    String? pin;
    String? reason;

    switch (method) {
      case _EvvVerificationMethod.qrGps:
        qrCode = await _promptQrScan();
        if (qrCode == null || qrCode.trim().isEmpty || !mounted) return;
        break;

      case _EvvVerificationMethod.gps:
        break;

      case _EvvVerificationMethod.facilityPin:
        pin = await _promptFacilityPin();
        if (pin == null || pin.trim().isEmpty || !mounted) return;
        break;

      case _EvvVerificationMethod.supervisor:
        reason = await _promptVerificationReason(
          title: 'Request supervisor verification',
          message:
              'Explain why normal EVV verification is unavailable. Your arrival will be recorded and sent for authorized review.',
        );
        if (reason == null || !mounted) return;
        break;

      case _EvvVerificationMethod.manualException:
        reason = await _promptVerificationReason(
          title: 'Report EVV exception',
          message:
              'Use this only when GPS, QR and facility PIN cannot be used. The visit will be recorded for review with a complete audit trail.',
        );
        if (reason == null || !mounted) return;
        break;
    }

    final ok = await ref
        .read(visitsProvider.notifier)
        .checkIn(
          widget.visit.id,
          verificationMethod: method.apiValue,
          qrCode: qrCode,
          pin: pin,
          reason: reason,
        );

    if (!mounted) return;

    _handleEvvResult(ok, isCheckIn: true, method: method);
  }

  Future<void> _handleCheckOut() async {
    final notes = await _promptCheckOutNotes();

    if (notes == null || !mounted) return;

    final method = await _promptVerificationMethod(isCheckIn: false);

    if (method == null || !mounted) return;

    String? qrCode;
    String? pin;
    String? reason;

    switch (method) {
      case _EvvVerificationMethod.qrGps:
        qrCode = await _promptQrScan();
        if (qrCode == null || qrCode.trim().isEmpty || !mounted) return;
        break;

      case _EvvVerificationMethod.gps:
        break;

      case _EvvVerificationMethod.facilityPin:
        pin = await _promptFacilityPin();
        if (pin == null || pin.trim().isEmpty || !mounted) return;
        break;

      case _EvvVerificationMethod.supervisor:
        reason = await _promptVerificationReason(
          title: 'Request supervisor checkout verification',
          message:
              'Explain why normal EVV checkout verification is unavailable. Your checkout will be recorded for authorized review.',
        );
        if (reason == null || !mounted) return;
        break;

      case _EvvVerificationMethod.manualException:
        reason = await _promptVerificationReason(
          title: 'Report checkout exception',
          message:
              'Use this only when the normal verification methods cannot be used. Your checkout will be recorded and flagged for review.',
        );
        if (reason == null || !mounted) return;
        break;
    }

    final ok = await ref
        .read(visitsProvider.notifier)
        .checkOut(
          widget.visit.id,
          verificationMethod: method.apiValue,
          qrCode: qrCode,
          pin: pin,
          reason: reason,
          notes: notes,
        );

    if (!mounted) return;

    _handleEvvResult(ok, isCheckIn: false, method: method);
  }

  void _handleEvvResult(
    bool ok, {
    required bool isCheckIn,
    required _EvvVerificationMethod method,
  }) {
    final state = ref.read(visitsProvider);

    if (ok) {
      final needsReview = state.evvFlagged;

      if (needsReview) {
        _showVerificationReviewDialog(
          isCheckIn: isCheckIn,
          message:
              state.evvError ??
              'Your ${isCheckIn ? 'check-in' : 'check-out'} was recorded and sent for review.',
        );
      } else {
        _showVerificationSuccessDialog(isCheckIn: isCheckIn, method: method);
      }

      ref.read(visitsProvider.notifier).clearEvvError();

      if (!isCheckIn && !needsReview) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SurveyScreen(
              shiftId: widget.visit.shiftId,
              visitId: widget.visit.id,
            ),
          ),
        );
      }

      return;
    }

    if (state.evvFlagged) {
      _showVerificationReviewDialog(
        isCheckIn: isCheckIn,
        message:
            state.evvError ?? 'Your visit activity needs authorized review.',
      );

      ref.read(visitsProvider.notifier).clearEvvError();

      return;
    }

    _showVerificationErrorDialog(
      isCheckIn: isCheckIn,
      message: state.evvError ?? 'Unable to complete this visit action.',
    );

    ref.read(visitsProvider.notifier).clearEvvError();
  }

  Future<_EvvVerificationMethod?> _promptVerificationMethod({
    required bool isCheckIn,
  }) {
    return showModalBottomSheet<_EvvVerificationMethod>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VerificationMethodSheet(isCheckIn: isCheckIn),
    );
  }

  Future<String?> _promptFacilityPin() {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FacilityPinSheet(),
    );
  }

  Future<String?> _promptVerificationReason({
    required String title,
    required String message,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VerificationReasonSheet(title: title, message: message),
    );
  }

  Future<String?> _promptQrScan() async {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _QrScanSheet(),
    );
  }

  Future<String?> _promptCheckOutNotes() async {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CheckOutNotesSheet(controller: _notesController),
    );
  }

  void _showVerificationSuccessDialog({
    required bool isCheckIn,
    required _EvvVerificationMethod method,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Color(0xFF027A48)),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                isCheckIn ? 'Checked in' : 'Checked out',
                style: const TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCheckIn
                  ? 'Your arrival was verified and the visit has started successfully.'
                  : 'Your departure was verified and the visit has been completed successfully.',
              style: const TextStyle(
                color: Color(0xFF475467),
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(method.icon, color: accentColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verified with ${method.label}',
                      style: const TextStyle(
                        color: Color(0xFF344054),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Continue',
              style: TextStyle(color: accentColor, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showVerificationReviewDialog({
    required bool isCheckIn,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.fact_check_outlined, color: Color(0xFFB54708), size: 22),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Recorded for review',
                style: TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFF475467),
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFAEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFEDFA8)),
              ),
              child: Text(
                isCheckIn
                    ? 'The arrival is in the EVV audit trail. You may continue the visit while the exception is reviewed, subject to your facility policy.'
                    : 'The checkout is in the EVV audit trail and will remain reviewable before payable hours are verified.',
                style: const TextStyle(
                  color: Color(0xFF934A0A),
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Got it',
              style: TextStyle(color: accentColor, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showVerificationErrorDialog({
    required bool isCheckIn,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Color(0xFFB42318)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isCheckIn ? 'Could not check in' : 'Could not check out',
                style: const TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Color(0xFF475467),
            fontSize: 12.5,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (isCheckIn) {
                _handleCheckIn();
              } else {
                _handleCheckOut();
              }
            },
            style: FilledButton.styleFrom(backgroundColor: accentColor),
            child: const Text('Try another method'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visitsState = ref.watch(visitsProvider);

    final liveVisit = visitsState.visits.firstWhere(
      (item) => item.id == widget.visit.id,
      orElse: () => widget.visit,
    );

    final isCheckingIn = visitsState.checkingInVisitId == liveVisit.id;

    final isCheckingOut = visitsState.checkingOutVisitId == liveVisit.id;

    final isCompleted =
        liveVisit.status == VisitStatus.checkedOut ||
        liveVisit.status == VisitStatus.verified ||
        liveVisit.status == VisitStatus.overrideApproved;

    return Container(
      color: _background,
      child: Column(
        children: [
          _buildHeader(context, liveVisit),
          Expanded(
            child: RefreshIndicator(
              color: accentColor,
              onRefresh: () async {
                await ref.read(visitsProvider.notifier).load(refresh: true);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 38),
                children: [
                  _buildVisitHero(
                    liveVisit,
                    isCheckingIn: isCheckingIn,
                    isCheckingOut: isCheckingOut,
                  ),

                  const SizedBox(height: 16),

                  if (liveVisit.status == VisitStatus.scheduled)
                    _buildPrepareCard(),

                  if (liveVisit.status == VisitStatus.scheduled)
                    const SizedBox(height: 16),

                  _buildVisitInformation(liveVisit),

                  if (liveVisit.checkInTime != null ||
                      liveVisit.checkOutTime != null) ...[
                    const SizedBox(height: 16),
                    _buildEvvTimeline(liveVisit),
                  ],

                  if (liveVisit.overrideRequired ||
                      liveVisit.status == VisitStatus.flagged ||
                      liveVisit.status == VisitStatus.overrideRequested) ...[
                    const SizedBox(height: 16),
                    _buildAttentionCard(liveVisit),
                  ],

                  if ((liveVisit.notes ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildNotesCard(liveVisit.notes!),
                  ],

                  if (liveVisit.auditEvents.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildAuditCard(liveVisit),
                  ],

                  if (isCompleted) ...[
                    const SizedBox(height: 20),
                    _buildSurveyButton(liveVisit),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, VisitModel visit) {
    final shift = visit.shiftInfo;

    final visitType = shift?.visitType.replaceAll('_', ' ') ?? 'Visit';

    final caseId = shift?.caseIdentifier;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: ColorConstants.appGradient),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(context),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Text(
                  'Visit details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.2,
                  ),
                ),
              ),

              _StatusBadge(status: visit.status),
            ],
          ),

          const SizedBox(height: 22),

          Text(
            _titleCase(visitType),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -.55,
            ),
          ),

          if (caseId != null && caseId.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Row(
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 15,
                  color: Colors.white.withValues(alpha: .75),
                ),
                const SizedBox(width: 6),
                Text(
                  caseId,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .82),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          if (shift != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _HeaderInfo(
                    icon: Icons.calendar_today_outlined,
                    text: _formatVisitDateTime(shift.scheduledStart),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeaderInfo(
                    icon: Icons.location_on_outlined,
                    text: shift.locationDisplay,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVisitHero(
    VisitModel visit, {
    required bool isCheckingIn,
    required bool isCheckingOut,
  }) {
    final status = visit.status;

    const earlyCheckInMinutes = 5;

    final scheduledStart = visit.shiftInfo?.scheduledStart;

    final checkInOpensAt = scheduledStart?.subtract(
      const Duration(minutes: earlyCheckInMinutes),
    );

    final now = DateTime.now();

    final isCheckInWindowOpen =
        checkInOpensAt != null && !now.isBefore(checkInOpensAt);

    final canCheckIn = status == VisitStatus.scheduled && isCheckInWindowOpen;

    final isWaitingForCheckIn =
        status == VisitStatus.scheduled &&
        scheduledStart != null &&
        !isCheckInWindowOpen;
    final canCheckOut =
        status == VisitStatus.checkedIn ||
        (status == VisitStatus.flagged &&
            visit.checkInTime != null &&
            visit.checkOutTime == null);

    final isCompleted =
        status == VisitStatus.checkedOut ||
        status == VisitStatus.verified ||
        status == VisitStatus.overrideApproved;

    final isAttention =
        status == VisitStatus.flagged ||
        status == VisitStatus.overrideRequested ||
        visit.overrideRequired;

    late Color heroColor;
    late Color heroBackground;
    late IconData heroIcon;
    late String eyebrow;
    late String title;
    late String subtitle;

    if (canCheckIn) {
      heroColor = accentColor;
      heroBackground = accentColor.withValues(alpha: .07);
      heroIcon = Icons.location_on_outlined;
      eyebrow = 'CHECK-IN AVAILABLE';
      title = 'Ready to check in';
      subtitle =
          'You are within the check-in window. Confirm you are on site, then start the visit using secure EVV.';
    } else if (isWaitingForCheckIn) {
      heroColor = const Color(0xFF175CD3);
      heroBackground = const Color(0xFFEFF8FF);
      heroIcon = Icons.schedule_rounded;
      eyebrow = 'UPCOMING VISIT';
      title = 'Your visit is scheduled';

      final openingTime = checkInOpensAt;

      subtitle = openingTime != null
          ? 'Check-in opens at ${DateFormat('h:mm a').format(openingTime)} — 5 minutes before the scheduled start.'
          : 'Check-in will become available shortly before the scheduled start.';
    } else if (canCheckOut) {
      heroColor = const Color(0xFF7F56D9);
      heroBackground = const Color(0xFFF4F3FF);
      heroIcon = Icons.timer_outlined;
      eyebrow = 'VISIT IN PROGRESS';
      title = 'You are checked in';

      subtitle = visit.checkInTime != null
          ? 'Started ${DateFormat('h:mm a').format(visit.checkInTime!)} · Check out when your visit is complete.'
          : 'Complete your work and check out when finished.';
    } else if (isCompleted) {
      heroColor = const Color(0xFF027A48);
      heroBackground = const Color(0xFFECFDF3);
      heroIcon = Icons.verified_outlined;
      eyebrow = 'VISIT COMPLETED';
      title = 'EVV visit recorded';
      subtitle = 'Your check-in and check-out information has been saved.';
    } else if (isAttention) {
      heroColor = const Color(0xFFB54708);
      heroBackground = const Color(0xFFFFFAEB);
      heroIcon = Icons.warning_amber_rounded;
      eyebrow = 'REVIEW REQUIRED';
      title = 'This visit needs attention';
      subtitle =
          'Review the visit details and any location or override information below.';
    } else {
      heroColor = const Color(0xFF475467);
      heroBackground = const Color(0xFFF2F4F7);
      heroIcon = Icons.event_note_outlined;
      eyebrow = 'VISIT STATUS';
      title = visit.status.label;
      subtitle = 'Review the details and audit information below.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09101828),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: heroBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(heroIcon, color: heroColor, size: 23),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: TextStyle(
                        color: heroColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .9,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      style: const TextStyle(
                        color: _heading,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _body,
                        fontSize: 11.8,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (canCheckIn || canCheckOut) ...[
            const SizedBox(height: 17),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEAECF0)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.my_location_rounded,
                    size: 16,
                    color: Color(0xFF667085),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Choose an approved verification method. TrabajoHub will use GPS when available and can also record QR, facility PIN, supervisor review, or a documented EVV exception.',
                      style: TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 10.8,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            if (canCheckIn)
              EvvActionButton(
                action: EvvAction.checkIn,
                isLoading: isCheckingIn,
                onPressed: _handleCheckIn,
              ),

            if (canCheckOut)
              EvvActionButton(
                action: EvvAction.checkOut,
                isLoading: isCheckingOut,
                onPressed: _handleCheckOut,
              ),
          ],

          if (isCompleted) ...[
            const SizedBox(height: 17),
            const Divider(height: 1, color: Color(0xFFEAECF0)),
            const SizedBox(height: 15),
            Row(
              children: [
                _CompactVisitStat(
                  label: 'Check in',
                  value: visit.checkInTime != null
                      ? DateFormat('h:mm a').format(visit.checkInTime!)
                      : '—',
                  icon: Icons.login_rounded,
                  accent: const Color(0xFF175CD3),
                ),
                _MiniDivider(),
                _CompactVisitStat(
                  label: 'Check out',
                  value: visit.checkOutTime != null
                      ? DateFormat('h:mm a').format(visit.checkOutTime!)
                      : '—',
                  icon: Icons.logout_rounded,
                  accent: const Color(0xFF027A48),
                ),
                _MiniDivider(),
                _CompactVisitStat(
                  label: 'Duration',
                  value: _durationLabel(visit.durationMinutes),
                  icon: Icons.timer_outlined,
                  accent: const Color(0xFF475467),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrepareCard() {
    const items = [
      (
        Icons.my_location_rounded,
        'Location services',
        'GPS is used for EVV verification.',
      ),
      (
        Icons.qr_code_scanner_rounded,
        'QR verification',
        'Scan the on-site QR code when available.',
      ),
      (
        Icons.security_rounded,
        'Secure EVV record',
        'Your visit timestamps and location are recorded.',
      ),
      (
        Icons.assignment_turned_in_outlined,
        'Visit documentation',
        'You can review notes and complete checkout afterward.',
      ),
    ];

    return _PremiumSection(
      title: 'Prepare for visit',
      icon: Icons.fact_check_outlined,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _PreparationRow(
              icon: items[index].$1,
              title: items[index].$2,
              subtitle: items[index].$3,
            ),
            if (index != items.length - 1)
              const Divider(height: 1, indent: 44, color: Color(0xFFEAECF0)),
          ],
        ],
      ),
    );
  }

  Widget _buildVisitInformation(VisitModel visit) {
    final shift = visit.shiftInfo;

    return _PremiumSection(
      title: 'Visit information',
      icon: Icons.assignment_outlined,
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.info_outline_rounded,
            label: 'Status',
            value: visit.status.label,
            valueColor: _statusColor(visit.status),
          ),

          if (shift?.caseIdentifier != null)
            _DetailRow(
              icon: Icons.folder_outlined,
              label: 'Case',
              value: shift!.caseIdentifier!,
            ),

          if (shift != null)
            _DetailRow(
              icon: Icons.medical_services_outlined,
              label: 'Visit type',
              value: _titleCase(shift.visitType.replaceAll('_', ' ')),
            ),

          if (shift != null)
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Schedule',
              value: _formatSchedule(shift.scheduledStart, shift.scheduledEnd),
            ),

          if (shift != null)
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: shift.locationDisplay,
              multiLine: true,
            ),

          if (visit.nurse != null)
            _DetailRow(
              icon: Icons.badge_outlined,
              label: 'Assigned nurse',
              value: '${visit.nurse!.fullName} · ${visit.nurse!.designation}',
              multiLine: true,
            ),
        ],
      ),
    );
  }

  Widget _buildEvvTimeline(VisitModel visit) {
    final df = DateFormat('EEE, MMM d · h:mm a');

    return _PremiumSection(
      title: 'EVV activity',
      icon: Icons.location_history_outlined,
      child: Column(
        children: [
          if (visit.checkInTime != null)
            _TimelineEvent(
              icon: Icons.login_rounded,
              title: 'Checked in',
              value: df.format(visit.checkInTime!),
              accent: const Color(0xFF175CD3),
            ),

          if (visit.checkInDistance != null)
            _TimelineEvent(
              icon: Icons.straighten_outlined,
              title: 'Check-in distance',
              value:
                  '${visit.checkInDistance!.toStringAsFixed(0)} m from visit location',
              accent: const Color(0xFF475467),
            ),

          if (visit.checkOutTime != null)
            _TimelineEvent(
              icon: Icons.logout_rounded,
              title: 'Checked out',
              value: df.format(visit.checkOutTime!),
              accent: const Color(0xFF027A48),
            ),

          if (visit.durationMinutes != null)
            _TimelineEvent(
              icon: Icons.timer_outlined,
              title: 'Visit duration',
              value: _durationLabel(visit.durationMinutes),
              accent: const Color(0xFF7F56D9),
              isLast: true,
            ),
        ],
      ),
    );
  }

  Widget _buildAttentionCard(VisitModel visit) {
    final reason = (visit.overrideReason ?? '').trim().isNotEmpty
        ? visit.overrideReason!
        : 'This visit requires review. Check the EVV details and follow your organization’s instructions.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFEDFA8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1D6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFB54708),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Visit needs attention',
                  style: TextStyle(
                    color: Color(0xFF7A2E0E),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  reason,
                  style: const TextStyle(
                    color: Color(0xFF934A0A),
                    fontSize: 11.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(String notes) {
    return _PremiumSection(
      title: 'Visit notes',
      icon: Icons.notes_rounded,
      child: Text(
        notes,
        style: const TextStyle(color: _body, fontSize: 12, height: 1.55),
      ),
    );
  }

  Widget _buildAuditCard(VisitModel visit) {
    return _PremiumSection(
      title: 'Audit trail',
      icon: Icons.history_rounded,
      child: Column(
        children: visit.auditEvents
            .map((event) => _AuditRow(event: event))
            .toList(),
      ),
    );
  }

  Widget _buildSurveyButton(VisitModel visit) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SurveyScreen(shiftId: visit.shiftId, visitId: visit.id),
            ),
          );
        },
        icon: const Icon(Icons.rate_review_outlined, size: 19),
        label: const Text('Complete visit survey'),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}

class _VisitLoadingScreen extends StatelessWidget {
  const _VisitLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
            decoration: const BoxDecoration(
              gradient: ColorConstants.appGradient,
            ),
            child: Row(
              children: [
                Material(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pop(context),
                    child: const SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Visit details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}

class _VisitErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  const _VisitErrorScreen({
    required this.message,
    required this.onBack,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_outlined,
                color: Color(0xFFB42318),
                size: 29,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load visit',
              style: TextStyle(
                color: Color(0xFF101828),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onBack,
                    child: const Text('Go back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Try again'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeaderInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: .75)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _PremiumSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E7EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07101828),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 17),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF344054),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PreparationRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PreparationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF027A48),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF344054),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF98A2B3),
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, size: 17, color: accentColor),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool multiLine;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.multiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: multiLine
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF98A2B3)),
          const SizedBox(width: 9),
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF98A2B3),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              maxLines: multiLine ? 3 : 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? const Color(0xFF344054),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEvent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color accent;
  final bool isLast;

  const _TimelineEvent({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 17, color: accent),
            ),
            if (!isLast)
              Container(width: 1.5, height: 28, color: const Color(0xFFEAECF0)),
          ],
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF344054),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 10.8,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactVisitStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _CompactVisitStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: accent, size: 17),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF98A2B3), fontSize: 9.5),
          ),
        ],
      ),
    );
  }
}

class _MiniDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 38, color: const Color(0xFFEAECF0));
  }
}

String _titleCase(String value) {
  return value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String _formatVisitDateTime(DateTime value) {
  return DateFormat('EEE, MMM d · h:mm a').format(value);
}

String _formatSchedule(DateTime start, DateTime end) {
  final day = DateFormat('EEE, MMM d').format(start);

  final startTime = DateFormat('h:mm a').format(start);

  final endTime = DateFormat('h:mm a').format(end);

  return '$day · $startTime – $endTime';
}

String _durationLabel(int? minutes) {
  if (minutes == null) return '—';

  final hours = minutes ~/ 60;
  final remainder = minutes % 60;

  if (hours == 0) {
    return '$remainder min';
  }

  if (remainder == 0) {
    return '${hours}h';
  }

  return '${hours}h ${remainder}m';
}

Color _statusColor(VisitStatus status) {
  switch (status) {
    case VisitStatus.scheduled:
      return const Color(0xFF175CD3);

    case VisitStatus.checkedIn:
      return const Color(0xFF7F56D9);

    case VisitStatus.checkedOut:
    case VisitStatus.verified:
    case VisitStatus.overrideApproved:
      return const Color(0xFF027A48);

    case VisitStatus.flagged:
      return const Color(0xFFB42318);

    case VisitStatus.cancelled:
      return const Color(0xFFB42318);

    case VisitStatus.overrideRequested:
      return const Color(0xFFB54708);
  }
}

enum _EvvVerificationMethod {
  qrGps,
  gps,
  facilityPin,
  supervisor,
  manualException,
}

extension on _EvvVerificationMethod {
  String get apiValue {
    switch (this) {
      case _EvvVerificationMethod.qrGps:
        return 'QR_GPS';
      case _EvvVerificationMethod.gps:
        return 'GPS';
      case _EvvVerificationMethod.facilityPin:
        return 'FACILITY_PIN';
      case _EvvVerificationMethod.supervisor:
        return 'SUPERVISOR';
      case _EvvVerificationMethod.manualException:
        return 'MANUAL_EXCEPTION';
    }
  }

  String get label {
    switch (this) {
      case _EvvVerificationMethod.qrGps:
        return 'QR + GPS';
      case _EvvVerificationMethod.gps:
        return 'GPS';
      case _EvvVerificationMethod.facilityPin:
        return 'Facility PIN';
      case _EvvVerificationMethod.supervisor:
        return 'Supervisor review';
      case _EvvVerificationMethod.manualException:
        return 'EVV exception';
    }
  }

  IconData get icon {
    switch (this) {
      case _EvvVerificationMethod.qrGps:
        return Icons.qr_code_scanner_rounded;
      case _EvvVerificationMethod.gps:
        return Icons.my_location_rounded;
      case _EvvVerificationMethod.facilityPin:
        return Icons.pin_outlined;
      case _EvvVerificationMethod.supervisor:
        return Icons.supervisor_account_outlined;
      case _EvvVerificationMethod.manualException:
        return Icons.report_problem_outlined;
    }
  }
}

class _VerificationMethodSheet extends StatelessWidget {
  final bool isCheckIn;

  const _VerificationMethodSheet({required this.isCheckIn});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.fromLTRB(18, 12, 18, bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD0D5DD),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isCheckIn ? 'Verify your arrival' : 'Verify your departure',
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -.35,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Choose the best available EVV method. If GPS or facility coordinates are unavailable, you can use an approved fallback without losing the visit record.',
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 17),
          _VerificationChoice(
            method: _EvvVerificationMethod.qrGps,
            title: 'Scan facility QR',
            subtitle: 'Uses the facility QR and GPS when available.',
            badge: 'RECOMMENDED',
          ),
          const SizedBox(height: 9),
          _VerificationChoice(
            method: _EvvVerificationMethod.gps,
            title: 'Verify with GPS',
            subtitle: 'Use your current precise location.',
          ),
          const SizedBox(height: 9),
          _VerificationChoice(
            method: _EvvVerificationMethod.facilityPin,
            title: 'Enter facility PIN',
            subtitle: 'Use the secure EVV PIN provided at the facility.',
          ),
          const SizedBox(height: 9),
          _VerificationChoice(
            method: _EvvVerificationMethod.supervisor,
            title: 'Request supervisor verification',
            subtitle: 'Record the event and send it for authorized review.',
          ),
          const SizedBox(height: 9),
          _VerificationChoice(
            method: _EvvVerificationMethod.manualException,
            title: 'Report verification issue',
            subtitle:
                'Last resort for missing coordinates, GPS failure, or other EVV problems.',
            destructive: true,
          ),
          const SizedBox(height: 13),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, size: 16, color: Color(0xFF98A2B3)),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Every method is timestamped and written to the TrabajoHub EVV audit trail. Exception methods remain reviewable before payable hours are verified.',
                  style: TextStyle(
                    color: Color(0xFF98A2B3),
                    fontSize: 10.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerificationChoice extends StatelessWidget {
  final _EvvVerificationMethod method;
  final String title;
  final String subtitle;
  final String? badge;
  final bool destructive;

  const _VerificationChoice({
    required this.method,
    required this.title,
    required this.subtitle,
    this.badge,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFB54708) : accentColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pop(context, method),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: destructive
                ? const Color(0xFFFFFAEB)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: destructive
                  ? const Color(0xFFFEDFA8)
                  : const Color(0xFFE4E7EC),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(method.icon, color: color, size: 21),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFF344054),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'RECOMMENDED',
                              style: TextStyle(
                                color: Color(0xFF027A48),
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .45,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 10.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF98A2B3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FacilityPinSheet extends StatefulWidget {
  const _FacilityPinSheet();

  @override
  State<_FacilityPinSheet> createState() => _FacilityPinSheetState();
}

class _FacilityPinSheetState extends State<_FacilityPinSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottom + 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Facility EVV PIN',
            style: TextStyle(
              color: Color(0xFF101828),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter the secure PIN provided by the facility. TrabajoHub verifies it on the server; the PIN itself is never stored on this device.',
            style: TextStyle(
              color: Color(0xFF667085),
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 8,
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Enter facility PIN',
              prefixIcon: const Icon(Icons.pin_outlined),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 49,
            child: FilledButton(
              onPressed: () {
                final value = _controller.text.trim();
                if (value.length < 4) return;
                Navigator.pop(context, value);
              },
              style: FilledButton.styleFrom(backgroundColor: accentColor),
              child: const Text(
                'Verify PIN',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationReasonSheet extends StatefulWidget {
  final String title;
  final String message;

  const _VerificationReasonSheet({required this.title, required this.message});

  @override
  State<_VerificationReasonSheet> createState() =>
      _VerificationReasonSheetState();
}

class _VerificationReasonSheetState extends State<_VerificationReasonSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottom + 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.message,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 4,
            minLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText:
                  'Example: Facility coordinates are missing and GPS verification cannot be completed.',
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 49,
            child: FilledButton.icon(
              onPressed: () {
                final value = _controller.text.trim();
                if (value.length < 10) return;
                Navigator.pop(context, value);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB54708),
              ),
              icon: const Icon(Icons.send_outlined, size: 18),
              label: const Text(
                'Record and send for review',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrScanSheet extends StatefulWidget {
  const _QrScanSheet();

  @override
  State<_QrScanSheet> createState() => _QrScanSheetState();
}

class _QrScanSheetState extends State<_QrScanSheet> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Scan QR Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context, null),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: MobileScanner(
                onDetect: (capture) {
                  if (_scanned) return;
                  final barcode = capture.barcodes.firstOrNull;
                  if (barcode?.rawValue != null) {
                    _scanned = true;
                    Navigator.pop(context, barcode!.rawValue);
                  }
                },
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              MediaQuery.of(context).padding.bottom + 14,
            ),
            child: const Text(
              'Point your camera at the TrabajoHub EVV QR code displayed at this facility.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Check-out notes sheet ─────────────────────────────────────────────────────

class _CheckOutNotesSheet extends StatelessWidget {
  final TextEditingController controller;
  const _CheckOutNotesSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Check-out notes',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A2632),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add any observations or notes about this visit (optional).',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B4)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 4,
            autofocus: true,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A2632)),
            decoration: InputDecoration(
              hintText: 'e.g. Patient was resting comfortably...',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B4),
                fontSize: 13,
              ),
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8ED)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8ED)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF0A9FBF),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, null),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8ED)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF536C79)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context, controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Check Out',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final VisitStatus status;
  const _StatusBadge({required this.status});

  static const _colors = {
    VisitStatus.scheduled: (Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
    VisitStatus.checkedIn: (Color(0xFFFEF3C7), Color(0xFFB45309)),
    VisitStatus.checkedOut: (Color(0xFFDCFCE7), Color(0xFF15803D)),
    VisitStatus.verified: (Color(0xFFE1F5EE), Color(0xFF0F6E56)),
    VisitStatus.flagged: (Color(0xFFFCEBEB), Color(0xFFB91C1C)),
    VisitStatus.overrideRequested: (Color(0xFFFEF3C7), Color(0xFFB45309)),
    VisitStatus.overrideApproved: (Color(0xFFDCFCE7), Color(0xFF15803D)),
  };

  @override
  Widget build(BuildContext context) {
    final colors = _colors[status] ?? _colors[VisitStatus.scheduled]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.$2,
        ),
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  final VisitAuditEvent event;
  const _AuditRow({required this.event});
  @override
  Widget build(BuildContext context) {
    final tf = DateFormat('MMM d · h:mm a');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5),
            decoration: const BoxDecoration(
              color: Color(0xFF0A9FBF),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.action,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2632),
                  ),
                ),
                Text(
                  tf.format(event.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
