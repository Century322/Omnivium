import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app_logger.dart';
import '../api_proxy_service.dart';

class ChatMessage {
  final String role;
  final String content;
  final String? model;

  const ChatMessage({required this.role, required this.content, this.model});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class RateLimitException implements Exception {
  final int waitSeconds;
  RateLimitException(this.waitSeconds);
  @override
  String toString() =>
      'Rate limit exceeded. Please try again in $waitSeconds seconds.';
}

class AIResponse {
  final String content;
  final String model;
  final int promptTokens;
  final int completionTokens;

  const AIResponse({
    required this.content,
    required this.model,
    this.promptTokens = 0,
    this.completionTokens = 0,
  });
}

class ChatService {
  static final ChatService _instance = ChatService._();
  static ChatService get instance => _instance;
  ChatService._();

  String _currentModel = '';

  String get currentModel => _currentModel;

  static final StreamController<AuthEvent> _authEventController =
      StreamController<AuthEvent>.broadcast();
  static Stream<AuthEvent> get onAuthEvent => _authEventController.stream;

  void setModel(String model) {
    _currentModel = model;
  }

  void _handleAuthFailure() {
    AppLogger.instance.warning(
      'AI API auth failure, not affecting Matrix session',
    );
  }

  Map<String, String> _headersWithBody(String body) {
    final proxy = ApiProxyService.instance;
    return {
      ...proxy.buildAuthHeaders(body: body),
      ...proxy.buildDeviceHeaders(),
      'Content-Type': 'application/json',
    };
  }

  Future<Stream<String>> chat(
    List<ChatMessage> messages, {
    String? model,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async {
    final proxy = ApiProxyService.instance;
    final uri = proxy.resolveChatUrl();
    final useModel = model ?? _currentModel;

    final request = http.Request('POST', uri);
    final body = jsonEncode({
      'model': useModel,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': true,
    });
    request.headers.addAll(_headersWithBody(body));
    request.headers['Accept'] = 'text/event-stream';
    request.body = body;

    final client = proxy.secureClient;
    final response = await client
        .send(request)
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 401) {
      _handleAuthFailure();
      throw Exception('Session expired. Please log in again.');
    }

    if (response.statusCode == 429) {
      final retryAfter = response.headers['retry-after'];
      final waitSeconds = retryAfter != null
          ? int.tryParse(retryAfter) ?? 30
          : 30;
      throw RateLimitException(waitSeconds);
    }

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception('API error: ${response.statusCode} - $body');
    }

    return response.stream
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .where((line) => line.startsWith('data: ') && !line.contains('[DONE]'))
        .map((line) {
          try {
            final json = jsonDecode(line.substring(6));
            final delta = json['choices']?[0]?['delta']?['content'];
            return delta ?? '';
          } catch (e, stackTrace) {
            AppLogger.instance.warning(
              'SSE parse failed',
              error: e,
              stackTrace: stackTrace,
            );
            return '';
          }
        })
        .where((content) => content.isNotEmpty)
        .cast<String>();
  }

  Future<AIResponse> chatSync(
    List<ChatMessage> messages, {
    String? model,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async {
    final proxy = ApiProxyService.instance;
    final uri = proxy.resolveChatUrl();
    final useModel = model ?? _currentModel;

    final syncBody = jsonEncode({
      'model': useModel,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': false,
    });
    final response = await proxy.secureClient
        .post(uri, headers: _headersWithBody(syncBody), body: syncBody)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 401) {
      _handleAuthFailure();
      throw Exception('Session expired. Please log in again.');
    }

    if (response.statusCode == 429) {
      final retryAfter = response.headers['retry-after'];
      final waitSeconds = retryAfter != null
          ? int.tryParse(retryAfter) ?? 30
          : 30;
      throw RateLimitException(waitSeconds);
    }

    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode} - ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List?;
    final content =
        choices?.firstOrNull?['message']?['content']?.toString() ?? '';
    return AIResponse(
      content: content,
      model: json['model'] as String? ?? useModel,
      promptTokens:
          (json['usage'] as Map<String, dynamic>?)?['prompt_tokens'] as int? ??
          0,
      completionTokens:
          (json['usage'] as Map<String, dynamic>?)?['completion_tokens']
              as int? ??
          0,
    );
  }

  Future<AgentStream> agentChat(
    List<ChatMessage> messages, {
    String? model,
    double temperature = 0.7,
    int maxTokens = 4096,
    List<Map<String, dynamic>>? skills,
  }) async {
    final proxy = ApiProxyService.instance;
    final uri = proxy.resolveChatUrl();
    final useModel = model ?? _currentModel;

    final request = http.Request('POST', uri);
    final agentBody = jsonEncode({
      'model': useModel,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': true,
      'agent_mode': true,
      'skills': skills ?? [],
    });
    request.headers.addAll(_headersWithBody(agentBody));
    request.headers['Accept'] = 'text/event-stream';
    request.body = agentBody;

    final client = proxy.secureClient;
    final response = await client
        .send(request)
        .timeout(const Duration(seconds: 120));

    if (response.statusCode == 401) {
      _handleAuthFailure();
      throw Exception('Session expired. Please log in again.');
    }

    if (response.statusCode == 429) {
      final retryAfter = response.headers['retry-after'];
      final waitSeconds = retryAfter != null
          ? int.tryParse(retryAfter) ?? 30
          : 30;
      throw RateLimitException(waitSeconds);
    }

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception('API error: ${response.statusCode} - $body');
    }

    return AgentStream(
      response.stream
          .transform(const Utf8Decoder())
          .transform(const LineSplitter()),
    );
  }
}

enum AuthEvent { tokenExpired }

class AgentStream {
  final Stream<String> _lines;
  AgentStream(this._lines);

  Stream<AgentEvent> get events => _lines
      .where((line) => line.startsWith('event: ') || line.startsWith('data: '))
      .transform(_AgentEventTransformer());
}

class AgentEvent {
  final String type;
  final Map<String, dynamic> data;
  const AgentEvent(this.type, this.data);
}

class _AgentEventTransformer extends StreamTransformerBase<String, AgentEvent> {
  @override
  Stream<AgentEvent> bind(Stream<String> stream) {
    String? currentEvent;
    return stream.transform(
      StreamTransformer.fromHandlers(
        handleData: (line, sink) {
          if (line.startsWith('event: ')) {
            currentEvent = line.substring(7).trim();
          } else if (line.startsWith('data: ')) {
            final dataStr = line.substring(6).trim();
            if (dataStr == '[DONE]') return;
            try {
              final data = jsonDecode(dataStr) as Map<String, dynamic>;
              final eventType = currentEvent ?? 'message';
              currentEvent = null;
              sink.add(AgentEvent(eventType, data));
            } catch (e) {
              AppLogger.instance.warning(
                'SSE: failed to parse event data',
                error: e,
              );
            }
          }
        },
      ),
    );
  }
}
