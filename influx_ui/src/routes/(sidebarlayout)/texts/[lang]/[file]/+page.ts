import { error } from '@sveltejs/kit';
export const ssr = false;
import type {AnnotatedDocument} from '$lib/types/AnnotatedDocument';

/** @type {import('./$types').PageLoad} */
export async function load({ fetch, params }) {
    const res = await fetch(`http://127.0.0.1:3000/docs/${params.lang}/${params.file}`);
    const json_res: {
        metadata: any,
        text: string,
        annotated_doc: AnnotatedDocument,
    } = await res.json();

    return json_res;
}