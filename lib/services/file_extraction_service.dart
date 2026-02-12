import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart' as xl;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class FileExtractionService {
  static const String _geminiModel = 'google/gemini-3-flash-preview';
  static const int _maxChars = 10000;

  static const Set<String> _supported = {
    'pdf',
    'csv',
    'txt',
    'md',
    'doc',
    'docx',
    'xls',
    'xlsx',
  };

  /// Extract text from a file.
  /// - PDF → Gemini Flash (native support)
  /// - TXT/MD/CSV → local read
  /// - DOCX → local ZIP+XML extraction
  /// - XLSX/XLS → local excel package
  static Future<String?> extractText(String filePath) async {
    try {
      final ext = filePath.split('.').last.toLowerCase();
      debugPrint('FileExtraction: processing .$ext file');

      switch (ext) {
        case 'txt':
        case 'md':
        case 'csv':
          return await _readPlainText(filePath);
        case 'pdf':
          return await _extractPdfWithGemini(filePath);
        case 'docx':
          return await _extractDocx(filePath);
        case 'doc':
          return await _extractDocFallback(filePath);
        case 'xlsx':
        case 'xls':
          return await _extractExcel(filePath);
        default:
          debugPrint('FileExtraction: unsupported extension $ext');
          return null;
      }
    } catch (e) {
      debugPrint('FileExtraction: error: $e');
      return null;
    }
  }

  // ── Plain text (TXT, MD, CSV) ──
  static Future<String?> _readPlainText(String filePath) async {
    try {
      final content = await File(filePath).readAsString();
      debugPrint('FileExtraction: plain text ${content.length} chars');
      return content.length > _maxChars
          ? content.substring(0, _maxChars)
          : content;
    } catch (e) {
      debugPrint('FileExtraction: plain text error: $e');
      return null;
    }
  }

  // ── PDF → Gemini Flash via OpenRouter ──
  static Future<String?> _extractPdfWithGemini(String filePath) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;

    final bytes = await File(filePath).readAsBytes();
    final base64Data = base64Encode(bytes);
    final dataUrl = 'data:application/pdf;base64,$base64Data';

    debugPrint(
        'FileExtraction: sending PDF (${bytes.length} bytes) to Gemini...');

    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://github.com/Chris/my-aicoach',
        'X-Title': 'myAIcoach',
      },
      body: jsonEncode({
        'model': _geminiModel,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text':
                    'Extract and return ALL the text content from this PDF document. '
                        'Return the full text as-is, preserving structure. '
                        'Do not summarize, do not add commentary. '
                        'Return ONLY the extracted text.',
              },
              {
                'type': 'image_url',
                'image_url': {'url': dataUrl},
              },
            ],
          },
        ],
        'max_tokens': 4000,
        'temperature': 0.0,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices']?[0]?['message']?['content'];
      if (content != null && content.toString().trim().isNotEmpty) {
        debugPrint(
            'FileExtraction: Gemini returned ${content.toString().length} chars');
        return content.toString().trim();
      }
    } else {
      debugPrint('FileExtraction: Gemini error ${response.statusCode} - '
          '${response.body.substring(0, response.body.length.clamp(0, 300))}');
    }
    return null;
  }

  // ── DOCX → local ZIP + XML extraction ──
  static Future<String?> _extractDocx(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        if (file.name == 'word/document.xml') {
          final xmlContent = utf8.decode(file.content as List<int>);
          // Extract text from XML: get content between <w:t> tags
          final textParts = <String>[];
          final regex = RegExp(r'<w:t[^>]*>([^<]*)</w:t>');
          for (final match in regex.allMatches(xmlContent)) {
            if (match.group(1) != null) {
              textParts.add(match.group(1)!);
            }
          }
          // Detect paragraph breaks
          final result = xmlContent
              .replaceAll(RegExp(r'<w:p[ /][^>]*>|<w:p>'), '\n')
              .replaceAll(RegExp(r'<[^>]+>'), '')
              .replaceAll(RegExp(r'\n{3,}'), '\n\n')
              .trim();

          final text = result.isNotEmpty ? result : textParts.join(' ');
          debugPrint('FileExtraction: DOCX extracted ${text.length} chars');
          return text.length > _maxChars ? text.substring(0, _maxChars) : text;
        }
      }
      debugPrint('FileExtraction: word/document.xml not found in DOCX');
      return null;
    } catch (e) {
      debugPrint('FileExtraction: DOCX error: $e');
      return null;
    }
  }

  // ── DOC (old binary format) → best-effort text extraction ──
  static Future<String?> _extractDocFallback(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      // Extract printable ASCII text from binary
      final buffer = StringBuffer();
      final chunk = StringBuffer();
      for (final b in bytes) {
        if ((b >= 32 && b < 127) || b == 10 || b == 13) {
          chunk.writeCharCode(b);
        } else {
          if (chunk.length > 5) {
            buffer.write(chunk.toString());
            buffer.write(' ');
          }
          chunk.clear();
        }
      }
      if (chunk.length > 5) buffer.write(chunk.toString());

      final text = buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
      debugPrint('FileExtraction: DOC fallback extracted ${text.length} chars');
      return text.length > _maxChars ? text.substring(0, _maxChars) : text;
    } catch (e) {
      debugPrint('FileExtraction: DOC error: $e');
      return null;
    }
  }

  // ── XLSX / XLS → excel package ──
  static Future<String?> _extractExcel(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final excel = xl.Excel.decodeBytes(bytes);
      final buffer = StringBuffer();

      for (final sheetName in excel.tables.keys) {
        final sheet = excel.tables[sheetName];
        if (sheet == null) continue;
        buffer.writeln('--- $sheetName ---');
        for (final row in sheet.rows) {
          final cells =
              row.map((cell) => cell?.value?.toString() ?? '').toList();
          buffer.writeln(cells.join(' | '));
          if (buffer.length > _maxChars) break;
        }
        if (buffer.length > _maxChars) break;
      }

      final text = buffer.toString().trim();
      debugPrint('FileExtraction: Excel extracted ${text.length} chars');
      return text.length > _maxChars ? text.substring(0, _maxChars) : text;
    } catch (e) {
      debugPrint('FileExtraction: Excel error: $e');
      return null;
    }
  }

  static String getSupportedExtensions() {
    return 'PDF, CSV, TXT, MD, DOC, DOCX, XLS, XLSX';
  }

  static bool isSupported(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    return _supported.contains(ext);
  }
}
