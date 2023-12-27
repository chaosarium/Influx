<script>
  import JSONTree from 'svelte-json-tree';
  export let data;
  export let name = '';
</script>

<div class="bg-indigo-50">
  <p>Data{#if name} ({name}){/if}:</p>
  <JSONTree value={data} />
</div>