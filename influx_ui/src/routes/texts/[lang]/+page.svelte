<script>
    import { page } from '$app/stores';
    export let data;
</script>

Page
<p>Text for language: `{$page.params.lang}`</p>
<hr>

{@debug data}

<ul>
    {#each data.text_entries as entry}
        <li>{entry.metadata.title}; [{entry.metadata.tags}]</li>
    {/each}
</ul>

<hr>
<p>Debug</p>
<p>{JSON.stringify(data.text_entries)}</p>
