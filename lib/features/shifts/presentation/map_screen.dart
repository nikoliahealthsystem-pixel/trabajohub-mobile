import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../data/models/shift_model.dart';
import '../providers/shifts_provider.dart';
import '../state/marketplace_state.dart';
import 'shift_detail_screen.dart';

class ShiftMapScreen extends ConsumerStatefulWidget {
  final List<ShiftModel> shifts;

  const ShiftMapScreen({super.key, required this.shifts});

  @override
  ConsumerState<ShiftMapScreen> createState() => _ShiftMapScreenState();
}

class _ShiftMapScreenState extends ConsumerState<ShiftMapScreen> {
  GoogleMapController? _mapController;
  ShiftModel? _selectedShift;

  late final List<ShiftModel> _mappableShifts;
  late final LatLng _initialCenter;
  static const double _initialZoom = 12.0;

  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _mappableShifts = widget.shifts
        .where((s) =>
    s.shiftCase?.latitude != null && s.shiftCase?.longitude != null)
        .toList();

    if (_mappableShifts.isEmpty) {
      _initialCenter = const LatLng(6.5244, 3.3792);
    } else {
      final avgLat = _mappableShifts
          .map((s) => s.shiftCase!.latitude!)
          .reduce((a, b) => a + b) /
          _mappableShifts.length;
      final avgLng = _mappableShifts
          .map((s) => s.shiftCase!.longitude!)
          .reduce((a, b) => a + b) /
          _mappableShifts.length;
      _initialCenter = LatLng(avgLat, avgLng);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _buildMarkers());
  }

  /// Renders each shift's custom marker widget off-screen to a BitmapDescriptor.
  Future<void> _buildMarkers({bool forceRebuild = false}) async {
    if (!forceRebuild && _markers.isNotEmpty) {
      // Only rebuild if necessary (e.g. selection changed)
      final needsRebuild = _mappableShifts.any((s) =>
      _selectedShift?.id == s.id ||
          (_markers.any((m) => m.markerId.value == s.id) == false));
      if (!needsRebuild) return;
    }

    final Set<Marker> markers = {};

    for (final shift in _mappableShifts) {
      final isSelected = _selectedShift?.id == shift.id;
      final bitmap = await _drawMarkerBitmap(
        shift: shift,
        isSelected: isSelected,
        size: isSelected ? 52.0 : 42.0,
      );

      markers.add(Marker(
        markerId: MarkerId(shift.id),
        position: LatLng(shift.shiftCase!.latitude!, shift.shiftCase!.longitude!),
        icon: bitmap,
        anchor: const Offset(0.5, 1.0),
        onTap: () => _onMarkerTap(shift),
      ));
    }

    if (mounted) setState(() => _markers = markers);
  }

  /// Converts a Flutter widget to a [BitmapDescriptor] for use as a Google Maps marker icon.
  Future<BitmapDescriptor> _widgetToBitmap(Widget widget,
      {double size = 42}) async {
    final repaintKey = GlobalKey();

    // Render off-screen
    final renderView = RepaintBoundary(
      key: repaintKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: SizedBox(width: size + 10, height: size + 16, child: widget),
          ),
        ),
      ),
    );

    // Use a PipelineOwner + BuildOwner to render without attaching to the tree
    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    final rootElement = renderView.createElement();
    buildOwner.buildScope(rootElement, () {
      rootElement.mount(null, null);
    });
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    // Fallback: use canvas drawing directly (simpler & more reliable)
    return _drawMarkerBitmap(shift: null, isSelected: false, size: size);
  }

  /// Draws a marker directly on canvas — reliable cross-platform alternative.
  Future<BitmapDescriptor> _drawMarkerBitmap({
    required ShiftModel? shift,
    required bool isSelected,
    required double size,
    Color? overrideColor,
  }) async {
    try {
      final dpr = ui.PlatformDispatcher.instance.views.first.devicePixelRatio.clamp(1.0, 3.0); // cap it
      final scaledSize = (size * dpr).roundToDouble();
      final pointerHeight = (8 * dpr).roundToDouble();
      final totalHeight = scaledSize + pointerHeight;

      final color = isSelected
          ? const Color(0xFF28D744)
          : (shift?.isUrgent ?? false) ? const Color(0xFFEF4444) : accentColor;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final cx = scaledSize / 2;
      final cy = scaledSize / 2;
      final r = scaledSize / 2;

      // Shadow
      canvas.drawCircle(
        Offset(cx, cy + 2 * dpr),
        r,
        Paint()
          ..color = color.withOpacity(0.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, isSelected ? 6 * dpr : 3 * dpr),
      );

      // Fill
      canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color);

      // White border
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * dpr,
      );

      // Icon
      final iconPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5 * dpr
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      if (shift?.isUrgent ?? false) {
        canvas.drawLine(
          Offset(cx, cy - r * 0.35),
          Offset(cx, cy + r * 0.1),
          iconPaint,
        );
        canvas.drawCircle(
          Offset(cx, cy + r * 0.35),
          1.5 * dpr,
          Paint()..color = Colors.white,
        );
      } else {
        final arm = r * 0.38;
        canvas.drawLine(Offset(cx, cy - arm), Offset(cx, cy + arm), iconPaint);
        canvas.drawLine(Offset(cx - arm, cy), Offset(cx + arm, cy), iconPaint);
      }

      // Pointer triangle
      final triPath = ui.Path()
        ..moveTo(cx - 5 * dpr, scaledSize)
        ..lineTo(cx + 5 * dpr, scaledSize)
        ..lineTo(cx, totalHeight)
        ..close();
      canvas.drawPath(triPath, Paint()..color = color);

      final picture = recorder.endRecording();
      final img = await picture.toImage(scaledSize.toInt(), totalHeight.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) throw Exception('Failed to get byte data');

      return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
    } catch (e, st) {
    debugPrint('Marker bitmap failed: $e\n$st');
    // Fallback to default marker
    return BitmapDescriptor.defaultMarkerWithHue(shift?.isUrgent ?? false ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure,
    );
  }
}

  Future<void> _onMarkerTap(ShiftModel shift) async {
    setState(() => _selectedShift = shift);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(shift.shiftCase!.latitude!, shift.shiftCase!.longitude!), 14.0));

    // Only rebuild markers once
    await _buildMarkers(forceRebuild: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Google Map ──────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialCenter,
              zoom: _initialZoom,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            onTap: (_) async {
              setState(() => _selectedShift = null);
              await _buildMarkers(); // deselect (revert green → original colour)
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // ── Top bar ─────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: ColorConstants.appGradient,
              ),
              padding: EdgeInsets.fromLTRB(
                  8, MediaQuery.of(context).padding.top + 4, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Shift locations',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${_mappableShifts.length} of ${widget.shifts.length} shifts mapped',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(_initialCenter, _initialZoom)),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.my_location_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Legend ──────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            right: 12,
            child: _buildLegend(),
          ),

          // ── Selected shift card ──────────────────────────────
          if (_selectedShift != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16,
              right: 16,
              child: _ShiftPreviewCard(
                shift: _selectedShift!,
                onClose: () async {
                  setState(() => _selectedShift = null);
                  await _buildMarkers();
                },
                onViewDetail: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ShiftDetailScreen(shiftId: _selectedShift!.id),
                  ),
                ),
                onBook: () async {
                  final ok = await ref
                      .read(marketplaceProvider.notifier)
                      .bookShift(_selectedShift!.id);
                  final errorMessage =
                      ref.read(marketplaceProvider).bookingError;
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok
                        ? 'Shift booked!'
                        : (errorMessage != null && errorMessage.length < 50)
                        ? errorMessage
                        : 'Booking failed'),
                    backgroundColor:
                    ok ? const Color(0xFF0F6E56) : Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ));
                  if (ok) {
                    setState(() => _selectedShift = null);
                    await _buildMarkers();
                  }
                },
                isBooking: ref.watch(marketplaceProvider).bookingShiftId ==
                    _selectedShift!.id,
              ),
            ),

          // ── Empty state overlay ──────────────────────────────
          if (_mappableShifts.isEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_off_outlined,
                        size: 48, color: Color(0xFF94A3B4)),
                    SizedBox(height: 12),
                    Text(
                      'No shifts have location data',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A2632)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Shifts appear here once a facility address is set.',
                      textAlign: TextAlign.center,
                      style:
                      TextStyle(fontSize: 12, color: Color(0xFF94A3B4)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegendRow(color: const Color(0xFFEF4444), label: 'Urgent'),
          const SizedBox(height: 4),
          _LegendRow(color: accentColor, label: 'Regular'),
          const SizedBox(height: 4),
          _LegendRow(color: const Color(0xFF28D744), label: 'Selected'),
        ],
      ),
    );
  }
}

