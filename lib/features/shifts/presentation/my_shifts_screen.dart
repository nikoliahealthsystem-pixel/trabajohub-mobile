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
    ('UPCOMING', 'Upcoming'),
    ('IN_PROGRESS', 'In Progress'),
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(myShiftsProvider);
      if (state.hasMore && state.status == MyShiftsStatus.success) {
        ref.read(myShiftsProvider.notifier).load();
      }
    }
  }

  Future<void> _confirmCancel(String shiftId) async {
    final notifier = ref.read(myShiftsProvider.notifier);

    late final dynamic preview;

    try {
      preview = await notifier.getCancellationPreview(shiftId);
    } catch (e) {
      if (!mounted) return;

      String message =
          'Unable to load the cancellation policy. Please try again.';

      if (e is Exception) {
        final text = e.toString().trim();
        if (text.isNotEmpty) {
          message = text.replaceFirst('Exception: ', '');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }

    if (!mounted) return;

    String cancellationReason = '';
    String? reasonError;

    final penalty = preview.penaltyAmount as double;
    final windowHours = preview.cancellationWindowHours as int;
    final isLate = preview.isLateCancellation as bool;

    final confirmedReason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final hasPenalty = penalty > 0;

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              backgroundColor: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF1F0),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.event_busy_rounded,
                                    color: Color(0xFFD94A48),
                                    size: 23,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cancel this shift?',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF172B36),
                                          height: 1.15,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        'Review the cancellation policy before you continue.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF667985),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => Navigator.of(ctx).pop(),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 21,
                                      color: Color(0xFF71828C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: hasPenalty
                                    ? const Color(0xFFFFF8EB)
                                    : const Color(0xFFEEF8F4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: hasPenalty
                                      ? const Color(0xFFF1D39A)
                                      : const Color(0xFFBFE2D2),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: hasPenalty
                                          ? const Color(0xFFFFE9BE)
                                          : const Color(0xFFD8EFE5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      hasPenalty
                                          ? Icons.warning_amber_rounded
                                          : Icons.check_circle_outline_rounded,
                                      size: 21,
                                      color: hasPenalty
                                          ? const Color(0xFF9B6100)
                                          : const Color(0xFF267255),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          hasPenalty
                                              ? '\$${penalty.toStringAsFixed(2)} cancellation fee'
                                              : 'No cancellation fee',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: hasPenalty
                                                ? const Color(0xFF805000)
                                                : const Color(0xFF215E49),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          hasPenalty
                                              ? 'This fee will be deducted from pending earnings first, then future earnings if necessary.'
                                              : 'You can cancel this shift without a cancellation charge.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            height: 1.45,
                                            color: hasPenalty
                                                ? const Color(0xFF805F25)
                                                : const Color(0xFF416E5D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F8FA),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    size: 19,
                                    color: Color(0xFF536C79),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      isLate
                                          ? 'This cancellation is inside the current $windowHours-hour late-cancellation window.'
                                          : 'The current late-cancellation window begins $windowHours hours before the shift starts.',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF536C79),
                                        height: 1.4,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 22),

                            const Text(
                              'Reason for cancellation',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF243A46),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Your reason will help the facility understand the change.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF71828C),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 11),

                            TextField(
                              autofocus: false,
                              maxLines: 4,
                              minLines: 3,
                              maxLength: 1000,
                              textCapitalization: TextCapitalization.sentences,
                              onChanged: (value) {
                                cancellationReason = value;

                                if (reasonError != null &&
                                    value.trim().isNotEmpty) {
                                  setDialogState(() {
                                    reasonError = null;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                hintText:
                                    'Briefly explain why you need to cancel...',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF9AA8B0),
                                  fontSize: 13,
                                ),
                                errorText: reasonError,
                                errorMaxLines: 2,
                                filled: true,
                                fillColor: const Color(0xFFFAFCFD),
                                contentPadding: const EdgeInsets.all(14),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: reasonError != null
                                        ? const Color(0xFFD94A48)
                                        : const Color(0xFFD8E0E4),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF536C79),
                                    width: 1.5,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD94A48),
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFD94A48),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: FilledButton(
                                onPressed: () {
                                  final value = cancellationReason.trim();

                                  if (value.isEmpty) {
                                    setDialogState(() {
                                      reasonError =
                                          'Please enter a cancellation reason.';
                                    });
                                    return;
                                  }

                                  Navigator.of(ctx).pop(value);
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFD94A48),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  hasPenalty
                                      ? 'Cancel shift & accept \$${penalty.toStringAsFixed(2)} fee'
                                      : 'Confirm cancellation',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF314B58),
                                  side: const BorderSide(
                                    color: Color(0xFFD6E0E5),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Keep my shift',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 4),

                            const Center(
                              child: Text(
                                'Your shift remains booked unless you confirm cancellation.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF8A99A2),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmedReason == null || confirmedReason.trim().isEmpty || !mounted) {
      return;
    }

    final success = await notifier.cancelShift(
      shiftId,
      reason: confirmedReason.trim(),
      expectedPenaltyAmount: preview.penaltyAmount,
      expectedPolicyVersion: preview.policyVersion,
    );

    if (!mounted) return;

    final cancellationState = ref.read(myShiftsProvider);

    final message = success
        ? (penalty > 0
              ? 'Shift cancelled. A \$${penalty.toStringAsFixed(2)} cancellation fee was assessed.'
              : 'Shift cancelled. No cancellation fee was assessed.')
        : (cancellationState.errorMessage?.trim().isNotEmpty == true
              ? cancellationState.errorMessage!.trim()
              : 'Failed to cancel shift');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? const Color(0xFF536C79) : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: success ? 4 : 7),
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
          _buildHeader(context, state),
          _buildTabs(state.selectedTab),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MyShiftsState state) {
    return Container(
      decoration: const BoxDecoration(gradient: ColorConstants.appGradient),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Shifts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              NotificationsBell(),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${state.total} ${state.selectedTab.toLowerCase()} shifts',
            style: TextStyle(color: Colors.white, fontSize: 13),
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
              onTap: () =>
                  ref.read(myShiftsProvider.notifier).switchTab(tab.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFEAF8FC)
                      : Colors.transparent,
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
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    if (state.assignments.isEmpty && state.status == MyShiftsStatus.success) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_outlined,
              size: 52,
              color: Color(0xFF94A3B4),
            ),
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
            return Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: accentColor),
              ),
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
                  MaterialPageRoute(
                    builder: (_) =>
                        ShiftDetailScreen(shiftId: assignment.shiftId),
                  ),
                );
              }
            },
            onCancel:
                state.selectedTab == 'UPCOMING' &&
                    assignment.status == 'ACCEPTED'
                ? () => _confirmCancel(assignment.shiftId)
                : null,
          );
        },
      ),
    );
  }
}
