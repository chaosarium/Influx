<script lang="ts">
  import TokenTooltip from "./TokenTooltip.svelte";
  import { createEventDispatcher } from 'svelte';
  
  import type { Token } from "$lib/types/Token";
  import type { SentenceConstituent } from "$lib/types/SentenceConstituent";
  export let token: Token;
  export let constituent: SentenceConstituent;

  const dispatch = createEventDispatcher();
  export let tokenisation_debug: boolean = false;
  export let is_focused: boolean = false;

</script>
<!-- svelte-ignore a11y -->
<TokenTooltip token={token}>
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
            class:border-white-50={token.status === 'UNMARKED'}
            class:border-violet-400={token.status === 'IGNORED'}
            class:border-red-400={token.status === 'L1'}
            class:border-orange-400={token.status === 'L2'}
            class:border-amber-400={token.status === 'L3'}
            class:border-lime-400={token.status === 'L4'}
            class:border-teal-400={token.status === 'L5'}
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
            {constituent.text}
          </span>
        </ruby><rt data-rt="{token?.definition}"></rt>
      </ruby><rt data-rt="{token?.phonetic}"></rt>
    </ruby>
    
  </div>
 
  
</TokenTooltip>

<style>
  rt:before {
    content: attr(data-rt);
  }

  .token_dbg {
    @apply bg-slate-50 border-solid border-2 hover:bg-slate-200;
  }

</style>
