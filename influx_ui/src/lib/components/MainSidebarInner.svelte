<script>
  import { onMount, onDestroy } from 'svelte';

  let connectionStatus = 'Checking...';
  let intervalId;
  import { IconHome, IconLanguageHiragana, IconCircleFilled, IconBooks, IconVocabulary, IconCalendarRepeat, IconArrowBadgeLeft, IconReportAnalytics, IconSettings } from '@tabler/icons-svelte';
    import Button from './Button.svelte';

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
      Navigation
      <li><Button href="/" class="flex">
        <div class="items-center inline-flex">
          <span><IconHome size={24} stroke={2} class="inline" /></span> <span class="ml-1">home</span>
        </div>
      </Button></li>
      <li><Button href="/languages" class="flex">
        <div class="items-center inline-flex">
          <span><IconLanguageHiragana size={24} stroke={2} class="inline" /></span> <span class="ml-1">languages</span>
        </div>
      </Button></li>
      <li><Button href="/texts" class="flex">
        <div class="items-center inline-flex">
          <span><IconBooks size={24} stroke={2} class="inline" /></span> <span class="ml-1">texts</span>
        </div>
      </Button></li>
      <li><Button href="/vocab" class="flex">
        <div class="items-center inline-flex">
          <span><IconVocabulary size={24} stroke={2} class="inline" /></span> <span class="ml-1">vocab</span>
        </div>
      </Button></li>
      <li><Button href="/srs" class="flex">
        <div class="items-center inline-flex">
          <span><IconCalendarRepeat size={24} stroke={2} class="inline" /></span> <span class="ml-1">SRS</span>
        </div>
      </Button></li>
      <li><Button href="/stats" class="flex">
        <div class="items-center inline-flex">
          <span><IconReportAnalytics size={24} stroke={2} class="inline" /></span> <span class="ml-1">stats</span>
        </div>
      </Button></li>
      <li><Button href="/settings" class="flex">
        <div class="items-center inline-flex">
          <span><IconSettings size={24} stroke={2} class="inline" /></span> <span class="ml-1">settings</span>
        </div>
      </Button></li>
      <hr>
      Actions
      <li><Button href="#" class="flex">
        <div class="items-center inline-flex">
          <span><IconArrowBadgeLeft size={24} stroke={2} class="inline" /></span> <span class="ml-1">hide side bar</span>
        </div>
      </Button></li>
      <hr>
      Debug
      <li><Button href="/texts/fr_demo/toy.md" class="flex">
        <span class="inline">dummy text</span>
      </Button></li>
    </ul>
  </div>

  <div>
    server alive: <IconCircleFilled size={16} stroke={2} class={connectionStatus === 'Connected' ? 'inline text-green-600' : 'inline text-red-600'} />
  </div>


</div>