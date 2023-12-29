<script>
  import { page } from '$app/stores';
    import PageTitle from '$lib/components/PageTitle.svelte';
  export let data;
  import DbgJsonData from "$lib/dbg/DbgJsonData.svelte";
  import LanguageEntry from './LanguageEntry.svelte';
</script>

<PageTitle>Languages</PageTitle> 

<!-- {@debug data} -->

<div class="my-3">
  <ul class="space-y-3">
    {#each data.language_entries as language_entry}
      <LanguageEntry {language_entry} />
    {/each}
  </ul>
</div>


<DbgJsonData {data} />