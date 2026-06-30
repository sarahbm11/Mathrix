/// Estimation du coût d'un appel d'extraction de notes, affichée à
/// l'étudiante avant confirmation d'envoi (cf. CLAUDE.md : informer du
/// nombre de frames et du coût avant d'envoyer à l'API vision).
class CostEstimate {
  final int frameCount;
  final int batchCount;
  final int estimatedInputTokens;
  final int estimatedOutputTokens;
  final double estimatedCostUsd;

  const CostEstimate({
    required this.frameCount,
    required this.batchCount,
    required this.estimatedInputTokens,
    required this.estimatedOutputTokens,
    required this.estimatedCostUsd,
  });
}
