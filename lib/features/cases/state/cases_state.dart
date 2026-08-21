import '../data/models/case_model.dart';

const _sentinel = Object();
enum CasesStatus { initial, loading, loadingMore, success, error }

class CasesState {
  final CasesStatus status;
  final List<CaseModel> cases;
  final int total;
  final bool hasMore;
  final int page;
  final String? searchQuery;
  final String? visitTypeFilter;
  final bool? isActiveFilter;
  final String? errorMessage;

  const CasesState({
    this.status = CasesStatus.initial,
    this.cases = const [],
    this.total = 0,
    this.hasMore = false,
    this.page = 1,
    this.searchQuery,
    this.visitTypeFilter,
    this.isActiveFilter,
    this.errorMessage,
  });

  CasesState copyWith({
    CasesStatus? status,
    List<CaseModel>? cases,
    int? total,
    bool? hasMore,
    int? page,
    Object? searchQuery = _sentinel,
    Object? visitTypeFilter = _sentinel,
    Object? isActiveFilter = _sentinel,
    Object? errorMessage = _sentinel,
  }) =>
      CasesState(
        status: status ?? this.status,
        cases: cases ?? this.cases,
        total: total ?? this.total,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        searchQuery: searchQuery == _sentinel
            ? this.searchQuery
            : searchQuery as String?,
        visitTypeFilter: visitTypeFilter == _sentinel
            ? this.visitTypeFilter
            : visitTypeFilter as String?,
        isActiveFilter: isActiveFilter == _sentinel
            ? this.isActiveFilter
            : isActiveFilter as bool?,
        errorMessage: errorMessage == _sentinel
            ? this.errorMessage
            : errorMessage as String?,
      );
}