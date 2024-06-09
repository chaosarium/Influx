<script lang="ts">
  import { page } from '$app/stores';
  // export let data: {
  //   lang: string,
  //   file: string,
  // };
  import TokenC from "$lib/components/TokenC.svelte";
  import DbgJsonData from "$lib/dbg/DbgJsonData.svelte";
  import AnnotatedText from './AnnotatedText.svelte';
  import TokenInfoPane from './ConstituentInfoPane.svelte';
  import DesktopLayout from './DesktopLayout.svelte';
  import PaneLayout from '$lib/wrappers/PaneLayout.svelte';
  import MainSidebar from '$lib/components/MainSidebarInner.svelte';
  import DbgConsole from '$lib/dbg/DbgConsole.svelte';
  import { writable_count, dbgConsoleMessages, fetchWorkingDocument, working_doc } from '$lib/store';
  import { writable } from 'svelte/store';
  import Accordion from '$lib/components/Accordion.svelte';
  import AccordionEntry from '$lib/components/AccordionEntry.svelte';
  import type { Token } from "$lib/types/Token";
  import type { Phrase } from "$lib/types/Phrase";
  import type { SentenceConstituent } from '$lib/types/SentenceConstituent';
  import type { AnnotatedDocument } from '$lib/types/AnnotatedDocument';
  import { Option } from '$lib/types/Option';
  import { try_access, try_key, try_lookup } from '$lib/utils';
  import LexemeEditor from './LexemeEditor.svelte';
  import RangeSelection from "./RangeSelection.svelte";
  import { app_settings } from '$lib/store';
  import { onMount, onDestroy } from 'svelte';
  import { fetchSettings } from '$lib/store';
  import type { DocumentSlice } from '$lib/types/Aliases';

  let mount_ready = false;
  onMount(async () => {
    await fetchWorkingDocument($page.params.lang, $page.params.file);
    mount_ready = true;
  });

  $: token_dict = $working_doc.annotated_doc.token_dict as Record<string, Token>;
  $: phrase_dict = $working_doc.annotated_doc.phrase_dict as Record<string, Phrase>;

  let last_hovered_sentence_cst: Option<SentenceConstituent> = Option.None();
  let last_clicked_sentence_cst: Option<SentenceConstituent> = Option.None();
  let last_focused_slice: Option<DocumentSlice> = Option.None(); // [[start_sentence_id, start_token_id, start_char], [end_sentence_id (incl), end_token_id (incl), end_char (excl)]]
  let mouse_is_down = false;

  const handleSentenceCstMouseEnter = (event: { detail: SentenceConstituent }) => {
    last_hovered_sentence_cst = Option.Some(event.detail);
    // dbgConsoleMessages.push_back("hovered: " + JSON.stringify(last_hovered_sentence_cst));

    if (last_focused_slice.is_some() && mouse_is_down) {
      // update end location
      switch (event.detail.type) {
        case "SubwordToken":
        case "SingleToken":
          last_focused_slice = Option.Some([
            last_focused_slice.unwrap()[0], 
            [event.detail.sentence_id, event.detail.id, event.detail.end_char]
          ]);
          break;
        case "Whitespace":
          break;
        case "CompositToken":
        case "PhraseToken":
          last_focused_slice = Option.Some([
            last_focused_slice.unwrap()[0], 
            [event.detail.sentence_id, event.detail.shadows[event.detail.shadows.length-1].id, event.detail.shadows[event.detail.shadows.length-1].end_char]
          ]);
          break;
      }
    }

  };
  const handleSentenceCstMouseDown = (event: { detail: SentenceConstituent }) => {
    dbgConsoleMessages.push_back("mouse down on: " + JSON.stringify(event.detail));
    mouse_is_down = true;
    // update last focused slice
    switch (event.detail.type) {
      case "SubwordToken":
      case "SingleToken":
        last_focused_slice = Option.Some([
          [event.detail.sentence_id, event.detail.id, event.detail.start_char], 
          [event.detail.sentence_id, event.detail.id, event.detail.end_char]
        ]);
        break;
      case "Whitespace":
        break;
      case "CompositToken":
      case "PhraseToken":
        last_focused_slice = Option.Some([
          [event.detail.sentence_id, event.detail.shadows[0].id, event.detail.shadows[0].start_char], 
          [event.detail.sentence_id, event.detail.shadows[event.detail.shadows.length-1].id, event.detail.shadows[event.detail.shadows.length-1].end_char]
        ]);
        break;
    }

  };
  const handleSentenceCstMouseUp = (event: { detail: SentenceConstituent }) => {
    dbgConsoleMessages.push_back("mouse up on: " + JSON.stringify(event.detail));
    mouse_is_down = false;
  };
  const handleSentenceCstClick = (event: { detail: SentenceConstituent }) => {
    last_clicked_sentence_cst = Option.Some(event.detail);
    dbgConsoleMessages.push_back("clicked: " + JSON.stringify(last_clicked_sentence_cst));
  };

  $: last_hovered_lexeme = try_lookup(token_dict, phrase_dict, last_hovered_sentence_cst)
  $: last_clicked_lexeme = try_lookup(token_dict, phrase_dict, last_clicked_sentence_cst)


