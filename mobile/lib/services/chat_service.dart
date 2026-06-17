import 'package:dio/dio.dart';
import 'api_client.dart';

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  const ChatMessage({required this.role, required this.content});

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class ChatService {
  final Dio _dio = buildApiClient();

  Future<String> send(List<ChatMessage> history) async {
    final res = await _dio.post('/chat', data: {
      'messages': history.map((m) => m.toJson()).toList(),
    });
    return res.data['message'] as String;
  }
}
