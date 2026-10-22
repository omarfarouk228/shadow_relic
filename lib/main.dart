import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'injection.dart';
import 'presentation/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ShadowRelicApp(gameFactory: createGame));
}
