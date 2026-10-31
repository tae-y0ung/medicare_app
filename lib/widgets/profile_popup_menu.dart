import 'package:flutter/material.dart';

import '../screens/user_profile.dart';
import '../screens/setting_page.dart';
import '../screens/guardian_account_page.dart';
import '../screens/guardian_medication_log_page.dart';
import '../screens/login_page.dart';
import '../services/login_session_service.dart';

class ProfilePopupMenu extends StatelessWidget {
  final UserProfile profile;
  final Future<void> Function()? onReturn;

  const ProfilePopupMenu({super.key, required this.profile, this.onReturn});

  Future<void> _openPage(BuildContext context, Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (context.mounted && onReturn != null) {
      await onReturn!();
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await LoginSessionService.logout();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('로그아웃 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '사용자 메뉴',
      icon: const Icon(
        Icons.account_circle_outlined,
        color: Colors.black,
        size: 28,
      ),
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) async {
        switch (value) {
          case 'profile':
            await _openPage(context, SettingScreen(profile: profile));
            break;
          case 'guardian':
            await _openPage(context, GuardianAccountPage(profile: profile));
            break;
          case 'ward_logs':
            await _openPage(
              context,
              GuardianMedicationLogPage(profile: profile),
            );
            break;
          case 'logout':
            await _logout(context);
            break;
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.manage_accounts_outlined),
              SizedBox(width: 12),
              Text('개인정보 수정'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'guardian',
          child: Row(
            children: [
              Icon(Icons.people_outline),
              SizedBox(width: 12),
              Text('피보호자 등록/관리'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'ward_logs',
          child: Row(
            children: [
              Icon(Icons.assignment_outlined),
              SizedBox(width: 12),
              Text('복약 기록 관리 (피보호자)'),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.redAccent),
              SizedBox(width: 12),
              Text('로그아웃', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    );
  }
}
