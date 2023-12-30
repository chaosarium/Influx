import { writable } from 'svelte/store';
export let writable_count = writable(0);

function mkStringVecStore(xs: string[]) {
    const { subscribe, set, update } = writable(xs)

    function log(x: string) {
        update(xs => [...xs, x])
    }

    function clear() {
        set([])
    }

    return { subscribe, set, update, log, clear }
}

export const dbgConsoleMessages = mkStringVecStore([])
export const logNotYet = () => dbgConsoleMessages.log('Not yet implemented')

function mkStringStore(x: string) {
    const { subscribe, set, update } = writable(x)

    function clear() {
        set('')
    }

    return { subscribe, set, update, clear }
}

export const curr_lang_id = mkStringStore('')

