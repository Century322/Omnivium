import 'package:flutter/material.dart';
import 'app_logger.dart';
import '../presentation/theme/app_colors.dart';
import '../presentation/theme/locale_provider.dart';

class RemoteUIEngine {
  static const _maxRenderDepth = 10;
  static const _allowedImageHosts = {
    'omnivium.app',
    'omnivium-api-proxy.so1946875590.workers.dev',
    'cdn.omnivium.app',
  };

  static const _allowedTypes = {
    'column',
    'row',
    'text',
    'button',
    'card',
    'list',
    'image',
    'divider',
    'spacer',
    'container',
    'switch',
    'input',
    'icon',
    'badge',
  };

  static const _maxChildren = 50;
  static const _maxTextLength = 10000;

  static Map<String, dynamic>? validateSchema(Map<String, dynamic> schema) {
    final type = schema['type'] as String?;
    if (type == null || !_allowedTypes.contains(type)) return null;
    if (schema.containsKey('children')) {
      final children = schema['children'];
      if (children is! List || children.length > _maxChildren) return null;
      for (final child in children) {
        if (child is! Map<String, dynamic>) return null;
        if (validateSchema(child) == null) return null;
      }
    }
    if (schema.containsKey('text')) {
      final text = schema['text'];
      if (text is String && text.length > _maxTextLength) return null;
    }
    if (schema.containsKey('action')) {
      final action = schema['action'];
      if (action is! Map<String, dynamic>) return null;
      if (action.containsKey('url')) {
        final url = action['url'] as String?;
        if (url != null && !_isUrlSafe(url)) return null;
      }
    }
    return schema;
  }

