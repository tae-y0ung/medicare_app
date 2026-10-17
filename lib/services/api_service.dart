import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static Future<bool> healthCheck() async {
    final url = Uri.parse('$baseUrl/health');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['status'] == 'ok';
    }
    return false;
  }

  static Future<List<String>> searchIngredients(
  String query,
) async {
  final keyword = query.trim();

  if (keyword.length < 2) return [];

  final uri = Uri.parse(
    '$baseUrl/ingredients/search',
  ).replace(
    queryParameters: {'q': keyword},
  );

  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final result = jsonDecode(
      utf8.decode(response.bodyBytes),
    );

    return List<String>.from(
      result['ingredients'] ?? [],
    );
  }

  throw Exception('성분 검색 실패: ${response.statusCode}');
}

  static Future<Map<String, dynamic>> sendEmailVerification(
    String email,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/email-verification/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
      }),
    );

    final data = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)),
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return data;
    }

    throw Exception(
      data['detail'] ?? '인증번호 발송에 실패했습니다.',
    );
  }

  static Future<Map<String, dynamic>> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/email-verification/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
      }),
    );

    final data = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)),
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return data;
    }

    throw Exception(
      data['detail'] ?? '인증번호 확인에 실패했습니다.',
    );
  }


  static Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String gender,
    required String pregnancy,
    required String birthYear,
    required String birthMonth,
    required String birthDay,
    required String guardianPhone,
    required String verificationToken,
    required List<String> allergyList,
  }) async {
    final url = Uri.parse('$baseUrl/users/create');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
        'gender': gender,
        'pregnancy': pregnancy,
        'birthYear': birthYear,
        'birthMonth': birthMonth,
        'birthDay': birthDay,
        'guardianPhone': guardianPhone,
        'allergyList': allergyList,
        'verificationToken': verificationToken,
      }),
    );

    final result = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return result;
    }

    throw Exception(
      result['detail'] ??
          result['message'] ??
          '회원가입 요청 실패 (${response.statusCode})',
    );
  }

  // ==========================================
  // 비밀번호 재설정 인증번호 발송
  // ==========================================
  static Future<Map<String, dynamic>> requestPasswordResetCode({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/password-reset/request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
      }),
    );

    final result = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)),
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        result['success'] == true) {
      return result;
    }

    throw Exception(
      result['detail']?.toString() ??
          result['message']?.toString() ??
          '인증번호 발송에 실패했습니다.',
    );
  }

  // ==========================================
  // 비밀번호 재설정 인증번호 확인
  // ==========================================
  static Future<Map<String, dynamic>> verifyPasswordResetCode({
    required String email,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/password-reset/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
      }),
    );

    final result = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)),
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        result['success'] == true) {
      return result;
    }

    throw Exception(
      result['detail']?.toString() ??
          result['message']?.toString() ??
          '인증번호 확인에 실패했습니다.',
    );
  }

  // ==========================================
  // 새 비밀번호 저장
  // ==========================================
  static Future<Map<String, dynamic>> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/password-reset/confirm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'resetToken': resetToken,
        'newPassword': newPassword,
      }),
    );

    final result = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)),
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        result['success'] == true) {
      return result;
    }

    throw Exception(
      result['detail']?.toString() ??
          result['message']?.toString() ??
          '비밀번호 변경에 실패했습니다.',
    );
  }

  // ============================================
  // 실제 알림 목록 조회
  // ============================================
  static Future<List<Map<String, dynamic>>> getNotifications(
    String userId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/user/$userId'),
    );

    final result = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        result['success'] != true) {
      throw Exception(
        result['detail'] ?? '알림 조회 실패',
      );
    }

    return (result['notifications'] as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // ============================================
  // 알림 개별 읽음
  // ============================================
  static Future<void> markNotificationRead({
    required String userId,
    required String notificationId,
  }) async {
    final response = await http.patch(
      Uri.parse(
        '$baseUrl/notifications/$notificationId/read',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );

    final result = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        result['success'] != true) {
      throw Exception(
        result['detail'] ?? '알림 읽음 처리 실패',
      );
    }
  }

  // ============================================
  // 전체 읽음
  // ============================================
  static Future<void> markAllNotificationsRead(
    String userId,
  ) async {
    final response = await http.patch(
      Uri.parse(
        '$baseUrl/notifications/user/$userId/read-all',
      ),
    );

    final result = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)),
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        result['success'] != true) {
      throw Exception(
        result['detail'] ?? '전체 읽음 처리 실패',
      );
    }
  }


  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/users/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final result = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return result;
    }

    throw Exception(
      result['detail'] ??
          result['message'] ??
          '로그인 실패 (${response.statusCode})',
    );
  }

  static Future<Map<String, dynamic>> getUser(String userId) async {
    final url = Uri.parse('$baseUrl/users/$userId');

    final response = await http.get(
      url,
      headers: {'accept': 'application/json'},
    );

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    final result = Map<String, dynamic>.from(decoded);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        result['success'] != false) {
      return result;
    }

    throw Exception(
      result['detail'] ??
          result['message'] ??
          '사용자 정보 조회 실패 '
              '(${response.statusCode})',
    );
  }

