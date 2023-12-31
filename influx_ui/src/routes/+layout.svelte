<script>
  import "../app.css";
  import "../panestyle.scss";
  
  import { onMount, onDestroy } from 'svelte';
  import { fetchSettings } from '$lib/store';
  onMount(() => {
    fetchSettings();
  });

</script>

<slot>empty slot</slot>