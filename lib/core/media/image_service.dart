import 'package:image_picker/image_picker.dart';

class ImageService {
  ImageService(this._picker);
  final ImagePicker _picker;

  Future<XFile?> pickFromGallery() =>
      _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
  Future<XFile?> pickFromCamera() =>
      _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
}
