<script>
  import { page } from '$app/stores';
  export let data;
  import JSONTree from 'svelte-json-tree';
</script>

Page
<p>Text for language: `{$page.params.lang}`</p>
<p>File `{$page.params.file}`</p>
<hr>

<h1 class="font-bold">{data.metadata.title}</h1>

<!-- vocabulary? -->



{#each data.tokenized as token}
  <span class="border-solid border-2 m-0.5 border-white-50">{token}</span>
  <span> </span>
  
{/each}

<!-- Text -->

<pre>
  {data.text}
</pre>

<hr>

{@debug data}

<hr>
<p>Debug</p>
<JSONTree value={data} defaultExpandedLevel={1}/>