import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/attachment_preview_screen.dart';
import '../data/models/credential_model.dart';
import '../providers/credentials_provider.dart';
import '../state/credentials_notifier.dart';
import '../state/credentials_state.dart';
import 'widgets/upload_credential_sheet.dart';

class CredentialsScreen extends ConsumerStatefulWidget {
  const CredentialsScreen({super.key});

  @override
  ConsumerState<CredentialsScreen> createState() =>
      _CredentialsScreenState();
}

class _CredentialsScreenState extends ConsumerState<CredentialsScreen> {
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
      backgroundColor: const Color(0xFFF4F7FA),
      body: Column(
        children: [
          _buildHeader(context, state),
          _buildSummaryRow(state),
          Expanded(child: _buildBody(state, notifier)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ok = await UploadCredentialSheet.show(context);
          if (ok == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Credential uploaded — pending review'),
              backgroundColor: Color(0xFF0F6E56),
              behavior: SnackBarBehavior.floating,
            ));
          }
        },
        backgroundColor: accentColor,
        icon: const Icon(Icons.upload_rounded, color: Colors.white),
        label: const Text('Upload',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CredentialsState state) =>
      Container(
        decoration: const BoxDecoration(
          gradient: ColorConstants.appGradient,
        ),
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 14, 20, 18),
        child: Row(
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Credentials',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700)),
                  Text('Manage your professional documents',
                      style:
                      TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            if (state.status == CredentialsStatus.loading)
              const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white)),
          ],
        ),
      );

  Widget _buildSummaryRow(CredentialsState state) {
    if (state.credentials.isEmpty) return const SizedBox.shrink();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _StatChip(
              label: 'Total',
              value: '${state.credentials.length}',
              color: accentColor),
          _StatChip(
              label: 'Approved',
              value: '${state.approvedCount}',
              color: const Color(0xFF10B981)),
          _StatChip(
              label: 'Pending',
              value: '${state.pendingCount}',
              color: const Color(0xFFF59E0B)),
          if (state.expiringCount > 0)
            _StatChip(
                label: 'Expiring',
                value: '${state.expiringCount}',
                color: const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildBody(
      CredentialsState state, CredentialsNotifier notifier) {
    if (state.status == CredentialsStatus.loading) {
      return Center(
          child: CircularProgressIndicator(color: accentColor));
    }
    if (state.status == CredentialsStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: Color(0xFFE24B4A)),
            const SizedBox(height: 12),
            Text(state.errorMessage ?? 'Failed to load credentials',
                style: const TextStyle(color: Color(0xFF536C79))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: notifier.load,
              style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (state.credentials.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8FC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.badge_outlined,
                  size: 44, color: accentColor),
            ),
            const SizedBox(height: 14),
            const Text('No credentials uploaded yet',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2632),
                    fontSize: 15)),
            const SizedBox(height: 4),
            const Text('Tap Upload to add your first document',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF94A3B4))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: accentColor,
      onRefresh: notifier.load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: state.credentials.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () =>_openPreview(context,"${state.credentials[i].downloadUrl}",state.credentials[i].displayLabel,state.credentials[i].fileUrl),
          child: _CredentialCard(
          credential: state.credentials[i],
          isDeleting:
          state.deletingId == state.credentials[i].id,
          onDelete: () => _confirmDelete(
              context, state.credentials[i], notifier),
        ),),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context,
      CredentialModel credential,
      CredentialsNotifier notifier,
      ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete credential?'),
        content: Text(
            'Remove ${credential.displayLabel}? This cannot be undone.'),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) notifier.delete(credential.id);
  }

  void _openPreview(BuildContext context, String url, String fileName, String filelink) {
    final extension = filelink.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
    final isPdf = extension == 'pdf';
    final isOfficeDoc = [
      'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
    ].contains(extension);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PreviewHeader(fileName: fileName, url: url),
                  const Divider(height: 1),
                  Flexible(
                    child: isImage
                        ? _ImagePreview(url: url)
                        : isPdf
                        ? _PdfPreview(url: url)
                        : isOfficeDoc
                        ? _OfficeDocPreview(url: url)
                        : _UnsupportedFilePreview(
                      fileName: fileName,
                      extension: extension,
                      url: url,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

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
          Expanded(
            child: Text(
              fileName,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new, size: 20),
            tooltip: 'Open externally',
            onPressed: () => launchUrlString(url, mode: LaunchMode.externalApplication),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
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
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: Center(
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) => const _PreviewError(
            message: 'Could not load image',
          ),
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
      return const _PreviewError(message: 'Could not load PDF');
    }
    return SfPdfViewer.network(
      widget.url,
      onDocumentLoadFailed: (details) {
        setState(() => _hasError = true);
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
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (_) => setState(() {
            _isLoading = false;
            _hasError = true;
          }),
        ),
      )
      ..loadRequest(Uri.parse(viewerUrl));
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const _PreviewError(
        message: 'Could not load document preview',
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file_outlined, size: 56, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(
              url,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Preview not available for this file type',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => launchUrlString(url, mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open file'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewError extends StatelessWidget {
  const _PreviewError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
// ── Credential card ────────────────────────────────────────────

class _CredentialCard extends StatelessWidget {
  final CredentialModel credential;
  final bool isDeleting;
  final VoidCallback onDelete;

  const _CredentialCard({
    required this.credential,
    required this.isDeleting,
    required this.onDelete,
  });

  static const _statusColors = {
    CredentialStatus.approved: (Color(0xFFDCFCE7), Color(0xFF15803D)),
    CredentialStatus.pending: (Color(0xFFFEF3C7), Color(0xFFB45309)),
    CredentialStatus.rejected: (Color(0xFFFCEBEB), Color(0xFFB91C1C)),
    CredentialStatus.expired: (Color(0xFFF1EFE8), Color(0xFF5F5E5A)),
  };

  @override
  Widget build(BuildContext context) {
    final colors =
        _statusColors[credential.status] ?? _statusColors[CredentialStatus.pending]!;
    final df = DateFormat('MMM d, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        children: [
          // Top accent
          Container(
            height: 3,
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: colors.$2,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: colors.$1,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.badge_outlined,
                          color: colors.$2, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(credential.displayLabel,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A2632))),
                          const SizedBox(height: 2),
                          Text(credential.type.label,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B4))),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.$1,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(credential.status.label,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colors.$2)),
                    ),
                  ],
                ),

                if (credential.expiresAt != null ||
                    credential.issuedAt != null) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFEEF1F4)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (credential.issuedAt != null)
                        _MetaItem(
                          icon: Icons.calendar_today_outlined,
                          label: 'Issued',
                          value: df.format(credential.issuedAt!),
                        ),
                      if (credential.issuedAt != null &&
                          credential.expiresAt != null)
                        const SizedBox(width: 16),
                      if (credential.expiresAt != null)
                        _MetaItem(
                          icon: Icons.event_outlined,
                          label: 'Expires',
                          value: df.format(credential.expiresAt!),
                          valueColor: credential.isExpired
                              ? Colors.redAccent
                              : credential.isExpiringSoon
                              ? const Color(0xFFB45309)
                              : null,
                        ),
                    ],
                  ),
                ],

                if (credential.rejectionReason != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCEBEB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 14, color: Colors.redAccent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(credential.rejectionReason!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFB91C1C))),
                        ),
                      ],
                    ),
                  ),
                ],

                if (credential.canDelete) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: isDeleting ? null : onDelete,
                      child: isDeleting
                          ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.redAccent))
                          : const Text('Delete',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _MetaItem(
      {required this.icon,
        required this.label,
        required this.value,
        this.valueColor});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 13, color: const Color(0xFF94A3B4)),
      const SizedBox(width: 4),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: Color(0xFF94A3B4))),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF1A2632))),
        ],
      ),
    ],
  );
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF94A3B4))),
      ],
    ),
  );
}