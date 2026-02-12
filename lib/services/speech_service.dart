import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class SpeechService {
  static final AudioRecorder _recorder = AudioRecorder();
  static bool _isRecording = false;
  static String? _currentPath;

  static bool get isRecording => _isRecording;

  /// Start recording audio
  static Future<bool> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _currentPath =
            '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: _currentPath!,
        );
        _isRecording = true;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Recording start error: $e');
      return false;
    }
  }

  /// Stop recording and return the file path
  static Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;
      final path = await _recorder.stop();
      _isRecording = false;
      return path;
    } catch (e) {
      debugPrint('Recording stop error: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Transcribe audio file using Gemini 3 Flash via OpenRouter
  static Future<String?> transcribe(String audioPath) async {
    try {
      final apiKey = dotenv.env['OPENROUTER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('OPENROUTER_API_KEY not found');
      }

      final bytes = await File(audioPath).readAsBytes();
      final base64Audio = base64Encode(bytes);

      debugPrint('SpeechService: transcribing ${bytes.length} bytes...');

      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://github.com/Chris/my-aicoach',
          'X-Title': 'myAIcoach',
        },
        body: jsonEncode({
          'model': 'google/gemini-3-flash-preview',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Transcribe this audio exactly as spoken. Return ONLY the transcription text, nothing else. '
                      'If the audio is in French, transcribe in French. If in English, transcribe in English. '
                      'Preserve the original language.',
                },
                {
                  'type': 'input_audio',
                  'input_audio': {
                    'data': base64Audio,
                    'format': 'mp4',
                  },
                },
              ],
            },
          ],
          'max_tokens': 500,
          'temperature': 0.0,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];
        if (content != null && content.toString().trim().isNotEmpty) {
          debugPrint('SpeechService: transcription OK');
          return content.toString().trim();
        }
      } else {
        debugPrint(
            'SpeechService: error ${response.statusCode} - ${response.body.substring(0, response.body.length.clamp(0, 300))}');
      }

      return null;
    } catch (e) {
      debugPrint('SpeechService: transcription error: $e');
      return null;
    } finally {
      // Clean up temp file
      try {
        await File(audioPath).delete();
      } catch (_) {}
    }
  }

  static Future<void> dispose() async {
    if (_isRecording) {
      await _recorder.stop();
      _isRecording = false;
    }
    _recorder.dispose();
  }
}
