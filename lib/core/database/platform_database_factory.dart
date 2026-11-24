import 'platform_database_factory_stub.dart'
    if (dart.library.js_interop) 'platform_database_factory_web.dart'
    if (dart.library.io) 'platform_database_factory_io.dart';

void initPlatformDatabaseFactory() {
  initPlatformDatabaseFactoryImpl();
}

