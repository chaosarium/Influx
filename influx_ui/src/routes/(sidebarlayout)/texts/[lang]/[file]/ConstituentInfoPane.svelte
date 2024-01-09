<script lang="ts">
    import type { Token } from "$lib/types/Token";
    import type { Phrase } from "$lib/types/Phrase";
    import type { SentenceConstituent } from "$lib/types/SentenceConstituent";
    import type { AnnotatedDocument } from "$lib/types/AnnotatedDocument";
    import { Option } from "$lib/types/Option";
    import type { Lexeme } from "$lib/types/Lexeme";
    import { try_lookup } from "$lib/utils";

    export let constituent: Option<SentenceConstituent>;
    export let annotated_doc: AnnotatedDocument;
    let token_dict = annotated_doc.token_dict as Record<string, Token>;
    let phrase_dict = annotated_doc.phrase_dict as Record<string, Phrase>;

    let lexeme: Option<Lexeme> = Option.None();

    $: lexeme = try_lookup(token_dict, phrase_dict, constituent);
</script>

{#if constituent.is_none()}
    <p>no constituent selected</p>
{:else}
    <!-- constituent info -->
    {#each [constituent.unwrap()] as c}
        <p><em>constituent info</em></p>
        <ol>
            <li>
                type: <b>{c.type}</b>
            </li>
            <li>
                text: <b>{c.text}</b>
            </li>
            <li>
                {#if c.type === "SingleToken" || c.type === "SubwordToken" || c.type === "CompositToken"}
                    orthography: <b>{c.orthography}</b>
                {:else if c.type === "Whitespace"}
                    UNREACHABLE
                {:else if c.type === "PhraseToken"}
                    normalised_orthography: <b>{c.normalised_orthography}</b>
                {/if}
            </li>
            <li>
                {#if c.type === "SingleToken" || c.type === "SubwordToken"}
                    lemma: <b>{c.lemma}</b>
                {:else if c.type === "Whitespace" || c.type === "CompositToken"}
                    lemma: N/A
                {:else if c.type === "PhraseToken"}
                    lemma: N/A
                {/if}
            </li>
            <li>
                shadows: <b>{JSON.stringify(c.shadows)}</b>
            </li>
        </ol>

        <hr />
        <!-- dict_entry info -->
        {#if lexeme.is_none()}
            UNREACHABLE
        {:else}
            {#each [lexeme.unwrap()] as l}
                {#if l.type === "Token"}
                    <p><em>in vocab db:</em></p>
                    <ol>
                        <li>
                            tb: <b>{l.value.id?.tb}</b>
                        </li>
                        <li>
                            id: <b>{l.value.id?.id.String}</b>
                        </li>
                        <li>
                            lang_id: <b>{l.value.lang_id}</b>
                        </li>
                        <li>
                            orthography: <b>{l.value.orthography}</b>
                        </li>
                        <li>
                            phonetic: <b>{l.value.phonetic}</b>
                        </li>
                        <li>
                            definition: <b>{l.value.definition}</b>
                        </li>
                        <li>
                            notes: <b>{l.value.notes}</b>
                        </li>
                        <li>
                            original_context: <b>{l.value.original_context}</b>
                        </li>
                        <li>
                            status: <b>{l.value.status}</b>
                        </li>
                        <li>
                            tags: <b>{JSON.stringify(l.value.tags)}</b>
                        </li>
                        <li>
                            srs: <b>{JSON.stringify(l.value.srs)}</b>
                        </li>
                    </ol>
                {:else if l.type === "Phrase"}
                    <p><em>in phrase db:</em></p>
                    <ol>
                        <li>
                            tb: <b>{l.value.id?.tb}</b>
                        </li>
                        <li>
                            id: <b>{l.value.id?.id.String}</b>
                        </li>
                        <li>
                            lang_id: <b>{l.value.lang_id}</b>
                        </li>
                        <li>
                            orthography_seq: <b
                                >{JSON.stringify(l.value.orthography_seq)}</b
                            >
                        </li>
                        <li>
                            definition: <b>{l.value.definition}</b>
                        </li>
                        <li>
                            notes: <b>{l.value.notes}</b>
                        </li>
                        <li>
                            original_context: <b>{l.value.original_context}</b>
                        </li>
                        <li>
                            status: <b>{l.value.status}</b>
                        </li>
                        <li>
                            tags: <b>{JSON.stringify(l.value.tags)}</b>
                        </li>
                        <li>
                            srs: <b>{JSON.stringify(l.value.srs)}</b>
                        </li>
                    </ol>
                {:else}
                    UNREACHABLE
                {/if}
            {/each}
        {/if}
    {/each}
{/if}
