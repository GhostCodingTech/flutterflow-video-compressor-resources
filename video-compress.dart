
import 'dart:io';
import 'package:video_compress/video_compress.dart';
import 'dart:async';

Future<String?> compressVideo(String videoPath) async {
  // Update status to "Compressing video"
  FFAppState().update(() {
    FFAppState().statusText = "Compressing video";
    FFAppState().uploadProgress = 0.0;
  });

  // Step 1: Set up a listener for compression progress
  final subscription = VideoCompress.compressProgress$.subscribe((progress) {
    // Update app state with compression progress
    FFAppState().update(() {
      FFAppState().uploadProgress = progress / 100.0; // normalize to 0.0 - 1.0
    });
  });

  // Step 2: Compress the video
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
    return null;
  }

  // Update status to indicate compression completion
  FFAppState().update(() {
    FFAppState().statusText = "Compression complete";
    FFAppState().uploadProgress = 1.0;
  });

  return compressedVideoPath;
}
