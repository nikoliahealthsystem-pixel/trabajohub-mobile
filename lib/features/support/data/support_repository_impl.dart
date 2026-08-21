import 'package:dio/dio.dart';
import '../../../core/cache/app_cache.dart';
import '../../../core/cache/cache_keys.dart';
import '../../../core/cache/cache_ttl.dart';
import 'api/support_api.dart';
import 'models/support_ticket.dart';
import 'support_repository.dart';
class SupportRepositoryImpl implements SupportRepository {
  final SupportApi _api;
  final AppCache _cache;

  SupportRepositoryImpl(this._api, this._cache);

  // ── Submit Ticket ─────────────────────────────
  @override
  Future<SubmitTicketResult> submitTicket({
    required String name,
    required String email,
    required String category,
    required String message,
    required String userId,
  }) async {

    final payload = {
      "name": name.trim(),
      "email": email.trim(),
      "subject": "$category: ${message.length > 60 ? '${message.substring(0, 60)}…' : message}",
      "category": category,
      "message": message.trim(),
      if (userId != null) "userId": userId,
    };

    final response = await _api.submitTicket(payload);
    return SubmitTicketResult.fromJson(response['data']);
  }

  // ── Ticket History ─────────────────────────────
  @override
  Future<({List<TicketListItem> tickets, int total, bool hasMore})> getTickets({
    int page = 1,
    int limit = 15,
    String? status,
    String? search,
  }) async {
    final key = CacheKeys.tickets(
      page: page,
      status: status,
      search: search,
    );

    final cached = _cache.get<({List<TicketListItem> tickets, int total, bool hasMore})>(key);

    if (cached != null && !cached.isStale) {
      return cached.data;
    }

    try {
      final raw = await _api.getTickets(
        page: page,
        limit: limit,
        status: status,
        search: search,
      );

      final data = raw['data'] as List? ?? [];
      final pagination = raw['pagination'] as Map<String, dynamic>? ?? {};

      final result = (
      tickets: data.map((j) => TicketListItem.fromJson(j)).toList(),
      total: pagination['total'] as int? ?? 0,
      hasMore: pagination['hasNext'] as bool? ?? false,
      );

      _cache.set(key, result, CacheTtl.tickets);
      return result;
    } catch (e) {
      if (cached != null) return cached.data;
      rethrow;
    }
  }

  // ── Ticket Detail ─────────────────────────────
  @override
  Future<TicketDetail> getTicketDetail(String ticketId) async {
    final key = CacheKeys.ticketDetail(ticketId);
    final cached = _cache.get<TicketDetail>(key);

    if (cached != null && !cached.isExpired) {
      return cached.data;
    }

    try {
      final raw = await _api.getTicketDetail(ticketId);
      final ticket = TicketDetail.fromJson(raw['data']);

      _cache.set(key, ticket, CacheTtl.ticketDetail);
      return ticket;
    } catch (e) {
      if (cached != null) return cached.data;
      rethrow;
    }
  }

  // ── Add Reply ─────────────────────────────
  @override
  Future<void> addReply({
    required String ticketId,
    required String body,
    bool isInternal = false,
  }) async {
    await _api.addReply(
      ticketId: ticketId,
      body: body,
      isInternal: isInternal,
    );

    // Invalidate related cache
    _cache.invalidate(CacheKeys.ticketDetail(ticketId));
  }
}