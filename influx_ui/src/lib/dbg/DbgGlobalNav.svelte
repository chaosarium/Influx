<script>
  import { onMount, onDestroy } from 'svelte';

  let connectionStatus = 'Checking...';
  let intervalId;

  const checkConnection = async () => {
    try {
      const response = await fetch('http://127.0.0.1:3000/test');

      if (response.ok) {
        connectionStatus = 'Connected';
      } else {
        connectionStatus = 'Server connected but not ok?';
      }
    } catch (error) {
      connectionStatus = 'Disconnected';
    }
  };

  onMount(() => {
    checkConnection();
    intervalId = setInterval(checkConnection, 2000); 
  });

  onDestroy(() => {
    clearInterval(intervalId); 
  });
</script>

<div class="bg-indigo-50">

  <a href="/texts/fr">fr texts</a> | 
  <a href="/">root</a> | 
  <a href="/texts/fr/toy.md">dummy text</a> | 
  server alive: <span class={connectionStatus === 'Connected' ? 'text-green-600' : 'text-red-600'}>{connectionStatus}</span>

</div>