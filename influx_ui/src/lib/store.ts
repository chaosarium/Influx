import { writable } from 'svelte/store';
export let writable_count = writable(0);

function mkVecDequeStore<T>(xs: T[]) {
    const { subscribe, set, update } = writable<T[]>(xs)

    function push_back(x: T) {
        update(xs => [...xs, x])
    }
    function push_front(x: T) {
        update(xs => [x, ...xs])
    }
    function pop_back() {
        update(xs => [...xs.slice(0, xs.length - 1)])
    }
    function pop_front() {
        update(xs => [...xs.slice(1)])
    }
    function clear() {
        set([])
    }

    return { subscribe, set, update, push_back, push_front, pop_back, pop_front, clear }
}

function mkToastStore<T>(x: T[]) {
    const { subscribe, set, update, push_back, push_front, pop_back, pop_front, clear } = mkVecDequeStore<T>([])

    function toast(x: T, timeout_ms: number = 2000) {
        push_back(x)
        setTimeout(() => pop_front(), timeout_ms)
    }

    return { subscribe, set, update, push_back, push_front, pop_back, pop_front, clear, toast }
}

function mkStore<T>(x: T) {
    const { subscribe, set, update } = writable<T>(x)
    return { subscribe, set, update }
}

function mkLocalStore<T>(key: string, _default: T | null) {
    const got = localStorage.getItem(key);
    console.log(got)
    const x: T | null = got ? JSON.parse(got) : _default;
    const { subscribe, set, update } = writable<T | null>(x)
    subscribe((value) => localStorage[key] = JSON.stringify(value))
    return { subscribe, set, update }
}

interface UISettings {
    theme: string;
    active_lang_id: string;
}
interface AppSettings {
    ui: UISettings;
    server: any;
}





export async function fetchSettings() {
    const res = await fetch('http://127.0.0.1:3000/settings/lang');
    const json_res: any[] = await res.json(); // TODO export the type from rust
    console.log(json_res);

    app_settings.update((settings) => {
        settings.server.lang = json_res;
        return settings;
    });
}
export const app_settings = writable<AppSettings>({
    ui: {
        theme: 'light',
        active_lang_id: 'en_demo',
    },
    server: {
        lang: [],
    }
});
  

export const testLocalStore = mkLocalStore<string>('test', 'hi')
export const dbgConsoleMessages = mkVecDequeStore<string>([])
export const toastQueue = mkToastStore<string>([])