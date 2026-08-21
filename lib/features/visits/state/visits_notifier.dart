import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';
import '../data/models/visit_model.dart';
import '../data/visits_repository.dart';
import 'visits_state.dart';

class VisitsNotifier extends StateNotifier<VisitsState> {
  final VisitsRepository _repo;
  VisitsNotifier(this._repo) : super(const VisitsState());

  // ── Load ──────────────────────────────────────────────────

  Future<void> load({bool refresh = false}) async {
    if (state.status == VisitsLoadStatus.loading) return;
    final page = refresh ? 1 : state.page;
    state = state.copyWith(
      status: (refresh || state.visits.isEmpty)
          ? VisitsLoadStatus.loading
          : VisitsLoadStatus.loadingMore,
      visits: refresh ? [] : state.visits,
    );
    try {
      final result = await _repo.getVisits(
        page: page,
        status: state.statusFilter,
        flaggedOnly: state.flaggedOnly,
      );
      state = state.copyWith(
        status: VisitsLoadStatus.success,
        visits: [...(refresh ? [] : state.visits), ...result.visits],
        total: result.total,
        hasMore: result.hasMore,
        page: page + 1,
      );
    } catch (e) {
      final msg = e is DioException ? (e.message ?? 'Something went wrong') : e.toString();
      state = state.copyWith(
          status: VisitsLoadStatus.error, errorMessage: msg);
    }
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status);
    load(refresh: true);
  }

  void toggleFlaggedOnly() {
    state = state.copyWith(flaggedOnly: !state.flaggedOnly);
    load(refresh: true);
  }

  void clearEvvError() =>
      state = state.copyWith(evvError: null, evvFlagged: false);

  // ── GPS helper ─────────────────────────────────────────────

  /// Requests location permission and returns current position.
  /// Throws a descriptive string on permission denial or service disabled.
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled. Please enable GPS.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission denied.';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission permanently denied. Please enable it in Settings.';
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  // ── Check-in ───────────────────────────────────────────────

  /// Returns true on success, false on error.
  /// On geofence flag (422), returns false and sets evvFlagged=true.
  Future<bool> checkIn(String visitId, {String? qrCode}) async {
    state = state.copyWith(
        checkingInVisitId: visitId, evvError: null, evvFlagged: false);
    try {
      final pos = await _getCurrentLocation();
      final updated = await _repo.checkIn(
        visitId: visitId,
        latitude: pos.latitude,
        longitude: pos.longitude,
        qrCode: qrCode,
      );
      // Replace the visit in the list with the updated model
      state = state.copyWith(
        checkingInVisitId: null,
        visits: _replaceVisit(updated),
      );
      return true;
    } catch (e) {
      final msg = e is DioException ? (e.message ?? 'Something went wrong') : e.toString();
      // 422 geofence flag — treat as a soft warning, not a hard error
      final isFlagged = msg.toLowerCase().contains('flagged') ||
          msg.toLowerCase().contains('override');
      state = state.copyWith(
        checkingInVisitId: null,
        evvError: msg.replaceAll('Exception: ', ''),
        evvFlagged: isFlagged,
      );
      return false;
    }
  }

  // ── Check-out ──────────────────────────────────────────────

  Future<bool> checkOut(String visitId, {String? notes}) async {
    state = state.copyWith(
        checkingOutVisitId: visitId, evvError: null, evvFlagged: false);
    try {
      final pos = await _getCurrentLocation();
      final updated = await _repo.checkOut(
        visitId: visitId,
        latitude: pos.latitude,
        longitude: pos.longitude,
        notes: notes,
      );
      state = state.copyWith(
        checkingOutVisitId: null,
        visits: _replaceVisit(updated),
      );
      return true;
    } catch (e) {
      final msg = e is DioException ? (e.message ?? 'Something went wrong') : e.toString();
      state = state.copyWith(
        checkingOutVisitId: null,
        evvError: msg.replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  List<VisitModel> _replaceVisit(VisitModel updated) => state.visits.map((v) => v.id == updated.id ? updated : v).toList();
}