<script>
  import "$lib/../app.css";
  import "$lib/../panestyle.scss";
    import MainSidebarInner from "$lib/components/MainSidebarInner.svelte";
</script>

<div class="h-screen">
  <div class="w-[200px] absolute top-0 left-0">
    <MainSidebarInner />
  </div>

  <div class="pl-[200px]">
      <slot>empty slot</slot>
  </div>

</div>

