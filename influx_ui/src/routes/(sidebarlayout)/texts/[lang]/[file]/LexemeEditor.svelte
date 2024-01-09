<script lang="ts">
    import TokenC from "$lib/components/TokenC.svelte";
    import DbgJsonData from "$lib/dbg/DbgJsonData.svelte";
    import AnnotatedText from "./AnnotatedText.svelte";
    import TokenInfoPane from "./ConstituentInfoPane.svelte";
    import DesktopLayout from "./DesktopLayout.svelte";
    import PaneLayout from "$lib/wrappers/PaneLayout.svelte";
    import MainSidebar from "$lib/components/MainSidebarInner.svelte";
    import DbgConsole from "$lib/dbg/DbgConsole.svelte";
    import { writable_count, dbgConsoleMessages, working_doc } from "$lib/store";
    import { writable } from "svelte/store";
    import Accordion from "$lib/components/Accordion.svelte";
    import AccordionEntry from "$lib/components/AccordionEntry.svelte";
    import type { Token } from "$lib/types/Token";
    import type { Phrase } from "$lib/types/Phrase";
    import type { SentenceConstituent } from "$lib/types/SentenceConstituent";
    import type { AnnotatedDocument } from "$lib/types/AnnotatedDocument";
    import { Option } from "$lib/types/Option";
    import { try_access, try_key, try_lookup } from "$lib/utils";
    import TokenEditForm from "./TokenEditForm.svelte";
    import PhraseEditForm from "./PhraseEditForm.svelte";

    export let annotated_doc: Record<string, Token>;
    export let last_clicked_sentence_cst: Option<SentenceConstituent>;



    $: last_clicked_lexeme = try_lookup(
        $working_doc.annotated_doc.token_dict,
        $working_doc.annotated_doc.phrase_dict,
        last_clicked_sentence_cst,
    );

    let editing_lexeme: undefined | Token | Phrase = undefined;
    let lexeme_edit_state:
        | "notEditing"
        | "newToken"
        | "existingToken"
        | "existingPhrase"
        | "newPhrase" = "notEditing";

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
            dbgConsoleMessages.push_back(
                `editing_lexeme: ${JSON.stringify(
                    editing_lexeme,
                )}, lexeme_edit_state: ${lexeme_edit_state}`,
            );
        }
    }
    $: last_clicked_sentence_cst, updateEditingLexeme();

    const handleLexemeEdited = (event: { detail: Token | Phrase }) => {
        editing_lexeme = structuredClone(event.detail);
        last_clicked_lexeme = try_lookup(
            $working_doc.annotated_doc.token_dict,
            $working_doc.annotated_doc.phrase_dict,
            last_clicked_sentence_cst,
        );
        dbgConsoleMessages.push_back(
            `handleLexemeEdited updated editor to: ${JSON.stringify(editing_lexeme)}`,
        );
        updateEditingLexeme();
    };

</script>

{#if lexeme_edit_state === "notEditing"}
    <p>nothing to edit</p>
{:else if lexeme_edit_state === "newToken"}
    {#if last_clicked_sentence_cst.unwrap()?.orthography != last_clicked_sentence_cst.unwrap()?.lemma}
        <p>
            this is an inflection of <u>{last_clicked_sentence_cst.unwrap()?.lemma}</u>
        </p>
    {/if}
    <TokenEditForm
        bind:editing_token={editing_lexeme}
        create_or_update={"create"}
        on:lexeme_edited={handleLexemeEdited}
    />
{:else if lexeme_edit_state === "existingToken"}
    {#if last_clicked_sentence_cst.unwrap()?.orthography != last_clicked_sentence_cst.unwrap()?.lemma}
        <p>
            this is an inflection of <u>{last_clicked_sentence_cst.unwrap()?.lemma}</u>
        </p>
    {/if}
    <TokenEditForm
        bind:editing_token={editing_lexeme}
        create_or_update={"update"}
        on:lexeme_edited={handleLexemeEdited}
    />
{:else if lexeme_edit_state === "newPhrase"}
    <!-- <PhraseEditForm
        bind:editing_phrase={editing_lexeme}
        create_or_update={"create"}
    /> -->
{:else if lexeme_edit_state === "existingPhrase"}
    <!-- <PhraseEditForm
        bind:editing_phrase={editing_lexeme}
        create_or_update={"update"}
    /> -->
{:else}
    UNREACHABLE
{/if}

<DbgJsonData name="editing_lexeme" data={editing_lexeme} />
<DbgJsonData name="last_clicked_lexeme" data={last_clicked_lexeme} />
