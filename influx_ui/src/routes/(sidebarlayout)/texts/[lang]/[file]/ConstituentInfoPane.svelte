<script lang="ts">
  import type { Token as TokenT } from "$lib/types/Token";
  import type { Phrase as PhraseT } from "$lib/types/Phrase";
  import type { SentenceConstituent } from "$lib/types/SentenceConstituent";
  import type { AnnotatedDocument } from "$lib/types/AnnotatedDocument";
  
  export let constituent: SentenceConstituent | undefined;
  export let annotated_doc: AnnotatedDocument;
  let token_dict = annotated_doc.token_dict as Record<string, TokenT>;
  let phrase_dict = annotated_doc.phrase_dict as Record<string, PhraseT>;

  let dict_entry: undefined | TokenT | PhraseT = undefined;
  
  function get_dict_entry(constituent: SentenceConstituent | undefined) {
    if (constituent === undefined) {
      return undefined;
    } else
    if (constituent.type === "SingleToken" || constituent.type === "SubwordToken" || constituent.type === "CompositToken") {
      return token_dict[constituent.orthography];
    } else if (constituent.type === "Whitespace") {
      return undefined;
    } else if (constituent.type === "PhraseToken") {
      return phrase_dict[constituent.normalised_orthography];
    } else {
      return undefined;
    }
  } 
  
  $: dict_entry = get_dict_entry(constituent);

</script>

{#if constituent === undefined}
  <p>no constituent selected</p>
{:else}
  <!-- constituent info -->
  <p><em>constituent info</em></p>
  <ol>
    <li>
      type: <b>{constituent.type}</b>
    </li>
    <li>
      text: <b>{constituent.text}</b>
    </li>
    <li>
      {#if constituent.type === "SingleToken" || constituent.type === "SubwordToken" || constituent.type === "CompositToken"}
        orthography: <b>{constituent.orthography}</b>
      {:else if constituent.type === "Whitespace"}
        UNREACHABLE
      {:else if constituent.type === "PhraseToken"}
        normalised_orthography: <b>{constituent.normalised_orthography}</b>
      {/if}
    </li>
    <li>
      {#if constituent.type === "SingleToken" || constituent.type === "SubwordToken"}
        lemma: <b>{constituent.lemma}</b>
      {:else if constituent.type === "Whitespace" || constituent.type === "CompositToken"}
        lemma: N/A
      {:else if constituent.type === "PhraseToken"}
        lemma: N/A
      {/if}
    </li>
    <li>
      shadows: <b>{JSON.stringify(constituent.shadows)}</b>
    </li>
  </ol>

  <hr>
  <!-- dict_entry info --> 
  <p><em>in the dictionary:</em></p>
  <ol>
    {#if dict_entry === undefined}
      UNREACHABLE
    {:else if dict_entry && (constituent.type === "SingleToken" || constituent.type === "SubwordToken" || constituent.type === "CompositToken")}
      <li>
        tb: <b>{dict_entry.id?.tb}</b>
      </li>
      <li>
        id: <b>{dict_entry.id?.id.String}</b>
      </li>
      <li>
        lang_id: <b>{dict_entry.lang_id}</b>
      </li>
      <li>
        orthography: <b>{dict_entry.orthography}</b>
      </li>
      <li>
        phonetic: <b>{dict_entry.phonetic}</b>
      </li>
      <li>
        definition: <b>{dict_entry.definition}</b>
      </li>
      <li>
        notes: <b>{dict_entry.notes}</b>
      </li>
      <li>
        original_context: <b>{dict_entry.original_context}</b>
      </li>
      <li>
        status: <b>{dict_entry.status}</b>
      </li>
      <li>
        tags: <b>{JSON.stringify(dict_entry.tags)}</b>
      </li>
      <li>
        srs: <b>{JSON.stringify(dict_entry.srs)}</b>
      </li>  
    {:else if dict_entry && (constituent.type === "Whitespace")}
      UNREACHABLE
    {:else if dict_entry && (constituent.type === "PhraseToken")}
      <li>
        tb: <b>{dict_entry.id?.tb}</b>
      </li>
      <li>
        id: <b>{dict_entry.id?.id.String}</b>
      </li>
      <li>
        lang_id: <b>{dict_entry.lang_id}</b>
      </li>
      <li>
        orthography_seq: <b>{JSON.stringify(dict_entry.orthography_seq)}</b>
      </li>
      <li>
        definition: <b>{dict_entry.definition}</b>
      </li>
      <li>
        notes: <b>{dict_entry.notes}</b>
      </li>
      <li>
        original_context: <b>{dict_entry.original_context}</b>
      </li>
      <li>
        status: <b>{dict_entry.status}</b>
      </li>
      <li>
        tags: <b>{JSON.stringify(dict_entry.tags)}</b>
      </li>
      <li>
        srs: <b>{JSON.stringify(dict_entry.srs)}</b>
      </li>
    {/if}
    
  </ol>
{/if}

