import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../data/models/credential_history_model.dart';
import '../data/models/credential_model.dart';
import '../providers/credentials_provider.dart';
import '../state/credentials_notifier.dart';
import '../state/credentials_state.dart';
import 'widgets/upload_credential_sheet.dart';

class CredentialsScreen extends ConsumerStatefulWidget {
  const CredentialsScreen({super.key});

  @override
  ConsumerState<CredentialsScreen> createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends ConsumerState<CredentialsScreen> {
  static const _pageBackground = Color(0xFFF5F7FA);
  static const _textPrimary = Color(0xFF17212B);
  static const _textSecondary = Color(0xFF667785);
  static const _textMuted = Color(0xFF94A3B4);
  static const _border = Color(0xFFE6EBF0);

  static const _success = Color(0xFF16805B);
  static const _successSoft = Color(0xFFE7F7F0);

  static const _warning = Color(0xFFB76A09);
  static const _warningSoft = Color(0xFFFFF4DA);

  static const _danger = Color(0xFFC43D3D);
  static const _dangerSoft = Color(0xFFFFECEC);

  static const _info = Color(0xFF2768A8);
  static const _infoSoft = Color(0xFFEAF3FD);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(credentialsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(credentialsProvider);
    final notifier = ref.read(credentialsProvider.notifier);

    return Scaffold(
      backgroundColor: _pageBackground,
      body: Column(
        children: [
          _buildHeader(context, state),
          Expanded(child: _buildBody(state, notifier)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context, CredentialsState state) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: ColorConstants.appGradient),
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.of(context).padding.top + 12,
        18,
        18,
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.maybePop(context),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Professional Readiness',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Credentials, reviews and expiration status',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (state.status == CredentialsStatus.loading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            )
          else
            Material(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  ref.read(credentialsProvider.notifier).load();
                },
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main body
  // ---------------------------------------------------------------------------

  Widget _buildBody(CredentialsState state, CredentialsNotifier notifier) {
    if (state.status == CredentialsStatus.loading &&
        state.credentials.isEmpty) {
      return _buildLoadingState();
    }

    if (state.status == CredentialsStatus.error && state.credentials.isEmpty) {
      return _buildErrorState(state.errorMessage, notifier);
    }

    final credentials = state.credentials;

    final attention =
        credentials.where((credential) => credential.needsAttention).toList()
          ..sort(_attentionSort);

    final pending =
        credentials
            .where(
              (credential) =>
                  credential.isAwaitingReview && !credential.isExpired,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final current =
        credentials
            .where(
              (credential) =>
                  credential.isApprovedAndCurrent && !credential.isExpiringSoon,
            )
            .toList()
          ..sort(_expirySort);

    final other =
        credentials
            .where(
              (credential) =>
                  !attention.contains(credential) &&
                  !pending.contains(credential) &&
                  !current.contains(credential),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return RefreshIndicator(
      color: accentColor,
      onRefresh: notifier.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
        children: [
          _buildReadinessCard(credentials, attention, pending),
          const SizedBox(height: 14),

          _buildStatsGrid(credentials, attention, pending),
          const SizedBox(height: 14),

          _buildEligibilityNotice(),
          const SizedBox(height: 18),

          _buildUploadCard(notifier),
          const SizedBox(height: 24),

          if (credentials.isEmpty)
            _buildEmptyState(notifier)
          else ...[
            if (attention.isNotEmpty) ...[
              _SectionHeader(
                icon: Icons.error_outline_rounded,
                title: 'Needs attention',
                subtitle:
                    '${attention.length} ${attention.length == 1 ? 'credential requires' : 'credentials require'} action',
                color: _danger,
              ),
              const SizedBox(height: 10),
              ...attention.map(
                (credential) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CredentialCard(
                    credential: credential,
                    isDeleting: state.deletingId == credential.id,
                    onOpen: () => _openPreview(credential),
                    onDelete: () => _confirmDelete(credential, notifier),
                    onReplace: credential.canReplace
                        ? () => _replaceCredential(credential, notifier)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (pending.isNotEmpty) ...[
              _SectionHeader(
                icon: Icons.hourglass_top_rounded,
                title: 'Pending review',
                subtitle: 'Documents submitted and waiting for verification',
                color: _warning,
              ),
              const SizedBox(height: 10),
              ...pending.map(
                (credential) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CredentialCard(
                    credential: credential,
                    isDeleting: state.deletingId == credential.id,
                    onOpen: () => _openPreview(credential),
                    onDelete: () => _confirmDelete(credential, notifier),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (current.isNotEmpty) ...[
              _SectionHeader(
                icon: Icons.verified_user_outlined,
                title: 'Current credentials',
                subtitle: 'Approved documents that are currently valid',
                color: _success,
              ),
              const SizedBox(height: 10),
              ...current.map(
                (credential) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CredentialCard(
                    credential: credential,
                    isDeleting: state.deletingId == credential.id,
                    onOpen: () => _openPreview(credential),
                    onDelete: () => _confirmDelete(credential, notifier),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (other.isNotEmpty) ...[
              _SectionHeader(
                icon: Icons.folder_copy_outlined,
                title: 'Other documents',
                subtitle: 'Additional credential records',
                color: _info,
              ),
              const SizedBox(height: 10),
              ...other.map(
                (credential) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CredentialCard(
                    credential: credential,
                    isDeleting: state.deletingId == credential.id,
                    onOpen: () => _openPreview(credential),
                    onDelete: () => _confirmDelete(credential, notifier),
                  ),
                ),
              ),
            ],
          ],

          if (state.status == CredentialsStatus.error &&
              state.credentials.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InlineError(
              message:
                  state.errorMessage ??
                  'Some credential data could not be refreshed.',
              onRetry: notifier.load,
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Professional readiness card
  // ---------------------------------------------------------------------------

  Widget _buildReadinessCard(
    List<CredentialModel> credentials,
    List<CredentialModel> attention,
    List<CredentialModel> pending,
  ) {
    final currentCount = credentials
        .where((credential) => credential.isApprovedAndCurrent)
        .length;

    final rejectedCount = credentials
        .where((credential) => credential.status == CredentialStatus.rejected)
        .length;

    final expiredCount = credentials
        .where((credential) => credential.isExpired)
        .length;

    final expiringCount = credentials
        .where((credential) => credential.isExpiringSoon)
        .length;

    final hasBlockingAttention = rejectedCount > 0 || expiredCount > 0;

    late final String title;
    late final String description;
    late final Color statusColor;
    late final Color statusBackground;
    late final IconData statusIcon;

    if (credentials.isEmpty) {
      title = 'Build your credential profile';
      description =
          'Upload your professional documents so TrabajoHub can review them for future shift eligibility.';
      statusColor = _info;
      statusBackground = _infoSoft;
      statusIcon = Icons.badge_outlined;
    } else if (hasBlockingAttention) {
      title = 'Action required';
      description =
          'One or more credentials are rejected or expired. Resolve them before booking shifts that require those documents.';
      statusColor = _danger;
      statusBackground = _dangerSoft;
      statusIcon = Icons.report_gmailerrorred_rounded;
    } else if (pending.isNotEmpty) {
      title = 'Review in progress';
      description =
          'Your submitted documents are being reviewed. Eligibility can vary by facility and shift requirements.';
      statusColor = _warning;
      statusBackground = _warningSoft;
      statusIcon = Icons.hourglass_top_rounded;
    } else if (expiringCount > 0) {
      title = 'Ready, with upcoming expirations';
      description =
          'Your current credentials look healthy, but renew expiring documents early to avoid interruptions.';
      statusColor = _warning;
      statusBackground = _warningSoft;
      statusIcon = Icons.event_repeat_rounded;
    } else {
      title = 'Credential profile looks healthy';
      description =
          'Your uploaded credentials are current. Final eligibility is still evaluated against each facility and shift.';
      statusColor = _success;
      statusBackground = _successSoft;
      statusIcon = Icons.verified_rounded;
    }

    final healthPercent = credentials.isEmpty
        ? 0
        : ((currentCount / credentials.length) * 100).round().clamp(0, 100);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 25),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CREDENTIAL READINESS',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.05,
                          color: _textMuted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 17,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$healthPercent%',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              description,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 13,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 17),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: healthPercent / 100,
                minHeight: 7,
                backgroundColor: const Color(0xFFEDF1F4),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(height: 13),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniStatusPill(
                  icon: Icons.verified_outlined,
                  text: '$currentCount current',
                  color: _success,
                  background: _successSoft,
                ),
                if (pending.isNotEmpty)
                  _MiniStatusPill(
                    icon: Icons.hourglass_empty_rounded,
                    text: '${pending.length} pending',
                    color: _warning,
                    background: _warningSoft,
                  ),
                if (attention.isNotEmpty)
                  _MiniStatusPill(
                    icon: Icons.warning_amber_rounded,
                    text: '${attention.length} attention',
                    color: _danger,
                    background: _dangerSoft,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    List<CredentialModel> credentials,
    List<CredentialModel> attention,
    List<CredentialModel> pending,
  ) {
    final approved = credentials
        .where((credential) => credential.isApprovedAndCurrent)
        .length;

    final expiring = credentials
        .where((credential) => credential.isExpiringSoon)
        .length;

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Current',
            value: '$approved',
            icon: Icons.verified_outlined,
            color: _success,
            background: _successSoft,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _MetricCard(
            label: 'Review',
            value: '${pending.length}',
            icon: Icons.schedule_rounded,
            color: _warning,
            background: _warningSoft,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _MetricCard(
            label: 'Attention',
            value: '${attention.length}',
            icon: Icons.warning_amber_rounded,
            color: _danger,
            background: _dangerSoft,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _MetricCard(
            label: 'Expiring',
            value: '$expiring',
            icon: Icons.event_repeat_outlined,
            color: _info,
            background: _infoSoft,
          ),
        ),
      ],
    );
  }

  Widget _buildEligibilityNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E9F3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 20, color: Color(0xFF34779B)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How shift eligibility works',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Requirements can differ by facility and shift. TrabajoHub checks your approved, non-expired credentials when you attempt to book.',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Upload
  // ---------------------------------------------------------------------------

  Widget _buildUploadCard(CredentialsNotifier notifier) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openUploadSheet(notifier),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.cloud_upload_outlined,
                  color: accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload a credential',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Add licenses, certifications and compliance documents',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUploadSheet(CredentialsNotifier notifier) async {
    final ok = await UploadCredentialSheet.show(context);

    if (!mounted) return;

    if (ok == true) {
      await notifier.load();

      if (!mounted) return;

      _showSuccess('Credential uploaded and submitted for review.');
    }
  }

  Future<void> _replaceCredential(
    CredentialModel credential,
    CredentialsNotifier notifier,
  ) async {
    final ok = await UploadCredentialSheet.show(context);

    if (!mounted) return;

    if (ok == true) {
      await notifier.load();

      if (!mounted) return;

      _showSuccess('Replacement document uploaded for review.');
    }
  }

  // ---------------------------------------------------------------------------
  // Empty / loading / error
  // ---------------------------------------------------------------------------

  Widget _buildLoadingState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: const [
        SizedBox(height: 16),
        _LoadingCard(height: 180),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _LoadingCard(height: 82)),
            SizedBox(width: 10),
            Expanded(child: _LoadingCard(height: 82)),
          ],
        ),
        SizedBox(height: 10),
        _LoadingCard(height: 108),
        SizedBox(height: 24),
        _LoadingCard(height: 145),
        SizedBox(height: 10),
        _LoadingCard(height: 145),
      ],
    );
  }

  Widget _buildErrorState(String? message, CredentialsNotifier notifier) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 65),
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: _dangerSoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.cloud_off_outlined,
              size: 36,
              color: _danger,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          "Couldn't load your credentials",

          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          message ??
              'We could not retrieve your professional documents. Check your connection and try again.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton.icon(
            onPressed: notifier.load,
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 19),
            label: const Text(
              'Try again',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(CredentialsNotifier notifier) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(21),
            ),
            child: Icon(Icons.badge_outlined, size: 34, color: accentColor),
          ),
          const SizedBox(height: 16),
          const Text(
            'Start your credential profile',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Upload professional licenses, certifications and compliance documents. Submitted documents will be reviewed before they can satisfy shift requirements.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => _openUploadSheet(notifier),
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: const Icon(Icons.upload_file_rounded, size: 19),
            label: const Text(
              'Upload first credential',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Delete
  // ---------------------------------------------------------------------------

  Future<void> _confirmDelete(
    CredentialModel credential,
    CredentialsNotifier notifier,
  ) async {
    if (!credential.canDelete) {
      _showInfo('Approved current credentials cannot be deleted.');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          title: const Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: _danger),
              SizedBox(width: 9),
              Text(
                'Delete credential?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: Text(
            'Remove ${credential.displayLabel}? This action cannot be undone.',
            style: const TextStyle(color: _textSecondary, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Keep it',
                style: TextStyle(
                  color: _textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: _danger,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (ok != true || !mounted) return;

    notifier.delete(credential.id);
  }

  // ---------------------------------------------------------------------------
  // Preview
  // ---------------------------------------------------------------------------

  void _openPreview(CredentialModel credential) {
    final url = credential.previewUrl;

    if (url == null || url.trim().isEmpty) {
      _showInfo('This document is not currently available for preview.');
      return;
    }

    final extension = credential.fileExtension;
    final isImage = credential.isImage;
    final isPdf = credential.isPdf;
    final isOfficeDoc = credential.isOfficeDocument;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 28,
          ),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 680,
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.82,
            ),
            child: Column(
              children: [
                _PreviewHeader(fileName: credential.displayLabel, url: url),
                const Divider(height: 1, color: _border),
                Expanded(
                  child: isImage
                      ? _ImagePreview(url: url)
                      : isPdf
                      ? _PdfPreview(url: url)
                      : isOfficeDoc
                      ? _OfficeDocPreview(url: url)
                      : _UnsupportedFilePreview(
                          fileName: credential.displayLabel,
                          extension: extension,
                          url: url,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  int _attentionSort(CredentialModel a, CredentialModel b) {
    int priority(CredentialModel credential) {
      if (credential.status == CredentialStatus.rejected) {
        return 0;
      }

      if (credential.isExpired) {
        return 1;
      }

      if (credential.isExpiringSoon) {
        return 2;
      }

      return 3;
    }

    final priorityCompare = priority(a).compareTo(priority(b));

    if (priorityCompare != 0) {
      return priorityCompare;
    }

    return _expirySort(a, b);
  }

  int _expirySort(CredentialModel a, CredentialModel b) {
    if (a.expiresAt == null && b.expiresAt == null) {
      return b.createdAt.compareTo(a.createdAt);
    }

    if (a.expiresAt == null) return 1;
    if (b.expiresAt == null) return -1;

    return a.expiresAt!.compareTo(b.expiresAt!);
  }

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      );
  }

  void _showInfo(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF334E5C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      );
  }
}

// =============================================================================
// Credential card
// =============================================================================

class _CredentialCard extends StatelessWidget {
  const _CredentialCard({
    required this.credential,
    required this.isDeleting,
    required this.onOpen,
    required this.onDelete,
    this.onReplace,
  });

  final CredentialModel credential;
  final bool isDeleting;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback? onReplace;

  static const _textPrimary = Color(0xFF17212B);
  static const _textMuted = Color(0xFF94A3B4);
  static const _border = Color(0xFFE6EBF0);

  static const _success = Color(0xFF16805B);
  static const _successSoft = Color(0xFFE7F7F0);

  static const _warning = Color(0xFFB76A09);
  static const _warningSoft = Color(0xFFFFF4DA);

  static const _danger = Color(0xFFC43D3D);
  static const _dangerSoft = Color(0xFFFFECEC);

  static const _info = Color(0xFF2768A8);
  static const _infoSoft = Color(0xFFEAF3FD);

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(credential);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: visual.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 3, color: visual.color),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: visual.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _iconForType(credential.type),
                        color: visual.color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            credential.displayLabel,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 14.5,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          if (credential.type == CredentialType.custom &&
                              credential.customLabel != null)
                            const Text(
                              'Custom credential',
                              style: TextStyle(
                                color: _textMuted,
                                fontSize: 11.5,
                              ),
                            )
                          else
                            Text(
                              credential.type.label,
                              style: const TextStyle(
                                color: _textMuted,
                                fontSize: 11.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(
                      text: credential.readinessMessage,
                      color: visual.color,
                      background: visual.background,
                    ),
                  ],
                ),

                if (credential.rejectionReason != null) ...[
                  const SizedBox(height: 13),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _dangerSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF5CACA)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.report_gmailerrorred_outlined,
                          color: _danger,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Review feedback',
                                style: TextStyle(
                                  color: _danger,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                credential.rejectionReason!,
                                style: const TextStyle(
                                  color: Color(0xFF8E3232),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (credential.issuedAt != null ||
                    credential.expiresAt != null) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: _border),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      if (credential.issuedAt != null)
                        Expanded(
                          child: _DateMeta(
                            icon: Icons.calendar_today_outlined,
                            label: 'Issued',
                            value: dateFormat.format(credential.issuedAt!),
                          ),
                        ),
                      if (credential.issuedAt != null &&
                          credential.expiresAt != null)
                        const SizedBox(width: 12),
                      if (credential.expiresAt != null)
                        Expanded(
                          child: _DateMeta(
                            icon: Icons.event_outlined,
                            label: 'Expires',
                            value: dateFormat.format(credential.expiresAt!),
                            valueColor: credential.isExpired
                                ? _danger
                                : credential.isExpiringSoon
                                ? _warning
                                : null,
                          ),
                        ),
                    ],
                  ),
                ],

                if (credential.isExpiringSoon) ...[
                  const SizedBox(height: 12),
                  _ExpiryWarning(credential: credential),
                ],

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: credential.hasPreviewUrl ? onOpen : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF324D5B),
                          side: const BorderSide(color: _border),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text(
                          'View',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),

                    if (onReplace != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onReplace,
                          style: FilledButton.styleFrom(
                            backgroundColor: visual.color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.upload_file_outlined,
                            size: 18,
                          ),
                          label: const Text(
                            'Replace',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],

                    if (credential.canDelete && onReplace == null) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 45,
                        height: 45,
                        child: OutlinedButton(
                          onPressed: isDeleting ? null : onDelete,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: _danger,
                            side: const BorderSide(color: Color(0xFFF0D3D3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isDeleting
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _danger,
                                  ),
                                )
                              : const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 19,
                                ),
                        ),
                      ),
                    ],
                  ],
                ),

                if (onReplace != null && credential.canDelete) ...[
                  const SizedBox(height: 7),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: isDeleting ? null : onDelete,
                      style: TextButton.styleFrom(
                        foregroundColor: _danger,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 4,
                        ),
                      ),
                      icon: isDeleting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _danger,
                              ),
                            )
                          : const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text(
                        'Delete old record',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                _CredentialHistoryPanel(credentialId: credential.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static _CredentialVisual _visualFor(CredentialModel credential) {
    if (credential.status == CredentialStatus.rejected) {
      return const _CredentialVisual(
        color: _danger,
        background: _dangerSoft,
        borderColor: Color(0xFFF3D5D5),
      );
    }

    if (credential.isExpired) {
      return const _CredentialVisual(
        color: _danger,
        background: _dangerSoft,
        borderColor: Color(0xFFF3D5D5),
      );
    }

    if (credential.isExpiringSoon) {
      return const _CredentialVisual(
        color: _warning,
        background: _warningSoft,
        borderColor: Color(0xFFF3E0B8),
      );
    }

    if (credential.status == CredentialStatus.pending) {
      return const _CredentialVisual(
        color: _warning,
        background: _warningSoft,
        borderColor: Color(0xFFF3E0B8),
      );
    }

    if (credential.status == CredentialStatus.approved) {
      return const _CredentialVisual(
        color: _success,
        background: _successSoft,
        borderColor: Color(0xFFCDE9DD),
      );
    }

    return const _CredentialVisual(
      color: _info,
      background: _infoSoft,
      borderColor: _border,
    );
  }

  static IconData _iconForType(CredentialType type) {
    switch (type) {
      case CredentialType.stateLicense:
        return Icons.workspace_premium_outlined;
      case CredentialType.cprCertification:
        return Icons.favorite_border_rounded;
      case CredentialType.tbTest:
        return Icons.science_outlined;
      case CredentialType.backgroundCheck:
        return Icons.fact_check_outlined;
      case CredentialType.governmentId:
        return Icons.credit_card_outlined;
      case CredentialType.oigCheck:
        return Icons.manage_search_rounded;
      case CredentialType.samCheck:
        return Icons.policy_outlined;
      case CredentialType.immunization:
        return Icons.vaccines_outlined;
      case CredentialType.workAuthorization:
        return Icons.work_outline_rounded;
      case CredentialType.custom:
        return Icons.description_outlined;
    }
  }
}

class _CredentialHistoryPanel extends ConsumerStatefulWidget {
  const _CredentialHistoryPanel({required this.credentialId});

  final String credentialId;

  @override
  ConsumerState<_CredentialHistoryPanel> createState() =>
      _CredentialHistoryPanelState();
}

class _CredentialHistoryPanelState
    extends ConsumerState<_CredentialHistoryPanel> {
  static const _textPrimary = Color(0xFF17212B);
  static const _textSecondary = Color(0xFF667785);
  static const _border = Color(0xFFE6EBF0);
  static const _info = Color(0xFF2768A8);
  static const _infoSoft = Color(0xFFEAF3FD);

  bool _expanded = false;

  Future<void> _toggle() async {
    final next = !_expanded;

    setState(() {
      _expanded = next;
    });

    if (!next) return;

    final state = ref.read(credentialsProvider);

    if (state.historyFor(widget.credentialId) == null &&
        !state.isHistoryLoading(widget.credentialId)) {
      await ref
          .read(credentialsProvider.notifier)
          .loadHistory(widget.credentialId);
    }
  }

  Future<void> _retry() async {
    await ref
        .read(credentialsProvider.notifier)
        .loadHistory(widget.credentialId, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(credentialsProvider);
    final history = state.historyFor(widget.credentialId);
    final isLoading = state.isHistoryLoading(widget.credentialId);
    final error = state.historyErrorFor(widget.credentialId);
    final eventCount = history?.events.length ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _infoSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: _info,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Credential history',
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Review document activity and status changes',
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 10.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (eventCount > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _infoSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$eventCount',
                          style: const TextStyle(
                            color: _info,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF71818D),
                        size: 21,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _border)),
              ),
              padding: const EdgeInsets.fromLTRB(13, 13, 13, 14),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isLoading
                    ? const _CredentialHistoryLoading()
                    : error != null
                    ? _CredentialHistoryError(message: error, onRetry: _retry)
                    : history == null || history.events.isEmpty
                    ? const _CredentialHistoryEmpty()
                    : _CredentialTimeline(events: history.events),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialTimeline extends StatelessWidget {
  const _CredentialTimeline({required this.events});

  final List<CredentialHistoryEvent> events;

  @override
  Widget build(BuildContext context) {
    final sorted = [...events]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.timeline_rounded, color: Color(0xFF2768A8), size: 17),
            SizedBox(width: 7),
            Text(
              'DOCUMENT ACTIVITY',
              style: TextStyle(
                color: Color(0xFF667785),
                fontSize: 10,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...List.generate(
          sorted.length,
          (index) => _CredentialTimelineItem(
            event: sorted[index],
            isLast: index == sorted.length - 1,
          ),
        ),
      ],
    );
  }
}

class _CredentialTimelineItem extends StatelessWidget {
  const _CredentialTimelineItem({required this.event, required this.isLast});

  final CredentialHistoryEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final visual = _historyVisualFor(event);
    final dateText = DateFormat(
      'MMM d, yyyy | h:mm a',
    ).format(event.createdAt.toLocal());

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: visual.background,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: visual.color.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Icon(visual.icon, size: 14, color: visual.color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8ED),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.action.label,
                          style: const TextStyle(
                            color: Color(0xFF17212B),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (event.status != null)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: visual.background,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            event.status!.replaceAll('_', ' '),
                            style: TextStyle(
                              color: visual.color,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    event.description,
                    style: TextStyle(
                      color: event.requiresAttention
                          ? const Color(0xFFC43D3D)
                          : const Color(0xFF667785),
                      fontSize: 11,
                      height: 1.4,
                      fontWeight: event.requiresAttention
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 7,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _TimelineMeta(
                        icon: Icons.person_outline_rounded,
                        text: event.performedBy.label,
                      ),
                      _TimelineMeta(
                        icon: Icons.schedule_rounded,
                        text: dateText,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static _HistoryVisual _historyVisualFor(CredentialHistoryEvent event) {
    switch (event.action) {
      case CredentialHistoryAction.approve:
        return const _HistoryVisual(
          color: Color(0xFF16805B),
          background: Color(0xFFE7F7F0),
          icon: Icons.check_rounded,
        );
      case CredentialHistoryAction.reject:
        return const _HistoryVisual(
          color: Color(0xFFC43D3D),
          background: Color(0xFFFFECEC),
          icon: Icons.close_rounded,
        );
      case CredentialHistoryAction.upload:
        return const _HistoryVisual(
          color: Color(0xFF2768A8),
          background: Color(0xFFEAF3FD),
          icon: Icons.upload_file_rounded,
        );
      case CredentialHistoryAction.delete:
        return const _HistoryVisual(
          color: Color(0xFFC43D3D),
          background: Color(0xFFFFECEC),
          icon: Icons.delete_outline_rounded,
        );
      case CredentialHistoryAction.update:
        return const _HistoryVisual(
          color: Color(0xFFB76A09),
          background: Color(0xFFFFF4DA),
          icon: Icons.edit_outlined,
        );
      case CredentialHistoryAction.download:
        return const _HistoryVisual(
          color: Color(0xFF2768A8),
          background: Color(0xFFEAF3FD),
          icon: Icons.download_rounded,
        );
      case CredentialHistoryAction.unknown:
        return const _HistoryVisual(
          color: Color(0xFF2768A8),
          background: Color(0xFFEAF3FD),
          icon: Icons.history_rounded,
        );
    }
  }
}

class _TimelineMeta extends StatelessWidget {
  const _TimelineMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF94A3B4)),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF94A3B4),
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CredentialHistoryLoading extends StatelessWidget {
  const _CredentialHistoryLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text(
            'Loading credential history...',
            style: TextStyle(
              color: Color(0xFF667785),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialHistoryError extends StatelessWidget {
  const _CredentialHistoryError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFC43D3D),
            size: 17,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF873535),
                fontSize: 10.8,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialHistoryEmpty extends StatelessWidget {
  const _CredentialHistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            color: Color(0xFF94A3B4),
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'No credential activity has been recorded yet.',
              style: TextStyle(
                color: Color(0xFF667785),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryVisual {
  const _HistoryVisual({
    required this.color,
    required this.background,
    required this.icon,
  });

  final Color color;
  final Color background;
  final IconData icon;
}

class _CredentialVisual {
  const _CredentialVisual({
    required this.color,
    required this.background,
    required this.borderColor,
  });

  final Color color;
  final Color background;
  final Color borderColor;
}

// =============================================================================
// Supporting widgets
// =============================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF17212B),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF778896),
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE6EBF0)),
      ),
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8997A2),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatusPill extends StatelessWidget {
  const _MiniStatusPill({
    required this.icon,
    required this.text,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.text,
    required this.color,
    required this.background,
  });

  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          height: 1.15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DateMeta extends StatelessWidget {
  const _DateMeta({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F5F7),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 14, color: const Color(0xFF71818D)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF94A3B4),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: valueColor ?? const Color(0xFF273641),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpiryWarning extends StatelessWidget {
  const _ExpiryWarning({required this.credential});

  final CredentialModel credential;

  @override
  Widget build(BuildContext context) {
    final days = credential.daysUntilExpiration;

    final String message;

    if (days == null) {
      message = 'This credential expires soon.';
    } else if (days <= 0) {
      message = 'This credential expires today.';
    } else if (days == 1) {
      message = 'This credential expires tomorrow.';
    } else {
      message = 'Renew within $days days to avoid an eligibility interruption.';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_repeat_rounded,
            size: 17,
            color: Color(0xFFB76A09),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF8B580B),
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFC43D3D), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF873535), fontSize: 11.5),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE9EDF1)),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

// =============================================================================
// Document preview
// =============================================================================

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({required this.fileName, required this.url});

  final String fileName;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.description_outlined,
              size: 18,
              color: Color(0xFF4F6673),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fileName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF17212B),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Open externally',
            onPressed: () {
              launchUrlString(url, mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 19),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 21),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F5F7),
      alignment: Alignment.center,
      child: InteractiveViewer(
        minScale: 0.8,
        maxScale: 5,
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              return child;
            }

            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return const _PreviewError(message: 'Could not load this image.');
          },
        ),
      ),
    );
  }
}

