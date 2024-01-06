<script lang="ts">
    import Token from "$lib/components/Token.svelte";
    import type { Token as TokenT } from "$lib/types/Token";
    import type { Document } from "$lib/types/Document";
    export let parsed_doc: Document;
    export let tokens_dict: Record<string, TokenT>;
    let tokenisation_debug = true;
    let moreclass = '';
    export { moreclass as class };
</script>

<div class={`leading-8 text-xl ${moreclass}`}>
    {#each parsed_doc.constituents as sentence_constituent}
        {#if sentence_constituent.type == "Whitespace"}
            <span class="whitespace-pre-wrap" class:bg-green={tokenisation_debug}
                >{sentence_constituent.text}</span
            >
        {:else if sentence_constituent.type == "Sentence"}
            <span class="py-1 " class:sentence_dbg={tokenisation_debug}>
                {#each sentence_constituent.constituents as constituent}
                    {#if constituent.type == "CompositToken"}
                        <Token
                            constituent={constituent}
                            token={tokens_dict[constituent?.orthography]}
                            on:token_hover
                            on:token_click
                            tokenisation_debug={tokenisation_debug}
                        />
                    {:else if constituent.type == "SubwordToken"}
                        <!-- ghost SubwordToken -->
                    {:else if constituent.type == "SingleToken"}
                        <Token
                            constituent={constituent}
                            token={tokens_dict[constituent?.orthography]}
                            on:token_hover
                            on:token_click
                            tokenisation_debug={tokenisation_debug}
                        />
                    {:else if constituent.type == "Whitespace"}
                        <span class="whitespace-pre-wrap" class:bg-green-100={tokenisation_debug}
                            >{constituent.text}</span
                        >
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