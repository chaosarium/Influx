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
                case "SET_AUDIO_PLAYBACK_POSITION":
                    let audio = document.getElementById('influx-audio-player');
                    audio.currentTime = data.playback_position * audio.duration;
                    console.log(`Set audio playback position to ${data.playback_position}`);
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
                case "ADJUST_ANNOTATION_WIDTHS":
                    adjustAnnotationWidths();
                    return;
                default:
                    console.warn(`Unhandled outgoing port: "${tag}"`);
                    return;
            }
        });
    }
};

// Width adjustment functionality for annotations
function measureTextWidth(text, fontSize, fontFamily) {
    const span = document.createElement('span');
    span.style.position = 'absolute';
    span.style.visibility = 'hidden';
    span.style.whiteSpace = 'nowrap';
    span.style.fontSize = fontSize;
    span.style.fontFamily = fontFamily;
    span.textContent = text;

    document.body.appendChild(span);
    const width = span.offsetWidth;
    document.body.removeChild(span);

    return width;
}

function adjustAnnotationWidth(element) {
    const topText = element.getAttribute('data-top') || '';
    const bottomText = element.getAttribute('data-bottom') || '';
    const mainText = element.textContent || '';

    // Get computed styles
    const computedStyle = window.getComputedStyle(element);
    const fontSize = computedStyle.fontSize;
    const fontFamily = computedStyle.fontFamily;

    // Calculate annotation font size (0.6em of main font)
    const annotationFontSize = parseFloat(fontSize) * 0.6 + 'px';

    // Measure widths
    const mainWidth = measureTextWidth(mainText, fontSize, fontFamily);
    const topWidth = topText ? measureTextWidth(topText, annotationFontSize, fontFamily) : 0;
    const bottomWidth = bottomText ? measureTextWidth(bottomText, annotationFontSize, fontFamily) : 0;

    // Find the maximum width
    const maxWidth = Math.min(Math.max(mainWidth, topWidth, bottomWidth), 2 * mainWidth);

    // Set CSS custom property for pseudo-element max-width constraint
    element.style.setProperty('--annotation-max-width', maxWidth + 'px');

    // Set minimum width if needed
    if (maxWidth > mainWidth) {
        element.style.textAlign = 'center';
        const padWidth = (maxWidth - mainWidth) / 2;
        element.style.paddingLeft = padWidth + 'px';
        element.style.paddingRight = padWidth + 'px';
    }
}

function adjustAnnotationWidths() {
    // Use requestAnimationFrame to ensure DOM is fully updated
    requestAnimationFrame(() => {
        const annotations = document.querySelectorAll('.double-ruby.tkn-auto-width');
        annotations.forEach(adjustAnnotationWidth);
    });
}
