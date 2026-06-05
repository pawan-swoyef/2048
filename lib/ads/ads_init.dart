// Initializes the mobile ads SDK on dart:io platforms; no-op on web.
export 'ads_init_stub.dart' if (dart.library.io) 'ads_init_io.dart';
