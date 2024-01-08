<script lang="ts">
    import type { Token as TokenT } from "$lib/types/Token";
    import type { Phrase as PhraseT } from "$lib/types/Phrase";
    import type { AnnotatedDocument } from "$lib/types/AnnotatedDocument";
    import Token from "$lib/components/Token.svelte";
    import Phrase from "../../../../../lib/components/Phrase.svelte";
    
    export let annotated_doc: AnnotatedDocument;
    let tokenisation_debug = true;
    let moreclass = '';
    let token_dict = annotated_doc.token_dict as Record<string, TokenT>;
    let phrase_dict = annotated_doc.phrase_dict as Record<string, PhraseT>;
    
    export { moreclass as class };
</script>

<div class={`leading-8 text-xl ${moreclass}`}>
    {#each annotated_doc.constituents as sentence_constituent}
        {#if sentence_constituent.type == "Whitespace"}
            <span class="whitespace-pre-wrap" class:bg-green={tokenisation_debug}
                >{sentence_constituent.text}</span
            >
        {:else if sentence_constituent.type == "Sentence"}
            <span class="py-1 " class:sentence_dbg={tokenisation_debug}>
                {#each sentence_constituent.constituents as constituent}
                    {#if constituent.type == "CompositToken" || constituent.type == "SubwordToken" || constituent.type == "SingleToken"}
                        {#if constituent.shadowed === false}
                            <Token
                                constituent={constituent}
                                token={token_dict[constituent.orthography]}
                                on:token_hover
                                on:token_click
                                tokenisation_debug={tokenisation_debug}
                            />
                        {/if}
                    {:else if constituent.type == "PhraseToken"}
                        {#if constituent.shadowed === false}
                            <Phrase
                                constituent={constituent}
                                phrase={phrase_dict[constituent.normalised_orthography]}
                                on:token_hover
                                on:token_click
                                tokenisation_debug={tokenisation_debug}
                                token_dict={token_dict}
                                phrase_dict={phrase_dict}
                            />
                        {/if}
                        {:else if constituent.type == "Whitespace"}
                        {#if constituent.shadowed === false}
                            <span class="whitespace-pre-wrap" class:bg-green-100={tokenisation_debug}
                                >{constituent.text}</span
                            >
                        {/if}
                    {/if}
                {/each}
            </span>
        {:else}
            <span class="">PANIC</span>
        {/if}
    {/each}
</div>

<style>
    .sentence_dbg {
        @apply border-1 border-blue-200 hover:bg-blue-200;
    }
</style>