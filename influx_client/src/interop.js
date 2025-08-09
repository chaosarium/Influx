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
                case "INJECT_HTML":
                    injectHtmlToElement(data.elementId, data.htmlContent, data.dictName);
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

function injectHtmlToElement(elementId, htmlContent, dictName) {
    console.log('Injecting HTML content into element:', { elementId, dictName });

    // Use requestAnimationFrame to ensure DOM is fully updated
    requestAnimationFrame(() => {
        const targetElement = document.getElementById(elementId);
        if (!targetElement) {
            console.warn(`Element with id "${elementId}" not found for HTML injection`);
            return;
        }

        if (!targetElement.shadowRoot) {
            targetElement.attachShadow({ mode: 'open' });
        }

        // Extract the dictionary directory name from dictName (remove .ifo suffix)
        // dictName format: "French - English/French - English.ifo"
        // We want: "French - English"
        const dictDir = dictName.includes('/') ? dictName.split('/')[0] : dictName.replace(/\.ifo$/, '');

        console.log('Dictionary injection:', { dictName, dictDir, elementId });

        // Process HTML content to resolve all resource paths (CSS, images, etc.)
        const processedHtml = processAllResourcePaths(htmlContent, dictDir);

        // Create isolation styles to prevent outside styling from affecting shadow DOM content
        const isolationStyles = `
            <style>
            </style>
        `;

        // Inject isolation styles and processed HTML content into shadow DOM
        targetElement.shadowRoot.innerHTML = isolationStyles + processedHtml;
    });
}

function processAllResourcePaths(htmlContent, dictDir) {
    // Create a temporary div to parse the HTML
    const tempDiv = document.createElement('div');
    tempDiv.innerHTML = htmlContent;

    // Process CSS link tags (href attributes)
    const cssLinks = tempDiv.querySelectorAll('link[rel="stylesheet"][href]');
    cssLinks.forEach(link => {
        const href = link.getAttribute('href');
        if (href && isRelativePath(href)) {
            const newHref = `http://127.0.0.1:3000/influx_app_data/dictionaries/stardicts/${encodeURIComponent(dictDir)}/res/${href}`;
            link.setAttribute('href', newHref);
        }
    });

    // Process script tags (src attributes)
    const scripts = tempDiv.querySelectorAll('script[src]');
    scripts.forEach(script => {
        const src = script.getAttribute('src');
        if (src && isRelativePath(src)) {
            const newSrc = `http://127.0.0.1:3000/influx_app_data/dictionaries/stardicts/${encodeURIComponent(dictDir)}/res/${src}`;
            script.setAttribute('src', newSrc);
        }
    });

    // Process img src attributes
    const images = tempDiv.querySelectorAll('img[src]');
    images.forEach(img => {
        const src = img.getAttribute('src');
        if (src && isRelativePath(src)) {
            const newSrc = `http://127.0.0.1:3000/influx_app_data/dictionaries/stardicts/${encodeURIComponent(dictDir)}/res/${src}`;
            img.setAttribute('src', newSrc);
        }
    });

    // Process audio/video source tags
    const mediaSources = tempDiv.querySelectorAll('audio[src], video[src], source[src]');
    mediaSources.forEach(media => {
        const src = media.getAttribute('src');
        if (src && isRelativePath(src)) {
            const newSrc = `http://127.0.0.1:3000/influx_app_data/dictionaries/stardicts/${encodeURIComponent(dictDir)}/res/${src}`;
            media.setAttribute('src', newSrc);
        }
    });

    // Process any other elements with relative resource references
    // (like background images in style attributes, etc.)
    const elementsWithStyle = tempDiv.querySelectorAll('[style]');
    elementsWithStyle.forEach(el => {
        const style = el.getAttribute('style');
        if (style) {
            const processedStyle = style.replace(
                /url\(['"]?([^'")]+)['"]?\)/g,
                (match, url) => {
                    if (isRelativePath(url)) {
                        return `url('http://127.0.0.1:3000/influx_app_data/dictionaries/stardicts/${encodeURIComponent(dictDir)}/res/${url}')`;
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
