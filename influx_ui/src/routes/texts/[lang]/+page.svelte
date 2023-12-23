<script>
  import { page } from '$app/stores';
  export let data;
  import DbgJsonData from "$lib/dbg/DbgJsonData.svelte";
</script>

<p>Text for language: `{$page.params.lang}`</p>
<hr>

{@debug data}

<ul>
  {#each data.text_entries as entry}
    <li>{entry.metadata.title}; [{entry.metadata.tags}]; <a href="{$page.params.lang}/{entry.filename}">{entry.filename}</a></li>
  {/each}
</ul>

<DbgJsonData {data} />