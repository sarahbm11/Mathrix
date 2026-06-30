import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';

final _mathPattern = RegExp(r'\$\$(.+?)\$\$|\$(.+?)\$', dotAll: true);

/// Description légère d'un segment de texte (Markdown ou formule LaTeX),
/// sans construire le widget correspondant. Le découpage (regex) est bon
/// marché même sur un long document ; c'est la construction des widgets
/// (en particulier Math.tex, qui parse le LaTeX) qui est coûteuse et doit
/// être différée au moment où le segment devient réellement visible.
class _Segment {
  final bool isMath;
  final bool isBlock;
  final String content;

  const _Segment.markdown(this.content) : isMath = false, isBlock = false;
  const _Segment.math(this.content, this.isBlock) : isMath = true;
}

List<_Segment> _splitSegments(String text) {
  final segments = <_Segment>[];
  int lastEnd = 0;

  for (final match in _mathPattern.allMatches(text)) {
    if (match.start > lastEnd) {
      segments.add(_Segment.markdown(text.substring(lastEnd, match.start)));
    }
    final isBlock = match.group(1) != null;
    final formula = (match.group(1) ?? match.group(2))!.trim();
    segments.add(_Segment.math(formula, isBlock));
    lastEnd = match.end;
  }
  if (lastEnd < text.length) {
    segments.add(_Segment.markdown(text.substring(lastEnd)));
  }

  return segments;
}

Widget _buildSegmentWidget(_Segment segment) {
  if (!segment.isMath) {
    if (segment.content.trim().isEmpty) return const SizedBox.shrink();
    return MarkdownBody(data: segment.content);
  }
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Math.tex(
      segment.content,
      textStyle: TextStyle(fontSize: segment.isBlock ? 18 : 16),
      onErrorFallback: (err) => Text(segment.content),
    ),
  );
}

/// Affiche [text] (Markdown + LaTeX) dans une simple colonne. Adapté aux
/// contenus courts qui sont déjà dans une liste défilante parente (ex. une
/// bulle de message de chat) : construire tous les segments d'un coup y
/// reste bon marché.
class MarkdownMathView extends StatelessWidget {
  final String text;

  const MarkdownMathView({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _splitSegments(text).map(_buildSegmentWidget).toList(),
    );
  }
}

/// Affiche [text] (Markdown + LaTeX) dans une liste défilante paresseuse.
/// Le découpage en segments (regex, bon marché) se fait une fois, mais
/// chaque widget de segment — en particulier Math.tex, dont la
/// construction parse le LaTeX et n'est pas gratuite — n'est créé que pour
/// les segments visibles, via itemBuilder. Chaque segment est en plus
/// isolé dans son propre RepaintBoundary pour éviter de redessiner tout le
/// rendu LaTeX à chaque frame de scroll. Adapté aux contenus longs (notes
/// extraites complètes d'un chapitre), pour lesquels construire tous les
/// widgets d'un coup avant l'affichage causait un blocage perceptible à
/// l'ouverture de l'écran.
class MarkdownMathListView extends StatelessWidget {
  final String text;
  final EdgeInsets padding;

  const MarkdownMathListView({
    super.key,
    required this.text,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final segments = _splitSegments(text);
    return ListView.builder(
      padding: padding,
      itemCount: segments.length,
      itemBuilder: (context, i) =>
          RepaintBoundary(child: _buildSegmentWidget(segments[i])),
    );
  }
}