  static bool _isUrlSafe(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.scheme != 'https' && uri.scheme != 'http') return false;
      final host = uri.host;
      if (host.isEmpty) return false;
      if (host == 'localhost' || host == '127.0.0.1') return false;
      return true;
    } catch (e) {
      AppLogger.instance.debug('URL validation failed', error: e);
      return false;  }

  static Widget render(
    Map<String, dynamic> schema,
    BuildContext context, [
    int depth = 0,
  ]) {
    final validated = validateSchema(schema);
    if (validated == null) {
      return const SizedBox.shrink();
    }
    if (depth > _maxRenderDepth) {
      return const SizedBox.shrink();
    }
    final type = schema['type'] as String? ?? 'column';
    switch (type) {
      case 'column':
        return _renderColumn(schema, context, depth);
      case 'row':
        return _renderRow(schema, context, depth);
      case 'text':
        return _renderText(schema, context);
      case 'button':
        return _renderButton(schema, context);
      case 'card':
        return _renderCard(schema, context, depth);
      case 'list':
        return _renderList(schema, context, depth);
      case 'image':
        return _renderImage(schema, context);
      case 'divider':
        return _renderDivider(schema, context);
      case 'spacer':
        return _renderSpacer(schema, context);
      case 'container':
        return _renderContainer(schema, context, depth);
      case 'switch':
        return _renderSwitch(schema, context);
      case 'input':
        return _renderInput(schema, context);
      case 'icon':
        return _renderIcon(schema, context);
      case 'badge':
        return _renderBadge(schema, context);
      default:
        return _renderUnknown(schema, context);
    }
  }

  static Widget _renderColumn(
    Map<String, dynamic> schema,
    BuildContext context,
    int depth,
  ) {
    final children = (schema['children'] as List? ?? [])
        .map<Widget>(
          (c) => render(c as Map<String, dynamic>, context, depth + 1),
        )
        .toList();
    return Column(
      mainAxisAlignment: _parseMainAlignment(schema['mainAxisAlignment']),
      crossAxisAlignment: _parseCrossAlignment(schema['crossAxisAlignment']),
      mainAxisSize: schema['mainAxisSize'] == 'min'
          ? MainAxisSize.min
          : MainAxisSize.max,
      children: children,
    );
  }

  static Widget _renderRow(
    Map<String, dynamic> schema,
    BuildContext context,
    int depth,
  ) {
    final children = (schema['children'] as List? ?? [])
        .map<Widget>(
          (c) => render(c as Map<String, dynamic>, context, depth + 1),
        )
        .toList();
    return Row(
      mainAxisAlignment: _parseMainAlignment(schema['mainAxisAlignment']),
      crossAxisAlignment: _parseCrossAlignment(schema['crossAxisAlignment']),
      children: children,
    );
  }

  static Widget _renderText(Map<String, dynamic> schema, BuildContext context) {
    final text = _resolveText(schema['text'], context);
    final style = TextStyle(
      fontSize: (schema['fontSize'] as num?)?.toDouble() ?? 14,
      fontWeight: _parseFontWeight(schema['fontWeight']),
      color: _parseColor(schema['color'], context),
    );
    final maxLines = schema['maxLines'] as int?;
    final overflow = maxLines != null ? TextOverflow.ellipsis : null;
    return Text(text, style: style, maxLines: maxLines, overflow: overflow);
  }

  static Widget _renderButton(
    Map<String, dynamic> schema,
    BuildContext context,
  ) {
    final label = _resolveText(schema['label'], context);
    final action = schema['action'] as String?;
    final variant = schema['variant'] as String? ?? 'filled';
    final onPressed = action != null
        ? () => _handleAction(action, schema['params'])
        : null;

    if (variant == 'outlined') {
      return OutlinedButton(onPressed: onPressed, child: Text(label));
    } else if (variant == 'text') {
      return TextButton(onPressed: onPressed, child: Text(label));
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(backgroundColor: AppColors.acc(context)),
      child: Text(label),
    );
  }

  static Widget _renderCard(
    Map<String, dynamic> schema,
    BuildContext context,
    int depth,
  ) {
    final children = (schema['children'] as List? ?? [])
        .map<Widget>(
          (c) => render(c as Map<String, dynamic>, context, depth + 1),
        )
        .toList();
    return Card(
      margin: _parseEdgeInsets(schema['margin']),
      elevation: (schema['elevation'] as num?)?.toDouble() ?? 1,
      color: _parseColor(schema['color'], context),
      shape: RoundedRectangleBorder(
        borderRadius: _parseBorderRadius(schema['borderRadius']),
      ),
      child: Padding(
        padding:
            _parseEdgeInsets(schema['padding']) ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  static Widget _renderList(
    Map<String, dynamic> schema,
    BuildContext context,
    int depth,
  ) {
    final items = schema['items'] as List? ?? [];
    final itemTemplate = schema['itemTemplate'] as Map<String, dynamic>?;
    if (itemTemplate == null) return const SizedBox.shrink();

    return SizedBox(
      height: 400,
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index] as Map<String, dynamic>;
          final resolved = _resolveTemplate(
            itemTemplate,
            item,
          );
          return render(resolved, context, depth + 1);
        },
      ),
    );
  }

  static Widget _renderImage(
    Map<String, dynamic> schema,
    BuildContext context,
  ) {
    final src = schema['src'] as String? ?? '';
    final width = (schema['width'] as num?)?.toDouble();
    final height = (schema['height'] as num?)?.toDouble();
    final borderRadius = _parseBorderRadius(schema['borderRadius']);

    if (src.startsWith('http')) {
      final uri = Uri.tryParse(src);
      if (uri == null || !_allowedImageHosts.contains(uri.host)) {
        return _placeholder(width, height);
      }
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.network(
          src,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder(width, height),
        ),
      );
    }
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.asset(
        src,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(width, height),
      ),
    );
  }

  static Widget _placeholder(double? w, double? h) {
    return Container(width: w, height: h, color: const Color(0xFFE0E0E0));
  }

  static Widget _renderDivider(
    Map<String, dynamic> schema,
    BuildContext context,
  ) {
    return Divider(
      height: (schema['height'] as num?)?.toDouble() ?? 1,
      thickness: (schema['thickness'] as num?)?.toDouble() ?? 0.5,
    );
  }

  static Widget _renderSpacer(
    Map<String, dynamic> schema,
    BuildContext context,
  ) {
    final flex = (schema['flex'] as int?) ?? 1;
    return Spacer(flex: flex);
  }

  static Widget _renderContainer(
    Map<String, dynamic> schema,
    BuildContext context,
    int depth,
  ) {
    final child = schema['child'] as Map<String, dynamic>?;
    return Container(
      width: (schema['width'] as num?)?.toDouble(),
      height: (schema['height'] as num?)?.toDouble(),
      padding: _parseEdgeInsets(schema['padding']),
      margin: _parseEdgeInsets(schema['margin']),
      decoration: BoxDecoration(
        color: _parseColor(schema['color'], context),
        borderRadius: _parseBorderRadius(schema['borderRadius']),
        border: schema['border'] != null
            ? Border.all(
                color:
                    _parseColor(schema['border'], context) ??
                    Colors.transparent,
              )
            : null,
      ),
      child: child != null ? render(child, context, depth + 1) : null,
    );
  }

  static Widget _renderSwitch(
    Map<String, dynamic> schema,
    BuildContext context,
  ) {
    return SwitchListTile(
      title: Text(_resolveText(schema['label'], context)),
      value: schema['value'] as bool? ?? false,
      onChanged: schema['action'] != null
          ? (v) => _handleAction(schema['action'], {'value': v})
          : null,
      activeThumbColor: AppColors.acc(context),
    );
  }

  static Widget _renderInput(
    Map<String, dynamic> schema,
    BuildContext context,
  ) {
    return TextField(
      decoration: InputDecoration(
        hintText: _resolveText(schema['placeholder'], context),
        filled: true,
        fillColor: AppColors.sf(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static Widget _renderIcon(Map<String, dynamic> schema, BuildContext context) {
    final iconName = schema['name'] as String? ?? 'help';
    final size = (schema['size'] as num?)?.toDouble() ?? 24.0;
    final color = _parseColor(schema['color'], context);
    return Icon(_mapIcon(iconName), size: size, color: color);
  }

  static Widget _renderBadge(
    Map<String, dynamic> schema,
    BuildContext context,
  ) {
    final count = schema['count'] as int? ?? 0;
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.acc(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static Widget _renderUnknown(
    Map<String, dynamic> schema,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Unsupported: ${schema['type']}',
        style: TextStyle(fontSize: 12, color: AppColors.textTertiary(context)),
      ),
    );
  }

  static String _resolveText(dynamic text, BuildContext context) {
    if (text == null) return '';
    if (text is String) return text;
    if (text is Map) {
      final locale = localeProvider.locale.languageCode;
      return text[locale] ??
          text['en'] ??
          text.values.firstOrNull?.toString() ??
          '';
    }
    return text.toString();
  }

  static Map<String, dynamic> _resolveTemplate(
    Map<String, dynamic> template,
    Map<String, dynamic> data,
  ) {
    final result = <String, dynamic>{};
    for (final entry in template.entries) {
      if (entry.value is String) {
        var str = entry.value as String;
        for (final d in data.entries) {
          str = str.replaceAll('{{${d.key}}}', d.value.toString());
        }
        result[entry.key] = str;
      } else if (entry.value is Map<String, dynamic>) {
        result[entry.key] = _resolveTemplate(
          entry.value as Map<String, dynamic>,
          data,
        );
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  static void _handleAction(String? action, Map<String, dynamic>? params) {
    if (action == null) return;
    RemoteUIActionHandler.instance.handle(action, params ?? {});
  }

  static MainAxisAlignment _parseMainAlignment(dynamic value) {
    switch (value) {
      case 'center':
        return MainAxisAlignment.center;
      case 'end':
        return MainAxisAlignment.end;
      case 'spaceBetween':
        return MainAxisAlignment.spaceBetween;
      case 'spaceAround':
        return MainAxisAlignment.spaceAround;
      case 'spaceEvenly':
        return MainAxisAlignment.spaceEvenly;
      default:
        return MainAxisAlignment.start;
    }
  }

  static CrossAxisAlignment _parseCrossAlignment(dynamic value) {
    switch (value) {
      case 'center':
        return CrossAxisAlignment.center;
      case 'end':
        return CrossAxisAlignment.end;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      default:
        return CrossAxisAlignment.start;
    }
  }

  static FontWeight _parseFontWeight(dynamic value) {
    switch (value) {
      case 'bold':
        return FontWeight.bold;
      case 'w300':
        return FontWeight.w300;
      case 'w500':
        return FontWeight.w500;
      case 'w600':
        return FontWeight.w600;
      case 'w700':
        return FontWeight.w700;
      case 'w900':
        return FontWeight.w900;
      default:
        return FontWeight.normal;
    }
  }

  static Color? _parseColor(dynamic value, BuildContext context) {
    if (value == null) return null;
    if (value is String) {
      switch (value) {
        case 'accent':
          return AppColors.acc(context);
        case 'primary':
          return AppColors.textPrimary(context);
        case 'secondary':
          return AppColors.textSecondary(context);
        case 'tertiary':
          return AppColors.textTertiary(context);
        case 'surface':
          return AppColors.sf(context);
        case 'background':
          return AppColors.bg(context);
        case 'error':
          return AppColors.dng(context);
        default:
          if (value.startsWith('#')) return _hexToColor(value);
          return null;
      }
    }
    return null;
  }

  static Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  static EdgeInsets? _parseEdgeInsets(dynamic value) {
    if (value == null) return null;
    if (value is num) return EdgeInsets.all(value.toDouble());
    if (value is List && value.length >= 4) {
      return EdgeInsets.fromLTRB(
        (value[0] as num).toDouble(),
        (value[1] as num).toDouble(),
        (value[2] as num).toDouble(),
        (value[3] as num).toDouble(),
      );
    }
    return null;
  }

  static BorderRadius _parseBorderRadius(dynamic value) {
    if (value == null) return BorderRadius.zero;
    if (value is num) return BorderRadius.circular(value.toDouble());
    return BorderRadius.zero;
  }

  static IconData _mapIcon(String name) {
    const icons = <String, IconData>{
      'settings': Icons.settings,
      'home': Icons.home,
      'search': Icons.search,
      'chat': Icons.chat,
      'person': Icons.person,
      'group': Icons.group,
      'notifications': Icons.notifications,
      'close': Icons.close,
      'add': Icons.add,
      'delete': Icons.delete,
      'edit': Icons.edit,
      'share': Icons.share,
      'download': Icons.download,
      'upload': Icons.upload,
      'mic': Icons.mic,
      'send': Icons.send,
      'link': Icons.link,
      'image': Icons.image,
      'file': Icons.insert_drive_file,
      'help': Icons.help,
      'info': Icons.info,
      'check': Icons.check,
      'warning': Icons.warning,
      'error': Icons.error,
    };
    return icons[name] ?? Icons.help;
  }
}

class RemoteUIActionHandler {
  static final RemoteUIActionHandler _instance = RemoteUIActionHandler._();
  static RemoteUIActionHandler get instance => _instance;
  RemoteUIActionHandler._();

  final Map<String, Future<void> Function(Map<String, dynamic>)> _handlers = {};

  void register(
    String action,
    Future<void> Function(Map<String, dynamic>) handler,
  ) {
    _handlers[action] = handler;
  }

  void handle(String action, Map<String, dynamic> params) {
    final handler = _handlers[action];
    if (handler == null) return;
    handler(params).catchError((e) {
      AppLogger.instance.warning(
        'RemoteUI action handler failed: $action',
        error: e,
      );
    });
  }
}
