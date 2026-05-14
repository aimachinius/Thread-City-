import 'package:flutter/material.dart';

class HashtagTextEditingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    List<TextSpan> children = [];
    final text = this.text;

    // Phân tích và highlight các từ bắt đầu bằng dấu #
    text.splitMapJoin(
      RegExp(r'#[^\s#.,!?]+'),
      onMatch: (Match match) {
        children.add(
          TextSpan(
            text: match[0],
            style: style?.copyWith(color: Colors.blueAccent, fontWeight: FontWeight.w600),
          ),
        );
        return '';
      },
      onNonMatch: (String text) {
        children.add(TextSpan(text: text, style: style));
        return '';
      },
    );

    return TextSpan(style: style, children: children);
  }
}
