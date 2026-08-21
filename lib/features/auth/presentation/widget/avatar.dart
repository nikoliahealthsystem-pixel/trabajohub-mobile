import 'package:dio/dio.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/models/user_model.dart';

class Avatar extends ConsumerStatefulWidget {
  final UserModel user;

  const Avatar({super.key, required this.user});

  @override
  ConsumerState<Avatar> createState() => AvatarState();
}

class AvatarState extends ConsumerState<Avatar> {
  bool _isUploading = false;
  String? _uploadedAvatarUrl;

  Future<void> _uploadProfilePicture() async {
    if (_isUploading) return;

    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          pickedFile.path,
          filename: pickedFile.name,
        ),
      });

      final dio = ref.read(dioClientProvider).instance;

      final response = await dio.post(
        '/users/me/avatar',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      final avatarUrl = _extractAvatarUrl(response.data);

      if (avatarUrl == null || avatarUrl.isEmpty) {
        throw Exception('Profile picture uploaded, but avatar URL was not returned');
      }

      if (!mounted) return;

      setState(() {
        _uploadedAvatarUrl = avatarUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture uploaded'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final message = e is DioException
          ? e.error?.toString() ?? 'Failed to upload profile picture'
          : 'Failed to upload profile picture';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  String? _extractAvatarUrl(dynamic data) {
    if (data is! Map<String, dynamic>) return null;

    final responseData = data['data'];
    if (responseData is! Map<String, dynamic>) return null;

    return responseData['avatarUrl']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = _uploadedAvatarUrl ?? widget.user.avatarUrl;

    final initials = widget.user.displayName.isNotEmpty
        ? widget.user.displayName
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .take(2)
        .join()
        .toUpperCase()
        : '?';

    return GestureDetector(
      onTap: _uploadProfilePicture,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white.withOpacity(0.25),
            backgroundImage: avatarUrl.isNotEmpty
                ? FastCachedImageProvider(avatarUrl)
                : null,
            child: avatarUrl.isEmpty
                ? Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            )
                : null,
          ),

          if (_isUploading)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          if (!_isUploading)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: Colors.black87,
                ),
              ),
            ),
        ],
      ),
    );
  }
}