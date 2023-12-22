<script>
  import { page } from '$app/stores';
  export let data;
  import DbgGlobalNav from "$lib/dbg/DbgGlobalNav.svelte";
  import DbgJsonData from "$lib/dbg/DbgJsonData.svelte";
  import Token from "$lib/components/Token.svelte";
  
  let lastHoveredOrth = '';
  let lastClickedOrth = '';
  const handleHover = event => {
    lastHoveredOrth = event.detail;
  };
  const handleClick = event => {
    lastClickedOrth = event.detail;
  };

</script>
<DbgGlobalNav />

Page
<p>Text for language: `{$page.params.lang}`</p>
<p>File `{$page.params.file}`</p>
<hr>

<p>Title:</p>

<h1 class="font-bold">{data.metadata.title}</h1>

<p>Text area:</p>

<div class="p-4 leading-10">
  {#each data.tokens as token}
    <Token {token} 
      on:token_hover={handleHover} 
      on:token_click={handleClick}
    />
  {/each}
</div>

<div class="p-4 bg-rose-50">
  <p>Last hovered token:</p>
  <p><b>{lastHoveredOrth}</b></p>
  <ol>
    <li>lemma:</li>
    <li>language:</li>
    <li>status:</li>
    <li>phonetic:</li>
  </ol>
</div>
<div class="p-4 bg-amber-50">
  <p>Last hovered token:</p>
  <p><b>{lastClickedOrth}</b></p>
  <ol>
    <li>lemma:</li>
    <li>language:</li>
    <li>status:</li>
    <li>phonetic:</li>
  </ol>
</div>




<!-- Text -->
<!-- <pre>
  {data.text}
</pre> -->

<DbgJsonData {data} />