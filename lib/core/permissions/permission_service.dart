import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestCamera() async =>
      (await Permission.camera.request()).isGranted;
  Future<bool> requestPhotos() async =>
      (await Permission.photos.request()).isGranted;
  Future<bool> requestNotification() async =>
      (await Permission.notification.request()).isGranted;

  Future<bool> isGranted(Permission p) async => (await p.status).isGranted;
}
