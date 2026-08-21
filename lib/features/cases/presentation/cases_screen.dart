import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../data/models/case_model.dart';
import '../providers/cases_provider.dart';
import '../state/cases_state.dart';
import 'case_detail_screen.dart';

class CasesScreen extends ConsumerStatefulWidget {
  const CasesScreen({super.key});
  @override
  ConsumerState<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends ConsumerState<CasesScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  static const _visitTypes = [
    'All', 'REGULAR', 'ADMISSION', 'DISCHARGE',
    'SUPERVISORY', 'RECERTIFICATION', 'RESUMPTION_OF_CARE'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(casesProvider.notifier).load(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final s = ref.read(casesProvider);
      if (s.hasMore && s.status == CasesStatus.success) {
        ref.read(casesProvider.notifier).load();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(casesProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: Column(
        children: [
          _buildHeader(context, state),
          _buildFilters(state),
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CasesState state) =>
      Container(
        decoration: const BoxDecoration(
          gradient: ColorConstants.appGradient,
        ),
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 14, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cases',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w700)),
                      Text('${state.total} cases found',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Search
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search by ID or patient name…',
                        hintStyle: TextStyle(
                            color: Colors.white60, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (v) =>
                          ref.read(casesProvider.notifier).search(v),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (_, v, __) => v.text.isNotEmpty
                        ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        ref
                            .read(casesProvider.notifier)
                            .search('');
                      },
                      child: const Icon(Icons.close,
                          color: Colors.white70, size: 18),
                    )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildFilters(CasesState state) => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _visitTypes.map((type) {
          final isActive = type == 'All'
              ? state.visitTypeFilter == null
              : state.visitTypeFilter == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => ref
                  .read(casesProvider.notifier)
                  .setVisitTypeFilter(type == 'All' ? null : type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFEAF8FC)
                      : const Color(0xFFF0F4F7),
                  border: Border.all(
                      color: isActive
                          ? accentColor
                          : const Color(0xFFE2E8ED)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  type == 'All'
                      ? 'All types'
                      : type.replaceAll('_', ' '),
                  style: TextStyle(
                    fontSize: 11,
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
  );

  Widget _buildBody(CasesState state) {
    if (state.status == CasesStatus.loading) {
      return Center(
          child: CircularProgressIndicator(color: accentColor));
    }
    if (state.status == CasesStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: Color(0xFFE24B4A)),
            const SizedBox(height: 12),
            Text(state.errorMessage!.length  < 20 ? "${state.errorMessage}" : "Error Fetching Cases"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(casesProvider.notifier).load(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (state.cases.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined,
                size: 52, color: Color(0xFF94A3B4)),
            SizedBox(height: 12),
            Text('No cases found',
                style: TextStyle(color: Color(0xFF536C79))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: accentColor,
      onRefresh: () =>
          ref.read(casesProvider.notifier).load(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: state.cases.length + (state.hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= state.cases.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                  child: CircularProgressIndicator(
                      color: accentColor)),
            );
          }
          return _CaseTile(
            caseModel: state.cases[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      CaseDetailScreen(caseId: state.cases[i].id)),
            ),
          );
        },
      ),
    );
  }
}

class _CaseTile extends StatelessWidget {
  final CaseModel caseModel;
  final VoidCallback onTap;
  const _CaseTile({required this.caseModel, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: caseModel.isActive
                  ? const Color(0xFFEAF8FC)
                  : const Color(0xFFF0F4F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.folder_outlined,
                color: caseModel.isActive
                    ? accentColor
                    : const Color(0xFF94A3B4),
                size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(caseModel.publicIdentifier,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B4),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: caseModel.isActive
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF0F4F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        caseModel.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: caseModel.isActive
                                ? const Color(0xFF15803D)
                                : const Color(0xFF94A3B4)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  caseModel.visitType.replaceAll('_', ' '),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2632)),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: Color(0xFF94A3B4)),
                    const SizedBox(width: 3),
                    Text(caseModel.locationDisplay,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B4))),
                    const Spacer(),
                    const Icon(Icons.work_outline,
                        size: 12, color: Color(0xFF94A3B4)),
                    const SizedBox(width: 3),
                    Text('${caseModel.shiftCount} shifts',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B4))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFF94A3B4)),
        ],
      ),
    ),
  );
}