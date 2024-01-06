<script lang="ts">
  import type { Token as TokenT } from "$lib/types/Token";
  export let token: TokenT | null | undefined = null;
</script>

<ol>
  <li>
    orthography: {#if token}
      <b>{token.orthography}</b>  
    {/if}
  </li>
  <li>
    lang_id: {#if token}
      <b>{token.lang_id}</b>  
    {/if}
  </li>
  <li>
    token_id: {#if token}
      <b>{token?.id?.id?.String}</b>  
    {/if}
  </li>
  <li>
    phonetic: {#if token}
      <b>{token.phonetic}</b>  
    {/if}
  </li>
  <li>
    definition: {#if token}
      <b>{token.definition}</b>  
    {/if}
  </li>
  <li>
    notes: {#if token}
      <b>{token.notes}</b>  
    {/if}
  </li>
  <li>
    status: {#if token}
      <b>{token.status}</b>  
    {/if}
  </li>
  <li>
    tags: {#if token}
      <b>{JSON.stringify(token.tags)}</b>  
    {/if}
  </li>
  <li>
    srs: {#if token}
      <b>{JSON.stringify(token.srs)}</b>  
    {/if}
  </li>
</ol>
