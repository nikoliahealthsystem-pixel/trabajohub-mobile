import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:trabajo_hub/features/surveys/presentation/survey_screen.dart';
import '../../../core/constants/app_constants.dart';
import 'widgets/evv_action_button.dart';
import '../data/models/visit_model.dart';
import '../providers/visits_provider.dart';
import '../state/visits_state.dart';

class VisitDetailScreen extends ConsumerWidget {
  final String visitId;
  const VisitDetailScreen({super.key, required this.visitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(visitDetailProvider(visitId));
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF0A9FBF))),
        error: (e, _) => Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/svg/calender.svg',
              width: 72,
              height: 72,
              color: Colors.grey,
            ),
            SizedBox(height: 24),
            Text(e is DioException ? (e.message ?? 'Something went wrong') : e.toString()),
            TextButton(onPressed:()=>Navigator.pop(context), child: Text("Go Back",style: TextStyle(color: accentColor),))
          ],)),
        data: (raw) => _VisitDetailBody(visit: raw as VisitModel),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Used from MyShiftsScreen / VisitsScreen — receives visit directly
// so EVV buttons can update in real-time without re-fetching.
// ─────────────────────────────────────────────────────────────────────────────
class VisitDetailFromState extends ConsumerWidget {
  final VisitModel visit;
  const VisitDetailFromState({super.key, required this.visit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for state updates so the button reflects latest visit status
    final visitsState = ref.watch(visitsProvider);
    final liveVisit = visitsState.visits.firstWhere(
          (v) => v.id == visit.id,
      orElse: () => visit,
    );
    return Scaffold(body: _VisitDetailBody(visit: liveVisit),);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _VisitDetailBody extends ConsumerStatefulWidget {
  final VisitModel visit;
  const _VisitDetailBody({required this.visit});

  @override
  ConsumerState<_VisitDetailBody> createState() => _VisitDetailBodyState();
}

class _VisitDetailBodyState extends ConsumerState<_VisitDetailBody> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // ── Check-in ────────────────────────────────────────────────

  Future<void> _handleCheckIn() async {
    // Ask if they want to scan a QR code first
    final qrCode = await _promptQrScan();
    final ok = await ref
        .read(visitsProvider.notifier).checkIn(widget.visit.id, qrCode: qrCode);

    if (!mounted) return;
    _handleEvvResult(ok, isCheckIn: true);
  }

  // ── Check-out ────────────────────────────────────────────────

  Future<void> _handleCheckOut() async {
    final notes = await _promptCheckOutNotes();
    if (notes == null) return; // user cancelled

    final ok = await ref.read(visitsProvider.notifier).checkOut(widget.visit.id, notes: notes);

    if (!mounted) return;
    _handleEvvResult(ok, isCheckIn: false);
  }

  // ── Result handler ───────────────────────────────────────────

  void _handleEvvResult(bool ok, {required bool isCheckIn}) {
    final state = ref.read(visitsProvider);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isCheckIn ? 'Checked in successfully!' : 'Checked out successfully!'),
        backgroundColor: const Color(0xFF0F6E56),
        behavior: SnackBarBehavior.floating,
      ));
      if(!isCheckIn)
      Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => SurveyScreen(shiftId: widget.visit.shiftId, visitId: widget.visit.id)));
    } else if (state.evvFlagged) {
      // Geofence override — show warning, not hard error
      _showGeofenceWarning(state.evvError ?? 'Location outside geofence.');
      ref.read(visitsProvider.notifier).clearEvvError();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(state.evvError ?? 'Operation failed'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      ref.read(visitsProvider.notifier).clearEvvError();
    }
  }

  // ── QR scan prompt ───────────────────────────────────────────

  Future<String?> _promptQrScan() async {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _QrScanSheet(),
    );
  }

  // ── Check-out notes prompt ───────────────────────────────────

  Future<String?> _promptCheckOutNotes() async {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CheckOutNotesSheet(controller: _notesController),
    );
  }

  // ── Geofence warning dialog ──────────────────────────────────

  void _showGeofenceWarning(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 22),
            SizedBox(width: 8),
            Text('Location flagged',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2632))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message,
                style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF536C79),
                    height: 1.5)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Text(
                'Your check-in has been recorded and sent for admin review. '
                    'You may continue working — no action is needed from you.',
                style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF92400E)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK, got it',
                style: TextStyle(color: Color(0xFF0A9FBF))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visitsState = ref.watch(visitsProvider);
    final df = DateFormat('EEE, MMM d, yyyy · h:mm a');

    final isCheckingIn =
        visitsState.checkingInVisitId == widget.visit.id;
    final isCheckingOut =
        visitsState.checkingOutVisitId == widget.visit.id;

    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // ── EVV Action Card ─────────────────────────────
              _buildEvvCard(isCheckingIn, isCheckingOut),
              const SizedBox(height: 12),

              _Section(title: 'Visit info', children: [
                _Row('Status', widget.visit.status.label),
                if (widget.visit.shiftInfo?.caseIdentifier != null)
                  _Row('Case', widget.visit.shiftInfo!.caseIdentifier!),
                if (widget.visit.shiftInfo != null)
                  _Row('Visit type',
                      widget.visit.shiftInfo!.visitType.replaceAll('_', ' ')),
                if (widget.visit.shiftInfo?.locationDisplay != null)
                  _Row('Location', widget.visit.shiftInfo!.locationDisplay),
                if (widget.visit.nurse != null)
                  _Row('Nurse',
                      '${widget.visit.nurse!.fullName} · ${widget.visit.nurse!.designation}'),
              ]),

              if (widget.visit.checkInTime != null ||
                  widget.visit.checkOutTime != null) ...[
                const SizedBox(height: 12),
                _Section(title: 'Check-in / out', children: [
                  if (widget.visit.checkInTime != null)
                    _Row('Check in', df.format(widget.visit.checkInTime!)),
                  if (widget.visit.checkInDistance != null)
                    _Row('Distance at CI',
                        '${widget.visit.checkInDistance!.toStringAsFixed(0)} m'),
                  if (widget.visit.checkOutTime != null)
                    _Row('Check out', df.format(widget.visit.checkOutTime!)),
                  if (widget.visit.durationMinutes != null)
                    _Row('Duration', '${widget.visit.durationMinutes} min'),
                ]),
              ],

              if (widget.visit.overrideRequired) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF09595)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFB91C1C), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Override Required',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB91C1C))),
                            if (widget.visit.overrideReason != null)
                              Text(widget.visit.overrideReason!,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFFB91C1C))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (widget.visit.notes != null) ...[
                const SizedBox(height: 12),
                _Section(title: 'Notes', children: [
                  Text(widget.visit.notes!,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF536C79),
                          height: 1.5)),
                ]),
              ],

              if (widget.visit.auditEvents.isNotEmpty) ...[
                const SizedBox(height: 12),
                _Section(
                  title: 'Audit trail',
                  children: widget.visit.auditEvents
                      .map((e) => _AuditRow(event: e))
                      .toList(),
                ),
              ],
              SizedBox(height: 24,),
              if (widget.visit.status == VisitStatus.checkedOut)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => SurveyScreen(shiftId: widget.visit.shiftId, visitId: widget.visit.id))),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.blue.withOpacity(0.8),
                      side: const BorderSide(color: Color(0xFFE2E8ED)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('View Survey',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              SizedBox(height: 32,),
            ],
          ),
        ),
      ],
    );
  }

  // ── EVV action card ──────────────────────────────────────────

  Widget _buildEvvCard(bool isCheckingIn, bool isCheckingOut) {
    final status = widget.visit.status;
    final canCheckIn = status == VisitStatus.scheduled;
    final canCheckOut = status == VisitStatus.checkedIn;
    final isCompleted = status == VisitStatus.checkedOut ||
        status == VisitStatus.verified ||
        status == VisitStatus.overrideApproved;

    if (!canCheckIn && !canCheckOut && !isCompleted) {
      return const SizedBox.shrink();
    }

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFDCFCE7)
                      : canCheckOut
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFEAF8FC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_outline_rounded
                      : canCheckOut
                      ? Icons.timer_outlined
                      : Icons.location_on_outlined,
                  color: isCompleted
                      ? const Color(0xFF15803D)
                      : canCheckOut
                      ? const Color(0xFFB45309)
                      : const Color(0xFF0A9FBF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompleted
                          ? 'Visit completed'
                          : canCheckOut
                          ? 'You are checked in'
                          : 'Ready to begin',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A2632)),
                    ),
                    Text(
                      isCompleted
                          ? 'Duration: ${widget.visit.durationMinutes ?? '—'} min'
                          : canCheckOut
                          ? 'Tap Check Out when you\'re done'
                          : 'Tap Check In to start your visit',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF94A3B4)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (canCheckIn || canCheckOut) ...[
            const SizedBox(height: 16),
            // GPS disclaimer
            Row(
              children: const [
                Icon(Icons.my_location_rounded,
                    size: 13, color: Color(0xFF94A3B4)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Your GPS location will be recorded and verified against the case address.',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B4), height: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEEF1F4)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _EvvStat(
                  label: 'Check-in',
                  value: widget.visit.checkInTime != null
                      ? DateFormat('h:mm a').format(widget.visit.checkInTime!)
                      : '—',
                  icon: Icons.login_rounded,
                  color: const Color(0xFF0A9FBF),
                ),
                Container(
                    height: 36, width: 1, color: const Color(0xFFEEF1F4)),
                _EvvStat(
                  label: 'Check-out',
                  value: widget.visit.checkOutTime != null
                      ? DateFormat('h:mm a').format(widget.visit.checkOutTime!)
                      : '—',
                  icon: Icons.logout_rounded,
                  color: const Color(0xFF28D744),
                ),
                Container(
                    height: 36, width: 1, color: const Color(0xFFEEF1F4)),
                _EvvStat(
                  label: 'Duration',
                  value: widget.visit.durationMinutes != null
                      ? '${widget.visit.durationMinutes} min'
                      : '—',
                  icon: Icons.timer_outlined,
                  color: const Color(0xFF536C79),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Container(
    width: double.maxFinite,
    decoration: const BoxDecoration(
      gradient: ColorConstants.appGradient,
    ),
    padding: EdgeInsets.fromLTRB(
        16, MediaQuery.of(context).padding.top + 12, 16, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 10),
        Text(
          widget.visit.shiftInfo?.visitType.replaceAll('_', ' ') ??
              'Visit',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        _StatusBadge(status: widget.visit.status),
      ],
    ),
  );
}

// ── QR scan bottom sheet ──────────────────────────────────────────────────────

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
            width: 36, height: 4,
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
                  child: Text('Scan QR Code',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context, null),
                  child: const Text('Skip',
                      style: TextStyle(
                          color: Colors.white60, fontSize: 14)),
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
                20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
            child: const Text(
              'Point your camera at the QR code on site, or tap Skip to check in without scanning.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.5),
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
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Check-out notes',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A2632))),
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
              hintStyle:
              const TextStyle(color: Color(0xFF94A3B4), fontSize: 13),
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
                    color: Color(0xFF0A9FBF), width: 1.5),
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
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(color: Color(0xFF536C79))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context, controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Check Out',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
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
      child: Text(status.label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: colors.$2)),
    );
  }
}

class _EvvStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _EvvStat(
      {required this.label,
        required this.value,
        required this.icon,
        required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: Color(0xFF94A3B4))),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});
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
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B4),
                letterSpacing: 0.6)),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF94A3B4))),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2632))),
        ),
      ],
    ),
  );
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
            width: 6, height: 6, margin: const EdgeInsets.only(top: 5),
            decoration: const BoxDecoration(
                color: Color(0xFF0A9FBF), shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.action,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2632))),
                Text(tf.format(event.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}