<script>

  import { page } from '$app/stores';
  export let data;
  import DbgJsonData from "$lib/dbg/DbgJsonData.svelte";
  import PageTitle from '$lib/components/PageTitle.svelte';
  import TextEntry from './TextEntry.svelte';
</script>

<div class="p-3">

  <PageTitle>Text for {$page.params.lang}</PageTitle> 

  <!-- {@debug data} -->

  <div class="my-3">
    <ul class="space-y-3">
      {#each data.text_entries as text_entry}
        <!-- <li>{text_entrie.metadata.title}; [{text_entrie.metadata.tags}]; <a href="{$page.params.lang}/{text_entrie.filename}">{text_entrie.filename}</a></li> -->
        <TextEntry {text_entry} />
      {/each}
    </ul>
  </div>


  <DbgJsonData {data} />
</div>
