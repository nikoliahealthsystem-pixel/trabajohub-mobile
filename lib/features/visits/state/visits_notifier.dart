import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';

import '../data/models/visit_model.dart';
import '../data/visits_repository.dart';
import 'visits_state.dart';

class VisitsNotifier extends StateNotifier<VisitsState> {
  final VisitsRepository _repo;

  VisitsNotifier(this._repo) : super(const VisitsState());

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
      state = state.copyWith(
        status: VisitsLoadStatus.error,
        errorMessage: _extractErrorMessage(
          e,
          fallback: 'Unable to load visits.',
        ),
      );
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

  void clearEvvError() {
    state = state.copyWith(evvError: null, evvFlagged: false);
  }

  Future<Position> _getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw 'Location services are disabled. You can enable GPS or choose another verification method.';
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw 'Location permission was denied. Choose another verification method if GPS is unavailable.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission is permanently denied. Enable it in Settings or choose another verification method.';
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  Future<Position?> _tryCurrentLocation() async {
    try {
      return await _getCurrentLocation();
    } catch (_) {
      return null;
    }
  }

  Future<bool> checkIn(
    String visitId, {
    String verificationMethod = 'GPS',
    String? qrCode,
    String? pin,
    String? reason,
  }) async {
    state = state.copyWith(
      checkingInVisitId: visitId,
      evvError: null,
      evvFlagged: false,
    );

    try {
      final requiresGps = verificationMethod == 'GPS';
      final position = requiresGps
          ? await _getCurrentLocation()
          : await _tryCurrentLocation();

      final updated = await _repo.checkIn(
        visitId: visitId,
        verificationMethod: verificationMethod,
        latitude: position?.latitude,
        longitude: position?.longitude,
        accuracy: position?.accuracy,
        qrCode: qrCode,
        pin: pin,
        reason: reason,
      );

      final needsReview =
          updated.overrideRequired || updated.status == VisitStatus.flagged;

      state = state.copyWith(
        checkingInVisitId: null,
        visits: _replaceVisit(updated),
        evvFlagged: needsReview,
        evvError: needsReview
            ? (updated.overrideReason ?? 'Check-in recorded for review.')
            : null,
      );

      return true;
    } catch (e) {
      final message = _extractErrorMessage(e, fallback: 'Unable to check in.');

      final isFlagged = _isReviewResponse(e, message);

      if (isFlagged) {
        await _refreshVisitAfterReview(visitId);
      }

      state = state.copyWith(
        checkingInVisitId: null,
        evvError: message,
        evvFlagged: isFlagged,
      );

      return false;
    }
  }

  Future<bool> checkOut(
    String visitId, {
    String verificationMethod = 'GPS',
    String? qrCode,
    String? pin,
    String? reason,
    String? notes,
  }) async {
    state = state.copyWith(
      checkingOutVisitId: visitId,
      evvError: null,
      evvFlagged: false,
    );

    try {
      final requiresGps = verificationMethod == 'GPS';
      final position = requiresGps
          ? await _getCurrentLocation()
          : await _tryCurrentLocation();

      final updated = await _repo.checkOut(
        visitId: visitId,
        verificationMethod: verificationMethod,
        latitude: position?.latitude,
        longitude: position?.longitude,
        accuracy: position?.accuracy,
        qrCode: qrCode,
        pin: pin,
        reason: reason,
        notes: notes,
      );

      final needsReview = updated.overrideRequired;

      state = state.copyWith(
        checkingOutVisitId: null,
        visits: _replaceVisit(updated),
        evvFlagged: needsReview,
        evvError: needsReview
            ? (updated.overrideReason ?? 'Checkout recorded for review.')
            : null,
      );

      return true;
    } catch (e) {
      final message = _extractErrorMessage(e, fallback: 'Unable to check out.');

      final isFlagged = _isReviewResponse(e, message);

      if (isFlagged) {
        await _refreshVisitAfterReview(visitId);
      }

      state = state.copyWith(
        checkingOutVisitId: null,
        evvError: message,
        evvFlagged: isFlagged,
      );

      return false;
    }
  }

  Future<void> _refreshVisitAfterReview(String visitId) async {
    try {
      final updated = await _repo.getVisit(visitId);
      state = state.copyWith(visits: _replaceVisit(updated));
    } catch (_) {
      // Keep the original list if the refresh itself fails.
    }
  }

  bool _isReviewResponse(Object error, String message) {
    if (error is DioException && error.response?.statusCode == 422) {
      return true;
    }

    final normalized = message.toLowerCase();

    return normalized.contains('flagged') ||
        normalized.contains('override') ||
        normalized.contains('review');
  }

  String _extractErrorMessage(Object error, {required String fallback}) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        final candidates = [data['message'], data['error'], data['detail']];

        for (final candidate in candidates) {
          if (candidate is String && candidate.trim().isNotEmpty) {
            return candidate.trim();
          }
        }
      }

      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!.trim();
      }
    }

    final text = error.toString().replaceFirst('Exception: ', '').trim();
    return text.isEmpty ? fallback : text;
  }

  List<VisitModel> _replaceVisit(VisitModel updated) {
    return state.visits
        .map((visit) => visit.id == updated.id ? updated : visit)
        .toList();
  }
}
