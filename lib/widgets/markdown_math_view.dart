import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Découpe [text] en segments Markdown et LaTeX (délimité par $$...$$ ou
/// $...$) et rend chaque segment avec le widget approprié. Permet
/// d'afficher les notes extraites et les réponses du tuteur, qui mélangent
/// les deux conventions, sans dépendance à une extension markdown custom.
class MarkdownMathView extends StatelessWidget {
  final String text;

  const MarkdownMathView({super.key, required this.text});

  static final _mathPattern = RegExp(r'\$\$(.+?)\$\$|\$(.+?)\$', dotAll: true);

  @override
  Widget build(BuildContext context) {
    final segments = <Widget>[];
    int lastEnd = 0;

    for (final match in _mathPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        segments.add(_markdownSegment(text.substring(lastEnd, match.start)));
      }
      final isBlock = match.group(1) != null;
      final formula = (match.group(1) ?? match.group(2))!.trim();
      segments.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Math.tex(
          formula,
          textStyle: TextStyle(fontSize: isBlock ? 18 : 16),
          onErrorFallback: (err) => Text(formula),
        ),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      segments.add(_markdownSegment(text.substring(lastEnd)));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: segments);
  }

  Widget _markdownSegment(String segment) {
    if (segment.trim().isEmpty) return const SizedBox.shrink();
    return MarkdownBody(data: segment);
  }
}