class _PdfPreview extends StatefulWidget {
  const _PdfPreview({required this.url});

  final String url;

  @override
  State<_PdfPreview> createState() => _PdfPreviewState();
}

class _PdfPreviewState extends State<_PdfPreview> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const _PreviewError(message: 'Could not load this PDF.');
    }

    return SfPdfViewer.network(
      widget.url,
      onDocumentLoadFailed: (_) {
        if (!mounted) return;

        setState(() {
          _hasError = true;
        });
      },
    );
  }
}

class _OfficeDocPreview extends StatefulWidget {
  const _OfficeDocPreview({required this.url});

  final String url;

  @override
  State<_OfficeDocPreview> createState() => _OfficeDocPreviewState();
}

class _OfficeDocPreviewState extends State<_OfficeDocPreview> {
  late final WebViewController _controller;

  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    final viewerUrl =
        'https://view.officeapps.live.com/op/embed.aspx?src=${Uri.encodeComponent(widget.url)}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);

            if (uri == null ||
                uri.scheme != 'https' ||
                uri.host != 'view.officeapps.live.com') {
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onPageFinished: (_) {
            if (!mounted) return;

            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (_) {
            if (!mounted) return;

            setState(() {
              _isLoading = false;
              _hasError = true;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(viewerUrl));
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _PreviewError(
        message: 'Could not preview this document.',
        actionUrl: widget.url,
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _UnsupportedFilePreview extends StatelessWidget {
  const _UnsupportedFilePreview({
    required this.fileName,
    required this.extension,
    required this.url,
  });

  final String fileName;
  final String extension;
  final String url;

  @override
  Widget build(BuildContext context) {
    final extensionLabel = extension.isEmpty
        ? 'document'
        : extension.toUpperCase();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F6),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.insert_drive_file_outlined,
                size: 34,
                color: Color(0xFF71818D),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              fileName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF17212B),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$extensionLabel preview is not available inside the app.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF778896),
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                launchUrlString(url, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Open document'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewError extends StatelessWidget {
  const _PreviewError({required this.message, this.actionUrl});

  final String message;
  final String? actionUrl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEC),
                borderRadius: BorderRadius.circular(21),
              ),
              child: const Icon(
                Icons.broken_image_outlined,
                size: 32,
                color: Color(0xFFC43D3D),
              ),
            ),
            const SizedBox(height: 13),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF667785), fontSize: 12.5),
            ),
            if (actionUrl != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  launchUrlString(
                    actionUrl!,
                    mode: LaunchMode.externalApplication,
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Open externally'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
