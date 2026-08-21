import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../data/models/case_model.dart';
import '../providers/cases_provider.dart';

class CaseDetailScreen extends ConsumerWidget {
  final String caseId;
  const CaseDetailScreen({super.key, required this.caseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(caseDetailProvider(caseId));
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: async.when(
        loading: () => Center(
            child: CircularProgressIndicator(color: accentColor)),
        error: (e, _) => Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/svg/file.svg',
              width: 72,
              height: 72,
              color: Colors.grey,
            ),
            SizedBox(height: 24),
            Text(e is DioException ? (e.message ?? 'Something went wrong') : e.toString()),
            TextButton(onPressed:()=>Navigator.pop(context), child: Text("Go Back",style: TextStyle(color: accentColor),))
          ],)),
        data: (raw) {
          final c = raw as CaseModel;
          return _CaseDetailBody(caseModel: c);
        },
      ),
    );
  }
}

class _CaseDetailBody extends StatelessWidget {
  final CaseModel caseModel;
  const _CaseDetailBody({required this.caseModel});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, MMM d, yyyy');
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: ColorConstants.appGradient,
          ),
          padding: EdgeInsets.fromLTRB(
              16, MediaQuery.of(context).padding.top + 12, 16, 20),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(caseModel.publicIdentifier,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 0.4)),
                  const SizedBox(height: 4),
                  Text(caseModel.visitType.replaceAll('_', ' '),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(caseModel.locationDisplay,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _Section(
                title: 'Case details',
                children: [
                  _Row('Facility', caseModel.facilityName ?? '—'),
                  _Row('Visit type',
                      caseModel.visitType.replaceAll('_', ' ')),
                  _Row('OASIS case',
                      caseModel.isOasisCase ? 'Yes' : 'No'),
                  if (caseModel.specialties.isNotEmpty)
                    _Row('Specialties',
                        caseModel.specialties.join(', ')),
                  _Row('Status',
                      caseModel.isActive ? 'Active' : 'Inactive',
                      valueColor: caseModel.isActive
                          ? const Color(0xFF15803D)
                          : const Color(0xFF94A3B4)),
                  _Row('Created',
                      df.format(caseModel.createdAt)),
                ],
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'Location',
                children: [
                  _Row('Address', caseModel.addressLine1),
                  if (caseModel.addressLine2 != null)
                    _Row('', caseModel.addressLine2!),
                  _Row('City / State',
                      '${caseModel.city}, ${caseModel.state}'),
                  _Row('Zip code', caseModel.zipCode),
                ],
              ),
              if (caseModel.primaryDiagnosis != null) ...[
                const SizedBox(height: 12),
                _Section(
                  title: 'Clinical',
                  children: [
                    _Row('Diagnosis',
                        caseModel.primaryDiagnosis!),
                    if (caseModel.notes != null)
                      _Row('Notes', caseModel.notes!),
                  ],
                ),
              ],
              if (caseModel.recentShifts.isNotEmpty) ...[
                const SizedBox(height: 12),
                _Section(
                  title: 'Recent shifts (${caseModel.shiftCount} total)',
                  children: caseModel.recentShifts
                      .map((s) => _ShiftRow(shift: s))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8EDF2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B4),
                letterSpacing: 0.6)),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _Row(this.label, this.value, {this.valueColor});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF94A3B4))),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                  valueColor ?? const Color(0xFF1A2632))),
        ),
      ],
    ),
  );
}

class _ShiftRow extends StatelessWidget {
  final CaseShiftSummary shift;
  const _ShiftRow({required this.shift});
  @override
  Widget build(BuildContext context) {
    final tf = DateFormat('MMM d · h:mm a');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
                color: accentColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shift.visitType.replaceAll('_', ' '),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2632))),
                Text(tf.format(shift.scheduledStart),
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B4))),
                if (shift.assignedNurses.isNotEmpty)
                  Text(shift.assignedNurses.join(', '),
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF536C79))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8FC),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(shift.status,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0A7D95))),
          ),
        ],
      ),
    );
  }
}