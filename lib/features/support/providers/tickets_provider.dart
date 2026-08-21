import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/misc.dart';
import '../../../core/cache/cache_provider.dart';
import '../data/api/support_api.dart';
import '../data/models/support_ticket.dart';
import '../data/support_repository.dart';
import '../data/support_repository_impl.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  final api = ref.watch(supportApiProvider);
  final cache = ref.watch(appCacheProvider);

  return SupportRepositoryImpl(api, cache);
});

final ticketsProvider = StateNotifierProvider<TicketsNotifier, TicketsState>((ref) {
  return TicketsNotifier(ref.watch(supportRepositoryProvider));
});

class TicketsState {
  final List<TicketListItem> tickets;
  final TicketsLoadStatus status;
  final String? errorMessage;
  final int total;
  final bool hasMore;
  final String? statusFilter;
  final String? searchQuery;

  TicketsState({
    this.tickets = const [],
    this.status = TicketsLoadStatus.initial,
    this.errorMessage,
    this.total = 0,
    this.hasMore = true,
    this.statusFilter,
    this.searchQuery,
  });

  TicketsState copyWith({
    List<TicketListItem>? tickets,
    TicketsLoadStatus? status,
    String? errorMessage,
    int? total,
    bool? hasMore,
    String? statusFilter,
    String? searchQuery,
  }) {
    return TicketsState(
      tickets: tickets ?? this.tickets,
      status: status ?? this.status,
      errorMessage: errorMessage,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

enum TicketsLoadStatus { initial, loading, success, error }

class TicketsNotifier extends StateNotifier<TicketsState> {
  final SupportRepository _repository;
  int _currentPage = 1;

  TicketsNotifier(this._repository) : super(TicketsState());

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      state = state.copyWith(tickets: [], status: TicketsLoadStatus.loading);
    }
    try {
      final response = await _repository.getTickets(
        page: _currentPage,
        limit: 15,
        status: state.statusFilter,
        search: state.searchQuery,
      );

      final newTickets = refresh ? response.tickets : [...state.tickets, ...response.tickets];

      state = state.copyWith(
        tickets: newTickets,
        total: response.total,
        hasMore: response.hasMore,
        status: TicketsLoadStatus.success,
      );
      if (response.hasMore) _currentPage++;
    }  catch (e) {
      debugPrint("❌ ERROR fetching tickets: $e");
    }
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status);
    load(refresh: true);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    load(refresh: true);
  }

  void toggleStatusFilter(String? status) {
    setStatusFilter(state.statusFilter == status ? null : status);
  }
}