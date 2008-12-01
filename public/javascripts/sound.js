soundManager.url = '/media/';
soundManager.debugMode = false;
soundManager.onload = function() {
    soundManager.createSound({
            id: 'notify_tweet',
            url: '/media/tweet.mp3'
        });
    soundManager.createSound({
            id: 'notify_pop',
            url: '/media/pop.mp3'
        });
}
