import '../data/models/shift_model.dart';

enum MarketplaceStatus { initial, loading, loadingMore, success, error }

class MarketplaceFilter {
  final String? visitType;
  final bool? isUrgent;
  final double? minPay;
  final double? maxPay;
  final String? date;
  final String? searchQuery;

  const MarketplaceFilter({
    this.visitType,
    this.isUrgent,
    this.minPay,
    this.maxPay,
    this.date,
    this.searchQuery,
  });

  MarketplaceFilter copyWith({
    Object? visitType = _sentinel,
    Object? isUrgent = _sentinel,
    Object? minPay = _sentinel,
    Object? maxPay = _sentinel,
    Object? date = _sentinel,
    Object? searchQuery = _sentinel,
  }) =>
      MarketplaceFilter(
        visitType: visitType == _sentinel ? this.visitType : visitType as String?,
        isUrgent: isUrgent == _sentinel ? this.isUrgent : isUrgent as bool?,
        minPay: minPay == _sentinel ? this.minPay : minPay as double?,
        maxPay: maxPay == _sentinel ? this.maxPay : maxPay as double?,
        date: date == _sentinel ? this.date : date as String?,
        searchQuery: searchQuery == _sentinel
            ? this.searchQuery
            : searchQuery as String?,
      );
}

const _sentinel = Object();

class MarketplaceState {
  final MarketplaceStatus status;
  final List<ShiftModel> shifts;
  final int currentPage;
  final int total;
  final String? errorMessage;
  final MarketplaceFilter filter;
  final String? bookingShiftId;
  final String? bookingError;

  const MarketplaceState({
    this.status = MarketplaceStatus.initial,
    this.shifts = const [],
    this.currentPage = 1,
    this.total = 0,
    this.errorMessage,
    this.filter = const MarketplaceFilter(),
    this.bookingShiftId,
    this.bookingError,
  });

  bool get hasMore => shifts.length < total;

  MarketplaceState copyWith({
    MarketplaceStatus? status,
    List<ShiftModel>? shifts,
    int? currentPage,
    int? total,
    String? errorMessage,
    MarketplaceFilter? filter,
    Object? bookingShiftId = _sentinel,
    Object? bookingError = _sentinel,
  }) =>
      MarketplaceState(
        status: status ?? this.status,
        shifts: shifts ?? this.shifts,
        currentPage: currentPage ?? this.currentPage,
        total: total ?? this.total,
        errorMessage: errorMessage ?? this.errorMessage,
        filter: filter ?? this.filter,
        bookingShiftId: bookingShiftId == _sentinel ? this.bookingShiftId : bookingShiftId as String?,
        bookingError: bookingError == _sentinel ? this.bookingError : bookingError as String?,
      );
}