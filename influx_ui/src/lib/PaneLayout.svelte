<script>
  import "../app.css";
  import DbgGlobalNav from "$lib/dbg/DbgGlobalNav.svelte";
  import { Pane, Splitpanes } from 'svelte-splitpanes';
</script>


<div id="appContainer" class="h-screen w-full">
  
  <Splitpanes  dblClickSplitter={false} pushOtherPanes={false}>
    
    <Pane maxSize={20} size={10} snapSize={5}>
      <slot name="left">left empty slot</slot>
    </Pane>

    <Pane minSize={40} size={50}>
      <Splitpanes horizontal={true} dblClickSplitter={false} pushOtherPanes={false}>
        <Pane minSize={5} maxSize={5} size={5} snapSize={5}>
          <slot name="mid-top">mid-top empty slot</slot>
        </Pane>
        <Pane>
          <slot name="mid-mid">mid-mid empty slot</slot>
        </Pane>
        <Pane size={5} snapSize={5}>
          <slot name="mid-bottom">mid-bottom empty slot</slot>
        </Pane>
      </Splitpanes>
    </Pane>
    
    <Pane size={40} snapSize={10}>
      <slot name="right">right empty slot</slot>
    </Pane>

  </Splitpanes>

</div>



