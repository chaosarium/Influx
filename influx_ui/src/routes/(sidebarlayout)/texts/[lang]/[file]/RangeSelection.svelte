<script lang="ts">
  import { page } from '$app/stores';
    import type { Token } from "$lib/types/Token";
    import type { Lexeme } from "$lib/types/Lexeme";
    import { Option } from "$lib/types/Option";
    import type { AnnotatedDocument } from "$lib/types/AnnotatedDocument";
    import type { DocumentConstituent } from "$lib/types/DocumentConstituent";
    import type { SentenceConstituent } from "$lib/types/SentenceConstituent";
    import type { DocumentSlice } from "$lib/types/Aliases";
    import { is_cst_in_slice } from "$lib/utils";
    import { dbgConsoleMessages } from '$lib/store';
  export let last_focused_slice: Option<DocumentSlice>;
  export let annotated_doc: AnnotatedDocument;

  function flatten_sentence_cons(sentence_cons: SentenceConstituent[]) : SentenceConstituent[] {
    return sentence_cons.flatMap((sentence_con) => {
      switch (sentence_con.type) {
        case "SingleToken":
          return [sentence_con];
        case "SubwordToken":
          return [sentence_con];
        case "PhraseToken":
          return flatten_sentence_cons(sentence_con.shadows);
        case "CompositToken":
          return flatten_sentence_cons(sentence_con.shadows);
        case "Whitespace":
          return [sentence_con];
      }
    });
  }

  function flatten_document_con_inner(document_con: DocumentConstituent) : DocumentConstituent {
    switch (document_con.type) {
      case "Sentence":
        return {
          type: "Sentence",
          id: document_con.id,
          text: document_con.text,
          start_char: document_con.start_char,
          end_char: document_con.end_char,
          constituents: flatten_sentence_cons(document_con.constituents),
        };
      case "Whitespace":
        return document_con;
    }
  }

  function flatten_document_cons(document_cons: DocumentConstituent[]) : SentenceConstituent[] {
    return document_cons.flatMap((document_con) => {
      switch (document_con.type) {
        case "Sentence":
          return flatten_sentence_cons(document_con.constituents);
        case "Whitespace":
          return [{
            type: "Whitespace",
            text: document_con.text,
            orthography: document_con.text,
            start_char: document_con.start_char,
            end_char: document_con.end_char,
            shadowed: false,
            shadows: [],
          }];
      }
    });
  }

  function gt_slice_content(slice: DocumentSlice): string[] {
    let ss = slice[0][0];
    let es = slice[1][0];
    let st = slice[0][1];
    let et = slice[1][1];
    let sc = slice[0][2];
    let ec = slice[1][2];
    // let related_cons = annotated_doc.cons.slice(slice[0][0], slice[1][0]+1);
    let ssi = annotated_doc.constituents.findIndex((con) => con.type == "Sentence" && con.id == ss);
    let esi = annotated_doc.constituents.findIndex((con) => con.type == "Sentence" && con.id == es);
    console.log("ssi", ssi, "esi", esi);
    let related_cons = annotated_doc.constituents.slice(ssi, esi+1);
    let related_cons_flat = flatten_document_cons(related_cons);
    let slice_cons = related_cons_flat.filter((con) => {
      return is_cst_in_slice(slice, con);
    })
    let slice_content = slice_cons.map((con) => con.text);
    return slice_content;
  }

  // returns the current selection (in concatinated string) and the language code (from the page params)
  function gt_selection_context(): [string, string] {
    let query = gt_slice_content(last_focused_slice.unwrap()).join("");
    let lang_code = $page.params.lang;
    return [query, lang_code];
  }

  // hand selection to the nlp backend
  async function lookup_button_click() {
    let [query, lang_code] = gt_selection_context();
    const response = await fetch(`http://127.0.0.1:3000/extern/macos_dict/${lang_code}/${query}`);
  }

  // hand selection to the nlp backend, and get back a translation
  let translated_text: string = ""
  async function translate_button_click() {
    let [query, lang_code] = gt_selection_context();

    const response = await fetch('http://127.0.0.1:3000/extern/translate', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        "from_lang_id": "en", 
        "to_lang_id": "fr", 
        "source_sequence": query,
        "provider": "google"
      }),
    });

    if (!response.ok) {
      const message = `An error has occurred: ${response.status}`;
      dbgConsoleMessages.push_back(`failed calling extern/translate ${message}`);
      } else {
      console.log(response);
      const res_json = await response.json();
      translated_text = res_json.translated_text;
    }

  }

  // call browser's tts api with selection
  async function tts_button_click() {
    let [query, lang_code] = gt_selection_context();
    
    const synth = window.speechSynthesis;
    const voices = synth.getVoices();

    // temporarily fix tts lang code, will make this configurable in the future
    console.log("lang_code: ", lang_code);
    if (lang_code == "fr_demo") {
      lang_code = "fr-FR";
    }

    const speak = (text: string, tts_lang_code: string, tts_speaker_name: string, tts_speed: number) => {
      const utterance = new SpeechSynthesisUtterance(text);
      const voice = voices.find((v) => v.lang === tts_lang_code && v.name === tts_speaker_name);
      console.log("voice being selected: ", voice, " among ", voices);
      if (voice) {
        utterance.voice = voice;
      }
      utterance.rate = tts_speed;
      synth.speak(utterance);
    };

    let tts_speaker_name = "Thomas";
    let tts_speed = 1.0;
    speak(query, lang_code, tts_speaker_name, tts_speed);
  }

  // Implement some APIs for opening an URL (presumably for dictionary or translator but can also be used for other things) either in a broser new tab, browser new window, a tauri webview, or a tauri window. For tauri webview/window, there's an additional option for whether to replace an exesting lookup webview/window or not.
  type WebOpenLocation = "new_tab" | "new_window"| "tauri_webview_new" | "tauri_webview_replace" | "tauri_window_new" | "tauri_window_replace";

  function influx_open_url(url: string, location: WebOpenLocation) {
    switch (location) {
      case "new_tab":
        window.open(url, '_blank');
        break;
      case 'new_window':
        window.open(url, '_blank', 'toolbar=0,location=0,menubar=0');
        break;
      case 'tauri_webview_new':
        // todo
        break;        
      case 'tauri_webview_replace':
        // todo
        break;        
      case 'tauri_window_new':
        // todo
        break;        
      case 'tauri_window_replace':
        // todo
        break;        
    }
  }

