<script>
    import { page } from '$app/stores';
    export let data;
    let text_entries = data.text_entries
</script>

Texts for language: `{$page.params.lang}`

<hr>

{@debug data}

<ul>
    {#each text_entries as entry}
        <li>{entry.metadata.title}; [{entry.metadata.tags}]</li>
    {/each}
</ul>

<hr>

<p>debug</p>

<p>{JSON.stringify(text_entries)}</p>
