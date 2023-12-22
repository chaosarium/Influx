<script>
  import { page } from '$app/stores';
  export let data;
  import DbgGlobalNav from "$lib/dbg/DbgGlobalNav.svelte";
  import DbgJsonData from "$lib/dbg/DbgJsonData.svelte";
  import Token from "$lib/components/Token.svelte";
</script>
<DbgGlobalNav />

Page
<p>Text for language: `{$page.params.lang}`</p>
<p>File `{$page.params.file}`</p>
<hr>

<h1 class="font-bold">{data.metadata.title}</h1>

<div class="p-4">
  {#each data.tokens as token}
    <Token {token} />
  {/each}
</div>

<!-- Text -->
<!-- <pre>
  {data.text}
</pre> -->

<DbgJsonData {data} />