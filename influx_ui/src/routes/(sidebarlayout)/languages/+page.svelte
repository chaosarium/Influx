<script>
  import { page } from '$app/stores';
  import PageTitle from '$lib/components/PageTitle.svelte';
  export let data;
  import DbgJsonData from "$lib/dbg/DbgJsonData.svelte";
  import LanguageEntry from './LanguageEntry.svelte';
  import { app_settings } from '$lib/store';
</script>

<div class="p-3">
  <PageTitle>Languages</PageTitle> 
  
  <!-- {@debug data} -->
  
  <div class="my-3">
    <ul class="space-y-3">
      {#each $app_settings.lang as language_entry}
        <LanguageEntry {language_entry} />
      {/each}
    </ul>
  </div>
  
  
  <DbgJsonData {data} />
  <DbgJsonData data={$app_settings} name={"app_settings"} />
</div>