// ── Marker widget (kept for reference / future use with RepaintBoundary) ──

class _ShiftMarkerWidget extends StatelessWidget {
  final ShiftModel shift;
  final bool isSelected;
  const _ShiftMarkerWidget({required this.shift, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? const Color(0xFF28D744)
        : shift.isUrgent
        ? const Color(0xFFEF4444)
        : accentColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isSelected ? 44 : 36,
          height: isSelected ? 44 : 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              shift.isUrgent
                  ? Icons.priority_high_rounded
                  : Icons.medical_services_outlined,
              color: Colors.white,
              size: isSelected ? 20 : 16,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(10, 6),
          painter: _TrianglePainter(color: color),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}

// ── Preview card ─────────────────────────────────────────────────────

class _ShiftPreviewCard extends ConsumerWidget {
  final ShiftModel shift;
  final VoidCallback onClose;
  final VoidCallback onViewDetail;
  final VoidCallback onBook;
  final bool isBooking;

  const _ShiftPreviewCard({
    required this.shift,
    required this.onClose,
    required this.onViewDetail,
    required this.onBook,
    required this.isBooking,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('EEE, MMM d');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: shift.isUrgent ? null : ColorConstants.appGradient,
              color: shift.isUrgent ? const Color(0xFFEF4444) : null,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (shift.shiftCase != null)
                            Text(
                              shift.shiftCase!.publicIdentifier,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B4),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4),
                            ),
                          Text(
                            shift.displayTitle,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A2632),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onClose,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4F7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: Color(0xFF536C79)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _InfoChip(
                      icon: Icons.access_time_rounded,
                      label:
                      '${dateFormat.format(shift.scheduledStart)} · '
                          '${timeFormat.format(shift.scheduledStart)}–'
                          '${timeFormat.format(shift.scheduledEnd)}',
                    ),
                    _InfoChip(
                      icon: Icons.location_on_outlined,
                      label: shift.locationDisplay,
                    ),
                    _InfoChip(
                      icon: Icons.attach_money_rounded,
                      label: '\$${shift.payRate.toStringAsFixed(0)}/hr',
                      highlight: true,
                    ),
                    if (shift.isUrgent)
                      _InfoChip(
                        icon: Icons.priority_high_rounded,
                        label: 'Urgent',
                        color: const Color(0xFFEF4444),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onViewDetail,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE2E8ED)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding:
                          const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Details',
                            style: TextStyle(color: Color(0xFF536C79))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          gradient:
                          isBooking ? null : ColorConstants.appGradient,
                          color: isBooking ? const Color(0xFFE2E8ED) : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: isBooking ? null : onBook,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isBooking
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                              : const Text('Book now',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;
  final Color? color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.highlight = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c =
        color ?? (highlight ? accentColor : const Color(0xFF536C79));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: c,
                fontWeight:
                highlight ? FontWeight.w700 : FontWeight.normal)),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
          width: 10,
          height: 10,
          decoration:
          BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(
              fontSize: 11, color: Color(0xFF536C79))),
    ],
  );
}