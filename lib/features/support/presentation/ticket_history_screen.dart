import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trabajo_hub/features/support/presentation/ticket_detail_screen.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/tickets_provider.dart';
import 'widgets/ticket_tile.dart';

class TicketHistoryScreen extends ConsumerStatefulWidget {
  const TicketHistoryScreen({super.key});

  @override
  ConsumerState<TicketHistoryScreen> createState() => _TicketHistoryScreenState();
}

class _TicketHistoryScreenState extends ConsumerState<TicketHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ticketsProvider.notifier).load(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final state = ref.read(ticketsProvider);
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        state.hasMore &&
        state.status == TicketsLoadStatus.success) {
      ref.read(ticketsProvider.notifier).load();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ticketsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: Column(
        children: [
          _buildHeader(state),
          _buildFilters(state),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildHeader(TicketsState state) => Container(
    decoration: const BoxDecoration(gradient: ColorConstants.appGradient),
    padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 18),
    child: Row(
      spacing: 16,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16),
          ),
        ),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Support Tickets',
                  style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
              Text('Your recent requests', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        Text('${state.total} tickets',
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    ),
  );

  Widget _buildFilters(TicketsState state) => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: ['All', 'OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'].map((status) {
          final isActive = state.statusFilter == (status == 'All' ? null : status);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => ref.read(ticketsProvider.notifier).setStatusFilter(status == 'All' ? null : status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFEAF8FC) : const Color(0xFFF0F4F7),
                  border: Border.all(color: isActive ? const Color(0xFF0A7D95) : const Color(0xFFE2E8ED)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.replaceAll("_", " "),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? const Color(0xFF0A7D95) : const Color(0xFF536C79),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );

  Widget _buildBody(TicketsState state) {
    if (state.status == TicketsLoadStatus.loading && state.tickets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == TicketsLoadStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(state.errorMessage ?? 'Failed to load tickets'),
            TextButton(
              onPressed: () => ref.read(ticketsProvider.notifier).load(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.tickets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.support_agent, size: 60, color: Color(0xFF94A3B4)),
            SizedBox(height: 12),
            Text('No tickets yet', style: TextStyle(color: Color(0xFF536C79))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(ticketsProvider.notifier).load(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: state.tickets.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.tickets.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final ticket = state.tickets[index];
          return TicketTile(
            ticket: ticket,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TicketDetailScreen(ticketId: ticket.id)),
            ),
          );
        },
      ),
    );
  }
}