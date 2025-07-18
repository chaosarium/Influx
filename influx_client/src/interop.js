// This is called BEFORE your Elm app starts up
//
// The value returned here will be passed as flags
// into your `Shared.init` function.
export const flags = ({ env }) => {
    return {
        message: "Hello, from JavaScript flags!",
    };
};
// This is called AFTER your Elm app starts up
//
// Here you can work with `app.ports` to send messages
// to your Elm application, or subscribe to incoming
// messages from Elm
export const onReady = ({ app, env }) => {
    if (app.ports && app.ports.outgoing) {
        app.ports.outgoing.subscribe(({ tag, data }) => {
            switch (tag) {
                case "OPEN_WINDOW_DIALOG":
                    window.alert(data);
                    return;
                case "GET_VOICES":
                    let voices = speechSynthesis.getVoices();
                    let voiceData = voices.map(v => ({ name: v.name, lang: v.lang, default: v.default }));
                    app.ports.jsIncoming.send({ tag: "VOICES_LIST", data: voiceData });
                    return;
                case "SPEAK":
                    let utterance = new SpeechSynthesisUtterance(data.text);
                    if (data.voice) {
                        let voice = speechSynthesis.getVoices().find(v => v.name === data.voice);
                        if (voice) {
                            utterance.voice = voice;
                        }
                    }
                    utterance.rate = data.rate || 1;
                    utterance.pitch = data.pitch || 1;
                    speechSynthesis.speak(utterance);
                    return;
                case "CANCEL":
                    speechSynthesis.cancel();
                    return;
                case "CANCEL_AND_SPEAK":
                    speechSynthesis.cancel();
                    // Small delay to ensure cancel completes before starting new speech
                    setTimeout(() => {
                        let utterance = new SpeechSynthesisUtterance(data.text);
                        if (data.voice) {
                            let voice = speechSynthesis.getVoices().find(v => v.name === data.voice);
                            if (voice) {
                                utterance.voice = voice;
                            }
                        }
                        utterance.rate = data.rate || 1;
                        utterance.pitch = data.pitch || 1;
                        speechSynthesis.speak(utterance);
                    }, 50);
                    return;
                default:
                    console.warn(`Unhandled outgoing port: "${tag}"`);
                    return;
            }
        });
    }
};
