<script lang="ts">
  import { Pane, Splitpanes } from 'svelte-splitpanes';
  export let show_mid_top: boolean = true;
  export let show_mid_bottom: boolean = true;
  // https://github.com/orefalo/svelte-splitpanes/issues/33 may help with pixel sizing the panels
</script>


<div id="appContainer" class="h-screen w-full">
  <Splitpanes theme="panestyletheme" dblClickSplitter={false} pushOtherPanes={false}>
    
    <Pane maxSize={20} size={10} snapSize={5}>
      <slot name="left">left empty slot</slot>
    </Pane>

    <Pane minSize={40} size={50}>
      <Splitpanes theme="panestyletheme" horizontal={true} dblClickSplitter={false} pushOtherPanes={false}>

        {#if show_mid_top}
          <Pane minSize={5} maxSize={5} size={5} snapSize={5}>
            <slot name="mid-top">mid-top empty slot</slot>
          </Pane>
        {/if}

        <Pane>
          <slot name="mid-mid">mid-mid empty slot</slot>
        </Pane>

        {#if show_mid_bottom}
          <Pane size={5} snapSize={5}>
            <slot name="mid-bottom">mid-bottom empty slot</slot>
          </Pane>
        {/if}

      </Splitpanes>
    </Pane>
    
    <Pane size={40} snapSize={10}>
      <slot name="right">right empty slot</slot>
    </Pane>

  </Splitpanes>

</div>
