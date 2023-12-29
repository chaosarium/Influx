<script>
  import { page } from '$app/stores';
    import PageTitle from '$lib/components/PageTitle.svelte';
  export let data;
  import DbgJsonData from "$lib/dbg/DbgJsonData.svelte";
  import LanguageEntry from './LanguageEntry.svelte';
</script>

<PageTitle>Languages</PageTitle> 

<!-- {@debug data} -->

<ul>
  {#each data.language_entries as language_entry}
    <LanguageEntry {language_entry} />
  {/each}
</ul>

<DbgJsonData {data} />