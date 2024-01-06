<script lang="ts">
  import { page } from '$app/stores';
  export let data;
  import Token from "$lib/components/Token.svelte";
  import DbgJsonData from "$lib/dbg/DbgJsonData.svelte";
  import AnnotatedText from './AnnotatedText.svelte';
  import TokenInfoPane from './TokenInfoPane.svelte';
  import DesktopLayout from './DesktopLayout.svelte';
  import PaneLayout from '$lib/wrappers/PaneLayout.svelte';
  import MainSidebar from '$lib/components/MainSidebarInner.svelte';
  import DbgConsole from '$lib/dbg/DbgConsole.svelte';
  import { writable_count, dbgConsoleMessages } from '$lib/store';
  import { writable } from 'svelte/store';
  import Accordion from '$lib/components/Accordion.svelte';
  import AccordionEntry from '$lib/components/AccordionEntry.svelte';
  import type { Token as TokenT } from "$lib/types/Token";
  import type { SentenceConstituent } from '$lib/types/SentenceConstituent';
    
  let last_hovered_sentence_cst: SentenceConstituent | undefined = undefined;
  let last_clicked_sentence_cst: SentenceConstituent | undefined = undefined;
  const handleSentenceCstHover = (event: { detail: SentenceConstituent; }) => {
    last_hovered_sentence_cst = event.detail;
  };
  const handleSentenceCstClick = (event: { detail: SentenceConstituent; }) => {
    last_clicked_sentence_cst = event.detail;
  };

  function key_or_undefined(obj: any, key: string | undefined) {
    if (key === undefined) {
      return undefined;
    }
    return obj[key];
  }

  $: last_hovered_tkn = key_or_undefined(data.tokens_dict, last_hovered_sentence_cst?.orthography)
  $: last_clicked_tkn = key_or_undefined(data.tokens_dict, last_clicked_sentence_cst?.orthography)

  let tkn_edit_form_data = {
    id: undefined,
    lang_id: undefined,
    orthography: undefined,
    phonetic: undefined,
    definition: undefined,
    notes: undefined,
    original_context: undefined,
    status: undefined,
    tags: undefined,
    srs: undefined,
  };
  let is_editing: boolean = false;

  function updateTknFormData() {
    if (last_clicked_sentence_cst && last_clicked_tkn) {
      // tkn_edit_form_data = {...data.tokens_dict[last_clicked_tkn_orth]};
      tkn_edit_form_data = structuredClone(last_clicked_tkn);
      is_editing = true;
    }
  }
  $: last_clicked_sentence_cst, updateTknFormData();

  async function createToken() {
    if (last_clicked_sentence_cst === undefined) {
      throw new Error("last_clicked_sentence_cst is undefined, cannot create token");
    }
    let creating_orthography: string = last_clicked_sentence_cst?.orthography;

    data.tokens_dict[creating_orthography] = structuredClone(tkn_edit_form_data);
    const token = tkn_edit_form_data;

    const response = await fetch('http://127.0.0.1:3000/vocab/create_token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(token),
    });

    if (!response.ok) {
      const message = `An error has occurred: ${response.status}`;
      throw new Error(message);
    }

    const created: Token = await response.json();
    data.tokens_dict[creating_orthography] = created;
    tkn_edit_form_data = structuredClone(created);
    dbgConsoleMessages.push_back(`success createToken ${JSON.stringify(created)}`);
  }
  async function updateToken() {
    if (last_clicked_sentence_cst === undefined) {
      throw new Error("last_clicked_sentence_cst is undefined, cannot create token");
    }
    let creating_orthography: string = last_clicked_sentence_cst?.orthography;

    data.tokens_dict[creating_orthography] = structuredClone(tkn_edit_form_data);
    const token = tkn_edit_form_data;

    const response = await fetch('http://127.0.0.1:3000/vocab/update_token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(token),
    });

    if (!response.ok) {
      const message = `An error has occurred: ${response.status}`;
      throw new Error(message);
    }

    const updated = await response.json();
    data.tokens_dict[creating_orthography] = updated;
    tkn_edit_form_data = structuredClone(updated);
    dbgConsoleMessages.push_back(`success updateToken ${JSON.stringify(updated)}`);
  }


