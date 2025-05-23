<script lang="ts">
  import TokenTooltip from "./TokenTooltip.svelte";
  import { createEventDispatcher } from 'svelte';
  import type { Phrase as Phrase } from "$lib/types/Phrase";
  import type { Token } from "$lib/types/Token";
  import type { SentenceConstituent } from "$lib/types/SentenceConstituent";
  import TokenC from "./TokenC.svelte";
    import { is_cst_in_slice } from "$lib/utils";
    export let last_focused_slice: Option<DocumentSlice>;
  export let constituent: SentenceConstituent;
  export let phrase: Phrase;
  export let token_dict: Record<string, Token>;
  export let phrase_dict: Record<string, Phrase>;

  const dispatch = createEventDispatcher();
  export let tokenisation_debug: boolean = false;

  let altKeyPressed = false;

  function handleKeyDown(event: KeyboardEvent) {
    altKeyPressed = event.altKey;
  }

  function handleKeyUp(event: KeyboardEvent) {
    altKeyPressed = event.altKey;
  }
  export let is_focused: boolean = false;

</script>

<svelte:window on:keydown={handleKeyDown} on:keyup={handleKeyUp} />

<!-- <TokenTooltip token={token}> -->
<div class="inline hover:cursor-default">
  
  {#if !altKeyPressed}



    <ruby>
      <ruby>
        <ruby style="ruby-position: alternate;">
          <span class=""
            class:border-white-50={phrase.status === 'UNMARKED'}
            class:border-violet-400={phrase.status === 'IGNORED'}
            class:border-red-400={phrase.status === 'L1'}
            class:border-orange-400={phrase.status === 'L2'}
            class:border-amber-400={phrase.status === 'L3'}
            class:border-lime-400={phrase.status === 'L4'}
            class:border-teal-400={phrase.status === 'L5'}
            on:mouseenter={() => dispatch('token_mouseenter', constituent)}
            on:click={() => dispatch('token_click', constituent)}
            on:mousedown={() => dispatch('token_mousedown', constituent)}
            on:mouseup={() => dispatch('token_mouseup', constituent)}
            class:token_dbg={tokenisation_debug}

            class:underline={is_focused}
            class:decoration-double={is_focused}
            class:decoration-2={is_focused}
            class:decoration-blue-500={is_focused}

          >
                    {#each constituent.shadows as sub_constituent}
                      {#if sub_constituent.type == "CompositToken" || sub_constituent.type == "SingleToken"}
                        <TokenC
                            constituent={sub_constituent}
                            token={token_dict[sub_constituent.orthography]}
                            tokenisation_debug={false}
                            is_focused={last_focused_slice.is_some() ? is_cst_in_slice(last_focused_slice.unwrap(), constituent) : false}
                          />
                      {:else if sub_constituent.type == "SentenceWhitespace"}
                        <span class="whitespace-pre-wrap" class:bg-green-100={tokenisation_debug}
                            >{sub_constituent.text}</span
                        >
                      {:else}
                        UNREACHABLE
                      {/if}
                    {/each}
    
          </span>      
        </ruby><rt data-rt="{phrase?.definition}"></rt>
      </ruby><!-- <rt data-rt="{phrase?.phonetic}"></rt> -->
    </ruby>
    
    




  {:else}



    <ruby>
      <ruby>
        <ruby style="ruby-position: alternate;">
          <span class=""
            class:border-white-50={phrase.status === 'UNMARKED'}
            class:border-violet-400={phrase.status === 'IGNORED'}
            class:border-red-400={phrase.status === 'L1'}
            class:border-orange-400={phrase.status === 'L2'}
            class:border-amber-400={phrase.status === 'L3'}
            class:border-lime-400={phrase.status === 'L4'}
            class:border-teal-400={phrase.status === 'L5'}
            class:token_dbg_alt={tokenisation_debug}
          >
                    {#each constituent.shadows as sub_constituent}
                      {#if sub_constituent.type == "CompositToken" || sub_constituent.type == "SingleToken"}
                        <TokenC
                            constituent={sub_constituent}
                            token={token_dict[sub_constituent.orthography]}
                            tokenisation_debug={false}
                            on:token_mouseenter
                            on:token_click
                            on:token_mousedown
                            on:token_mouseup
                            is_focused={last_focused_slice.is_some() ? is_cst_in_slice(last_focused_slice.unwrap(), sub_constituent) : false}
                        />
                      {:else if sub_constituent.type == "SentenceWhitespace"}
                        <span class="whitespace-pre-wrap" class:bg-green-100={tokenisation_debug}
                            >{sub_constituent.text}</span
                        >
                      {:else}
                        UNREACHABLE
                      {/if}
                    {/each}
    
          </span>      
        </ruby><rt data-rt="{phrase?.definition}"></rt>
      </ruby><!-- <rt data-rt="{phrase?.phonetic}"></rt> -->
    </ruby>






  {/if}

</div>
 
  
<!-- </TokenTooltip> -->

<style>
  rt:before {
    content: attr(data-rt);
  }

  .token_dbg {
    @apply bg-red-100 border-solid border-2 hover:bg-red-300;
  }
  .token_dbg_alt {
    @apply bg-red-100 border-solid border-2;
  }

</style>
