<script lang="ts">
  import { page } from '$app/stores';
  export let data: {
    metadata: any,
    text: string,
    annotated_doc: AnnotatedDocument,
  };
  import TokenC from "$lib/components/TokenC.svelte";
  import DbgJsonData from "$lib/dbg/DbgJsonData.svelte";
  import AnnotatedText from './AnnotatedText.svelte';
  import TokenInfoPane from './ConstituentInfoPane.svelte';
  import DesktopLayout from './DesktopLayout.svelte';
  import PaneLayout from '$lib/wrappers/PaneLayout.svelte';
  import MainSidebar from '$lib/components/MainSidebarInner.svelte';
  import DbgConsole from '$lib/dbg/DbgConsole.svelte';
  import { writable_count, dbgConsoleMessages } from '$lib/store';
  import { writable } from 'svelte/store';
  import Accordion from '$lib/components/Accordion.svelte';
  import AccordionEntry from '$lib/components/AccordionEntry.svelte';
  import type { Token } from "$lib/types/Token";
  import type { Phrase } from "$lib/types/Phrase";
  import type { SentenceConstituent } from '$lib/types/SentenceConstituent';
  import type { AnnotatedDocument } from '$lib/types/AnnotatedDocument';
  import { Option } from '$lib/types/Option';
  import { try_access, try_key, try_lookup } from '$lib/utils';
    import TokenEditForm from './TokenEditForm.svelte';
    import PhraseEditForm from './PhraseEditForm.svelte';

  let token_dict = data.annotated_doc.token_dict as Record<string, Token>;
  let phrase_dict = data.annotated_doc.phrase_dict as Record<string, Phrase>;


  let last_hovered_sentence_cst: Option<SentenceConstituent> = Option.None();
  let last_clicked_sentence_cst: Option<SentenceConstituent> = Option.None();
  const handleSentenceCstHover = (event: { detail: SentenceConstituent }) => {
    last_hovered_sentence_cst = Option.Some(event.detail);
    // dbgConsoleMessages.push_back("hovered: " + JSON.stringify(last_hovered_sentence_cst));
  };
  const handleSentenceCstClick = (event: { detail: SentenceConstituent }) => {
    last_clicked_sentence_cst = Option.Some(event.detail);
    dbgConsoleMessages.push_back("clicked: " + JSON.stringify(last_clicked_sentence_cst));
  };

  $: last_hovered_lexeme = try_lookup(token_dict, phrase_dict, last_hovered_sentence_cst)
  $: last_clicked_lexeme = try_lookup(token_dict, phrase_dict, last_clicked_sentence_cst)


  let editing_lexeme: undefined | Token | Phrase = undefined;
  let lexeme_edit_state: "notEditing" | "newToken" | "existingToken" | "existingPhrase" | "newPhrase" = "notEditing";

  function updateEditingLexeme() {
    if (last_clicked_lexeme.is_some()) {
      let last_clicked = last_clicked_lexeme.unwrap();
      if (last_clicked.type === "Token") {
        editing_lexeme = structuredClone(last_clicked.value);
        if (last_clicked.value.id) {
          lexeme_edit_state = "existingToken";
        } else {
          lexeme_edit_state = "newToken";
        }
      } else if (last_clicked.type === "Phrase") {
        editing_lexeme = structuredClone(last_clicked.value);
        if (last_clicked.value.id) {
          lexeme_edit_state = "existingPhrase";
        } else {
          lexeme_edit_state = "newPhrase";
        }
      } else {
        throw new Error("UNREACHABLE");
      }
      dbgConsoleMessages.push_back(`editing_lexeme: ${JSON.stringify(editing_lexeme)}, lexeme_edit_state: ${lexeme_edit_state}`);
    }
  }
  $: last_clicked_sentence_cst, updateEditingLexeme();


  async function createToken() {
    if (last_clicked_sentence_cst === undefined) {
      throw new Error("last_clicked_sentence_cst is undefined, cannot create token");
    }
    if (!data.annotated_doc.token_dict) {
      throw new Error("data.annotated_doc.token_dict is undefined, cannot create token");
    }
    let creating_orthography: string = last_clicked_sentence_cst?.orthography;

    data.annotated_doc.token_dict[creating_orthography] = structuredClone(editing_lexeme);
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
      throw new Error(message);
    }

    const created: Token = await response.json();
    data.tokens_dict[creating_orthography] = created;
    editing_lexeme = structuredClone(created);
    dbgConsoleMessages.push_back(`success createToken ${JSON.stringify(created)}`);
  }
  async function updateToken() {
    if (last_clicked_sentence_cst === undefined) {
      throw new Error("last_clicked_sentence_cst is undefined, cannot create token");
    }
    let creating_orthography: string = last_clicked_sentence_cst?.orthography;

    data.tokens_dict[creating_orthography] = structuredClone(editing_lexeme);
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
      throw new Error(message);
    }

    const updated = await response.json();
    data.tokens_dict[creating_orthography] = updated;
    editing_lexeme = structuredClone(updated);
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
          annotated_doc={data.annotated_doc}
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
            constituent={last_clicked_sentence_cst}
            annotated_doc={data.annotated_doc}
          ></TokenInfoPane>
        </div>
      </AccordionEntry>
      
      <AccordionEntry>
        <h2 slot="header" class="px-3 font-bold bg-orange-50">Lexeme Editor</h2>
        <div class="p-3">
          {#if lexeme_edit_state === "notEditing"}
            <p>nothing to edit</p>
          {:else if lexeme_edit_state === "newToken"}
            {#if last_clicked_sentence_cst.unwrap()?.orthography != last_clicked_sentence_cst.unwrap()?.lemma} 
              <p>this is an inflection of <u>{last_clicked_sentence_cst.unwrap()?.lemma}</u></p>
            {/if}
            <TokenEditForm 
              editing_token={editing_lexeme}
              create_or_update={"create"}
              on:submit={createToken}
            />
          {:else if lexeme_edit_state === "existingToken"}
            {#if last_clicked_sentence_cst.unwrap()?.orthography != last_clicked_sentence_cst.unwrap()?.lemma} 
              <p>this is an inflection of <u>{last_clicked_sentence_cst.unwrap()?.lemma}</u></p>
            {/if}
            <TokenEditForm 
              editing_token={editing_lexeme}
              create_or_update={"update"}
              on:submit={createToken}
            />
          {:else if lexeme_edit_state === "newPhrase"}
            <PhraseEditForm 
              editing_phrase={editing_lexeme}
              create_or_update={"create"}
            />
          {:else if lexeme_edit_state === "existingPhrase"}
            <PhraseEditForm 
              editing_phrase={editing_lexeme}
              create_or_update={"update"}
            />
          {:else}
            UNREACHABLE
          {/if}

        </div>
      </AccordionEntry>

      <AccordionEntry>
        <h2 slot="header" class="px-3 font-bold bg-rose-50">Last Hovered</h2>
        <div class="p-3">
          <TokenInfoPane 
            constituent={last_hovered_sentence_cst}
            annotated_doc={data.annotated_doc}
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
    <DbgJsonData name='tokenFormData bindings' data={editing_lexeme} />
    <DbgJsonData name='page params' data={$page.params} />
    <DbgJsonData name='last_hovered_sentence_cst' data={last_hovered_sentence_cst} />
    <DbgJsonData name='last_clicked_sentence_cst' data={last_clicked_sentence_cst} />
    <DbgJsonData name='last_hovered_lexeme' data={last_hovered_lexeme} />
    <DbgJsonData name='last_clicked_lexeme' data={last_clicked_lexeme} />
  </div>
</PaneLayout>


