import 'dart:convert';
import '../../core/agent/agent_state.dart';
import '../../core/skills/skill.dart';
import '../../core/api_proxy_service.dart';

class WebSearchSkill extends Skill {
  @override
  String get id => 'search.web';

  @override
  String get name => '联网搜索';

  @override
  String get description => '搜索互联网获取最新信息，返回搜索结果摘要';

  @override
  IntentChannel get channel => IntentChannel.slow;

  @override
  PermissionLevel get permission => PermissionLevel.auto;

  @override
  int get timeoutMs => 15000;

  @override
  int get maxRetries => 2;

  @override
  bool get isDestructive => false;

  @override
  Future<SkillResult> execute(Map<String, dynamic> params) async {
    final query = params['query'] as String?;
    if (query == null || query.isEmpty) {
      return SkillResult.fail('搜索关键词不能为空');
    }

    try {
      final proxy = ApiProxyService.instance;
      final uri = Uri.parse('${proxy.backendUrl}/ai/search');
      final response = await proxy.secureClient
          .post(
            uri,
            headers: <String, String>{
              ...proxy.buildAuthHeaders(),
              ...proxy.buildDeviceHeaders(),
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'q': query}),
          )
          .timeout(Duration(milliseconds: timeoutMs));

      if (response.statusCode != 200) {
        return SkillResult.fail('搜索请求失败: ${response.statusCode}');
      }

      final json = jsonDecode(response.body);
      if (json is! Map<String, dynamic>) {
        return SkillResult.fail('Invalid search response format');
      }
      final results = <Map<String, String>>[];

      final organic = json['organic'] as List?;
      if (organic != null) {
        for (final item in organic.take(5)) {
          if (item is Map<String, dynamic>) {
            results.add({
              'title': item['title']?.toString() ?? '',
              'link': item['link']?.toString() ?? '',
              'snippet': item['snippet']?.toString() ?? '',
            });
          }
        }
      }

      final knowledgeGraph = json['knowledgeGraph'] as Map<String, dynamic>?;
      String? kgDescription;
      if (knowledgeGraph != null) {
        kgDescription = knowledgeGraph['description'] as String?;
      }

      final output = StringBuffer();
      if (kgDescription != null) {
        output.writeln('📋 $kgDescription\n');
      }
      output.writeln('搜索结果（"$query"）：\n');
      for (var i = 0; i < results.length; i++) {
        final r = results[i];
        output.writeln('${i + 1}. ${r['title']}');
        output.writeln('   ${r['snippet']}');
        output.writeln('   🔗 ${r['link']}\n');
      }

      return SkillResult.ok({
        'query': query,
        'results': results,
        'summary': output.toString(),
      });
    } catch (e) {
      return SkillResult.fail('搜索出错: $e');
    }
  }
}
