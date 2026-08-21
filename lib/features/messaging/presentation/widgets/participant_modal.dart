import 'package:flutter/material.dart';
import 'package:trabajo_hub/core/widgets/buttons/button_big.dart';

import '../../data/models/conversation_model.dart';

Future<void> showParticipantDetailsModal(
    BuildContext context,
    ConversationParticipant participant,
    ) {
  Widget infoTile(String label, String? value, IconData icon) {
    if (value == null || value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  final profile = participant.nurseProfile ??
      participant.adminProfile ??
      participant.facilityMember;

  return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) =>  Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: 24),
        child:  Container(
      padding: const EdgeInsets.all(24),
      decoration:  BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 24),

            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey,
              backgroundImage: participant.effectiveAvatarUrl.isNotEmpty
                  ? NetworkImage(participant.effectiveAvatarUrl)
                  : null,
              child: participant.effectiveAvatarUrl.isEmpty
                  ? Text(
                participant.initials,
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),

            const SizedBox(height: 16),

            Text(
              participant.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (participant.subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                participant.subtitle == "SUPER ADMIN"?"ADMIN":participant.subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),

            infoTile(
              "Email",
              participant.email,
              Icons.email_outlined,
            ),

            infoTile(
              "Role",
              participant.role == "SUPER_ADMIN"?"ADMIN":participant.role,
              Icons.badge_outlined,
            ),

            // infoTile(
            //   "Status",
            //   participant.status,
            //   Icons.circle_outlined,
            // ),

            infoTile(
              "Verification",
              participant.verificationStatus,
              Icons.verified_outlined,
            ),

            infoTile(
              "Designation",
              profile?["designation"]?.toString(),
              Icons.medical_services_outlined,
            ),

            infoTile(
              "Job Title",
              profile?["jobTitle"]?.toString(),
              Icons.work_outline,
            ),

            const SizedBox(height: 8),

            Button(buttonText: 'Close',onPressed: ()=> Navigator.pop(context),),
          ],
        ),
      ),
    )),
  );
}