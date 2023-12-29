<script>
  import { page } from '$app/stores';
  export let data;
  import Token from "$lib/components/Token.svelte";
  import DbgJsonData from "$lib/dbg/DbgJsonData.svelte";
  import AnnotatedText from './AnnotatedText.svelte';
  import TokenInfoPane from './TokenInfoPane.svelte';
  import DesktopLayout from './DesktopLayout.svelte';
  import PaneLayout from '$lib/PaneLayout.svelte';
    import DbgGlobalNav from '$lib/dbg/DbgGlobalNav.svelte';
    
  let lastHoveredOrth = '';
  let lastClickedOrth = '';
  const handleHover = event => {
    lastHoveredOrth = event.detail;
  };
  const handleClick = event => {
    lastClickedOrth = event.detail;
  };

  let tokenFormData = {
    orthography: '',
    lemma: '',
    definition: '',
    phonetic: '',
    status: '',
    notes: ''
  };

  function updateTokenFormData() {
    if (lastClickedOrth && data.tokens_dict[lastClickedOrth]) {
      tokenFormData = {...data.tokens_dict[lastClickedOrth]};
    }
  }
  $: lastClickedOrth, updateTokenFormData();

  async function createToken() {
    data.tokens_dict[lastClickedOrth] = {...tokenFormData};
    const token = data.tokens_dict[lastClickedOrth];

    const response = await fetch('http://127.0.0.1:3000/vocab/create_token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        lang_id: token.lang_id,
        orthography: token.orthography,
        phonetic: token.phonetic,
        lemma: token.lemma,
        definition: token.definition,
        status: token.status,
        notes: token.notes
      }),
    });

    if (!response.ok) {
      const message = `An error has occurred: ${response.status}`;
      throw new Error(message);
    }

    const result = await response.json();
    console.log(result);
  }
  async function updateToken() {
    data.tokens_dict[lastClickedOrth] = {...tokenFormData};
    const token = data.tokens_dict[lastClickedOrth];

    const response = await fetch('http://127.0.0.1:3000/vocab/update_token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        id: token.id.id?.String,
        lang_id: token.lang_id,
        orthography: token.orthography,
        phonetic: token.phonetic,
        lemma: token.lemma,
        definition: token.definition,
        status: token.status,
        notes: token.notes
      }),
    });

    if (!response.ok) {
      const message = `An error has occurred: ${response.status}`;
      throw new Error(message);
    }

    const result = await response.json();
    console.log(result);
  }

</script>

<PaneLayout>
  <svelte:fragment slot="left">
    SIDEBAR
    <DbgGlobalNav />
  </svelte:fragment>

  <div slot="mid-mid">
    <p>TITLE:</p>

    <h1 class="font-bold">{data.metadata.title}</h1>

    <p>ANNOTATED TEXT:</p>

    <AnnotatedText 
      parsed_doc={data.parsed_doc}
      tokens_dict={data.tokens_dict}
      on:token_hover={handleHover} 
      on:token_click={handleClick}
    ></AnnotatedText>

  </div>

  <div slot="right">
    <div class="p-4 bg-rose-50">
      <p>Last hovered:</p>
      <TokenInfoPane 
        populated={lastHoveredOrth != ''}
        dict_entry={data.tokens_dict[lastHoveredOrth]}
      ></TokenInfoPane>
    </div>


    <div class="p-4 bg-amber-50">
      <p>Last clicked:</p>
      <TokenInfoPane 
        populated={lastClickedOrth != ''}
        dict_entry={data.tokens_dict[lastClickedOrth]}
      ></TokenInfoPane>

      <div class="p-4 bg-amber-100">
        <p><b>Editor</b></p>
        {#if lastClickedOrth != ''}
          <form on:submit|preventDefault={data.tokens_dict[lastClickedOrth].id ? updateToken : createToken}>
            <label for="orthography">orthography:</label><br>
            <input class="border-solid border-2 border-gray-400" disabled type="text" id="orthography" bind:value={tokenFormData.orthography}><br>

            <label for="lemma">lemma:</label><br>
            <input class="border-solid border-2 border-gray-400" type="text" id="lemma" bind:value={tokenFormData.lemma}><br>

            <label for="definition">definition:</label><br>
            <input class="border-solid border-2 border-gray-400" type="text" id="definition" bind:value={tokenFormData.definition}><br>

            <label for="phonetic">phonetic:</label><br>
            <input class="border-solid border-2 border-gray-400" type="text" id="phonetic" bind:value={tokenFormData.phonetic}><br>
            
            <label for="status">status:</label><br>
            <select class="border-solid border-2 border-gray-400" id="status" bind:value={tokenFormData.status}>
              <option value="L1">L1</option>
              <option value="L2">L2</option>
              <option value="L3">L3</option>
              <option value="L4">L4</option>
              <option value="L5">L5</option>
              <option value="IGNORED">IGNORED</option>
            </select><br>

            <label for="notes">notes:</label><br>
            <textarea class="border-solid border-2 border-gray-400" id="notes" bind:value={tokenFormData.notes} /><br>


            <input class="mt-2 border-solid border-2 border-gray-400" type="submit" value="Update Token">
          </form>
        {/if}
      </div>

    </div>

  </div>

  <div slot="mid-bottom">
    DEBUG
    <DbgJsonData {data} />
    <DbgJsonData name='tokenFormData bindings' data={tokenFormData} />
    <DbgJsonData name='page params' data={$page.params} />
  </div>
</PaneLayout>


