
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

  const ProfilePopupMenu({
    super.key,
    required this.profile,
    this.onReturn,
  });

  static const Color _menuText = Color(0xFF222222);
  static const Color _divider = Color(0xFFE5E5E5);

  Future<void> _openPage(
    BuildContext context,
    Widget page,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );

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
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, true),
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
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 실패: $e')),
      );
    }
  }

  PopupMenuItem<String> _menuItem({
  required String value,
  required IconData icon,
  required String label,
  Color color = _menuText,
}) {
  return PopupMenuItem<String>(
    value: value,
    height: 54, // 기존 64 → 54
    padding: const EdgeInsets.symmetric(
      horizontal: 16, // 기존 20 → 16
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
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

      // 메뉴 전체 디자인
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(
          color: Color(0xFFE5E5E5),
          width: 1,
        ),
      ),

      onSelected: (value) async {
        switch (value) {
          case 'profile':
            await _openPage(
              context,
              SettingScreen(profile: profile),
            );
            break;

          case 'guardian':
            await _openPage(
              context,
              GuardianAccountPage(profile: profile),
            );
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

      itemBuilder: (_) => [
        _menuItem(
          value: 'profile',
          icon: Icons.manage_accounts_outlined,
          label: '개인정보 수정',
        ),
        const PopupMenuDivider(height: 1, color: _divider),

        _menuItem(
          value: 'guardian',
          icon: Icons.people_outline,
          label: '피보호자 등록/관리',
        ),
        const PopupMenuDivider(height: 1, color: _divider),

        _menuItem(
          value: 'ward_logs',
          icon: Icons.assignment_outlined,
          label: '복약 기록 관리 (피보호자)',
        ),
        const PopupMenuDivider(height: 1, color: _divider),

        _menuItem(
          value: 'logout',
          icon: Icons.logout,
          label: '로그아웃',
          color: Colors.redAccent,
        ),
      ],
    );
  }
}
