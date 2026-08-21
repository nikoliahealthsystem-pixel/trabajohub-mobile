import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/cases_repository.dart';
import 'cases_state.dart';

class CasesNotifier extends StateNotifier<CasesState> {
  final CasesRepository _repo;
  Timer? _searchDebounce;
  CasesNotifier(this._repo) : super(const CasesState());

  Future<void> load({bool refresh = false}) async {
    if (state.status == CasesStatus.loading) return;
    final page = refresh ? 1 : state.page;
    state = state.copyWith(
      status: (refresh || state.cases.isEmpty)
          ? CasesStatus.loading
          : CasesStatus.loadingMore,
      cases: refresh ? [] : state.cases,
    );
    try {
      final result = await _repo.getCases(
        page: page,
        visitType: state.visitTypeFilter,
        isActive: state.isActiveFilter,
        search: state.searchQuery,
      );
      state = state.copyWith(
        status: CasesStatus.success,
        cases: [...(refresh ? [] : state.cases), ...result.cases],
        total: result.total,
        hasMore: result.hasMore,
        page: page + 1,
      );
    } catch (e) {
      final message = e is DioException
          ? (e.error?.toString() ?? 'Something went wrong')
          : e.toString();
      state = state.copyWith(
          status: CasesStatus.error, errorMessage: message);
    }
  }

  void search(String query) {
    _searchDebounce?.cancel();
    state = state.copyWith(searchQuery: query.isEmpty ? null : query);
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      load(refresh: true);
    });
  }

  void setVisitTypeFilter(String? type) {
    state = state.copyWith(visitTypeFilter: type);
    load(refresh: true);
  }

  void setActiveFilter(bool? isActive) {
    state = state.copyWith(isActiveFilter: isActive);
    load(refresh: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}