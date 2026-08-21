import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trabajo_hub/core/constants/app_constants.dart';
import 'package:trabajo_hub/core/widgets/buttons/notification_button.dart';
import '../providers/shifts_provider.dart';
import '../state/my_shifts_state.dart';
import 'widgets/my_shift_card.dart';
import 'shift_detail_screen.dart';

class MyShiftsScreen extends ConsumerStatefulWidget {
  const MyShiftsScreen({super.key});

  @override
  ConsumerState<MyShiftsScreen> createState() => _MyShiftsScreenState();
}

class _MyShiftsScreenState extends ConsumerState<MyShiftsScreen> {
  final _scrollController = ScrollController();

  static const _tabs = [
    ('ACCEPTED', 'Upcoming'),
    ('COMPLETED', 'Completed'),
    ('CANCELLED', 'Cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myShiftsProvider.notifier).load(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(myShiftsProvider);
      if (state.hasMore && state.status == MyShiftsStatus.success) {
        ref.read(myShiftsProvider.notifier).load();
      }
    }
  }

  Future<void> _confirmCancel(String shiftId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel shift'),
        content: const Text('Are you sure you want to cancel this shift? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep shift')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel shift', style: TextStyle(color: Color(0xFFE24B4A))),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await ref.read(myShiftsProvider.notifier).cancelShift(shiftId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Shift cancelled' : 'Failed to cancel shift'),
        backgroundColor: success ? const Color(0xFF536C79) : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myShiftsProvider);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context,state),
          _buildTabs(state.selectedTab),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context,MyShiftsState state) {
    return Container(
      decoration: const BoxDecoration(gradient: ColorConstants.appGradient),
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [ const Text('My Shifts',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
                NotificationsBell()]),
          const SizedBox(height: 2),
          Text(
            '${state.total} ${state.selectedTab.toLowerCase()} shifts',
            style:  TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(String selectedTab) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: _tabs.map((tab) {
          final isActive = selectedTab == tab.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(myShiftsProvider.notifier).switchTab(tab.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFEAF8FC) : Colors.transparent,
                  border: Border.all(
                    color: isActive ? accentColor : Colors.transparent,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tab.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? accentColor : const Color(0xFF94A3B4),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody(MyShiftsState state) {
    if (state.status == MyShiftsStatus.loading) {
      return  Center(child: CircularProgressIndicator(color: accentColor));
    }

    if (state.assignments.isEmpty && state.status == MyShiftsStatus.success) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_outlined, size: 52, color: Color(0xFF94A3B4)),
            const SizedBox(height: 12),
            Text(
              'No ${state.selectedTab.toLowerCase()} shifts',
              style: const TextStyle(color: Color(0xFF536C79)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: accentColor,
      onRefresh: () => ref.read(myShiftsProvider.notifier).load(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        itemCount: state.assignments.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.assignments.length) {
            return  Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: accentColor)),
            );
          }
          final assignment = state.assignments[index];
          return MyShiftCard(
            assignment: assignment,
            isCancelling: state.cancellingId == assignment.shiftId,
            onTap: () {
              if (assignment.shift != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ShiftDetailScreen(shiftId: assignment.shiftId)),
                );
              }
            },
            onCancel: assignment.status == 'ACCEPTED'
                ? () => _confirmCancel(assignment.shiftId)
                : null,
          );
        },
      ),
    );
  }
}