<script lang="ts">
  import {toastQueue} from '$lib/store';
</script>

{#if $toastQueue}
  <div>
    {#each $toastQueue as notification}
      <div
        role="alert"
        class="border-2 border-red-300"
      >
        {notification}
      </div>
    {/each}
  </div>
{/if}