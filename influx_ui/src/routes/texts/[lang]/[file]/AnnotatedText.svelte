<script>
    import Token from "$lib/components/Token.svelte";
    export let parsed_doc;
    export let tokens_dict;
</script>

<div class="p-4 leading-8 text-xl bg-white">
    {#each parsed_doc.constituents as sentence_constituent}
        {#if sentence_constituent.type == "Whitespace"}
            <span class="bg-green-200 whitespace-pre-wrap"
                >{sentence_constituent.text}</span
            >
        {:else if sentence_constituent.type == "Sentence"}
            <span class="border-1 border-blue-200 py-1 hover:bg-blue-200">
                {#each sentence_constituent.constituents as constituent}
                    {#if constituent.type == "CompositToken"}
                        <Token
                            token={tokens_dict[constituent?.text]}
                            on:token_hover
                            on:token_click
                        />
                    {:else if constituent.type == "SubwordToken"}
                        <!-- ghost SubwordToken -->
                    {:else if constituent.type == "SingleToken"}
                        <Token
                            token={tokens_dict[constituent?.text]}
                            on:token_hover
                            on:token_click
                        />
                    {:else if constituent.type == "Whitespace"}
                        <span class="bg-green-200 whitespace-pre-wrap"
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
