<script lang="ts">
  import Tooltip from "./TokenTooltip.svelte";
  export let token;
</script>

<Tooltip token={token}>

  <span class="border-solid border-2"
    class:border-white-50={token.status === 'UNMARKED'}
    class:border-violet-400={token.status === 'IGNORED'}
    class:border-red-400={token.status === 'L1'}
    class:border-orange-400={token.status === 'L2'}
    class:border-amber-400={token.status === 'L3'}
    class:border-lime-400={token.status === 'L4'}
    class:border-teal-400={token.status === 'L5'}
  >{token.orthography}</span><span class="border-solid bg-blue-50 px-1"> </span>
  
</Tooltip>

