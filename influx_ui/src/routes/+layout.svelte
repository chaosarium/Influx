<script>
  import "../app.css";
  import DbgGlobalNav from "$lib/dbg/DbgGlobalNav.svelte";
  let leftPane_expanded = false;

</script>


<div id="appContainer" class="" class:leftPane_expanded={leftPane_expanded}>

  <div id="leftPane">
    <button class="bg-gray-400 rounded-md p-1" on:click={() => leftPane_expanded = !leftPane_expanded}>toggle</button>
    <p>sidebar</p>
  </div>

  <div id="midPane">
    <DbgGlobalNav />
    <slot>no content</slot>
  </div>

</div>

<style>
  #appContainer {
    @apply box-border min-h-screen;
  }

  #leftPane {
    @apply h-screen bg-slate-100 border-r-2 border-r-gray-200  fixed top-0 left-0 overflow-hidden;
  }
  :not(.leftPane_expanded) #leftPane {
    @apply w-[20px];
  }
  .leftPane_expanded #leftPane {
    @apply w-[200px];
  }

  .leftPane_expanded #midPane {
    @apply h-screen pl-[200px];
  }
  :not(.leftPane_expanded) #midPane {
    @apply h-screen pl-[20px];
  }
</style>