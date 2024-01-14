import { error } from '@sveltejs/kit';
export const ssr = false;
/** @type {import('./$types').PageLoad} */
export async function load({ fetch, params }) {
    const res = await fetch(`http://127.0.0.1:3000/docs/${params.lang}`);
    const json_res = await res.json();

    return {
        text_entries: json_res,
    };
}