import 'package:flutter/material.dart';

import '../../data/models/conversation_model.dart';

class CompactAvatar extends StatelessWidget {
  final ConversationParticipant user;
  final double radius;
  final bool showStatusDot;
  final bool isOnline;

  const CompactAvatar({
    super.key,
    required this.user,
    this.radius = 20,
    this.showStatusDot = false,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.effectiveAvatarUrl.trim();
    final diameter = radius * 2;

    final avatar = ClipOval(
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: avatarUrl.isNotEmpty
            ? Image.network(
          avatarUrl,
          key: ValueKey(avatarUrl),
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;

            return _InitialsAvatar(
              initials: user.initials,
              radius: radius,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('CompactAvatar failed to load image: $error');
            debugPrint('CompactAvatar URL: $avatarUrl');

            return _InitialsAvatar(
              initials: user.initials,
              radius: radius,
            );
          },
        )
            : _InitialsAvatar(
          initials: user.initials,
          radius: radius,
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        if (showStatusDot)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.55,
              height: radius * 0.55,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  final double radius;

  const _InitialsAvatar({
    required this.initials,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}