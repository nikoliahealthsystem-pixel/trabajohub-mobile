import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/credential_model.dart';
import '../../providers/credentials_provider.dart';

class UploadCredentialSheet extends ConsumerStatefulWidget {
  const UploadCredentialSheet({super.key});

  static Future<bool?> show(BuildContext context) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const UploadCredentialSheet(),
  );

  @override
  ConsumerState<UploadCredentialSheet> createState() =>
      _UploadCredentialSheetState();
}

class _UploadCredentialSheetState
    extends ConsumerState<UploadCredentialSheet> {
  CredentialType _selectedType = CredentialType.stateLicense;
  final _customLabelController = TextEditingController();
  DateTime? _issuedAt;
  DateTime? _expiresAt;
  PlatformFile? _pickedFile;

  @override
  void dispose() {
    _customLabelController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _pickDate(bool isIssued) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        if (isIssued) {
          _issuedAt = picked;
        } else {
          _expiresAt = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_pickedFile == null || _pickedFile!.path == null) return;

    final ok = await ref.read(credentialsProvider.notifier).upload(
      filePath: _pickedFile!.path!,
      fileName: _pickedFile!.name,
      type: _selectedType,
      customLabel: _selectedType == CredentialType.custom
          ? _customLabelController.text.trim()
          : null,
      issuedAt: _issuedAt,
      expiresAt: _expiresAt,
    );

    if (!mounted) return;
    Navigator.pop(context, ok);
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = ref.watch(
        credentialsProvider.select((s) => s.isUploading));
    final uploadError = ref.watch(
        credentialsProvider.select((s) => s.uploadError));
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final df = DateFormat('MMM d, yyyy');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Upload Credential',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2632))),
            const SizedBox(height: 18),

            // Type dropdown
            _Label('Credential type'),
            const SizedBox(height: 6),
            DropdownButtonFormField<CredentialType>(
              value: _selectedType,
              decoration: _inputDecoration('Select type'),
              items: CredentialType.values
                  .map((t) => DropdownMenuItem(
                  value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedType = v!),
            ),

            // Custom label
            if (_selectedType == CredentialType.custom) ...[
              const SizedBox(height: 14),
              _Label('Custom label'),
              const SizedBox(height: 6),
              TextField(
                controller: _customLabelController,
                decoration: _inputDecoration('e.g. BLS Certification'),
              ),
            ],

            const SizedBox(height: 14),

            // Date pickers
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Issued date'),
                      const SizedBox(height: 6),
                      _DateTile(
                        label: _issuedAt != null
                            ? df.format(_issuedAt!)
                            : 'Select',
                        onTap: () => _pickDate(true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Expiry date'),
                      const SizedBox(height: 6),
                      _DateTile(
                        label: _expiresAt != null
                            ? df.format(_expiresAt!)
                            : 'Select',
                        onTap: () => _pickDate(false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // File picker
            _Label('Document file'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _pickedFile != null
                        ? const Color(0xFF0A9FBF)
                        : const Color(0xFFE2E8ED),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _pickedFile != null
                          ? Icons.insert_drive_file_outlined
                          : Icons.upload_file_outlined,
                      color: const Color(0xFF0A9FBF),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _pickedFile?.name ?? 'Tap to select PDF or image',
                        style: TextStyle(
                          fontSize: 13,
                          color: _pickedFile != null
                              ? const Color(0xFF1A2632)
                              : const Color(0xFF94A3B4),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_pickedFile != null)
                      GestureDetector(
                        onTap: () => setState(() => _pickedFile = null),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: Color(0xFF94A3B4)),
                      ),
                  ],
                ),
              ),
            ),

            if (uploadError != null) ...[
              const SizedBox(height: 10),
              Text(uploadError,
                  style: const TextStyle(
                      color: Colors.redAccent, fontSize: 12)),
            ],

            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  gradient: (_pickedFile != null && !isUploading)
                      ? const LinearGradient(
                      colors: [Color(0xFF0A9FBF), Color(0xFF28D744)])
                      : null,
                  color: (_pickedFile == null || isUploading)
                      ? const Color(0xFFE2E8ED)
                      : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton(
                  onPressed:
                  (_pickedFile == null || isUploading) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isUploading
                      ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                      : const Text('Upload credential',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle:
    const TextStyle(color: Color(0xFF94A3B4), fontSize: 13),
    filled: true,
    fillColor: const Color(0xFFF7F8FA),
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8ED)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8ED)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:
      const BorderSide(color: Color(0xFF0A9FBF), width: 1.5),
    ),
  );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF94A3B4),
          letterSpacing: 0.5));
}

class _DateTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateTile({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8ED)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 14, color: Color(0xFF94A3B4)),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF1A2632))),
        ],
      ),
    ),
  );
}