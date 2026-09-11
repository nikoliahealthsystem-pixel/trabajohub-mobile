import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/credential_model.dart';
import '../../providers/credentials_provider.dart';

class UploadCredentialSheet extends ConsumerStatefulWidget {
  const UploadCredentialSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (_) => const UploadCredentialSheet(),
    );
  }

  @override
  ConsumerState<UploadCredentialSheet> createState() =>
      _UploadCredentialSheetState();
}

class _UploadCredentialSheetState extends ConsumerState<UploadCredentialSheet> {
  static const _brand = Color(0xFF0A9FBF);
  static const _green = Color(0xFF28D744);
  static const _ink = Color(0xFF17232E);
  static const _muted = Color(0xFF71808D);
  static const _soft = Color(0xFFF6F8FA);
  static const _border = Color(0xFFE2E8ED);
  static const _danger = Color(0xFFDC2626);

  static const int _maxFileBytes = 10 * 1024 * 1024;

  final _customLabelController = TextEditingController();

  CredentialType _selectedType = CredentialType.stateLicense;
  DateTime? _issuedAt;
  DateTime? _expiresAt;
  PlatformFile? _pickedFile;

  String? _fileError;
  String? _customLabelError;
  String? _dateError;

  @override
  void dispose() {
    _customLabelController.dispose();
    super.dispose();
  }

  bool get _isCustom => _selectedType == CredentialType.custom;

  bool get _hasFile =>
      _pickedFile != null &&
      _pickedFile!.path != null &&
      _pickedFile!.path!.trim().isNotEmpty;

  bool get _canSubmit {
    if (!_hasFile) return false;

    if (_isCustom && _customLabelController.text.trim().isEmpty) {
      return false;
    }

    if (_issuedAt != null &&
        _expiresAt != null &&
        _expiresAt!.isBefore(_issuedAt!)) {
      return false;
    }

    return true;
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return 'Unknown size';

    if (bytes < 1024) {
      return '$bytes B';
    }

    final kb = bytes / 1024;

    if (kb < 1024) {
      return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB';
    }

    final mb = kb / 1024;
    return '${mb.toStringAsFixed(mb >= 10 ? 1 : 2)} MB';
  }

  String _extensionOf(String name) {
    final index = name.lastIndexOf('.');

    if (index == -1 || index == name.length - 1) {
      return '';
    }

    return name.substring(index + 1).toLowerCase();
  }

  IconData _fileIcon(String name) {
    final extension = _extensionOf(name);

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Future<void> _pickFile() async {
    FocusScope.of(context).unfocus();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
      withData: false,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    final extension = _extensionOf(file.name);

    if (!const ['pdf', 'jpg', 'jpeg', 'png'].contains(extension)) {
      setState(() {
        _pickedFile = null;
        _fileError = 'Please select a PDF, JPG, JPEG, or PNG document.';
      });
      return;
    }

    if (file.path == null || file.path!.trim().isEmpty) {
      setState(() {
        _pickedFile = null;
        _fileError =
            'This document could not be accessed. Please select it again.';
      });
      return;
    }

    if (file.size <= 0) {
      setState(() {
        _pickedFile = null;
        _fileError =
            'This document appears to be empty. Please select another file.';
      });
      return;
    }

    if (file.size > _maxFileBytes) {
      setState(() {
        _pickedFile = null;
        _fileError =
            'The document is larger than 10 MB. Please choose a smaller file.';
      });
      return;
    }

    setState(() {
      _pickedFile = file;
      _fileError = null;
    });
  }

  void _removeFile() {
    setState(() {
      _pickedFile = null;
      _fileError = null;
    });
  }

  Future<void> _pickIssuedDate() async {
    FocusScope.of(context).unfocus();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _issuedAt ?? today,
      firstDate: DateTime(1950),
      lastDate: today,
      helpText: 'Select issued date',
    );

    if (!mounted || picked == null) return;

    setState(() {
      _issuedAt = picked;

      if (_expiresAt != null && _expiresAt!.isBefore(picked)) {
        _dateError = 'Expiry date cannot be before the issued date.';
      } else {
        _dateError = null;
      }
    });
  }

  Future<void> _pickExpiryDate() async {
    FocusScope.of(context).unfocus();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDate = _issuedAt ?? DateTime(1950);

    DateTime initialDate;

    if (_expiresAt != null && !_expiresAt!.isBefore(firstDate)) {
      initialDate = _expiresAt!;
    } else if (_issuedAt != null) {
      initialDate = _issuedAt!;
    } else {
      initialDate = today;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 50, 12, 31),
      helpText: 'Select expiry date',
    );

    if (!mounted || picked == null) return;

