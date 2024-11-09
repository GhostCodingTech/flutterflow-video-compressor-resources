
import 'dart:io';
import 'package:video_compress/video_compress.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

Future<void> compressAndUploadVideo(
    String videoPath, String apiKey, String libraryId, String videoId) async {
  // Step 1: Update status to compressing
  FFAppState().update(() {
    FFAppState().statusText = "Compressing video";
    FFAppState().uploadProgress = 0.0;
  });

  // Step 2: Set up a listener for compression progress
  final subscription = VideoCompress.compressProgress$.subscribe((progress) {
    // Update app state with compression progress
    FFAppState().update(() {
      FFAppState().uploadProgress = progress / 100.0; // normalize to 0.0 - 1.0
    });
  });

  // Step 3: Compress the video
  final info = await VideoCompress.compressVideo(
    videoPath,
    quality: VideoQuality.HighestQuality,
    deleteOrigin: false,
  );

  // Remove the subscription after compression is complete
  subscription.unsubscribe();

  // Check if compression was successful
  final compressedVideoPath = info?.file?.path;
  if (compressedVideoPath == null) {
    print('Video compression failed');
    FFAppState().update(() {
      FFAppState().statusText = "Compression failed";
      FFAppState().uploadProgress = 0.0;
    });
    return;
  }

  // Step 4: Update status to uploading
  FFAppState().update(() {
    FFAppState().statusText = "Uploading video";
    FFAppState().uploadProgress = 0.0;
  });

  // Step 5: Upload the compressed video to Bunny CDN
  var url = Uri.parse(
      'https://video.bunnycdn.com/library/$libraryId/videos/$videoId');
  var file = File(compressedVideoPath);
  var fileSize = await file.length();
  var fileStream = file.openRead();

  var request = http.StreamedRequest('PUT', url)
    ..headers.addAll({
      'AccessKey': apiKey,
      'Content-Type': 'application/octet-stream',
    });

  int bytesSent = 0;

  fileStream.listen((chunk) {
    bytesSent += chunk.length;
    var uploadProgress = bytesSent / fileSize;

    FFAppState().update(() {
      FFAppState().uploadProgress = uploadProgress;
    });

    request.sink.add(chunk);
  }, onDone: () async {
    await request.sink.close();
  });
  FFAppState().update(() {
    FFAppState().statusText = "Processing Upload";
  });
  var response = await request.send();

  if (response.statusCode == 200) {
    print('Video uploaded successfully');
  } else {
    print('Failed to upload video. Status code: ${response.statusCode}');
  }

  // Step 6: Delete the temporary compressed video file
  try {
    await file.delete();
    print('Temporary compressed video file deleted');
  } catch (e) {
    print('Failed to delete temporary file: $e');
  }
}