static Future<List<String>>
getAllergies(
  String userId,
) async {
  final result =
      await getUser(
    userId,
  );

  Map<String, dynamic>
      user = {};

  if (result['user'] is Map) {
    user =
        Map<String, dynamic>.from(
      result['user'],
    );
  } else {
    user =
        Map<String, dynamic>.from(
      result,
    );
  }

  final raw =
      user['allergyList'];

  if (raw is! List) {
    return <String>[];
  }

  return raw
      .map(
        (e) =>
            e.toString().trim(),
      )
      .where(
        (e) => e.isNotEmpty,
      )
      .toList();
}


static Future<Map<String, dynamic>>
updateAllergies({
  required String userId,
  required List<String>
      allergyList,
}) async {
  final url = Uri.parse(
    '$baseUrl/users/'
    '$userId/'
    'allergies',
  );

  final response =
      await http.patch(
    url,
    headers: {
      'Content-Type':
          'application/json',
    },
    body: jsonEncode({
      'allergyList':
          allergyList,
    }),
  );

  final decoded =
      jsonDecode(
    utf8.decode(
      response.bodyBytes,
    ),
  );

  final result =
      Map<String, dynamic>.from(
    decoded,
  );

  if (response.statusCode >= 200 &&
      response.statusCode < 300 &&
      result['success'] != false) {
    return result;
  }

  throw Exception(
    result['detail'] ??
        result['message'] ??
        result['error'] ??
        '알레르기 정보 저장 실패',
  );
}

  static Future<
    Map<String, String>> getMedicationTimes(
  String userId,
) async {
  final result =
      await getUser(userId);

  Map<String, dynamic>
      user = {};

  if (result['user'] is Map) {
    user =
        Map<String, dynamic>.from(
      result['user'] as Map,
    );
  } else {
    user =
        Map<String, dynamic>.from(
      result,
    );
  }

  Map<String, dynamic>
      times = {};

  if (user['medicationTimes']
      is Map) {
    times =
        Map<String, dynamic>.from(
      user['medicationTimes']
          as Map,
    );
  }

  return {
    'morning':
        (times['morning'] ??
                '08:30')
            .toString(),

    'lunch':
        (times['lunch'] ??
                '13:30')
            .toString(),

    'dinner':
        (times['dinner'] ??
                '19:30')
            .toString(),
  };
}


static Future<
    Map<String, dynamic>>
