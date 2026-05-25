browser.runtime.onMessage.addListener((message, sender) => {
    if (message.type === 'updateBadge') {
        if (sender.tab) {
            browser.action.setBadgeText({
                text: message.count.toString(),
                tabId: sender.tab.id
            });
            browser.action.setBadgeBackgroundColor({
                color: '#4CAF50',
                tabId: sender.tab.id
            });
        }
    }
    else if (message.type === 'incrementTotal') {
        browser.storage.local.get(['totalProxied']).then((result) => {
            const newTotal = (result.totalProxied || 0) + message.amount;
            browser.storage.local.set({ totalProxied: newTotal });
        });
    }
});
