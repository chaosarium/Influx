<script lang="ts">
  import type { Token } from "$lib/types/Token";
  import type { Phrase } from "$lib/types/Phrase";
 
  export let editing_lexeme: Token;
  export let create_or_update: "create" | "update";
  import { writable_count, dbgConsoleMessages, working_doc } from "$lib/store";
  import { createEventDispatcher } from 'svelte';

  const dispatch = createEventDispatcher();
  function dispatchLexemeEdited(updated_lexeme: Token | Phrase) {
    return () => {
      dispatch('lexeme_edited', updated_lexeme);
    }
  };


  async function createToken() {
    let editing_orthography: string = editing_lexeme.orthography;
    const token = editing_lexeme;

    const response = await fetch('http://127.0.0.1:3000/vocab/create_token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(token),
    });

    if (!response.ok) {
      const message = `An error has occurred: ${response.status}`;
      dbgConsoleMessages.push_back(`failed createToken ${message}`);
    } else {
      const edited: Token = await response.json();
      $working_doc.annotated_doc.token_dict[editing_orthography] = structuredClone(edited);
      dispatchLexemeEdited(structuredClone(edited))();
      dbgConsoleMessages.push_back(`success createToken ${JSON.stringify(edited)}`);
    }
  }
  
  async function updateToken() {
    let editing_orthography: string = editing_lexeme.orthography;
    const token = editing_lexeme;

    const response = await fetch('http://127.0.0.1:3000/vocab/update_token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(token),
    });

    if (!response.ok) {
      const message = `An error has occurred: ${response.status}`;
      dbgConsoleMessages.push_back(`failed updateToken ${message}`);
    } else {
      const edited: Token = await response.json();
      $working_doc.annotated_doc.token_dict[editing_orthography] = structuredClone(edited);
      dispatchLexemeEdited(structuredClone(edited))();
      dbgConsoleMessages.push_back(`success updateToken ${JSON.stringify(edited)}`);
    }

  }

  async function deleteToken() {
    let editing_orthography: string = editing_lexeme.orthography;
    const token = editing_lexeme;

    const response = await fetch('http://127.0.0.1:3000/vocab/delete_token', {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(token),
    });

    if (!response.ok) {
      const message = `An error has occurred: ${response.status}`;
      dbgConsoleMessages.push_back(`failed deleteToken ${message}`);
    } else {
      const edited: Token = await response.json();
      $working_doc.annotated_doc.token_dict[editing_orthography] = {
        lang_id: token.lang_id,
        orthography: token.orthography,
        definition: "",
        phonetic: "",
        status: "UNMARKED",
        notes: "",
        original_context: "",
        tags: [],
        srs: {"dummy": "dummy"}
      };
      dispatchLexemeEdited(structuredClone(edited))();
      dbgConsoleMessages.push_back(`success deleteToken ${JSON.stringify(edited)}`);
    }
  }

</script>


<form on:submit|preventDefault={create_or_update === "create" ? createToken : updateToken}>
  <label for="orthography">orthography:</label><br>
  <input class="border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
    disabled type="text" id="orthography" bind:value={editing_lexeme.orthography}
  ><br>

  <label for="definition">definition:</label><br>
  <input class="border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
    type="text" id="definition" bind:value={editing_lexeme.definition}
  ><br>

  <label for="phonetic">phonetic:</label><br>
  <input class="border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
    type="text" id="phonetic" bind:value={editing_lexeme.phonetic}
  ><br>
  
  <label for="status">status:</label><br>
  <select required class="border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
    id="status" bind:value={editing_lexeme.status}
  >
    <option value="L1">L1</option>
    <option value="L2">L2</option>
    <option value="L3">L3</option>
    <option value="L4">L4</option>
    <option value="L5">L5</option>
    <option value="KNOWN">KNOWN</option>
    <option value="IGNORED">IGNORED</option>
  </select><br>

  <label for="notes">notes:</label><br>
  <textarea class="border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
    id="notes" bind:value={editing_lexeme.notes} 
  /><br>

  <!-- TODO -->
  <!-- <label for="original_context">original_context:</label><br>
  <textarea class="border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
    id="original_context" disabled bind:value={editing_token.original_context} 
  /><br> -->

  <!-- TODO tags -->

  {#if create_or_update === "create"}
    <input class="mt-2 border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
      type="submit" value="Create Token"
    >
  {/if}

  {#if create_or_update === "update"}
    <input class="mt-2 border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
      type="submit" value="Update Token"
    >
    <input class="mt-2 border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
      type="button" value="Delete Token" on:click={deleteToken}
    >
  {/if}

</form>
