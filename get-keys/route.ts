
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