<script lang="ts">
    import type { Token as TokenT } from "$lib/types/Token";
    import type { Phrase as PhraseT } from "$lib/types/Phrase";
    import type { AnnotatedDocument } from "$lib/types/AnnotatedDocument";
    import Token from "$lib/components/TokenC.svelte";
    import Phrase from "../../../../../lib/components/PhraseC.svelte";
    import type { DocumentSlice } from "$lib/types/Aliases";
    import { Option } from '$lib/types/Option';
    import { is_cst_in_slice } from "$lib/utils";
    export let annotated_doc: AnnotatedDocument;
    export let last_focused_slice: Option<DocumentSlice>;
    let tokenisation_debug = true;
    let moreclass = "";
    $: token_dict = annotated_doc.token_dict as Record<string, TokenT>;
    $: phrase_dict = annotated_doc.phrase_dict as Record<string, PhraseT>;
    export let mount_ready: boolean;

    export { moreclass as class };
</script>

{#if mount_ready}
    <div class={`leading-8 text-xl ${moreclass}`}>
        {#each annotated_doc.constituents as sentence_constituent}{#if sentence_constituent.type == "Whitespace"}<span
                    class="whitespace-pre-wrap"
                    class:bg-green={tokenisation_debug}
                    >{sentence_constituent.text}</span
                >{:else if sentence_constituent.type == "Sentence"}<span
                    class="py-1"
                    class:sentence_dbg={tokenisation_debug}
                    >{#each sentence_constituent.constituents as constituent}{#if constituent.type == "CompositToken" || constituent.type == "SubwordToken" || constituent.type == "SingleToken"}{#if constituent.shadowed === false}<Token
                                    {constituent}
                                    token={token_dict[constituent.orthography]}
                                    on:token_mouseenter
                                    on:token_click
                                    on:token_mousedown
                                    on:token_mouseup
                                    is_focused={last_focused_slice.is_some() ? is_cst_in_slice(last_focused_slice.unwrap(), constituent) : false}
                                    {tokenisation_debug}
                                />{/if}{:else if constituent.type == "PhraseToken"}{#if constituent.shadowed === false}<Phrase
                                    {constituent}
                                    phrase={phrase_dict[
                                        constituent.normalised_orthography
                                    ]}
                                    on:token_mouseenter
                                    on:token_click
                                    on:token_mousedown
                                    on:token_mouseup
                                    {tokenisation_debug}
                                    {token_dict}
                                    {phrase_dict}
                                    is_focused={last_focused_slice.is_some() ? is_cst_in_slice(last_focused_slice.unwrap(), constituent) : false}
                                    last_focused_slice={last_focused_slice}

                                />{/if}{:else if constituent.type == "Whitespace"}{#if constituent.shadowed === false}<span
                                    class="whitespace-pre-wrap"
                                    class:bg-green-100={tokenisation_debug}
                                    >{constituent.text}</span
                                >{/if}{/if}{/each}</span
                >{:else}<span class="">PANIC</span>{/if}{/each}
    </div>
{:else}
    <p>loading...</p>
{/if}

<style>
    .sentence_dbg {
        @apply border-1 border-blue-200 hover:bg-blue-200;
    }
</style>
