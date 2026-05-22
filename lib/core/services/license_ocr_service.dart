import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:rakni_v2/core/models/license_model.dart';
import 'package:rakni_v2/core/services/license_image_processor.dart';

/// Result wrapper for OCR calls — separates success/failure cleanly.
class OcrResult {
  final LicenseModel? data;
  final bool success;
  final String? errorMessage;

  const OcrResult.success(this.data) : success = true, errorMessage = null;

  const OcrResult.failure(this.errorMessage) : success = false, data = null;
}

/// Sends a preprocessed license image to Gemini Vision API and returns
/// structured [LicenseModel] data using strict JSON mode prompting.
class LicenseOcrService {
  LicenseOcrService._();
  static final instance = LicenseOcrService._();

  // SECURITY NOTE:
  // For production, move this call to a Firebase Cloud Function so the
  // API key is never exposed in the client app bundle.
  // For MVP development only:
  static const String _apiKey = 'AIzaSyCDTtucqRKFNsPq4SsC6Q4PxDa7P5OER4k';
  static const String _model = 'gemini-2.5-flash';
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  /// Main entry point.
  /// [rawImageBytes] — raw bytes of the picked image before preprocessing.
  /// Returns [OcrResult] with structured data or an error message.
  Future<OcrResult> extractFromBytes(Uint8List rawImageBytes) async {
    try {
      final processedBytes = await LicenseImageProcessor.instance.process(
        rawImageBytes,
      );
      final base64Image = base64Encode(processedBytes);

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: jsonEncode(_buildRequestBody(base64Image)),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return OcrResult.failure(
          'API error ${response.statusCode}: ${response.body}',
        );
      }

      return _parseResponse(response.body);
    } on Exception catch (e) {
      return OcrResult.failure('OCR failed: $e');
    }
  }

  /// Also accepts a base64 data URI string for compatibility with ImageUtils.
  Future<OcrResult> extractFromBase64Uri(String base64DataUri) async {
    final rawBase64 = base64DataUri.contains(',')
        ? base64DataUri.split(',').last
        : base64DataUri;
    final bytes = base64Decode(rawBase64);
    return extractFromBytes(bytes);
  }

  Map<String, dynamic> _buildRequestBody(String base64Image) {
    return {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
            },
            {'text': _buildPrompt()},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0,
        'maxOutputTokens': 600,
        'responseMimeType': 'application/json',
      },
    };
  }

  /// Engineered prompt that extracts bilingual fields and enforces JSON output.
  String _buildPrompt() {
    return '''
You are an OCR specialist for Egyptian government documents.

The image provided is the FRONT SIDE of an Egyptian Driver's License (رخصة قيادة مصرية).

Extract the following fields and return ONLY a raw JSON object — no markdown code blocks, no explanation, no preamble, just the JSON itself.

Required JSON schema (use exactly these key names):
{
  "holder_name_arabic": "Full name in Arabic as printed on the license",
  "holder_name_english": "Full name in English/Latin if present, otherwise empty string",
  "national_id": "14-digit national identification number if visible",
  "license_number": "The license serial/ID number (typically 6-8 digits)",
  "issue_date": "Issue date in DD/MM/YYYY format",
  "expiry_date": "Expiry date in DD/MM/YYYY format",
  "categories": "Permitted vehicle categories as comma-separated letters, e.g. B or A,B,C",
  "issuing_authority": "Name of the issuing traffic directorate if visible"
}

Rules:
- Return ONLY the JSON object. No extra text before or after.
- If a field is not visible or unreadable, use an empty string "".
- Dates must always be in DD/MM/YYYY format. Convert any other format.
- The national_id is the 14-digit number that usually appears below the photo.
- Categories are letters like A, B, C, D, BE, CE — list all that appear.
- Do not guess or hallucinate values. If unsure, use empty string.
''';
  }

  /// Parses Gemini's response body into an [OcrResult].
  /// Handles cases where the model might wrap JSON in markdown despite instructions.
  OcrResult _parseResponse(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List<dynamic>? ?? [];
      if (candidates.isEmpty) {
        return const OcrResult.failure('Empty response from API.');
      }

      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>? ?? [];
      if (parts.isEmpty) {
        return const OcrResult.failure('No text content found in response.');
      }

      String rawText = (parts.first['text'] as String? ?? '').trim();
      rawText = rawText
          .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
          .replaceAll(RegExp(r'\s*```$', multiLine: true), '')
          .trim();

      final jsonStart = rawText.indexOf('{');
      final jsonEnd = rawText.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1) {
        return const OcrResult.failure('No JSON object found in response.');
      }

      final jsonString = rawText.substring(jsonStart, jsonEnd + 1);
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final model = LicenseModel.fromOcrJson(jsonMap);

      return OcrResult.success(model);
    } catch (e) {
      return OcrResult.failure('Failed to parse OCR response: $e');
    }
  }
}
