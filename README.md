<div align="center">
  <br />
    <a href="https://youtu.be/W8ZuA6cetR0" target="_blank">
      <img src="https://ghost-coding.b-cdn.net/ghost-coding/video-compression/FlutterFlow%20(1).png" alt="Project Banner">
    </a>
  <br />

  <h3 align="center">FlutterFlow Video Compression</h3>

   <div align="center">
    Join me as we add video compression to our FlutterFlow application and upload it to BunnyCDN by following the detailed tutorial <a href="https://www.youtube.com/@GhostCoding_" target="_blank"><b>Ghost Coding</b></a> YouTube. Don't forget to like, subscribe and hit the notifications button!
    </div>
</div>

## 🚨 Tutorial

This repository contains the code corresponding to an in-depth tutorial available on our YouTube channel, <a href="https://www.youtube.com/@GhostCoding_" target="_blank"><b>Ghost Coding</b></a>. 

If you prefer visual learning, this is the perfect resource for you. Follow our tutorial to learn how to add video compression to your FlutterFlow app!

<a href="https://youtu.be/W8ZuA6cetR0" target="_blank"><img src="https://github.com/sujatagunale/EasyRead/assets/151519281/1736fca5-a031-4854-8c09-bc110e3bc16d" /></a>

## <a name="introduction">🤖 Introduction</a>

Using custom actions select a video, compress it, and then upload it to BunnyCDN. We will update app states in FlutterFlow directly from our code to provide a great user experience to track the progress

If you're getting started and need assistance or face any bugs, join our active Discord community. It's a place where people help each other out.

<a href="https://discord.gg/SATshHCGg8" target="_blank"><img src="https://github.com/sujatagunale/EasyRead/assets/151519281/618f4872-1e10-42da-8213-1d69e486d02e" /></a>

## <a name="tech-stack">⚙️ Tech Stack</a>

- Next.js
- TypeScript
- FlutterFlow
- BunnyCDN
- Firebase

## <a name="features">🔋 Features</a>

👉 **Create Collection**: Create collections in your BunnyCDN Video Library by making an API call directly from FlutterFlow or skip to learning how to code your own API in Nextjs to where you can make the API call to keep your keys more secure

👉 **Create Video**: Create your video and associate it with your collectionID in your BunnyCDN Video Library by making an API call directly from FlutterFlow or skip to learning how to code your own API in Nextjs to where you can make the API call to keep your keys more secure

👉 **Compressing-Video and upload**
   - **Select Video**: We'll use a custom action to select a video from our device
   - **Compress Video**: Using the path for the video we will compress the video and create a temporary file path
   - **Subscribe to video compression**: We'll add an additional action to subscribe to the video compression progress and update an app state to track and display it to the user
   - **Upload to Bunny**: We'll finally upload it to bunny

👉 **Get VideoURL and ThumbnailURL**: Using combined text and responses from our API's we'll update our Firebase document with the videoUrl and the thumbnailUrl

👉 **Webhook**: Finally to make the process faster for the user and not be stuck on the same screen for too long, we will be using a webhook to update our Firebase when the video upload has been successfully processed with bunny



**Prerequisites**

Make sure you have the following installed on your machine:

