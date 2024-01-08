<script lang="ts">
  import TokenTooltip from "./TokenTooltip.svelte";
  import { createEventDispatcher } from 'svelte';
  import type { Phrase as PhraseT } from "$lib/types/Phrase";
  import type { SentenceConstituent } from "$lib/types/SentenceConstituent";
  
  export let constituent: SentenceConstituent;
  export let phrase: PhraseT;

  const dispatch = createEventDispatcher();
  const handleMouseEnter = () => {
    dispatch('token_hover', constituent);
  };
  const handleClick = () => {
    dispatch('token_click', constituent);
  };
  export let tokenisation_debug: boolean = false;

</script>


<!-- <TokenTooltip token={token}> -->
  <div class="inline hover:cursor-default" >

    <!-- <ruby>

      <rtc class="rtc-top"><rt class="">{token?.definition}</rt>
      
      <rb>
        <span class="border-solid border-2"
          class:border-white-50={token.status === 'UNMARKED'}
          class:border-violet-400={token.status === 'IGNORED'}
          class:border-red-400={token.status === 'L1'}
          class:border-orange-400={token.status === 'L2'}
          class:border-amber-400={token.status === 'L3'}
          class:border-lime-400={token.status === 'L4'}
          class:border-teal-400={token.status === 'L5'}
          on:mouseenter={handleMouseEnter}
          on:click={handleClick}
        >
          {token.orthography}
        </span>
      </rb>
      

      <rtc class="rtc-bot"><rt class="">{token?.definition}</rt></rtc>

    </ruby> -->

  
    <!-- <rt data-rt="{token?.phonetic}"></rt>
    <rtc><rt data-rt="{token?.definition}"></rt></rtc> -->

    

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
            {constituent.text}
          </span>
        </ruby>

        <!-- <rt data-rt="{token?.definition}"></rt> -->
      </ruby>
      <!-- <rt data-rt="{token?.phonetic}"></rt> -->
    </ruby>
    
  </div>
 
  
<!-- </TokenTooltip> -->

<style>
  rt:before {
    content: attr(data-rt);
  }

  .token_dbg {
    @apply bg-red-100 border-solid border-2 hover:bg-red-300;
  }

</style>
