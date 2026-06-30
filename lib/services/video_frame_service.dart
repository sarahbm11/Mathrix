import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Extrait des frames d'une vidéo locale à intervalle régulier, puis
/// déduplique les frames quasi identiques pour limiter le nombre d'images
/// envoyées à l'API Claude (coût des appels vision).
class VideoFrameService {
  /// Largeur maximale (px) des frames extraites. 1568px est la dimension
  /// maximale au-delà de laquelle Claude vision redimensionne de toute
  /// façon les images en entrée — extraire plus grand n'apporte rien et
  /// alourdit inutilement la requête (risque de 413 "request too large"
  /// avec plusieurs frames en pleine résolution).
  static const _maxFrameWidth = 1568;

  /// Extrait une frame toutes les [intervalSeconds] secondes de [videoPath],
  /// redimensionnée et compressée en JPEG, et retourne la liste des chemins
  /// de fichiers générés, dans l'ordre.
  Future<List<String>> extractFrames(
    String videoPath, {
    double intervalSeconds = 1.0,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final framesDir = Directory(
      '${tempDir.path}/frames_${DateTime.now().millisecondsSinceEpoch}',
    );
    await framesDir.create(recursive: true);

    final outputPattern = '${framesDir.path}/frame_%05d.jpg';
    final fps = 1 / intervalSeconds;
    final command = '-i "$videoPath" '
        '-vf "fps=$fps,scale=\'min($_maxFrameWidth,iw)\':-2" '
        '-vsync 0 -q:v 4 "$outputPattern"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      throw Exception('Échec de l\'extraction de frames (ffmpeg) : $logs');
    }

    final files = framesDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.jpg'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    return files.map((f) => f.path).toList();
  }

  /// Filtre une liste de chemins de frames pour ne garder que celles qui
  /// diffèrent suffisamment de la précédente conservée (déduplication par
  /// similarité de pixels). [threshold] est la différence moyenne par pixel
  /// (0-255) en dessous de laquelle deux frames sont jugées quasi identiques.
  Future<List<String>> deduplicateFrames(
    List<String> framePaths, {
    double threshold = 8.0,
  }) async {
    if (framePaths.isEmpty) return [];

    final kept = <String>[framePaths.first];
    img.Image? previous = img.decodeImage(
      await File(framePaths.first).readAsBytes(),
    );

    for (var i = 1; i < framePaths.length; i++) {
      final current = img.decodeImage(
        await File(framePaths[i]).readAsBytes(),
      );
      if (current == null) continue;
      if (previous == null || _averageDiff(previous, current) > threshold) {
        kept.add(framePaths[i]);
        previous = current;
      }
    }

    return kept;
  }

  /// Différence moyenne par pixel entre deux images, sur une grille
  /// sous-échantillonnée (rapide, suffisant pour détecter des pages
  /// de cahier différentes vs frames de transition/flou).
  double _averageDiff(img.Image a, img.Image b) {
    const sampleSize = 32;
    final aResized = img.copyResize(a, width: sampleSize, height: sampleSize);
    final bResized = img.copyResize(b, width: sampleSize, height: sampleSize);

    double totalDiff = 0;
    for (var y = 0; y < sampleSize; y++) {
      for (var x = 0; x < sampleSize; x++) {
        final pa = aResized.getPixel(x, y);
        final pb = bResized.getPixel(x, y);
        totalDiff += (pa.r - pb.r).abs() +
            (pa.g - pb.g).abs() +
            (pa.b - pb.b).abs();
      }
    }
    return totalDiff / (sampleSize * sampleSize * 3);
  }
}
