document.addEventListener('DOMContentLoaded', () => {
    browser.tabs.query({ active: true, currentWindow: true }).then((tabs) => {
        const currentTab = tabs[0];
        if (currentTab) {
            browser.action.getBadgeText({ tabId: currentTab.id }).then((text) => {
                document.getElementById('currentCount').textContent = text || '0';
            });
        }
    });

    function updateTotalCount() {
        browser.storage.local.get(['totalProxied']).then((result) => {
            const count = result.totalProxied || 0;
            document.getElementById('totalCount').textContent = count.toLocaleString();
        });
    }

    updateTotalCount();

    browser.runtime.onMessage.addListener((message) => {
        if (message.type === 'updateBadge') {
            document.getElementById('currentCount').textContent = message.count;
        }
        else if (message.type === 'incrementTotal') {
            updateTotalCount();
        }
    });
});
