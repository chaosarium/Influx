<script>
  import Button from "$lib/components/Button.svelte";
  export let language_entry;
</script>

<li>

  <div class="border-2 border-gray-200 p-3">
    
    <div class="flex flex-row content-between ">
      <div class="flex-auto">
        <h1 class="font-bold textxl">{language_entry.display_name}</h1>
      </div>
      <div class="">
        <span class="text-gray-500">{language_entry.identifier}</span>
      </div>
  
    </div>

    <div class="flex flex-row mt-3">
      <Button href="/texts/{language_entry.identifier}">Texts</Button>
      <Button href="#" class='ml-2'>Stats</Button>
      <Button href="#" class='ml-2'>Vocab</Button>
    </div>

  </div>
  
</li>    
