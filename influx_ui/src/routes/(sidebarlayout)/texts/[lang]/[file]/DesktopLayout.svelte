<div id="appContainer" class="">

  <div id="leftPane" class="">
    Sidebar
  </div>

  <div id="mainPane">
    <slot>no content</slot>
  </div>

</div>

<style>
  #appContainer {
    @apply box-border min-h-screen;
  }

  #leftPane {
    @apply h-screen bg-slate-100 border-r-2 border-r-gray-200 w-[200px] fixed top-0 left-0;
  }

  #mainPane {
    @apply h-screen pl-[200px];
  }
</style>