</script>


<p><em>slice selection</em></p>
<ol>
  {#if last_focused_slice.is_none()}
    <li>
      no slice focused
    </li>
  {:else}
    <li>
      slice: {JSON.stringify(last_focused_slice)}
    </li>
    <li>
      slice content (csts): {JSON.stringify(gt_slice_content(last_focused_slice.unwrap()))}
    </li>
    <li>
      slice content (string): {gt_slice_content(last_focused_slice.unwrap()).join("")}
    </li>
    <li>
      translated: <span class="bg-yellow-200 ">{translated_text}</span>
    </li>
  {/if}
</ol>


<input class="mt-2 border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" type="button" value="Lookup (Mac Dictionary)" on:click={lookup_button_click}>
<br>
<input class="mt-2 border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" type="button" value="Translate (Google Translate API)" on:click={translate_button_click}>
<br>
<input class="mt-2 border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" type="button" value="Lookup (Web Dict in tab)" on:click={() => influx_open_url('https://www.wordreference.com/fren/', 'new_tab')}>
<input class="mt-2 border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" type="button" value="Lookup (Web Dict in new window)" on:click={() => influx_open_url('https://www.wordreference.com/fren/', 'new_window')}>
<br>
<input class="mt-2 border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" type="button" value="TTS (OS Voices)" on:click={tts_button_click}>
<input class="mt-2 border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" type="button" value="Copy">