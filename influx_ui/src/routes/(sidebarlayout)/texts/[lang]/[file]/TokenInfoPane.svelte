<script lang="ts">
  export let dict_entry;
  export let populated: boolean;
</script>

<ol>
  <li>
    orthography: {#if populated && dict_entry}
      <b>{dict_entry.orthography}</b>  
    {/if}
  </li>
  <li>
    definition: {#if populated && dict_entry}
      <b>{dict_entry.definition}</b>  
    {/if}
  </li>
  <li>
    token_id: {#if populated && dict_entry}
      <b>{dict_entry?.id?.id?.String}</b>  
    {/if}
  </li>
  <li>
    phonetic: {#if populated && dict_entry}
      <b>{dict_entry.phonetic}</b>  
    {/if}
  </li>
  <li>
    status: {#if populated && dict_entry}
      <b>{dict_entry.status}</b>  
    {/if}
  </li>
  <li>
    notes: {#if populated && dict_entry}
      <b>{dict_entry.notes}</b>  
    {/if}
  </li>
</ol>
