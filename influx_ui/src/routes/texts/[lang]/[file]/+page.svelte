<script>
  import { page } from '$app/stores';
  export let data;
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

  async function updateToken() {
    const token = data.tokens_dict[lastClickedOrth];
    console.log("trying to update token: ", token);

    const body = JSON.stringify({
      id: token.id?.id?.String,
      language: token.language,
      
      orthography: token.orthography,
      phonetic: token.phonetic,
      lemma: token.lemma,

      definition: token.definition,
      status: token.status,
      notes: token.notes
    })

    console.log("token id seems like: ", body);


    const response = await fetch('http://127.0.0.1:3000/vocab/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    });

    if (!response.ok) {
      const message = `An error has occurred: ${response.status}`;
      throw new Error(message);
    }

    const result = await response.json();
    console.log(result);
  }

</script>

Page
<p>Text for language: `{$page.params.lang}`</p>
<p>File `{$page.params.file}`</p>
<hr>

<p>Title:</p>

<h1 class="font-bold">{data.metadata.title}</h1>

<p>Text area:</p>

<div class="p-4 leading-10 text-2xl">
  {#each data.tokens_strs as token}   
    <Token token={data.tokens_dict[token]} 
      on:token_hover={handleHover} 
      on:token_click={handleClick}
    />
  {/each}
</div>


<div class="p-4 bg-rose-50">
  <p>Last hovered: <b>{lastHoveredOrth}</b></p>
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
  <p>Last clicked: <b>{lastClickedOrth}</b></p>
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

  <div class="p-4 bg-amber-100">
    <p><b>Editor</b></p>
    {#if lastClickedOrth != ''}
      <form on:submit|preventDefault={updateToken}>
        <label for="orthography">orthography:</label><br>
        <input class="border-solid border-2 border-gray-400" disabled type="text" id="orthography" bind:value={data.tokens_dict[lastClickedOrth].orthography}><br>

        <label for="lemma">lemma:</label><br>
        <input class="border-solid border-2 border-gray-400" type="text" id="lemma" bind:value={data.tokens_dict[lastClickedOrth].lemma}><br>

        <label for="definition">definition:</label><br>
        <input class="border-solid border-2 border-gray-400" type="text" id="definition" bind:value={data.tokens_dict[lastClickedOrth].definition}><br>

        <label for="phonetic">phonetic:</label><br>
        <input class="border-solid border-2 border-gray-400" type="text" id="phonetic" bind:value={data.tokens_dict[lastClickedOrth].phonetic}><br>
        
        <label for="status">status:</label><br>
        <select class="border-solid border-2 border-gray-400" id="status" bind:value={data.tokens_dict[lastClickedOrth].status}>
          <option value="UNMARKED">UNMARKED</option>
          <option value="L1">L1</option>
          <option value="L2">L2</option>
          <option value="L3">L3</option>
          <option value="L4">L4</option>
          <option value="L5">L5</option>
          <option value="IGNORED">IGNORED</option>
        </select><br>

        <label for="notes">notes:</label><br>
        <textarea class="border-solid border-2 border-gray-400" id="notes" bind:value={data.tokens_dict[lastClickedOrth].notes} /><br>


        <input class="mt-2 border-solid border-2 border-gray-400" type="submit" value="Update Token">
      </form>
    {/if}
  </div>

</div>




<!-- Text -->
<!-- <pre>
  {data.text}
</pre> -->

<DbgJsonData {data} />