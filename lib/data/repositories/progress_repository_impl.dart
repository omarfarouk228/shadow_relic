import 'dart:convert';

import '../../domain/entities/game_progress.dart';
import '../../domain/repositories/progress_repository.dart';
import '../datasources/progress_local_source.dart';
import '../models/game_progress_model.dart';

class LocalProgressRepository implements ProgressRepository {
  LocalProgressRepository(this._source);

  final ProgressLocalSource _source;

  @override
  Future<GameProgress?> load() async {
    final raw = await _source.read();
    if (raw == null) return null;
    try {
      return GameProgressModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null; // sauvegarde corrompue : on repart de zéro
    }
  }

  @override
  Future<void> save(GameProgress progress) =>
      _source.write(jsonEncode(GameProgressModel.toJson(progress)));

  @override
  Future<void> clear() => _source.delete();
}
