import '../data/models/visit_model.dart';

const _sentinel = Object();
enum VisitsLoadStatus { initial, loading, loadingMore, success, error }

class VisitsState {
  final VisitsLoadStatus status;
  final List<VisitModel> visits;
  final int total;
  final bool hasMore;
  final int page;
  final String? statusFilter;
  final bool flaggedOnly;
  final String? errorMessage;

  // ── EVV (check-in / check-out) ─────────────────────────
  final String? checkingInVisitId;   // visitId currently being checked in
  final String? checkingOutVisitId;  // visitId currently being checked out
  final String? evvError;            // geofence / server error message
  final bool evvFlagged;             // true when backend returns 422 geofence flag

  const VisitsState({
    this.status = VisitsLoadStatus.initial,
    this.visits = const [],
    this.total = 0,
    this.hasMore = false,
    this.page = 1,
    this.statusFilter,
    this.flaggedOnly = false,
    this.errorMessage,
    this.checkingInVisitId,
    this.checkingOutVisitId,
    this.evvError,
    this.evvFlagged = false,
  });

  VisitsState copyWith({
    VisitsLoadStatus? status,
    List<VisitModel>? visits,
    int? total,
    bool? hasMore,
    int? page,
    Object? statusFilter = _sentinel,
    bool? flaggedOnly,
    Object? errorMessage = _sentinel,
    Object? checkingInVisitId = _sentinel,
    Object? checkingOutVisitId = _sentinel,
    Object? evvError = _sentinel,
    bool? evvFlagged,
  }) =>
      VisitsState(
        status: status ?? this.status,
        visits: visits ?? this.visits,
        total: total ?? this.total,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        statusFilter: statusFilter == _sentinel
            ? this.statusFilter
            : statusFilter as String?,
        flaggedOnly: flaggedOnly ?? this.flaggedOnly,
        errorMessage: errorMessage == _sentinel
            ? this.errorMessage
            : errorMessage as String?,
        checkingInVisitId: checkingInVisitId == _sentinel
            ? this.checkingInVisitId
            : checkingInVisitId as String?,
        checkingOutVisitId: checkingOutVisitId == _sentinel
            ? this.checkingOutVisitId
            : checkingOutVisitId as String?,
        evvError: evvError == _sentinel
            ? this.evvError
            : evvError as String?,
        evvFlagged: evvFlagged ?? this.evvFlagged,
      );
}