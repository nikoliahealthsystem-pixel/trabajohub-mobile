import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/buttons/notification_button.dart';
import '../providers/shifts_provider.dart';
import '../state/marketplace_state.dart';
import 'widgets/shift_card.dart';
import 'shift_detail_screen.dart';
import 'map_screen.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();   // ← was missing
  Timer? _searchDebounce;

  static const _visitTypes = [
    'All', 'REGULAR', 'ADMISSION', 'DISCHARGE', 'SUPERVISORY', 'RECERTIFICATION'
  ];
  String _selectedType = 'All';
  bool _urgentOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(marketplaceProvider.notifier).load(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(marketplaceProvider);
      if (state.hasMore && state.status == MarketplaceStatus.success) {
        ref.read(marketplaceProvider.notifier).load();
      }
    }
  }

  // ── Debounced Search ───────────────────────────────────────
    void _onSearchChanged(String value) {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 450), () {
        _applyFilter();
      });
    }

  // Updated applyFilter
  Future<void> _applyFilter() async {
    final filter = MarketplaceFilter(
      visitType: _selectedType == 'All' ? null : _selectedType,
      isUrgent: _urgentOnly ? true : null,
      searchQuery: _searchController.text.trim(),   // Always read from controller here
    );

    await ref.read(marketplaceProvider.notifier).applyFilter(filter);
  }

  Future<void> _handleBook(String shiftId) async {
    final success =
    await ref.read(marketplaceProvider.notifier).bookShift(shiftId);
    final errorMessage = ref.read(marketplaceProvider).bookingError;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Shift booked successfully!'
            : errorMessage ?? "Booking Failed"),
        backgroundColor:
        success ? const Color(0xFF0F6E56) : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceProvider);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          _buildFilterChips(),
          Expanded(child: _buildBody(state)),
        ],
      ),
      // ── Map FAB ──────────────────────────────────────────
      floatingActionButton: state.shifts.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShiftMapScreen(shifts: state.shifts),
          ),
        ),
        backgroundColor: accentColor,
        icon: const Icon(Icons.map_outlined, color: Colors.white),
        label: const Text('Map',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: ColorConstants.appGradient),
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 20),
      child:
         Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
               ),Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
               const Text('Shifts Market Place',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),

                     const SizedBox(height: 2),
                     const Text('Open shifts matching your designation',
                         style: TextStyle(color: Colors.white70, fontSize: 13)),
                   ],
               ),
               NotificationsBell()]),

          // ── cant be used cause backend can no longer be modified safely ─────────────────────
          // const SizedBox(height: 14),
          // Container(
          //   height: 44,
          //   decoration: BoxDecoration(
          //     color: Colors.white.withOpacity(0.18),
          //     borderRadius: BorderRadius.circular(12),
          //   ),
          //   padding: const EdgeInsets.symmetric(horizontal: 12),
          //   child: Row(
          //     children: [
          //       const Icon(Icons.search, color: Colors.white70, size: 18),
          //       const SizedBox(width: 8),
          //       Expanded(
          //         child: TextField(
          //           controller: _searchController,
          //           style: const TextStyle(color: Colors.white, fontSize: 14),
          //           decoration: const InputDecoration(
          //             hintText: 'Search by city or visit type…',
          //             hintStyle:
          //             TextStyle(color: Colors.white60, fontSize: 14),
          //             border: InputBorder.none,
          //             isDense: true,
          //           ),
          //           onChanged: _onSearchChanged,
          //         ),
          //       ),
          //       // Clear button
          //       ValueListenableBuilder<TextEditingValue>(
          //         valueListenable: _searchController,
          //         builder: (_, value, __) => value.text.isNotEmpty
          //             ? GestureDetector(
          //           onTap: () {
          //             _searchController.clear();
          //             _applyFilter();
          //           },
          //           child: const Icon(Icons.close,
          //               color: Colors.white70, size: 18),
          //         )
          //             : const SizedBox.shrink(),
          //       ),
          //     ],
          //   ),
          // ),

    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _FilterChip(
              label: 'Urgent',
              isActive: _urgentOnly,
              onTap: () {
                setState(() => _urgentOnly = !_urgentOnly);
                _applyFilter();
              },
            ),
            const SizedBox(width: 8),
            ..._visitTypes.map((type) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: type == 'All'
                    ? 'All types'
                    : type.replaceAll('_', ' '),
                isActive: _selectedType == type,
                onTap: () {
                  setState(() => _selectedType = type);
                  _applyFilter();
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(MarketplaceState state) {
    if (state.status == MarketplaceStatus.loading) {
      return Center(
          child: CircularProgressIndicator(color: accentColor));
    }

    if (state.status == MarketplaceStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: Color(0xFFE24B4A)),
            const SizedBox(height: 12),
            Text(state.errorMessage!.length  < 50 ? "${state.errorMessage}" : "Error Fetching Shift, Something Went Wrong"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(marketplaceProvider.notifier).load(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.shifts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.work_off_outlined,
                size: 52, color: Color(0xFF94A3B4)),
            SizedBox(height: 12),
            Text('No open shifts available',
                style: TextStyle(color: Color(0xFF536C79))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: accentColor,
      onRefresh: () =>
          ref.read(marketplaceProvider.notifier).load(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 12, bottom: 100),
        itemCount: state.shifts.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.shifts.length) {
            return Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                  child: CircularProgressIndicator(
                      color: accentColor)),
            );
          }
          final shift = state.shifts[index];
          return ShiftCard(
            shift: shift,
            isBooking: state.bookingShiftId == shift.id,
            onBook: () => _handleBook(shift.id),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ShiftDetailScreen(shiftId: shift.id)),
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFEAF8FC)
            : const Color(0xFFF0F4F7),
        border: Border.all(
          color: isActive
              ? accentColor
              : const Color(0xFFE2E8ED),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive
              ? const Color(0xFF0A7D95)
              : const Color(0xFF536C79),
        ),
      ),
    ),
  );
}