updateMedicationTimes({
  required String userId,
  required String morning,
  required String lunch,
  required String dinner,
}) async {
  final url = Uri.parse(
    '$baseUrl/users/'
    '$userId/'
    'medication-times',
  );

  final response =
      await http.patch(
    url,
    headers: {
      'Content-Type':
          'application/json',
    },
    body: jsonEncode({
      'morning': morning,
      'lunch': lunch,
      'dinner': dinner,
    }),
  );

  final decoded =
      jsonDecode(
    utf8.decode(
      response.bodyBytes,
    ),
  );

  final result =
      Map<String, dynamic>.from(
    decoded,
  );

  if (response.statusCode >= 200 &&
      response.statusCode < 300) {
    return result;
  }

  throw Exception(
    result['detail'] ??
        result['message'] ??
        '복약 시간 저장 실패',
  );
}

  static Future<Map<String, dynamic>> createSchedule({
    required String userId,
    required String medicineName,
    required int dailyCount,
    required double dosage,
    required String timing,
    required String startDate,
    required String endDate,
    required int period,
  }) async {
    final url = Uri.parse('$baseUrl/schedules/create');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'medicineName': medicineName,
        'dailyCount': dailyCount,
        'dosage': dosage,
        'timing': timing,
        'startDate': startDate,
        'endDate': endDate,
        'period': period,
      }),
    );

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> getSchedules(String userId) async {
    final url = Uri.parse('$baseUrl/schedules/user/$userId');

    final response = await http.get(url);

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> markAsTaken({
    required String userId,
    required String scheduleId,
    required String medicineName,
    required String date,
    required String time,
  }) async {
    final url = Uri.parse('$baseUrl/logs/taken');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'scheduleId': scheduleId,
        'medicineName': medicineName,
        'date': date,
        'time': time,
      }),
    );

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    final result = Map<String, dynamic>.from(decoded);

    debugPrint('복용 완료 API 응답: $result');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return result;
    }

    throw Exception(
      result['detail'] ??
          result['message'] ??
          '복용 기록 저장 실패 '
              '(${response.statusCode})',
    );
  }

  static Future<Map<String, dynamic>> getLogs(String userId) async {
    final url = Uri.parse('$baseUrl/logs/user/$userId');

    final response = await http.get(url);

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>>
deleteStockLog({
  required String userId,
  required String logId,
}) async {
  final url = Uri.parse(
    '$baseUrl/logs/stock/'
    '$userId/'
    '$logId',
  );

  final response =
      await http.delete(
    url,
    headers: {
      'Content-Type':
          'application/json',
    },
  );

  final decoded =
      jsonDecode(
    utf8.decode(
      response.bodyBytes,
    ),
  );

  final result =
      Map<String, dynamic>.from(
    decoded,
  );

  debugPrint(
    '상비약 기록 삭제 응답: '
    '$result',
  );

  if (response.statusCode >= 200 &&
      response.statusCode < 300 &&
      result['success'] == true) {
    return result;
  }

  throw Exception(
    result['detail'] ??
        result['message'] ??
        '상비약 기록 삭제 실패',
  );
}

  static Future<Map<String, dynamic>> uploadPrescriptionOnlyWeb({
    required XFile pickedFile,
  }) async {
    final url = Uri.parse('$baseUrl/ocr/prescription');

    debugPrint('OCR 요청 URL: $url');
    debugPrint('선택된 파일 이름: ${pickedFile.name}');

    final request = http.MultipartRequest('POST', url);

    final bytes = await pickedFile.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: pickedFile.name),
    );

    debugPrint('파일 첨부 완료');

    final streamedResponse = await request.send();

    debugPrint('서버 응답 수신 완료');
    debugPrint('응답 코드: ${streamedResponse.statusCode}');

    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('응답 body: ${response.body}');

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> saveEditedPrescription({
    required String userId,
    required List<Map<String, dynamic>> medicines,
    XFile? pickedFile,
  }) async {
    final url = Uri.parse('$baseUrl/ocr/prescription/save');

    debugPrint('수정된 처방전 저장 요청 URL: $url');

    final request = http.MultipartRequest('POST', url);

    request.fields['userId'] = userId;

    request.fields['medicinesJson'] = jsonEncode(medicines);

    // ✅ Web / 모바일 둘 다 사용 가능
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: pickedFile.name),
      );

      debugPrint(
        '처방전 이미지 첨부 완료: '
        '${pickedFile.name}',
      );
    }

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(streamedResponse);

    final responseBody = utf8.decode(response.bodyBytes);

    debugPrint('처방전 저장 응답: $responseBody');

    final decoded = jsonDecode(responseBody);

    final result = Map<String, dynamic>.from(decoded);

    if (streamedResponse.statusCode >= 200 &&
        streamedResponse.statusCode < 300 &&
        result['success'] != false) {
      return result;
    }

    throw Exception(
      result['detail'] ?? result['message'] ?? result['error'] ?? '처방전 저장 실패',
    );
  }

  static Future<Map<String, dynamic>> searchDrugs(String medicineName) async {
    final url = Uri.parse(
      '$baseUrl/drugs/search',
    ).replace(queryParameters: {'name': medicineName});

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    final responseBody = utf8.decode(response.bodyBytes);

    final decoded = jsonDecode(responseBody);

    final result = Map<String, dynamic>.from(decoded);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        result['success'] == true) {
      return result;
    }

    throw Exception(result['error'] ?? result['message'] ?? '의약품 검색 실패');
  }

  static Future<Map<String, dynamic>>
    getDrugDetail(String itemSeq) async {
  final url = Uri.parse(
    '$baseUrl/drugs/$itemSeq',
  );

  debugPrint(
    '약 상세정보 요청 URL: $url',
  );

  final response = await http.get(
    url,
    headers: {
      'accept': 'application/json',
    },
  );

  final responseBody =
      utf8.decode(
    response.bodyBytes,
  );

  debugPrint(
    '약 상세정보 응답 코드: '
    '${response.statusCode}',
  );

  final decoded =
      jsonDecode(responseBody);

  final result =
      Map<String, dynamic>.from(
    decoded,
  );

  if (response.statusCode >= 200 &&
      response.statusCode < 300 &&
      result['success'] == true) {
    return result;
  }

  throw Exception(
    result['error'] ??
        result['message'] ??
        '의약품 상세정보 조회 실패',
  );
}

