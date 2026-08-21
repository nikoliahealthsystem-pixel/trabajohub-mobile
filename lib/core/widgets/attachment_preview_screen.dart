import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:trabajo_hub/core/constants/app_constants.dart';

class AttachmentPreviewScreen extends StatefulWidget {
  final String url;
  final String fileName;

  const AttachmentPreviewScreen({
    super.key,
    required this.url,
    required this.fileName,
  });

  @override
  State<AttachmentPreviewScreen> createState() =>
      _AttachmentPreviewScreenState();
}

class _AttachmentPreviewScreenState extends State<AttachmentPreviewScreen> {
  bool _pdfError = false;

  String get _ext =>
      widget.fileName.split('.').last.toLowerCase();

  bool get _isImage =>
      ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(_ext);

  bool get _isPdf => _ext == 'pdf';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Content ──────────────────────────────────────────
          SafeArea(
            top: false,
            child: _buildPreview(),
          ),

          // ── Top bar ──────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: ColorConstants.appGradient,
              ),
              padding: EdgeInsets.fromLTRB(
                  8, MediaQuery.of(context).padding.top + 8, 8, 16),
              child: Row(
                children: [
                  // Close
                  _iconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  // File name
                  Expanded(
                    child: Text(
                      widget.fileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Open externally
                  _iconButton(
                    icon: Icons.save_alt,
                    onTap: _downloadFile,
                    tooltip: 'Download File',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Preview router ───────────────────────────────────────────

  Widget _buildPreview() {
    if (_isImage) return _buildImagePreview();
    if (_isPdf) return _buildPdfPreview();
    return _buildUnsupportedPreview();
  }

  // ── Image (pinch-zoom) ───────────────────────────────────────

  Widget _buildImagePreview() {
    return PhotoView(
      imageProvider: CachedNetworkImageProvider(widget.url),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3,
      backgroundDecoration: const BoxDecoration(color: Colors.white),
      loadingBuilder: (_, event) => Center(
        child: CircularProgressIndicator(
          value: event?.expectedTotalBytes != null
              ? event!.cumulativeBytesLoaded / event.expectedTotalBytes!
              : null,
          color: accentColor,
        ),
      ),
      errorBuilder: (_, __, ___) => _buildErrorState('Could not load image'),
    );
  }

  // ── PDF ──────────────────────────────────────────────────────

  Widget _buildPdfPreview() {
    if (_pdfError) {
      return _buildErrorState(
        'Could not preview PDF.\nTap the icon above to open externally.',
      );
    }
    return SfPdfViewer.network(
      widget.url,
      onDocumentLoadFailed: (_) => setState(() => _pdfError = true),
    );
  }

  // ── Unsupported type ─────────────────────────────────────────

  Widget _buildUnsupportedPreview() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.insert_drive_file_rounded,
                color: Colors.white54, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            widget.fileName,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _ext.toUpperCase(),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _downloadFile,
            icon: const Icon(Icons.save_alt, size: 18),
            label: const Text('Open externally'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ──────────────────────────────────────────────

  Widget _buildErrorState(String message) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.broken_image_outlined,
            color: Colors.white38, size: 48),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style:
          const TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ],
    ),
  );

  // ── Helpers ──────────────────────────────────────────────────

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Tooltip(
          message: tooltip ?? '',
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.32),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      );

  Future<void> _downloadFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/${widget.fileName}';

      await Dio().download(
        widget.url,
        savePath,
      );

      debugPrint('Downloaded to: $savePath');
    } catch (e) {
      debugPrint('Download failed: $e');
    }
  }
}