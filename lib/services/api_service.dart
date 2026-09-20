import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.189:8000'; // 할 때마다 IP 바꾸기

  static Future<bool> healthCheck() async {
    final url = Uri.parse('$baseUrl/health');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['status'] == 'ok';
    }
    return false;
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
}) async {
  final url = Uri.parse('$baseUrl/users/create');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
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

      'allergyList' : [],
    }),
  );

  final result =
      jsonDecode(utf8.decode(response.bodyBytes));

  if (response.statusCode >= 200 &&
      response.statusCode < 300) {
    return result;
  }

  throw Exception(
    result['detail'] ??
        result['message'] ??
        '회원가입 요청 실패 (${response.statusCode})',
  );
}

static Future<Map<String, dynamic>> login({
  required String email,
  required String password,
}) async {
  final url = Uri.parse('$baseUrl/users/login');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );

  final result =
      jsonDecode(utf8.decode(response.bodyBytes));

  if (response.statusCode >= 200 &&
      response.statusCode < 300) {
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

    final response = await http.get(url);

    return jsonDecode(utf8.decode(response.bodyBytes));
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
      headers: {
        'Content-Type': 'application/json',
      },
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
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': userId,
        'scheduleId': scheduleId,
        'medicineName': medicineName,
        'date': date,
        'time': time,
      }),
    );

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> getLogs(String userId) async {
    final url = Uri.parse('$baseUrl/logs/user/$userId');

    final response = await http.get(url);

    return jsonDecode(utf8.decode(response.bodyBytes));
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
    http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: pickedFile.name,
    ),
  );

  debugPrint('파일 첨부 완료');

  final streamedResponse = await request.send();

  debugPrint('서버 응답 수신 완료');
  debugPrint('응답 코드: ${streamedResponse.statusCode}');

  final response = await http.Response.fromStream(streamedResponse);

  debugPrint('응답 body: ${response.body}');

  return jsonDecode(utf8.decode(response.bodyBytes));
}

static Future<Map<String, dynamic>>
    saveEditedPrescription({
  required String userId,
  required List<Map<String, dynamic>> medicines,
  XFile? pickedFile,
}) async {
  final url = Uri.parse(
    '$baseUrl/ocr/prescription/save',
  );

  debugPrint(
    '수정된 처방전 저장 요청 URL: $url',
  );

  final request = http.MultipartRequest(
    'POST',
    url,
  );

  request.fields['userId'] = userId;

  request.fields['medicinesJson'] =
      jsonEncode(medicines);

  // ✅ Web / 모바일 둘 다 사용 가능
  if (pickedFile != null) {
    final bytes =
        await pickedFile.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: pickedFile.name,
      ),
    );

    debugPrint(
      '처방전 이미지 첨부 완료: '
      '${pickedFile.name}',
    );
  }

  final streamedResponse =
      await request.send();

  final response =
      await http.Response.fromStream(
    streamedResponse,
  );

  final responseBody =
      utf8.decode(
    response.bodyBytes,
  );

  debugPrint(
    '처방전 저장 응답: $responseBody',
  );

  final decoded =
      jsonDecode(responseBody);

  final result =
      Map<String, dynamic>.from(
    decoded,
  );

  if (streamedResponse.statusCode >= 200 &&
      streamedResponse.statusCode < 300 &&
      result['success'] != false) {
    return result;
  }

  throw Exception(
    result['detail'] ??
        result['message'] ??
        result['error'] ??
        '처방전 저장 실패',
  );
}

static Future<Map<String, dynamic>> searchDrugs(
  String medicineName,
) async {
  final url = Uri.parse(
    '$baseUrl/drugs/search',
  ).replace(
    queryParameters: {
      'name': medicineName,
    },
  );

  final response = await http.get(
    url,
    headers: {
      'Content-Type':
          'application/json',
    },
  );

  final responseBody =
      utf8.decode(
    response.bodyBytes,
  );

  final decoded =
      jsonDecode(responseBody);

  final result =
      Map<String, dynamic>.from(
    decoded,
  );

  if (
    response.statusCode >= 200
    && response.statusCode < 300
    && result['success'] == true
  ) {
    return result;
  }

  throw Exception(
    result['error']
        ?? result['message']
        ?? '의약품 검색 실패',
  );
}

static String drugImageProxyUrl(
  String originalUrl,
) {
  return Uri.parse(
    '$baseUrl/drugs/image',
  ).replace(
    queryParameters: {
      'url': originalUrl,
    },
  ).toString();
}

}