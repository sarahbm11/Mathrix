/// Prompt envoyé à Claude (modèle vision) pour transcrire fidèlement le
/// contenu d'une page de cahier manuscrite, conformément aux exigences de
/// fidélité de notation décrites dans CLAUDE.md.
const String extractionPrompt = '''
Tu reçois une ou plusieurs photos de pages d'un cahier de notes manuscrites de
mathématiques (calcul différentiel ou algèbre linéaire, niveau Cégep).

Retranscris EXACTEMENT le contenu de chaque page, tel qu'écrit, sans corriger,
reformuler, ni compléter ce qui semble manquant :

- Conserve la notation mathématique exacte utilisée (symboles, lettres,
  conventions), même si une autre notation est plus standard.
- Conserve les justifications, remarques et exemples dans l'ordre où ils
  apparaissent.
- Écris les formules en LaTeX, en notation inline (\$...\$) pour les formules
  dans le texte et en notation bloc (\$\$...\$\$) pour les formules isolées.
- Utilise le Markdown pour la structure (titres de section, listes) si le
  cahier présente une structure visible.
- Si un passage est illisible, indique-le explicitement entre crochets
  (ex. [illisible]) plutôt que de deviner ou d'inventer le contenu.

Ne produis que la transcription Markdown, sans commentaire ni résumé de ta part.
''';