static Future<Map<String, dynamic>>
checkInteractions({
  required String userId,
  required String itemSeq,
}) async {
  final url = Uri.parse(
    '$baseUrl/interactions/check',
  );

  debugPrint(
    '병용금기 확인 요청 URL: $url',
  );

  final response = await http.post(
    url,
    headers: {
      'Content-Type':
          'application/json',
    },
    body: jsonEncode({
      'userId': userId,
      'itemSeq': itemSeq,
    }),
  );

  final responseBody =
      utf8.decode(
    response.bodyBytes,
  );

  debugPrint(
    '병용금기 응답 코드: '
    '${response.statusCode}',
  );

  debugPrint(
    '병용금기 응답: '
    '$responseBody',
  );

  final decoded =
      jsonDecode(
    responseBody,
  );

  final result =
      Map<String, dynamic>.from(
    decoded,
  );

  if (response.statusCode >= 200 &&
      response.statusCode < 300) {
    return result;
  }

  throw Exception(
    result['detail'] ??
        result['message'] ??
        result['error'] ??
        '병용금기 확인 실패',
  );
}

static Future<Map<String, dynamic>>
checkAllergy({
  required String userId,
  required String itemSeq,
}) async {
  final url = Uri.parse(
    '$baseUrl/allergy/check',
  );

  debugPrint(
    '알레르기 확인 요청 URL: $url',
  );

  final response = await http.post(
    url,
    headers: {
      'Content-Type':
          'application/json',
    },
    body: jsonEncode({
      'userId': userId,
      'itemSeq': itemSeq,
    }),
  );

  final responseBody =
      utf8.decode(
    response.bodyBytes,
  );

  debugPrint(
    '알레르기 응답 코드: '
    '${response.statusCode}',
  );

  debugPrint(
    '알레르기 응답: '
    '$responseBody',
  );

  final decoded =
      jsonDecode(
    responseBody,
  );

  final result =
      Map<String, dynamic>.from(
    decoded,
  );

  if (response.statusCode >= 200 &&
      response.statusCode < 300) {
    return result;
  }

  throw Exception(
    result['detail'] ??
        result['message'] ??
        result['error'] ??
        '알레르기 확인 실패',
  );
}

