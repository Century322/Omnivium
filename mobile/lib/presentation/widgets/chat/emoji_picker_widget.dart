import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/locale_cubit.dart';

class EmojiPickerWidget extends StatelessWidget {
  final ValueChanged<String> onEmojiSelected;
  final VoidCallback? onClose;

  const EmojiPickerWidget({
    super.key,
    required this.onEmojiSelected,
    this.onClose,
  });

  static const _emojis = [
    '😀', '😂', '🥹', '😊', '😍', '🥰', '😘', '😜',
    '🤔', '😏', '😢', '😭', '😤', '🤯', '🥳', '😴',
    '👍', '👎', '👏', '🙌', '🤝', '❤️', '🔥', '⭐',
    '🎉', '💪', '🙏', '✨', '💯', '🌈', '🎵', '🌟',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      color: AppColors.sf(context),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onClose != null)
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textSecondary(context), size: 20),
                  onPressed: onClose),
            ]),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4),
              itemCount: _emojis.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () => onEmojiSelected(_emojis[index]),
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    child: Text(_emojis[index], style: const TextStyle(fontSize: 24)),
                  ),
                );
              }),
          ),
        ],
      ),
    );
  }
}
