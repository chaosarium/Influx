<script>
  import { page } from '$app/stores';
  export let data;
  import DbgGlobalNav from "$lib/dbg/DbgGlobalNav.svelte";
  import DbgJsonData from "$lib/dbg/DbgJsonData.svelte";
  import Token from "$lib/components/Token.svelte";
    import { stringify } from 'postcss';
  
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
  {#each data.tokens_strs as token}   
    <Token token={data.tokens_dict[token]} 
      on:token_hover={handleHover} 
      on:token_click={handleClick}
    />
  {/each}
</div>


<div class="p-4 bg-rose-50">
  <p>Last hovered token:</p>
  <p><b>{lastHoveredOrth}</b></p>
  <ol>
    <li>
      definition: {#if lastHoveredOrth != '' && data.tokens_dict[lastHoveredOrth]}
        <b>{data.tokens_dict[lastHoveredOrth].definition}</b>  
      {/if}
    </li>
    <li>
      phonetic: {#if lastHoveredOrth != '' && data.tokens_dict[lastHoveredOrth]}
        <b>{data.tokens_dict[lastHoveredOrth].phonetic}</b>  
      {/if}
    </li>
    <li>
      status: {#if lastHoveredOrth != '' && data.tokens_dict[lastHoveredOrth]}
        <b>{data.tokens_dict[lastHoveredOrth].status}</b>  
      {/if}
    </li>
  </ol>
</div>
<div class="p-4 bg-amber-50">
  <p>Last hovered token:</p>
  <p><b>{lastClickedOrth}</b></p>
  <ol>
    <li>
      definition: {#if lastClickedOrth != '' && data.tokens_dict[lastClickedOrth]}
        <b>{data.tokens_dict[lastClickedOrth].definition}</b>  
      {/if}
    </li>
    <li>
      phonetic: {#if lastClickedOrth != '' && data.tokens_dict[lastClickedOrth]}
        <b>{data.tokens_dict[lastClickedOrth].phonetic}</b>  
      {/if}
    </li>
    <li>
      status: {#if lastClickedOrth != '' && data.tokens_dict[lastClickedOrth]}
        <b>{data.tokens_dict[lastClickedOrth].status}</b>  
      {/if}
    </li>
  </ol>
</div>




<!-- Text -->
<!-- <pre>
  {data.text}
</pre> -->

<DbgJsonData {data} />