    setState(() {
      _expiresAt = picked;

      if (_issuedAt != null && picked.isBefore(_issuedAt!)) {
        _dateError = 'Expiry date cannot be before the issued date.';
      } else {
        _dateError = null;
      }
    });
  }

  void _clearIssuedDate() {
    setState(() {
      _issuedAt = null;
      _dateError = null;
    });
  }

  void _clearExpiryDate() {
    setState(() {
      _expiresAt = null;
      _dateError = null;
    });
  }

  bool _validate() {
    FocusScope.of(context).unfocus();

    String? fileError;
    String? customLabelError;
    String? dateError;

    if (!_hasFile) {
      fileError = 'Select a credential document before continuing.';
    }

    if (_isCustom && _customLabelController.text.trim().isEmpty) {
      customLabelError = 'Enter a name for this credential.';
    }

    if (_issuedAt != null &&
        _expiresAt != null &&
        _expiresAt!.isBefore(_issuedAt!)) {
      dateError = 'Expiry date cannot be before the issued date.';
    }

    setState(() {
      _fileError = fileError;
      _customLabelError = customLabelError;
      _dateError = dateError;
    });

    return fileError == null && customLabelError == null && dateError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    final file = _pickedFile!;

    final ok = await ref
        .read(credentialsProvider.notifier)
        .upload(
          filePath: file.path!,
          fileName: file.name,
          type: _selectedType,
          customLabel: _isCustom ? _customLabelController.text.trim() : null,
          issuedAt: _issuedAt,
          expiresAt: _expiresAt,
        );

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = ref.watch(
      credentialsProvider.select((state) => state.isUploading),
    );

    final uploadError = ref.watch(
      credentialsProvider.select((state) => state.uploadError),
    );

    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    final dateFormat = DateFormat('MMM d, yyyy');

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.94),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7DEE4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _brand.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.verified_user_outlined,
                            color: _brand,
                            size: 23,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add credential',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.25,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Keep your professional readiness profile current.',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: isUploading
                              ? null
                              : () => Navigator.of(context).pop(false),
                          icon: const Icon(Icons.close_rounded, color: _muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFEDF1F4)),
              Flexible(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeading(
                        icon: Icons.badge_outlined,
                        title: 'Credential details',
                        subtitle:
                            'Tell us what professional document you are adding.',
                      ),
                      const SizedBox(height: 16),

                      const _FieldLabel(
                        text: 'Credential type',
                        requiredField: true,
                      ),
                      const SizedBox(height: 7),

                      DropdownButtonFormField<CredentialType>(
                        initialValue: _selectedType,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _muted,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Select credential type',
                          prefixIcon: Icons.workspace_premium_outlined,
                        ),
                        items: CredentialType.values
                            .map(
                              (type) => DropdownMenuItem<CredentialType>(
                                value: type,
                                child: Text(
                                  type.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isUploading
                            ? null
                            : (value) {
                                if (value == null) return;

                                setState(() {
                                  _selectedType = value;

                                  if (value != CredentialType.custom) {
                                    _customLabelController.clear();
                                    _customLabelError = null;
                                  }
                                });
                              },
                      ),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: !_isCustom
                            ? const SizedBox.shrink()
                            : Padding(
                                key: const ValueKey('custom-label'),
                                padding: const EdgeInsets.only(top: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FieldLabel(
                                      text: 'Credential name',
                                      requiredField: true,
                                    ),
                                    const SizedBox(height: 7),
                                    TextField(
                                      controller: _customLabelController,
                                      enabled: !isUploading,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      maxLength: 80,
                                      onChanged: (_) {
                                        if (_customLabelError != null) {
                                          setState(() {
                                            _customLabelError = null;
                                          });
                                        } else {
                                          setState(() {});
                                        }
                                      },
                                      decoration: _inputDecoration(
                                        hint: 'e.g. BLS Certification',
                                        prefixIcon: Icons.edit_note_rounded,
                                        errorText: _customLabelError,
                                      ).copyWith(counterText: ''),
                                    ),
                                  ],
                                ),
                              ),
                      ),

                      const SizedBox(height: 24),

                      const _SectionHeading(
                        icon: Icons.event_available_outlined,
                        title: 'Validity period',
                        subtitle:
                            'Add dates when they appear on the credential.',
                      ),
                      const SizedBox(height: 16),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final stackDates = constraints.maxWidth < 340;

                          final issued = _DateField(
                            label: 'Issued date',
                            value: _issuedAt == null
                                ? 'Not selected'
                                : dateFormat.format(_issuedAt!),
                            hasValue: _issuedAt != null,
                            enabled: !isUploading,
                            onTap: _pickIssuedDate,
                            onClear: _issuedAt == null
                                ? null
                                : _clearIssuedDate,
                          );

                          final expiry = _DateField(
                            label: 'Expiry date',
                            value: _expiresAt == null
                                ? 'Not selected'
                                : dateFormat.format(_expiresAt!),
                            hasValue: _expiresAt != null,
                            enabled: !isUploading,
                            onTap: _pickExpiryDate,
                            onClear: _expiresAt == null
                                ? null
                                : _clearExpiryDate,
                          );

                          if (stackDates) {
                            return Column(
                              children: [
                                issued,
                                const SizedBox(height: 12),
                                expiry,
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: issued),
                              const SizedBox(width: 12),
                              Expanded(child: expiry),
                            ],
                          );
                        },
                      ),

                      if (_dateError != null) ...[
                        const SizedBox(height: 9),
                        _InlineMessage(
                          icon: Icons.error_outline_rounded,
                          text: _dateError!,
                          color: _danger,
                          background: const Color(0xFFFEF2F2),
                        ),
                      ],

                      const SizedBox(height: 24),

                      const _SectionHeading(
                        icon: Icons.upload_file_outlined,
                        title: 'Credential document',
                        subtitle:
                            'Upload a clear copy so the compliance team can review it.',
                      ),
                      const SizedBox(height: 16),

                      InkWell(
                        onTap: isUploading ? null : _pickFile,
                        borderRadius: BorderRadius.circular(18),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _pickedFile == null
                                ? _soft
                                : _brand.withValues(alpha: 0.055),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _fileError != null
                                  ? _danger.withValues(alpha: 0.65)
                                  : _pickedFile != null
                                  ? _brand.withValues(alpha: 0.55)
                                  : _border,
                              width: _pickedFile != null ? 1.4 : 1,
                            ),
                          ),
                          child: _pickedFile == null
                              ? const _EmptyFilePicker()
                              : Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: _brand.withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        _fileIcon(_pickedFile!.name),
                                        color: _brand,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _pickedFile!.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: _ink,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_extensionOf(_pickedFile!.name).toUpperCase()} • ${_formatBytes(_pickedFile!.size)}',
                                            style: const TextStyle(
                                              color: _muted,
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      tooltip: 'Remove document',
                                      onPressed: isUploading
                                          ? null
                                          : _removeFile,
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 20,
                                        color: _muted,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 15,
                            color: _muted,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'PDF, JPG, JPEG or PNG • Maximum file size 10 MB',
                              style: TextStyle(color: _muted, fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),

                      if (_fileError != null) ...[
                        const SizedBox(height: 9),
                        _InlineMessage(
                          icon: Icons.error_outline_rounded,
                          text: _fileError!,
                          color: _danger,
                          background: const Color(0xFFFEF2F2),
                        ),
                      ],

                      if (uploadError != null &&
                          uploadError.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _InlineMessage(
                          icon: Icons.cloud_off_outlined,
                          text: uploadError,
                          color: _danger,
                          background: const Color(0xFFFEF2F2),
                        ),
                      ],

                      const SizedBox(height: 18),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FBFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _brand.withValues(alpha: 0.13),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: _brand,
                              size: 19,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Your document will be submitted for compliance review. Its status will appear in Professional Readiness after submission.',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 11.8,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: _canSubmit && !isUploading
                                ? const LinearGradient(colors: [_brand, _green])
                                : null,
                            color: !_canSubmit || isUploading
                                ? const Color(0xFFDDE4E9)
                                : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _canSubmit && !isUploading
                                ? [
                                    BoxShadow(
                                      color: _brand.withValues(alpha: 0.18),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : null,
                          ),
                          child: ElevatedButton(
                            onPressed: isUploading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              disabledForegroundColor: const Color(0xFF91A0AA),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: isUploading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.3,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 11),
                                      Text(
                                        'Uploading credential...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.cloud_upload_outlined,
                                        size: 20,
                                      ),
                                      SizedBox(width: 9),
                                      Text(
                                        'Submit credential',
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Center(
                        child: Text(
                          'Only upload documents that belong to you and are accurate.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF98A5AF),
                            fontSize: 10.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? prefixIcon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      hintStyle: const TextStyle(color: Color(0xFF9AA7B1), fontSize: 13),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, size: 20, color: _muted),
      filled: true,
      fillColor: _soft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _brand, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _danger, width: 1.5),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFF0A9FBF).withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF0A9FBF), size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF17232E),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF71808D),
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

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool requiredField;

  const _FieldLabel({required this.text, this.requiredField = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Color(0xFF647582),
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.45,
        ),
        children: [
          TextSpan(text: text.toUpperCase()),
          if (requiredField)
            const TextSpan(
              text: '  *',
              style: TextStyle(color: Color(0xFFDC2626)),
            ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final bool hasValue;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateField({
    required this.label,
    required this.value,
    required this.hasValue,
    required this.enabled,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(text: label),
        const SizedBox(height: 7),
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 50,
            padding: const EdgeInsets.only(left: 12, right: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8ED)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: Color(0xFF71808D),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasValue
                          ? const Color(0xFF17232E)
                          : const Color(0xFF9AA7B1),
                      fontSize: 12.5,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (hasValue && onClear != null)
                  IconButton(
                    tooltip: 'Clear date',
                    onPressed: enabled ? onClear : null,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 17,
                      color: Color(0xFF82919C),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(right: 7),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFF9AA7B1),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyFilePicker extends StatelessWidget {
  const _EmptyFilePicker();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _UploadIcon(),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose credential document',
                style: TextStyle(
                  color: Color(0xFF17232E),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tap to browse files on this device',
                style: TextStyle(color: Color(0xFF71808D), fontSize: 11.5),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: Color(0xFF91A0AA)),
      ],
    );
  }
}

class _UploadIcon extends StatelessWidget {
  const _UploadIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF0A9FBF).withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.upload_file_rounded,
        color: Color(0xFF0A9FBF),
        size: 24,
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color background;

  const _InlineMessage({
    required this.icon,
    required this.text,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11.8,
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
