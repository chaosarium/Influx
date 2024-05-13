<script lang="ts">
    import type { Token } from "$lib/types/Token";
    import type { Lexeme } from "$lib/types/Lexeme";
    import { Option } from "$lib/types/Option";
    import type { AnnotatedDocument } from "$lib/types/AnnotatedDocument";
    import type { DocumentConstituent } from "$lib/types/DocumentConstituent";
    import type { SentenceConstituent } from "$lib/types/SentenceConstituent";
    import type { DocumentSlice } from "$lib/types/Aliases";
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

  function gt_slice_content(slice: DocumentSlice): string {
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
      switch (con.type) {
        case "SingleToken":
        case "SubwordToken":
          return ((con.sentence_id == ss && con.id >= st) || con.sentence_id > ss) && ((con.sentence_id == es && con.id <= et) || con.sentence_id < es);
        case "PhraseToken":
        case "CompositToken":
        case "Whitespace":
          return con.start_char >= sc && con.end_char <= ec;
      }
    })
    let slice_string = slice_cons.map((con) => con.text).join("");
    return slice_string;
  }
</script>


<p><em>last focused slice</em></p>
<ol>
  {#if last_focused_slice.is_none()}
    <li>
      no slice focused
    </li>
  {:else}
    <li>
      last focused slice: {JSON.stringify(last_focused_slice)}
    </li>
    <li>
      slice content (string): {gt_slice_content(last_focused_slice.unwrap())}
    </li>
  {/if}
</ol>


<input class="mt-2 border-solid border-2 border-gray-400 disabled:border-gray-200 disabled:cursor-not-allowed" type="button" value="Lookup">
