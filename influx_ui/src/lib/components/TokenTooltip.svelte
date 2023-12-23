<script>
  export let token;
</script>

<span class="relative inline-block group">
  <slot />
  {#if token.status != 'UNMARKED'}
    <p class="tooltip-text absolute z-10 bottom-full left-1/2 transform -translate-x-1/2 opacity-0 transition-opacity duration-300 invisible group-hover:visible group-hover:opacity-100 bg-black text-white text-center p-1 rounded-md">
      {token.definition}, {token.status}
    </p>
  {/if}
</span>

<style>
  :hover .tooltip-text {
    visibility: visible;
    min-width: 100pt;
  }
</style>