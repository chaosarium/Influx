<script lang="ts">
    import { dbgConsoleMessages } from "$lib/store";
  import type { Token } from "$lib/types/Token";
  import { Label, Input } from 'flowbite-svelte';
  
  export let editing_token: Token;
  export let create_or_update: "create" | "update";
  export let token_dict: Record<string, Token>;

  async function createToken() {
    let editing_orthography: string = editing_token.orthography;
    const token = editing_token;

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
      const created: Token = await response.json();
      token_dict[editing_orthography] = structuredClone(created);
      editing_token = structuredClone(created);
      dbgConsoleMessages.push_back(`success createToken ${JSON.stringify(created)}`);
    }
  }
  
  async function updateToken() {
    let editing_orthography: string = editing_token.orthography;
    const token = editing_token;

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
      const created: Token = await response.json();
      token_dict[editing_orthography] = structuredClone(created);
      token_dict = token_dict;
      editing_token = structuredClone(created);
      dbgConsoleMessages.push_back(`success createToken ${JSON.stringify(created)}`);
    }

  }

</script>


<form on:submit|preventDefault>
  <label for="orthography">orthography:</label><br>
  <input class="border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
    disabled type="text" id="orthography" bind:value={editing_token.orthography}
  ><br>

  <label for="definition">definition:</label><br>
  <input class="border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
    type="text" id="definition" bind:value={editing_token.definition}
  ><br>

  <label for="phonetic">phonetic:</label><br>
  <input class="border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
    type="text" id="phonetic" bind:value={editing_token.phonetic}
  ><br>
  
  <label for="status">status:</label><br>
  <select required class="border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
    id="status" bind:value={editing_token.status}
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
    id="notes" bind:value={editing_token.notes} 
  /><br>

  <!-- TODO -->
  <!-- <label for="original_context">original_context:</label><br>
  <textarea class="border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
    id="original_context" disabled bind:value={editing_token.original_context} 
  /><br> -->

  <!-- TODO tags -->

  {#if create_or_update === "create"}
    <input class="mt-2 border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
      type="submit" value="Create Token" on:click={createToken}
    >
  {/if}

  {#if create_or_update === "update"}
    <input class="mt-2 border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
      type="submit" value="Update Token" on:click={updateToken}
    >
    <input class="mt-2 border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" 
      type="button" value="Delete Token"
    >
  {/if}

</form>
