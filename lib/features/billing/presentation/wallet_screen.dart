import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trabajo_hub/features/billing/presentation/payment_config.dart';
import '../../../core/constants/app_constants.dart';
import '../data/models/payout_model.dart';
import '../providers/billing_provider.dart';
import '../state/billing_state.dart';
import 'widgets/wallet_card.dart';
import 'widgets/payout_tile.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _scrollController = ScrollController();

  static const _statusFilters = [
    (null, 'All'),
    ('PENDING', 'Pending'),
    ('SETTLED', 'Settled'),
    ('FAILED', 'Failed'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(billingProvider.notifier)
        ..loadWallet()
        ..loadPayouts(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = ref.read(billingProvider);
      if (state.payoutsHasMore &&
          state.payoutsStatus == PayoutsStatus.success) {
        ref.read(billingProvider.notifier).loadPayouts();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: RefreshIndicator(
        color: accentColor,
        onRefresh: () async {
          await ref.read(billingProvider.notifier).loadWallet();
          await ref
              .read(billingProvider.notifier)
              .loadPayouts(refresh: true);
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ── Header ──────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader(context)),

            // ── Wallet card ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _buildWalletSection(state),
              ),
            ),

            // ── Payouts header + filter ───────────────────────
            SliverToBoxAdapter(child: _buildPayoutsHeader(state)),

            // ── Payout list ───────────────────────────────────
            _buildPayoutsList(state),

            // ── Bottom padding ────────────────────────────────
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: ColorConstants.appGradient,
    ),
    padding: EdgeInsets.fromLTRB(
        20, MediaQuery.of(context).padding.top + 14, 20, 20),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Wallet & Payouts',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700)),
              Text('Your earnings and payment history',
                  style:
                  TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
        IconButton(onPressed: ()=> Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => PaymentConfig())), icon: Icon(Icons.settings_suggest,color: Colors.white,))
      ],
    ),
  );

  // ── Wallet section ───────────────────────────────────────────

  Widget _buildWalletSection(BillingState state) {
    if (state.walletStatus == BillingStatus.loading) {
      return Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF0A9FBF)),
        ),
      );
    }

    if (state.walletStatus == BillingStatus.error) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFCEBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF09595)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline,
                color: Color(0xFFB91C1C), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                state.walletError ?? 'Failed to load wallet',
                style: const TextStyle(
                    color: Color(0xFFB91C1C), fontSize: 13),
              ),
            ),
            GestureDetector(
              onTap: () =>
                  ref.read(billingProvider.notifier).loadWallet(),
              child: const Text('Retry',
                  style: TextStyle(
                      color: Color(0xFFB91C1C),
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          ],
        ),
      );
    }

    if (state.wallet == null) return const SizedBox.shrink();
    return WalletCard(wallet: state.wallet!);
  }

  // ── Payouts header + filter bar ──────────────────────────────

  Widget _buildPayoutsHeader(BillingState state) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Payout history',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2632)),
              ),
            ),
            Text(
              '${state.payoutsTotal} total',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF94A3B4)),
            ),
          ],
        ),
      ),

      // Filter chips
      SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: _statusFilters.map((filter) {
            final isActive =
                state.payoutsStatusFilter == filter.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => ref
                    .read(billingProvider.notifier)
                    .setStatusFilter(filter.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFEAF8FC)
                        : Colors.white,
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF0A9FBF)
                          : const Color(0xFFE2E8ED),
                      width: isActive ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    filter.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? const Color(0xFF0A7D95)
                          : const Color(0xFF536C79),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 12),
    ],
  );

  // ── Payouts list ─────────────────────────────────────────────

  Widget _buildPayoutsList(BillingState state) {
    if (state.payoutsStatus == PayoutsStatus.loading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: Color(0xFF0A9FBF)),
          ),
        ),
      );
    }

    if (state.payoutsStatus == PayoutsStatus.error) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.error_outline,
                    size: 40, color: Color(0xFF94A3B4)),
                const SizedBox(height: 10),
                Text(state.payoutsError ?? 'Failed to load payouts',
                    style: const TextStyle(color: Color(0xFF536C79))),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref
                      .read(billingProvider.notifier)
                      .loadPayouts(refresh: true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A9FBF)),
                  child: const Text('Retry',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.payouts.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8FC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    size: 40,
                    color: Color(0xFF0A9FBF),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('No payouts yet',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2632))),
                const SizedBox(height: 4),
                Text(
                  state.payoutsStatusFilter != null
                      ? 'No ${state.payoutsStatusFilter!.toLowerCase()} payouts'
                      : 'Your earnings will appear here once processed',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF94A3B4)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          // Loading more indicator
          if (index >= state.payouts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF0A9FBF))),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PayoutTile(payout: state.payouts[index]),
          );
        },
        childCount:
        state.payouts.length + (state.payoutsHasMore ? 1 : 0),
      ),
    );
  }
}