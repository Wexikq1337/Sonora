import 'package:flutter/material.dart';

import 'app.dart';
import 'ui/glass/glass_shaders.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Runtime shader is optional: if the platform cannot compile it, glass falls
  // back to gradients + borders and the app still runs.
  await GlassShaders.load();
  runApp(const SonoraApp());
}