static Future<Map<String, dynamic>>
recommendBySymptom({
  required String userId,
  required String symptom,
}) async {
  final url = Uri.parse(
    '$baseUrl/symptom/recommend',
  );

  debugPrint(
    '증상별 약 추천 요청: $url',
  );

  final response = await http.post(
    url,
    headers: {
      'Content-Type':
          'application/json',
    },
    body: jsonEncode({
      'userId': userId,
      'symptom': symptom,
    }),
  );

  final responseBody =
      utf8.decode(
    response.bodyBytes,
  );

  debugPrint(
    '증상별 약 추천 응답 코드: '
    '${response.statusCode}',
  );

  debugPrint(
    '증상별 약 추천 응답: '
    '$responseBody',
  );

  final decoded =
      jsonDecode(
    responseBody,
  );

  final result =
      Map<String, dynamic>.from(
    decoded,
  );

  if (response.statusCode >= 200 &&
      response.statusCode < 300 &&
      result['success'] != false) {
    return result;
  }

  throw Exception(
    result['detail'] ??
        result['message'] ??
        result['error'] ??
        '증상별 약 조회 실패',
  );
}

  static String drugImageProxyUrl(String originalUrl) {
    return Uri.parse(
      '$baseUrl/drugs/image',
    ).replace(queryParameters: {'url': originalUrl}).toString();
  }

  static Future<Map<String, dynamic>> createGuardianCode({
    required String wardUserId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/guardians/code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'wardUserId': wardUserId}),
    );

    final result = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return result;
    }

    throw Exception(result['detail'] ?? result['message'] ?? '연결 코드 생성 실패');
  }

  static Future<Map<String, dynamic>> connectGuardian({
    required String guardianUserId,
    required String connectionCode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/guardians/connect'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'guardianUserId': guardianUserId,
        'connectionCode': connectionCode,
      }),
    );

    final result = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return result;
    }

    throw Exception(result['detail'] ?? result['message'] ?? '보호자 연결 실패');
  }

    // 보호자 연결 해제
  static Future<Map<String, dynamic>> disconnectGuardian({
    required String wardUserId,
    required String guardianUserId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/guardians/disconnect',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'wardUserId': wardUserId,
        'guardianUserId': guardianUserId,
      }),
    );

    final result = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)),
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        result['success'] == true) {
      return result;
    }

    throw Exception(
      result['detail'] ??
          result['message'] ??
          '보호자 연결 해제에 실패했습니다.',
    );
  }


  static Future<Map<String, dynamic>> getGuardiansForWard(
    String wardUserId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/guardians/ward/'
        '$wardUserId',
      ),
    );

    final result = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return result;
    }

    throw Exception(result['detail'] ?? '보호자 목록 조회 실패');
  }

  static Future<Map<String, dynamic>> getWardsForGuardian(
    String guardianUserId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/guardians/guardian/'
        '$guardianUserId',
      ),
    );

    final result = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return result;
    }

    throw Exception(result['detail'] ?? '보호 대상 목록 조회 실패');
  }

  static Future<Map<String, dynamic>> getGuardianTodayStatus({
    required String guardianUserId,
    required String wardUserId,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/guardians/'
        '$guardianUserId'
        '/wards/'
        '$wardUserId'
        '/today',
      ),
    );

    final result = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return result;
    }

    throw Exception(result['detail'] ?? '복약 현황 조회 실패');
  }

  static Future<Map<String, dynamic>> getStocks(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/stocks/user/$userId'));

    final result = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return result;
    }

    throw Exception(result['detail'] ?? '상비약 조회 실패');
  }

  static Future<Map<String, dynamic>> consumeStock({
    required String userId,
    required String stockId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/stocks/consume'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'stockId': stockId}),
    );

    final result = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(response.bodyBytes)),
    );

    debugPrint('상비약 복용 API 응답: $result');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return result;
    }

    throw Exception(result['detail'] ?? result['message'] ?? '상비약 복용 실패');
  }

  static Future<Map<String, dynamic>> addStockBox({
  required String userId,
  required String stockId,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/stocks/add-box'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'userId': userId, 'stockId': stockId}),
  );
  final result = Map<String, dynamic>.from(jsonDecode(utf8.decode(response.bodyBytes)));
  if (response.statusCode >= 200 && response.statusCode < 300) return result;
  throw Exception(result['detail'] ?? result['message'] ?? '상비약 추가 실패');
}

static Future<Map<String, dynamic>> deleteStock({
  required String userId,
  required String stockId,
}) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/stocks/$userId/$stockId'),
    headers: {'Content-Type': 'application/json'},
  );
  final result =
      Map<String, dynamic>.from(jsonDecode(utf8.decode(response.bodyBytes)));
  if (response.statusCode >= 200 && response.statusCode < 300) return result;
  throw Exception(result['detail'] ?? result['message'] ?? '상비약 삭제 실패');
}

}


