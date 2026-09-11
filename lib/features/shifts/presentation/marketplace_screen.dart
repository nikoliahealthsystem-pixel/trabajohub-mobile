import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../credentials/presentation/credentials_screen.dart';
import '../../../core/widgets/buttons/notification_button.dart';
import '../providers/shifts_provider.dart';
import '../state/marketplace_state.dart';
import 'map_screen.dart';
import 'shift_detail_screen.dart';
import 'widgets/shift_card.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  Timer? _searchDebounce;

  static const _visitTypes = <String>[
    'All',
    'REGULAR',
    'ADMISSION',
    'DISCHARGE',
    'SUPERVISORY',
    'RECERTIFICATION',
  ];

  String _selectedType = 'All';
  bool _urgentOnly = false;

  double? _minPay;
  double? _maxPay;
  DateTime? _selectedDate;

  int get _advancedFilterCount {
    var count = 0;

    if (_minPay != null) count++;
    if (_maxPay != null) count++;
    if (_selectedDate != null) count++;

    return count;
  }

  int get _activeFilterCount {
    var count = _advancedFilterCount;

    if (_selectedType != 'All') count++;
    if (_urgentOnly) count++;

    return count;
  }

  bool get _hasFilters =>
      _activeFilterCount > 0 || _searchController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(marketplaceProvider.notifier).load(refresh: true);
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 220) {
      final state = ref.read(marketplaceProvider);

      if (state.hasMore && state.status == MarketplaceStatus.success) {
        ref.read(marketplaceProvider.notifier).load();
      }
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});

    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 450), _applyFilter);
  }

  String? _apiDate(DateTime? date) {
    if (date == null) return null;

    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');

    return '$y-$m-$d';
  }

  Future<void> _applyFilter() async {
    final filter = MarketplaceFilter(
      visitType: _selectedType == 'All' ? null : _selectedType,
      isUrgent: _urgentOnly ? true : null,
      minPay: _minPay,
      maxPay: _maxPay,
      date: _apiDate(_selectedDate),
      searchQuery: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
    );

    await ref.read(marketplaceProvider.notifier).applyFilter(filter);
  }

  Future<void> _clearFilters() async {
    _searchDebounce?.cancel();
    _searchController.clear();

    setState(() {
      _selectedType = 'All';
      _urgentOnly = false;
      _minPay = null;
      _maxPay = null;
      _selectedDate = null;
    });

    await _applyFilter();
  }

  Future<void> _handleBook(String shiftId) async {
    final success = await ref
        .read(marketplaceProvider.notifier)
        .bookShift(shiftId);

    final errorMessage = ref.read(marketplaceProvider).bookingError;

    final bookingState = ref.read(marketplaceProvider);
    final errorCode = bookingState.bookingErrorCode;
    final structuredMissingCredentialTypes =
        bookingState.bookingMissingCredentialTypes;
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Shift booked successfully.')),
              ],
            ),
            backgroundColor: const Color(0xFF027A48),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      return;
    }

    final message = errorMessage?.trim().isNotEmpty == true
        ? errorMessage!.trim()
        : 'Unable to book this shift. Please try again.';

    final lowerMessage = message.toLowerCase();

    final isCredentialError =
        errorCode == 'SHIFT_CREDENTIAL_REQUIREMENTS_NOT_MET' ||
        lowerMessage.contains('credential requirements') ||
        lowerMessage.contains('credential requirement') ||
        lowerMessage.contains('missing, pending, rejected, or expired');

    if (isCredentialError) {
      const credentialLabels = <String, String>{
        'STATE_LICENSE': 'State License',
        'CPR_CERTIFICATION': 'CPR Certification',
        'TB_TEST': 'TB Test',
        'BACKGROUND_CHECK': 'Background Check',
        'GOVERNMENT_ID': 'Government ID',
        'OIG_CHECK': 'OIG Check',
        'SAM_CHECK': 'SAM Check',
        'IMMUNIZATION': 'Immunization',
        'WORK_AUTHORIZATION': 'Work Authorization',
        'CUSTOM': 'Required Credential',
      };

      const missingMarker = 'Missing, pending, rejected, or expired:';

      final markerIndex = message.toLowerCase().indexOf(
        missingMarker.toLowerCase(),
      );

      List<String> credentialsNeedingAttention =
          structuredMissingCredentialTypes
              .map(
                (item) =>
                    credentialLabels[item.toUpperCase()] ??
                    item
                        .replaceAll('_', ' ')
                        .toLowerCase()
                        .split(' ')
                        .where((word) => word.isNotEmpty)
                        .map(
                          (word) =>
                              '${word[0].toUpperCase()}${word.substring(1)}',
                        )
                        .join(' '),
              )
              .toList();

      if (credentialsNeedingAttention.isEmpty && markerIndex != -1) {
        final rawCredentials = message
            .substring(markerIndex + missingMarker.length)
            .trim();

        credentialsNeedingAttention = rawCredentials
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .map(
              (item) =>
                  credentialLabels[item.toUpperCase()] ??
                  item
                      .replaceAll('_', ' ')
                      .toLowerCase()
                      .split(' ')
                      .where((word) => word.isNotEmpty)
                      .map(
                        (word) =>
                            '${word[0].toUpperCase()}${word.substring(1)}',
                      )
                      .join(' '),
            )
            .toList();
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            icon: const Icon(
              Icons.verified_user_outlined,
              size: 38,
              color: Color(0xFFB54708),
            ),
            title: const Text(
              'Credentials required',
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You cannot book this shift yet because one or more required credentials are missing, pending approval, rejected, or expired.',
                ),
                if (credentialsNeedingAttention.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Needs attention:',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...credentialsNeedingAttention.map(
                    (credential) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('| '),
                          Expanded(child: Text(credential)),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Open Credentials to upload or update the required documents. You can book the shift once all required credentials are approved and current.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Not now'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();

                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CredentialsScreen()),
                  );
                },
                icon: const Icon(Icons.badge_outlined),
                label: const Text('Update credentials'),
              ),
            ],
          );
        },
      );

      return;
    }

    // Non-credential booking failures keep the real backend reason.
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: const Color(0xFFB42318),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  void _openMap(MarketplaceState state) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ShiftMapScreen(shifts: state.shifts)),
    );
  }

  Future<void> _showFilters() async {
    final minController = TextEditingController(
      text: _minPay?.toStringAsFixed(0) ?? '',
    );

    final maxController = TextEditingController(
      text: _maxPay?.toStringAsFixed(0) ?? '',
    );

    var localDate = _selectedDate;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD0D5DD),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'More filters',
                              style: TextStyle(
                                color: Color(0xFF101828),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              minController.clear();
                              maxController.clear();

                              setSheetState(() {
                                localDate = null;
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Narrow open shifts by pay and date.',
                        style: TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 24),

                      const _FilterSectionTitle(
                        title: 'Pay range',
                        icon: Icons.attach_money_rounded,
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minController,
                              keyboardType: TextInputType.number,
                              decoration: _filterInputDecoration(
                                'Minimum',
                                '\$ / hr',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: maxController,
                              keyboardType: TextInputType.number,
                              decoration: _filterInputDecoration(
                                'Maximum',
                                '\$ / hr',
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      const _FilterSectionTitle(
                        title: 'Shift date',
                        icon: Icons.calendar_month_outlined,
                      ),

                      const SizedBox(height: 10),

                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: localDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 1),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );

                          if (picked != null) {
                            setSheetState(() {
                              localDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFD0D5DD)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: Color(0xFF667085),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  localDate == null
                                      ? 'Any date'
                                      : '${_monthName(localDate!.month)} ${localDate!.day}, ${localDate!.year}',
                                  style: TextStyle(
                                    color: localDate == null
                                        ? const Color(0xFF98A2B3)
                                        : const Color(0xFF344054),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (localDate != null)
                                IconButton(
                                  onPressed: () {
                                    setSheetState(() {
                                      localDate = null;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 26),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final min = double.tryParse(
                              minController.text.trim(),
                            );

                            final max = double.tryParse(
                              maxController.text.trim(),
                            );

                            setState(() {
                              _minPay = min;
                              _maxPay = max;
                              _selectedDate = localDate;
                            });

                            Navigator.of(sheetContext).pop();

                            _applyFilter();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Show matching shifts',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    minController.dispose();
    maxController.dispose();
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
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          _buildHeader(context, state),
          _buildMarketplaceControls(state),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MarketplaceState state) {
    return Container(
      decoration: const BoxDecoration(
        gradient: ColorConstants.appGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.of(context).padding.top + 12,
        18,
        24,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _GlassIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shift Marketplace',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Find shifts that fit your schedule',
                      style: TextStyle(color: Colors.white70, fontSize: 11.5),
                    ),
                  ],
                ),
              ),

              NotificationsBell(),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A101828),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search city, shift or visit type',
                hintStyle: const TextStyle(
                  color: Color(0xFF98A2B3),
                  fontSize: 12.5,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF667085),
                  size: 21,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          _applyFilter();
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF667085),
                          size: 19,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _HeaderStat(
                  icon: Icons.work_outline_rounded,
                  label: 'Available',
                  value: state.total.toString(),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _HeaderStat(
                  icon: Icons.bolt_rounded,
                  label: 'Filters',
                  value: _activeFilterCount == 0
                      ? 'All'
                      : '$_activeFilterCount active',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarketplaceControls(MarketplaceState state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  state.status == MarketplaceStatus.loading
                      ? 'Finding available shifts...'
                      : state.total == 1
                      ? '1 open shift'
                      : '${state.total} open shifts',
                  style: const TextStyle(
                    color: Color(0xFF344054),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              if (_hasFilters)
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text(
                    'Clear',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),

              _ActionButton(
                icon: Icons.tune_rounded,
                label: 'Filters',
                badge: _advancedFilterCount,
                onTap: _showFilters,
              ),

              if (state.shifts.isNotEmpty) ...[
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.map_outlined,
                  label: 'Map',
                  onTap: () => _openMap(state),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _QuickFilterChip(
                  label: 'Urgent',
                  icon: Icons.bolt_rounded,
                  isActive: _urgentOnly,
                  onTap: () {
                    setState(() {
                      _urgentOnly = !_urgentOnly;
                    });

                    _applyFilter();
                  },
                ),

                const SizedBox(width: 8),

                ..._visitTypes.map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _QuickFilterChip(
                      label: type == 'All' ? 'All types' : _displayType(type),
                      isActive: _selectedType == type,
                      onTap: () {
                        setState(() {
                          _selectedType = type;
                        });

                        _applyFilter();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(MarketplaceState state) {
    if (state.status == MarketplaceStatus.loading && state.shifts.isEmpty) {
      return const _MarketplaceSkeleton();
    }

    if (state.status == MarketplaceStatus.error && state.shifts.isEmpty) {
      return _MarketplaceError(
        message: _friendlyError(state.errorMessage),
        onRetry: () =>
            ref.read(marketplaceProvider.notifier).load(refresh: true),
      );
    }

    if (state.shifts.isEmpty) {
      return _MarketplaceEmpty(
        filtered: _hasFilters,
        onClearFilters: _hasFilters ? _clearFilters : null,
      );
    }

    return RefreshIndicator(
      color: accentColor,
      onRefresh: () =>
          ref.read(marketplaceProvider.notifier).load(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 36),
        itemCount: state.shifts.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.shifts.length) {
            return const Padding(
              padding: EdgeInsets.all(22),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            );
          }

          final shift = state.shifts[index];

          return ShiftCard(
            shift: shift,
            isBooking: state.bookingShiftId == shift.id,
            onBook: () => _handleBook(shift.id),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ShiftDetailScreen(shiftId: shift.id),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _displayType(String raw) {
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  static String _friendlyError(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'We could not load available shifts.';
    }

    if (raw.length > 120) {
      return 'We could not load available shifts. Check your connection and try again.';
    }

    return raw;
  }

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }
}

InputDecoration _filterInputDecoration(String label, String suffix) {
  return InputDecoration(
    labelText: label,
    suffixText: suffix,
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
    ),
  );
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: .12)),
        ),
        child: Icon(icon, color: Colors.white, size: 17),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeaderStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: .09)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white60, fontSize: 9.5),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFFE4E7EC)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF475467)),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF475467),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (badge > 0) ...[
              const SizedBox(width: 5),
              Container(
                width: 17,
                height: 17,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF0A9FBF),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final VoidCallback onTap;

  const _QuickFilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEAF8FC) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive ? const Color(0xFF0A9FBF) : const Color(0xFFE4E7EC),
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isActive
                    ? const Color(0xFF0A7D95)
                    : const Color(0xFF667085),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF0A7D95)
                    : const Color(0xFF667085),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _FilterSectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF475467)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF344054),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MarketplaceSkeleton extends StatelessWidget {
  const _MarketplaceSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: 5,
      itemBuilder: (_, _) {
        return Container(
          height: 248,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE4E7EC)),
          ),
        );
      },
    );
  }
}

class _MarketplaceEmpty extends StatelessWidget {
  final bool filtered;
  final VoidCallback? onClearFilters;

  const _MarketplaceEmpty({required this.filtered, this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF8FC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.work_outline_rounded,
                color: Color(0xFF0A9FBF),
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              filtered ? 'No matching shifts' : 'No open shifts right now',
              style: const TextStyle(
                color: Color(0xFF101828),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              filtered
                  ? 'Try changing your filters or search to discover more available shifts.'
                  : 'New opportunities will appear here as facilities publish shifts.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
            if (filtered && onClearFilters != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MarketplaceError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _MarketplaceError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                color: Color(0xFFB42318),
                size: 31,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load shifts',
              style: TextStyle(
                color: Color(0xFF101828),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
