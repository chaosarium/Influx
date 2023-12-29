<script>

  import { page } from '$app/stores';
  export let data;
  import DbgJsonData from "$lib/dbg/DbgJsonData.svelte";
  import PageTitle from '$lib/components/PageTitle.svelte';
</script>

<PageTitle>Text for {$page.params.lang}</PageTitle> 

<!-- {@debug data} -->

<ul>
  {#each data.text_entries as entry}
    <li>{entry.metadata.title}; [{entry.metadata.tags}]; <a href="{$page.params.lang}/{entry.filename}">{entry.filename}</a></li>
  {/each}
</ul>

<DbgJsonData {data} />