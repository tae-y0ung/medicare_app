import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String baseUrl = 'http://172.16.101.244:8000'; // 할 때마다 IP 바꾸기

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
    required int dosage,
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

  static Future<Map<String, dynamic>> uploadPrescriptionAndSaveWeb({
  required String userId,
  required String startDate,
  required String endDate,
  required XFile pickedFile,
}) async {
  final url = Uri.parse('$baseUrl/ocr/prescription/save');

  debugPrint('OCR 저장 요청 URL: $url');
  debugPrint('선택된 파일 이름: ${pickedFile.name}');

  final request = http.MultipartRequest('POST', url);

  request.fields['userId'] = userId;
  request.fields['startDate'] = startDate;
  request.fields['endDate'] = endDate;

  final bytes = await pickedFile.readAsBytes();

  request.files.add(
    http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: pickedFile.name,
    ),
  );

  debugPrint('OCR 저장 파일 첨부 완료');

  final streamedResponse = await request.send();

  debugPrint('OCR 저장 응답 코드: ${streamedResponse.statusCode}');

  final response = await http.Response.fromStream(streamedResponse);

  debugPrint('OCR 저장 응답 body: ${response.body}');

  return jsonDecode(utf8.decode(response.bodyBytes));
}
}