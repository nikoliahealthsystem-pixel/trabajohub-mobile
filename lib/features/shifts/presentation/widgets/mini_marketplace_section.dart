import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trabajo_hub/features/shifts/presentation/widgets/shift_card.dart';
import '../../../../core/constants/app_constants.dart';
import '../../providers/shifts_provider.dart';
import '../../state/marketplace_state.dart';
import '../marketplace_screen.dart';
import '../shift_detail_screen.dart';

class MiniMarketplaceSection extends ConsumerWidget {
  const MiniMarketplaceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(marketplaceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Shift Marketplace',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
              ),
              child: Text('View All',style: TextStyle(color: accentColor),),
            ),
          ],
        ),

        // Content
        _buildContent(context, ref, state),
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, MarketplaceState state) {
    if (state.status == MarketplaceStatus.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.status == MarketplaceStatus.error) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(height: 8),
            Text(state.errorMessage ?? 'Failed to load shifts'),
            TextButton(
              onPressed: () => ref.read(marketplaceProvider.notifier).load(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.shifts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('No open shifts right now'),
      );
    }

    // Show latest 5 shifts
    final latestShifts = state.shifts.take(5).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: latestShifts.map((shift) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: ShiftCard(
            noMargin: true,
            shift: shift,
            isBooking: state.bookingShiftId == shift.id,
            onBook: () => _handleBook(context, ref, shift.id),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShiftDetailScreen(shiftId: shift.id),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _handleBook(BuildContext context, WidgetRef ref, String shiftId) async {
    final success = await ref.read(marketplaceProvider.notifier).bookShift(shiftId);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Shift booked successfully!' : 'Booking failed'),
        backgroundColor: success ? const Color(0xFF0F6E56) : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}