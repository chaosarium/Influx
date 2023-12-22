<script>
  import JSONTree from 'svelte-json-tree';
  export let data;
</script>

<div class="bg-indigo-50">
  <p>Data:</p>
  <JSONTree value={data} />
</div>