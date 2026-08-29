import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract final class FileService {
  static Future<Directory> appDocs() => getApplicationDocumentsDirectory();
  static Future<Directory> temp() => getTemporaryDirectory();

  static Future<File> writeTemp(String name, List<int> bytes) async {
    final dir = await temp();
    final f = File('${dir.path}/$name');
    return f.writeAsBytes(bytes);
  }
}
