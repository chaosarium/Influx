<script lang="ts">
  import Tooltip from "./TokenTooltip.svelte";
  import { createEventDispatcher } from 'svelte';

  export let token;

  const dispatch = createEventDispatcher();
  const handleMouseEnter = () => {
    dispatch('token_hover', token.orthography);
  };
  const handleClick = () => {
    dispatch('token_click', token.orthography);
  };


</script>
<!-- svelte-ignore a11y -->
<Tooltip token={token}>

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
  >{token.orthography}</span><span class="border-solid bg-blue-50 px-1"> </span>
  
</Tooltip>

