import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../theme/app_colors.dart';
import '../../theme/locale_cubit.dart';

class LinkPreviewCard extends StatelessWidget {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;

  const LinkPreviewCard({
    super.key,
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.bg2(context)),
        borderRadius: BorderRadius.circular(8)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Image.network(
                    imageUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink())),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        description!,
                        style: TextStyle(
                          color: AppColors.textSecondary(context),
                          fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      Uri.tryParse(url)?.host ?? url,
                      style: TextStyle(
                        color: AppColors.sec(context),
                        fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  ])),
            ])),
      ),
    );
  }
}

class HighlightedText extends StatelessWidget {
  final String text;
  final int highlightStart;
  final int highlightLength;

  const HighlightedText({
    super.key,
    required this.text,
    required this.highlightStart,
    required this.highlightLength,
  });

  @override
  Widget build(BuildContext context) {
    if (highlightStart < 0 ||
        highlightStart >= text.length ||
        highlightLength <= 0) {
      return Text(text, style: TextStyle(color: AppColors.textPrimary(context), fontSize: 15));
    }
    final end = (highlightStart + highlightLength).clamp(0, text.length);
    final before = text.substring(0, highlightStart);
    final highlighted = text.substring(highlightStart, end);
    final after = text.substring(end);

    return RichText(
      text: TextSpan(
        style: TextStyle(color: AppColors.textPrimary(context), fontSize: 15),
        children: [
          if (before.isNotEmpty) TextSpan(text: before),
          TextSpan(
            text: highlighted,
            style: TextStyle(
              color: AppColors.acc(context),
              backgroundColor: AppColors.acc(context).withValues(alpha: 0.2))),
          if (after.isNotEmpty) TextSpan(text: after),
        ]));
  }
}

List<InlineSpan> buildTextWithLinks(String text, BuildContext context) {
  final urlRegex = RegExp(r'https?://[^\s<>"{}|\\^`\[\]]+');
  final spans = <InlineSpan>[];
  var lastEnd = 0;

  for (final match in urlRegex.allMatches(text)) {
    if (match.start > lastEnd) {
      spans.add(TextSpan(
        text: text.substring(lastEnd, match.start),
        style: TextStyle(color: AppColors.textPrimary(context), fontSize: 15)));
    }
    spans.add(TextSpan(
      text: match.group(0),
      style: TextStyle(color: AppColors.sec(context), fontSize: 15),
      recognizer: TapGestureRecognizer()..onTap = () {}));
    lastEnd = match.end;
  }

  if (lastEnd < text.length) {
    spans.add(TextSpan(
      text: text.substring(lastEnd),
      style: TextStyle(color: AppColors.textPrimary(context), fontSize: 15)));
  }

  if (spans.isEmpty) {
    spans.add(TextSpan(
      text: text,
      style: TextStyle(color: AppColors.textPrimary(context), fontSize: 15)));
  }

  return spans;
}
