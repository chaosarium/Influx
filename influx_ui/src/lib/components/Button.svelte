<script lang="ts">
  export let href: string | undefined = undefined;
  let moreclass = '';
  export { moreclass as class };
</script>

{#if href}
  <a class={`p-1 border-gray-200 border-2 hover:bg-gray-200 ${moreclass}`} href={href}>
    <slot></slot>
  </a>
{:else}
  <button class={`p-1 border-gray-200 border-2 hover:bg-gray-200 ${moreclass}`}>
    <slot></slot>
  </button>
{/if}