</script>

<PaneLayout show_left={false} show_mid_top={false}>

  <div slot="mid-mid" class="h-full">

    <!-- content column -->
    <div class="flex justify-center my-auto h-full">
      <div class="mx-3 my-auto max-w-[800px] flex-auto">
        
        <h1 class="font-bold text-3xl mt-4 mb-2">{data.metadata.title}</h1>
        <p class="text-gray-500">Tags: {undefined}</p>
        <p class="text-gray-500">File: {undefined}</p>
        <p class="text-gray-500">Created: {data.metadata.date_created}</p>
        <p class="text-gray-500">Modified: {data.metadata.date_modified}</p>
        <p class="text-gray-500">Last Viewed: {undefined}</p>


        <AnnotatedText 
          parsed_doc={data.parsed_doc}
          tokens_dict={data.tokens_dict}
          on:token_hover={handleSentenceCstHover} 
          on:token_click={handleSentenceCstClick}
          class="my-4"
        ></AnnotatedText>

      </div>
    </div>


  </div>

  <div slot="right">

    <Accordion>

      <AccordionEntry>
        <h2 slot="header" class="px-3 font-bold bg-amber-50">Last Clicked</h2>
        <div class="p-3">
          <TokenInfoPane 
            token={last_clicked_tkn}
          ></TokenInfoPane>
        </div>
      </AccordionEntry>
      
      <AccordionEntry>
        <h2 slot="header" class="px-3 font-bold bg-orange-50">Token Editor</h2>
        <div class="p-3">
            <form on:submit|preventDefault={last_clicked_tkn.id ? updateToken : createToken}>
              <label for="orthography">orthography:</label><br>
              <input class="border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
                disabled type="text" id="orthography" bind:value={tkn_edit_form_data.orthography}
              ><br>
    
              <label for="definition">definition:</label><br>
              <input class="border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
                disabled={!is_editing} type="text" id="definition" bind:value={tkn_edit_form_data.definition}
              ><br>
    
              <label for="phonetic">phonetic:</label><br>
              <input class="border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
                disabled={!is_editing} type="text" id="phonetic" bind:value={tkn_edit_form_data.phonetic}
              ><br>
              
              <label for="status">status:</label><br>
              <select required class="border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
                disabled={!is_editing} id="status" bind:value={tkn_edit_form_data.status}
              >
                <option value="L1">L1</option>
                <option value="L2">L2</option>
                <option value="L3">L3</option>
                <option value="L4">L4</option>
                <option value="L5">L5</option>
                <option value="KNOWN">IGNORED</option>
                <option value="IGNORED">IGNORED</option>
              </select><br>
    
              <label for="notes">notes:</label><br>
              <textarea class="border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
                disabled={!is_editing} id="notes" bind:value={tkn_edit_form_data.notes} 
              /><br>

              <label for="original_context">original_context:</label><br>
              <textarea class="border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
                disabled={!is_editing} id="original_context" bind:value={tkn_edit_form_data.original_context} 
              /><br>
    
              <input class="mt-2 border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
                disabled={!is_editing} type="submit" value={is_editing ? (last_clicked_tkn.id ? "Update Token" : "Create Token") : "Nothing to Edit"}
              >
            </form>
        </div>
      </AccordionEntry>

      <AccordionEntry>
        <h2 slot="header" class="px-3 font-bold bg-rose-50">Last Hovered</h2>
        <div class="p-3">
          <TokenInfoPane 
            token={last_hovered_tkn}
          ></TokenInfoPane>
        </div>
      </AccordionEntry>
      
      <AccordionEntry>
        <h2 slot="header" class="px-3 font-bold bg-blue-50">Output Console</h2>
        <div class="p-3 ">
          <button on:click={() => {dbgConsoleMessages.push_back('hi')}}>
            DEBUG CONSOLE
          </button>
          <DbgConsole />
        </div>
      </AccordionEntry>

    </Accordion>

  </div>

  <div slot="mid-bottom">
    <DbgJsonData {data} />
    <DbgJsonData name='tokenFormData bindings' data={tkn_edit_form_data} />
    <DbgJsonData name='page params' data={$page.params} />
  </div>
</PaneLayout>