</script>






<PaneLayout show_left={false} show_mid_top={false}>

  <div slot="mid-mid" class="h-full">

    <!-- content column -->
    <div class="flex justify-center my-auto h-full">
      <div class="mx-3 my-auto max-w-[800px] flex-auto">
        
        <h1 class="font-bold text-3xl mt-4 mb-2">{$working_doc.metadata.title}</h1>
        <p class="text-gray-500">Tags: {undefined}</p>
        <p class="text-gray-500">File: {undefined}</p>
        <p class="text-gray-500">Created: {$working_doc.metadata.date_created}</p>
        <p class="text-gray-500">Modified: {$working_doc.metadata.date_modified}</p>
        <p class="text-gray-500">Last Viewed: {undefined}</p>


        <AnnotatedText 
          annotated_doc={$working_doc.annotated_doc}
          last_focused_slice={last_focused_slice}
          on:token_mouseenter={handleSentenceCstMouseEnter} 
          on:token_click={handleSentenceCstClick}
          on:token_mousedown={handleSentenceCstMouseDown}
          on:token_mouseup={handleSentenceCstMouseUp}
          class="my-4"
          mount_ready={mount_ready}
        ></AnnotatedText>

      </div>
    </div>


  </div>

  <div slot="right">

    <Accordion>

      <AccordionEntry>
        <h2 slot="header" class="px-3 font-bold bg-orange-50">Lexeme Editor</h2>
        <div class="p-3">
          <LexemeEditor 
            last_clicked_sentence_cst={last_clicked_sentence_cst}
          ></LexemeEditor>
        </div>
      </AccordionEntry>

      <AccordionEntry>
        <h2 slot="header" class="px-3 font-bold bg-orange-50">Current Selection</h2>
        <div class="p-3">
          <RangeSelection 
            last_focused_slice={last_focused_slice}
            annotated_doc={$working_doc.annotated_doc}
          ></RangeSelection>
        </div>
      </AccordionEntry>

      <AccordionEntry>
        <h2 slot="header" class="px-3 font-bold bg-amber-50">Last Clicked</h2>
        <div class="p-3">
          <TokenInfoPane 
            constituent={last_clicked_sentence_cst}
            annotated_doc={$working_doc.annotated_doc}
          ></TokenInfoPane>
        </div>
      </AccordionEntry>
      
      <AccordionEntry>
        <h2 slot="header" class="px-3 font-bold bg-rose-50">Last Hovered</h2>
        <div class="p-3">
          <TokenInfoPane 
            constituent={last_hovered_sentence_cst}
            annotated_doc={$working_doc.annotated_doc}
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
    <DbgJsonData name='working_doc' data={$working_doc} />
    <DbgJsonData name='page params' data={$page.params} />
    <DbgJsonData name='app settings' data={$app_settings} />
    <DbgJsonData name='last_hovered_sentence_cst' data={last_hovered_sentence_cst} />
    <DbgJsonData name='last_clicked_sentence_cst' data={last_clicked_sentence_cst} />
    <DbgJsonData name='last_hovered_lexeme' data={last_hovered_lexeme} />
    <DbgJsonData name='last_clicked_lexeme' data={last_clicked_lexeme} />
  </div>
</PaneLayout>


