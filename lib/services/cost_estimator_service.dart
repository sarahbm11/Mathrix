import 'dart:io';

import 'package:image/image.dart' as img;

import '../models/cost_estimate.dart';
import 'claude_api_service.dart';

/// Estimation approximative du coût d'un appel d'extraction de notes,
/// avant envoi, pour informer l'étudiante (cf. CLAUDE.md : "informer
/// l'utilisatrice du nombre de frames qui seront envoyées avant
/// confirmation d'extraction").
///
/// Tarifs claude-sonnet-4-6 : 3 $ / million de tokens en entrée,
/// 15 $ / million de tokens en sortie. Le coût des images suit la formule
/// documentée par Anthropic : tokens ≈ (largeur × hauteur) / 750.
class CostEstimatorService {
  static const _inputPricePerMillionTokens = 3.0;
  static const _outputPricePerMillionTokens = 15.0;

  /// Tokens de sortie estimés par frame (transcription Markdown d'une page
  /// de cahier) : une approximation, le contenu réel varie selon la
  /// densité d'écriture de la page.
  static const _estimatedOutputTokensPerFrame = 350;

  Future<CostEstimate> estimateExtractionCost({
    required List<String> framePaths,
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final batchCount =
        (framePaths.length / ClaudeApiService.maxFramesPerRequest).ceil();

    var imageTokens = 0;
    for (final path in framePaths) {
      final bytes = await File(path).readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) continue;
      imageTokens += ((image.width * image.height) / 750).ceil();
    }

    // Le system prompt et le prompt utilisateur sont envoyés une fois par
    // lot (chaque lot est une requête /v1/messages indépendante).
    final promptTokensPerBatch =
        _estimateTextTokens(systemPrompt) + _estimateTextTokens(userPrompt);
    final inputTokens =
        imageTokens + (promptTokensPerBatch * batchCount);

    final outputTokens = framePaths.length * _estimatedOutputTokensPerFrame;

    final costUsd = (inputTokens / 1000000 * _inputPricePerMillionTokens) +
        (outputTokens / 1000000 * _outputPricePerMillionTokens);

    return CostEstimate(
      frameCount: framePaths.length,
      batchCount: batchCount,
      estimatedInputTokens: inputTokens,
      estimatedOutputTokens: outputTokens,
      estimatedCostUsd: costUsd,
    );
  }

  /// Heuristique grossière (~4 caractères par token) pour estimer la
  /// taille en tokens d'un texte, sans appeler l'API.
  int _estimateTextTokens(String text) => (text.length / 4).ceil();
}
