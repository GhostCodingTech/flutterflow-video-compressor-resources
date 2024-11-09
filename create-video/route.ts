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