<script lang="ts">
  import type { Token } from "$lib/types/Token";
  import type { Phrase } from "$lib/types/Phrase";

  export let editing_lexeme: Phrase;
  export let create_or_update: "create" | "update";
  import { writable_count, dbgConsoleMessages, working_doc } from "$lib/store";
  import { createEventDispatcher } from 'svelte';

  const dispatch = createEventDispatcher();
  function dispatchLexemeEdited(updated_lexeme: Token | Phrase) {
    return () => {
      dispatch('lexeme_edited', updated_lexeme);
    }
  };

  async function createPhrase() {
    dbgConsoleMessages.push_back(`createPhrase not yet implemented`);
  }

  async function updatePhrase() {
    let editing_orthography_seq: string[] = editing_lexeme.orthography_seq;
    let editing_normalised_orthography: string = editing_orthography_seq.join(" ");
    const phrase = editing_lexeme;

    const response = await fetch('http://127.0.0.1:3000/phrase/update_phrase', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(phrase),
    });

    if (!response.ok) {
      const message = `An error has occurred: ${response.status}`;
      dbgConsoleMessages.push_back(`failed updatePhrase ${message}`);
    } else {
      const edited: Phrase = await response.json();
      $working_doc.annotated_doc.phrase_dict[editing_normalised_orthography] = structuredClone(edited);
      dispatchLexemeEdited(structuredClone(edited))();
      dbgConsoleMessages.push_back(`success updatePhrase ${JSON.stringify(edited)}`);
    }
  }

  async function deletePhrase() {
    dbgConsoleMessages.push_back(`deletePhrase not yet implemented`);
  }

</script>


<form on:submit|preventDefault={create_or_update === "create" ? createPhrase : updatePhrase}>
  <label for="orthography_seq">orthography_seq:</label><br>
  <input class="border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
    disabled type="text" id="orthography_seq" value={editing_lexeme.orthography_seq.join(" ")}
  ><br>

  <label for="definition">definition:</label><br>
  <input class="border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
    type="text" id="definition" bind:value={editing_lexeme.definition}
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
    id="original_context" disabled bind:value={editing_phrase.original_context} 
  /><br> -->

  <!-- TODO tags -->

  {#if create_or_update === "create"}
    <input class="mt-2 border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
      type="submit" value="Create Phrase"
    >
  {/if}

  {#if create_or_update === "update"}
    <input class="mt-2 border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
      type="submit" value="Update Phrase"
    >
    <input class="mt-2 border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
      type="button" value="Delete Phrase" on:click={deletePhrase}
    >
  {/if}

</form>
