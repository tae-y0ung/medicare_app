import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../screens/user_profile.dart';
import 'api_service.dart';

class LoginSessionService {
  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String _tokenKey =
      'medicare_session_token';

  // ==========================================
  // 로그인 토큰 저장
  // ==========================================
  static Future<void> save(String token) async {
    if (token.trim().isEmpty) {
      throw Exception(
        '서버에서 로그인 토큰을 받지 못했습니다.',
      );
    }

    await _storage.write(
      key: _tokenKey,
      value: token,
    );
  }

  // ==========================================
  // 로그인 토큰 조회
  // 개인정보 수정 및 회원 탈퇴 API에서 사용
  // ==========================================
  static Future<String?> getToken() async {
    return await _storage.read(
      key: _tokenKey,
    );
  }

  // ==========================================
  // 로그인 토큰 삭제
  // ==========================================
  static Future<void> clear() async {
    await _storage.delete(
      key: _tokenKey,
    );
  }

  // ==========================================
  // 자동 로그인 복원
  // ==========================================
  static Future<UserProfile?> restore() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiService.baseUrl}/users/session/me',
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 12),
      );

      if (response.statusCode == 401 ||
          response.statusCode == 403 ||
          response.statusCode == 404) {
        await clear();
        return null;
      }

      if (response.statusCode != 200) {
        throw Exception(
          '자동 로그인 서버 연결 오류',
        );
      }

      final decoded = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (decoded is! Map ||
          decoded['success'] != true ||
          decoded['user'] is! Map) {
        return null;
      }

      final user = Map<String, dynamic>.from(
        decoded['user'],
      );

      return UserProfile.fromJson(user);
    } catch (e) {
      // 서버 연결이 안 되는 경우
      // 토큰은 유지하여 다음 실행에서 재검증
      return null;
    }
  }

  // ==========================================
  // 로그아웃
  // ==========================================
  static Future<void> logout() async {
    final token = await getToken();

    try {
      if (token != null && token.isNotEmpty) {
        await http.post(
          Uri.parse(
            '${ApiService.baseUrl}/users/session/logout',
          ),
          headers: {
            'Authorization': 'Bearer $token',
          },
        ).timeout(
          const Duration(seconds: 8),
        );
      }
    } catch (_) {
      // 네트워크 연결이 없어도
      // 기기에 저장된 로그인 토큰은 삭제
    } finally {
      await clear();
    }
  }
}
