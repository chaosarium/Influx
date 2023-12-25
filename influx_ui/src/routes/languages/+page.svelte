<script>
  import { page } from '$app/stores';
  export let data;
  import DbgJsonData from "$lib/dbg/DbgJsonData.svelte";
</script>

<p>Listing languages</p>
<hr>

<!-- {@debug data} -->

<ul>
  {#each data.language_entries as language_entry}
    <li>
      <a href="/texts/{language_entry.identifier}">{language_entry.display_name}</a>
    </li>    
  {/each}
</ul>

<DbgJsonData {data} />