- [Git](https://git-scm.com/)
- [Node.js](https://nodejs.org/en)
- [npm](https://www.npmjs.com/) (Node Package Manager)
- [Visual Studio Code](https://code.visualstudio.com)
- [BunnyCDN](https://bunny.net?ref=6qsfs3fi0p)



## <a name="snippets">🕸️ Snippets</a>

<details>
<summary><code>select-video.dart</code></summary>

```dart
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
```

</details>

<details>
<summary><code>video-compress-and-upload.dart</code></summary>

```dart

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
```

</details>

<details>
<summary><code>video-compress</code></summary>

```dart
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
```

</details>

<details>
<summary><code>api/webhook/route.ts</code></summary>

```typescript
import admin from 'firebase-admin';
import { NextRequest, NextResponse } from 'next/server';

if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert({
            
            projectId: "video-upload-server",
            privateKey: "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDgp16+4UDY013o\nMAfvWwEtS4tDd3e7nruPAxR3KxgPcsyQDZs8E6FQSrKCYSj1m0u5uUrnQU0gkgnk\nt+NUHESBdZvd4+IXQSs8ak8jji5iI7dW+vnTJwoqhoRj+b96PNu8BC87vJeoTpU9\nBKW/3LICxz1i4vm5zPGIbtHhIhpXpdOjMfTIPa1PxWe7wpgpnQjNOYAOF3dlRNYR\n+ocTqKiMkOegpQdpRxXimC2KytCV0TEQ9kgzrcDbrDozKqpXvpu6HUiQyOQlc+eY\n16BvraKDvGkUT/7Vdbn/PjYrA64wzj8JmRKSdnG9CvhtQ58tmj97U6tMNbzSq39e\n+M70KoupAgMBAAECggEAFlKLJ4xaVTErc5bSMwZn54hKHjoQu6PaHyu/LNgrW92c\nVfQEKMQKk1/YvPvKhh0YOSwgNTpX35SjRwa+n+zvIa39/t5V6Nmg4i/uDSpjkXzb\nCtmFWWXXrMIRBZ4bWJoTe2svBlCHAUJNsfJ0Rcw4I+6IOvsytTOYDGZ2lFg/JdY0\ntn/VDhr4GtECTvC3si3CUKuzTEsucKTUh7l1LDfj3F3ADf08+iNzTc8QPcleRplF\nDV/8eajg8HcPOiOQjUj2To9cdHn7p0bzEyI5aq7qjtuxTipyjB8/6MBJ+MbpSjfx\nlcTwMQvmKkjQE7CHo9ls8vRNWlspkagwPephpqwoAQKBgQD0b0U2zvJbv9geUOEp\nSkHnB8g76I+qovlV69sJuC+Wf1b2gRA1qcjHCqBX2WSr9h/k0DjfeV7+vte3oPAP\n+EDcmW0ie99owP47vlMfu1sdHLkPz1nfB8hQBLTR5FB/4Ql3lXaktbR+tdXiFCKX\n0CZt+65cY0i/uWMnBVGRImhMGQKBgQDrSIC66PB/4VZxC8ikORZlIpyCu0pdl2UV\n/A9CAkV9cSw+qC3cx6dLBSmaD//Fpa+U9G8G2s4G7zprQFmh4zSkag6xkTMRrA//\nHPuEmZO69EprH2OKeVJdtpkCbQikhI44wyGQ2cQuihP47EoYzgANZS3Jnb2o8FQ4\nqR4jXDkuEQKBgE4XxpsuHswlTJzS5jzU1p1DJTvOnye7DcHfqok+aSXB5Ty4Gz+p\n0NWWlYe7kqhF6AaoZ6MuGaV1v2GRb2EKxV41PmLIBKZpElBwDAqVRxTT+mQMsP/K\ncrrt5f8w3G8erHGiNNeGnfXljkG+gRbTj5OP1zL5HWLzjbQHxPmDbqLxAoGAJfU7\nd2wPKMJk3LYG95+SIlzUHS80DydWkpZoq8CMD3HLrowZYg3/ylWZ4ZYFMJDLY9+P\nbe6s4GeF6DmofDqYipHlrvX65DX7GrBFT54rPDUfMGsO9w8dn6rOwppuk4QjIbsx\nVhob0VpLYJRWW+wYDBEvsuA08eVb4Qw/pXrCatECgYBmvLlDwR6X6bkz2FgdT0Ej\ndxBw7vS7ufrXRFsr7boEea7KjcPGAaOGd/Rai0XTYAVOQBe9+neM9AgnStU9moPK\nwc4gE8zMxtwdB6YQmJM4HQGtIxET1s+DMDprMG2vAcrrfsrQHAcJgyD8BQi9Koxg\n+aHIACUKwZIePNZfXGhrpw==\n-----END PRIVATE KEY-----\n",
            clientEmail: "firebase-adminsdk-tz5eu@video-upload-server.iam.gserviceaccount.com",
            
        }),
    });
}

const db = admin.firestore();

export async function POST(req: NextRequest) {
    try {
        const requestBody = await req.json();
        console.log('Data received from BunnyCDN:', requestBody);

        const { VideoGuid, Status } = requestBody;

        if (Status === 3 || Status === 5) {
            const videoRef = db.collection('video-uploads');
            const snapshot = await videoRef.where("videoguid", "==", VideoGuid).get();

            if(snapshot.empty) {
                console.log('Video not found in Firestore');
                return NextResponse.json({ error: 'Video not found' }, { status: 404 });
            }

            const doc = snapshot.docs[0];
            if (Status === 3) {
                console.log('Video successfully uploaded to Bunny and updating document for VideoGuid: ', VideoGuid, "setting draft to false");
                await doc.ref.update({ draft: false });
            } else if (Status === 5) {
                console.log('Video failed to upload to Bunny and updating document for VideoGuid: ', VideoGuid, "setting uploadFailed to true");
                await doc.ref.update({ uploadFailed: true });
            }
            console.log('Webhook processed successfully for videoguid: ', VideoGuid);
            return NextResponse.json({ message: 'Webhook processed successfully' }, { status: 200 });

        } else {
            console.log('No action taken for Status: ', Status, "with VideoGuid: ", VideoGuid);
            return NextResponse.json({ message: 'No action taken' }, { status: 200 });
        }


    } catch (error) {
        console.error('Webhook Error:', error);
        return NextResponse.json({ error: 'An error occurred' }, { status: 500 });
    }
    


}
```

</details>

<details>
<summary><code>components/DeleteModal.tsx</code></summary>

```typescript
"use client";

import Image from "next/image";
import { useState } from "react";

import { deleteDocument } from "@/lib/actions/room.actions";

import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";

import { Button } from "./ui/button";

export const DeleteModal = ({ roomId }: DeleteModalProps) => {
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);

  const deleteDocumentHandler = async () => {
    setLoading(true);

    try {
      await deleteDocument(roomId);
      setOpen(false);
    } catch (error) {
      console.log("Error notif:", error);
    }

    setLoading(false);
  };

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button className="min-w-9 rounded-xl bg-transparent p-2 transition-all">
          <Image
            src="/assets/icons/delete.svg"
            alt="delete"
            width={20}
            height={20}
            className="mt-1"
          />
        </Button>
      </DialogTrigger>
      <DialogContent className="shad-dialog">
        <DialogHeader>
          <Image
            src="/assets/icons/delete-modal.svg"
            alt="delete"
            width={48}
            height={48}
            className="mb-4"
          />
          <DialogTitle>Delete document</DialogTitle>
          <DialogDescription>
            Are you sure you want to delete this document? This action cannot be
            undone.
          </DialogDescription>
        </DialogHeader>

        <DialogFooter className="mt-5">
          <DialogClose asChild className="w-full bg-dark-400 text-white">
            Cancel
          </DialogClose>

          <Button
            variant="destructive"
            onClick={deleteDocumentHandler}
            className="gradient-red w-full"
          >
            {loading ? "Deleting..." : "Delete"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};
```

</details>

<details>
<summary><code>api/create-collection/route.ts</code></summary>

```typescript
import axios from "axios";
import { NextRequest, NextResponse } from "next/server";

export async function GET(req: NextRequest){

    const { searchParams } = new URL(req.url); 
    
    const uniqueId = searchParams.get('uniqueId');

    if(!uniqueId){
        return NextResponse.json({ error: 'Missing uniqueId' }, { status: 400 });
    }

    try {
        const libraryId = process.env.LIBRARY_ID;
        const response = await axios.post(`https://video.bunnycdn.com/library/${libraryId}/collections`,
            {
                name: uniqueId
            },
            {
                headers: {
                    "Content-Type": "application/json",
                    AccessKey: process.env.BUNNY_API_KEY!,
                },
            }
        );

        const collectionId = response.data.guid;
        return NextResponse.json({ collectionId}, { status: 200 });
    } catch (error) {
        console.error('Error creating collection:', error);
        return NextResponse.json({ error: 'An error occurred' }, { status: 500 });
    }
}
```

</details>
<details>
<summary><code>api/create-video/route.ts</code></summary>

```typescript
import axios from "axios";
import { NextRequest, NextResponse } from "next/server";

export async function GET(req: NextRequest){

    const { searchParams } = new URL(req.url); 
    
    const uniqueId = searchParams.get('uniqueId');
    const collectionIdValue = searchParams.get('collectionId');
    const thumbnail = searchParams.get('thumbnailTime');

    if(!uniqueId || !collectionIdValue || !thumbnail){
        return NextResponse.json({ error: 'Missing uniqueId or collectionId thumbnail' }, { status: 400 });
    }

    try {
        const libraryId = process.env.LIBRARY_ID;
        const response = await axios.post(`https://video.bunnycdn.com/library/${libraryId}/videos`,
            {
                title: uniqueId,
                collectionId: collectionIdValue,
                thumbnailTime: thumbnail
            },
            {
                headers: {
                    "Content-Type": "application/json",
                    AccessKey: process.env.BUNNY_API_KEY!,
                },
            }
        );

        const videoguid = response.data.guid;
        const thumbnailFileName = response.data.thumbnailFileName;
        return NextResponse.json({ videoguid, thumbnailFileName}, { status: 200 });
    } catch (error) {
        console.error('Error creating collection:', error);
        return NextResponse.json({ error: 'An error occurred' }, { status: 500 });
    }
}
```

</details>
<details>
<summary><code>api/get-keys/route.ts</code></summary>

```typescript

import {  NextResponse } from "next/server";

export async function GET(){


    try {
        const libraryId = process.env.LIBRARY_ID;
        const accessKey = process.env.BUNNY_API_KEY
           
         

        
        return NextResponse.json({ libraryId, accessKey }, { status: 200 });
    } catch (error) {
        console.error('Error creating collection:', error);
        return NextResponse.json({ error: 'An error occurred' }, { status: 500 });
    }
}
```

</details>


## <a name="more">🚀 More</a>
**Advance your FlutterFlow applications with custom widgets**

Find Custom widgets and Advanced Courses up for sale on both [BuyMeACoffee](https://buymeacoffee.com/ghostcoding/extras) and [Patreon](https://www.patreon.com/ghostcoding/shop)! You can also buy me a coffee if you would like to support me. Simply click on the image below or scan the QR code.

<a href="https://buymeacoffee.com/ghostcoding" target="_blank">
<img src="https://ghost-coding.b-cdn.net/ghost-coding/bmc_qr%20(1).png" alt="BuyMeACoffee Page">
</a>
