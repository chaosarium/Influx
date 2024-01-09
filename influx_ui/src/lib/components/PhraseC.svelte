<script lang="ts">
  import TokenTooltip from "./TokenTooltip.svelte";
  import { createEventDispatcher } from 'svelte';
  import type { Phrase as PhraseT } from "$lib/types/Phrase";
  import type { Token } from "$lib/types/Token";
  import type { SentenceConstituent } from "$lib/types/SentenceConstituent";
  import TokenC from "./TokenC.svelte";
  
  export let constituent: SentenceConstituent;
  export let phrase: PhraseT;
  export let token_dict: Record<string, Token>;
  export let phrase_dict: Record<string, PhraseT>;

  const dispatch = createEventDispatcher();
  const handleMouseEnter = () => {
    dispatch('token_hover', constituent);
  };
  const handleClick = () => {
    dispatch('token_click', constituent);
  };
  export let tokenisation_debug: boolean = false;

  let altKeyPressed = false;

  function handleKeyDown(event: KeyboardEvent) {
    altKeyPressed = event.altKey;
  }

  function handleKeyUp(event: KeyboardEvent) {
    altKeyPressed = event.altKey;
  }

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
            on:mouseenter={handleMouseEnter}
            on:click={handleClick}
            class:token_dbg={tokenisation_debug}
          >
                    {#each constituent.shadows as sub_constituent}
                      {#if sub_constituent.type == "CompositToken" || sub_constituent.type == "SingleToken"}
                        <TokenC
                            constituent={sub_constituent}
                            token={token_dict[sub_constituent.orthography]}
                            tokenisation_debug={false}
                        />
                      {:else if sub_constituent.type == "Whitespace"}
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
                            on:token_hover
                            on:token_click
                        />
                      {:else if sub_constituent.type == "Whitespace"}
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
