<script>
  let open = true;

  function toggle() {
    open = !open;
  }
</script>

<div class="">
  <div class="border-t-2 border-b-2 cursor-default" on:click={toggle}>
    <slot name="header">empty header</slot>
  </div>
  {#if open}
    <div class="">
      <slot></slot>
    </div>
  {/if}
</div>
