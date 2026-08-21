import 'models/support_ticket.dart';

abstract class SupportRepository {
  Future<SubmitTicketResult> submitTicket({
    required String name,
    required String email,
    required String category,
    required String message,
    required String userId,
  });

  Future<({List<TicketListItem> tickets, int total, bool hasMore})> getTickets({
    int page = 1,
    int limit = 15,
    String? status,
    String? search,
  });

  Future<TicketDetail> getTicketDetail(String ticketId);

  Future<void> addReply({
    required String ticketId,
    required String body,
    bool isInternal = false,
  });
}