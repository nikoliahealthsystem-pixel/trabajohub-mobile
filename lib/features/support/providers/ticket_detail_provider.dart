import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:trabajo_hub/features/support/providers/support_provider.dart';
import '../data/support_repository.dart';
import '../data/models/support_ticket.dart';

final ticketDetailProvider = StateNotifierProvider.family<TicketDetailNotifier, TicketDetailState, String>(
      (ref, ticketId) => TicketDetailNotifier(ref.watch(supportRepositoryProvider), ticketId),
);

class TicketDetailState {
  final TicketDetail? ticket;
  final bool isLoading;
  final String? error;

  TicketDetailState({
    this.ticket,
    this.isLoading = true,
    this.error,
  });

  TicketDetailState copyWith({
    TicketDetail? ticket,
    bool? isLoading,
    String? error,
  }) {
    return TicketDetailState(
      ticket: ticket ?? this.ticket,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class TicketDetailNotifier extends StateNotifier<TicketDetailState> {
  final SupportRepository _repository;
  final String ticketId;

  TicketDetailNotifier(this._repository, this.ticketId)
      : super(TicketDetailState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final ticket = await _repository.getTicketDetail(ticketId);
      state = state.copyWith(
        ticket: ticket,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      debugPrint("❌ Failed to load ticket $ticketId: $e"); // ← Debug
      debugPrint(stackTrace.toString());

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addReply(String body) async {
    if (state.ticket == null) return;

    try {
      await _repository.addReply(ticketId: ticketId, body: body);
      await load(); // Refresh after reply
    } catch (e) {
      debugPrint("❌ Failed to add reply: $e");
      // You can show a snackbar here
    }
  }
}