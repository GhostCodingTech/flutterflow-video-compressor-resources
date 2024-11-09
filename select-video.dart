import 'package:image_picker/image_picker.dart';

Future<String> selectVideo() async {
  // Using image picker get video path

  final ImagePicker _picker = ImagePicker();
  final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);

  if (video != null) {
    return video.path;
  } else {
    throw Exception('No video selected');
  }
}
