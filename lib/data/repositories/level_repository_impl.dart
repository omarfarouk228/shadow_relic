import '../../domain/entities/level_grid.dart';
import '../../domain/repositories/level_repository.dart';
import '../datasources/ascii_level_data.dart';
import '../datasources/ascii_level_parser.dart';

class AsciiLevelRepository implements LevelRepository {
  const AsciiLevelRepository({this.rows = levelRows});

  final List<String> rows;

  @override
  LevelGrid loadLevel() => parseAsciiLevel(rows);
}
