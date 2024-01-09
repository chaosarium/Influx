import { error } from '@sveltejs/kit';
export const ssr = false;
import type {AnnotatedDocument} from '$lib/types/AnnotatedDocument';

/** @type {import('./$types').PageLoad} */
export async function load({ fetch, params }) {
    return {
        lang: params.lang,
        file: params.file,
    }
}