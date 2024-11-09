import admin from 'firebase-admin';
import { NextRequest, NextResponse } from 'next/server';

if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert({
            
            projectId: "add-your-project-id",
            privateKey: "-----BEGIN PRIVATE KEY-----addyourprivatekeyhere-----END PRIVATE KEY-----\n",
            clientEmail: "your-client-email-here",
            
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
