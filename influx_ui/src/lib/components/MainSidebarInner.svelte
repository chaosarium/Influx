<script>
  import { onMount, onDestroy } from 'svelte';

  let connectionStatus = 'Checking...';
  let intervalId;
  import { IconHome, IconLanguageHiragana, IconCircleFilled, IconBooks, IconVocabulary, IconCalendarRepeat, IconReportAnalytics, IconSettings } from '@tabler/icons-svelte';

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

<div class="border-2 border-indigo-50 p-3 box-border flex flex-col justify-between h-screen">


  <div class="">
    <ul class="space-y-2">
      <li class="p-1 border-gray-400 border-2 rounded-md hover:bg-gray-200">
        <a class="flex items-center" href="/"><IconHome size={24} stroke={2} /> home</a>
      </li>
      <li class="p-1 border-gray-400 border-2 rounded-md hover:bg-gray-200">
        <a class="flex items-center" href="/languages"><IconLanguageHiragana size={24} stroke={2} /> languages</a>
      </li>
      <li class="p-1 border-gray-400 border-2 rounded-md hover:bg-gray-200">
        <a class="flex items-center" href="/texts"><IconBooks size={24} stroke={2} /> texts</a>
      </li>
      <li class="p-1 border-gray-400 border-2 rounded-md hover:bg-gray-200">
        <a class="flex items-center" href="/vocab"><IconVocabulary size={24} stroke={2} /> vocab</a>
      </li>
      <li class="p-1 border-gray-400 border-2 rounded-md hover:bg-gray-200">
        <a class="flex items-center" href="/srs"><IconCalendarRepeat size={24} stroke={2} /> SRS</a>
      </li>
      <li class="p-1 border-gray-400 border-2 rounded-md hover:bg-gray-200">
        <a class="flex items-center" href="/stats"><IconReportAnalytics size={24} stroke={2} /> stats</a>
      </li>
      <li class="p-1 border-gray-400 border-2 rounded-md hover:bg-gray-200">
        <a class="flex items-center" href="/settings"><IconSettings size={24} stroke={2} /> settings</a>
      </li>
      <hr>
      Debug
      <li class="p-1 border-gray-400 border-2 rounded-md hover:bg-gray-200">
        <a class="flex items-center" href="/texts/fr_demo/toy.md">dummy text</a>
      </li>
    </ul>
  </div>

  <div>
    server alive: <IconCircleFilled size={16} stroke={2} class={connectionStatus === 'Connected' ? 'inline text-green-600' : 'inline text-red-600'} />
  </div>


</div>