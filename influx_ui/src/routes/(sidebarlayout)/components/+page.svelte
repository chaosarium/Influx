<script>
  import { testLocalStore } from "$lib/store";
  import Toast from "$lib/components/Toast.svelte";
  import { toastQueue } from "$lib/store";
  let countr = 1;
  import Button from "$lib/components/Button.svelte";
</script>

<h1 class="text-3xl font-bold">Component testing page</h1>

<hr>

  <h1 class="text-xl font-bold">local string store</h1>

  <Button on:click={() => testLocalStore.update((v) => `${v}v`)}>make longer</Button>
  {$testLocalStore}

<hr>
  
  <h1 class="text-xl font-bold">toasts</h1>

  <Button on:click={() => {toastQueue.toast(`hi ${countr}`); countr += 1;}}>
    toast something
  </Button>
  <Toast />


<hr>