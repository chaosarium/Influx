<script>
  import Button from "$lib/components/Button.svelte";
  export let text_entry;
  import { page } from '$app/stores';

</script>

<li>

  <div class="border-2 border-gray-200 p-3">
    
    <div class="flex flex-row content-between ">
      <div class="flex-auto">
        <h1 class="font-bold textxl">{text_entry.metadata.title}</h1>
      </div>
      <div class="">
        <span class="text-gray-500">{text_entry.filename}</span>
      </div>
    </div>

    <div class="mt-3">
      {#each text_entry.metadata.tags as tag}
        <span class="inline-block bg-gray-200 rounded-full px-3 py-1 text-sm font-semibold text-gray-700 mr-2 mb-2">{tag}</span>
      {/each}
    </div>
      

    <div class="flex flex-row mt-3">
      <Button href="{$page.params.lang}/{text_entry.filename}">Open</Button>
      <Button href="#" class='ml-2'>Stats</Button>
      <Button href="#" class='ml-2'>Vocab</Button>
    </div>

  </div>
  
</li>    
