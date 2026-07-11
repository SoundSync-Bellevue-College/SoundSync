import 'package:dio/dio.dart';
import 'api_client.dart';

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  const ChatMessage({required this.role, required this.content});

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class ChatRoute {
  final String origin;
  final String destination;
  const ChatRoute({required this.origin, required this.destination});
}

class ChatResponse {
  final String message;
  final ChatRoute? route;
  const ChatResponse({required this.message, this.route});
}

class ChatService {
  final Dio _dio = buildApiClient();

  Future<ChatResponse> send(List<ChatMessage> history) async {
    final res = await _dio.post('/chat', data: {
      'messages': history.map((m) => m.toJson()).toList(),
    });
    final data = res.data as Map<String, dynamic>;
    ChatRoute? route;
    if (data['route'] != null) {
      final r = data['route'] as Map<String, dynamic>;
      route = ChatRoute(
        origin: r['origin'] as String,
        destination: r['destination'] as String,
      );
    }
    return ChatResponse(message: data['message'] as String, route: route);
  }
}
