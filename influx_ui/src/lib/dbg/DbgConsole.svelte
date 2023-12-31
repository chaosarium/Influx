<script lang="ts">
  import { writable } from 'svelte/store'
  import { dbgConsoleMessages } from '$lib/store'
</script>

<div class="overflow-y-auto h-[200px] font-mono text-xs bg-slate-200 border-2 border-slate-600 p-2 break-all">
  <ul>
    {#each $dbgConsoleMessages as message, index}
      <li>{message}</li>
    {/each}
  </ul>
</div>
