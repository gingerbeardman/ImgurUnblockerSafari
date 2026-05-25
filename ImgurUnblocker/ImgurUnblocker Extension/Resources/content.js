const imgurRegex = /^https?:\/\/(\w+\.)?imgur\.com\/.*/;
const ddgProxyPrefix = 'https://external-content.duckduckgo.com/iu/?u=';

function ddgProxy(url) {
    return ddgProxyPrefix + encodeURIComponent(url);
}

let pageCount = 0;
const processedImages = new Set();

function notifyBadge() {
    browser.runtime.sendMessage({ type: 'updateBadge', count: pageCount });
}

function notifyTotal(amount) {
    browser.runtime.sendMessage({ type: 'incrementTotal', amount });
}

function checkRedirect() {
    const url = new URL(window.location.href);
    if (url.hostname === 'external-content.duckduckgo.com') {
        const originalUrl = url.searchParams.get('u');
        if (originalUrl && imgurRegex.test(originalUrl)) {
            pageCount++;
            notifyBadge();
            notifyTotal(1);
        }
    }
}

function processImages() {
    const images = document.querySelectorAll('img');
    let newCount = 0;

    images.forEach(img => {
        if (processedImages.has(img)) return;
        if (!img.src) return;

        if (imgurRegex.test(img.src)) {
            processedImages.add(img);
            img.src = ddgProxy(img.src);
            newCount++;
        }
    });

    if (newCount > 0) {
        pageCount += newCount;
        notifyBadge();
        notifyTotal(newCount);
    }
}

checkRedirect();
processImages();

const observer = new MutationObserver(processImages);
observer.observe(document.body, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ['src']
});
