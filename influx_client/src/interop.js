// This is called BEFORE your Elm app starts up
//
// The value returned here will be passed as flags
// into your `Shared.init` function.
export const flags = ({ env }) => {
    return {
        message: "Hello, from JavaScript flags!",
    };
};
// Define the custom shadow-element
class ShadowElement extends HTMLElement {
    static get observedAttributes() {
        return ['inner-html', 'base-url'];
    }

    constructor() {
        super();
        this.attachShadow({ mode: 'open' });
    }

    attributeChangedCallback(name, oldValue, newValue) {
        if ((name === 'inner-html' || name === 'base-url') && newValue !== oldValue) {
            this.updateContent();
        }
    }

    updateContent() {
        const htmlContent = this.getAttribute('inner-html');
        const baseUrl = this.getAttribute('base-url');

        if (!htmlContent) {
            this.shadowRoot.innerHTML = '';
            return;
        }

        // Process HTML content to resolve all resource paths using the provided base URL
        const processedHtml = processAllResourcePaths(htmlContent, baseUrl);

        // Create isolation styles to prevent outside styling from affecting shadow DOM content
        const isolationStyles = `
            <style>
            </style>
        `;

        // Inject isolation styles and processed HTML content into shadow DOM
        this.shadowRoot.innerHTML = isolationStyles + processedHtml;
    }
}

// Register the custom element
customElements.define('shadow-element', ShadowElement);

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
                    const sendVoicesToElm = () => {
                        let voices = speechSynthesis.getVoices();
                        let voiceData = voices.map(v => ({ name: v.name, lang: v.lang, default: v.default }));
                        app.ports.jsIncoming.send({ tag: "VOICES_LIST", data: voiceData });
                    };

                    let voices = speechSynthesis.getVoices();
                    if (voices.length > 0) {
                        let voiceData = voices.map(v => ({ name: v.name, lang: v.lang, default: v.default }));
                        app.ports.jsIncoming.send({ tag: "VOICES_LIST", data: voiceData });
                    } else {
                        // in case voices is async...
                        const handleVoicesChanged = () => {
                            speechSynthesis.removeEventListener('voiceschanged', handleVoicesChanged);
                            sendVoicesToElm();
                        };
                        speechSynthesis.addEventListener('voiceschanged', handleVoicesChanged);

                        setTimeout(() => {
                            let voices = speechSynthesis.getVoices();
                            if (voices.length > 0) {
                                speechSynthesis.removeEventListener('voiceschanged', handleVoicesChanged);
                                let voiceData = voices.map(v => ({ name: v.name, lang: v.lang, default: v.default }));
                                app.ports.jsIncoming.send({ tag: "VOICES_LIST", data: voiceData });
                            }
                        }, 100);
                    }
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
    const mainText = Array.from(element.childNodes)
        .filter(node => node.nodeType === Node.TEXT_NODE)
        .map(node => node.textContent)
        .join('');

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

function processAllResourcePaths(htmlContent, baseUrl) {
    // If no baseUrl provided, return original content
    if (!baseUrl) {
        return htmlContent;
    }

    // Create a temporary div to parse the HTML
    const tempDiv = document.createElement('div');
    tempDiv.innerHTML = htmlContent;

    // Process all elements with src or href attributes
    const elementsWithPaths = tempDiv.querySelectorAll('[src], [href]');
    elementsWithPaths.forEach(element => {
        // Check src attribute
        const src = element.getAttribute('src');
        if (src && isRelativePath(src)) {
            element.setAttribute('src', `${baseUrl}/${src}`);
        }

        // Check href attribute
        const href = element.getAttribute('href');
        if (href && isRelativePath(href)) {
            element.setAttribute('href', `${baseUrl}/${href}`);
        }
    });

    // Process any other elements with relative resource references in style attributes
    const elementsWithStyle = tempDiv.querySelectorAll('[style]');
    elementsWithStyle.forEach(el => {
        const style = el.getAttribute('style');
        if (style) {
            const processedStyle = style.replace(
                /url\(['"]?([^'")]+)['"]?\)/g,
                (match, url) => {
                    if (isRelativePath(url)) {
                        return `url('${baseUrl}/${url}')`;
                    }
                    return match;
                }
            );
            el.setAttribute('style', processedStyle);
        }
    });

    return tempDiv.innerHTML;
}

function isRelativePath(path) {
    // Check if path is relative (not starting with http://, https://, //, or /)
    return path &&
        !path.startsWith('http://') &&
        !path.startsWith('https://') &&
        !path.startsWith('//') &&
        !path.startsWith('/');
}
