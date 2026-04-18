// lib/features/ai_assistant/services/captcha_service.dart
// =============================================================================
// 验证码服务 - 获取和验证图形验证码
// =============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// 验证码服务
class CaptchaService {
  static const String _captchaEndpoint = '/api/captcha';
  static const String _verifyEndpoint = '/api/captcha/verify';

  final String baseUrl;
  final int timeout;

  HttpClient? _client;

  CaptchaService({
    this.baseUrl = '',
    this.timeout = 10000,
  });

  /// 获取验证码
  /// 返回包含 id 和 image(base64) 的对象
  Future<CaptchaResult?> getCaptcha() async {
    try {
      final response = await _get('/api/captcha');
      
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        return CaptchaResult(
          id: data['id'] as String,
          image: data['image'] as String, // SVG 格式
        );
      }
      return null;
    } catch (e) {
      debugPrint('CaptchaService Error: $e');
      return null;
    }
  }

  /// 验证验证码
  Future<bool> verify(String captchaId, String code) async {
    try {
      final response = await _post(
        '/api/captcha/verify',
        body: {
          'id': captchaId,
          'code': code,
        },
      );
      
      return response['success'] == true;
    } catch (e) {
      debugPrint('CaptchaService verify Error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _get(String endpoint) async {
    _client ??= HttpClient();

    final uri = Uri.parse('$baseUrl$endpoint');
    final request = await _client!.openUrl('GET', uri)
      ..headers.set('Accept', 'application/json');

    try {
      final httpResponse = await request.close().timeout(
        Duration(milliseconds: timeout),
      );

      final responseBody = await httpResponse.transform(utf8.decoder).join();
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  Future<Map<String, dynamic>> _post(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    _client ??= HttpClient();

    final uri = Uri.parse('$baseUrl$endpoint');
    final request = await _client!.openUrl('POST', uri)
      ..headers.contentType = ContentType.json
      ..headers.set('Accept', 'application/json')
      ..write(jsonEncode(body));

    try {
      final httpResponse = await request.close().timeout(
        Duration(milliseconds: timeout),
      );

      final responseBody = await httpResponse.transform(utf8.decoder).join();
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  void dispose() {
    _client?.close();
    _client = null;
  }
}

/// 验证码结果
class CaptchaResult {
  final String id;
  final String image; // SVG 格式的验证码图片

  CaptchaResult({
    required this.id,
    required this.image,
  });
}
