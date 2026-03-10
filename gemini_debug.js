async function initializeOAC() {
    const statusEl = document.getElementById('status');
    const container = document.getElementById('embedding-container');

    try {
        const response = await fetch('./tokens.json');
        if (!response.ok) throw new Error('tokens.json load failed');
        const data = await response.json();
        
        // トークンの有効期限が切れていないか確認（ダウンロードから1時間以内か）
        const accessToken = data.access_token;

        const oacElement = document.createElement('oracle-dv');
        
        // プロパティとして設定（Mike Durran氏推奨）
        oacElement.authConfig = {
            tokenType: 'Bearer',
            accessToken: accessToken
        };

        // 念のため、属性としても文字列でセット（一部のバージョンで有効）
        oacElement.setAttribute('auth-config', JSON.stringify({
            tokenType: 'Bearer',
            accessToken: accessToken
        }));

        oacElement.setAttribute('project-path', '/shared/Samples/World Cities');
        oacElement.setAttribute('active-page', 'canvas', '1');

        // 重要：先に全ての設定を終えてからコンテナに追加する
        container.appendChild(oacElement);
        
        statusEl.innerText = "Attempting to load with Token...";
        statusEl.style.color = "blue";

    } catch (error) {
        console.error('Error:', error);
        statusEl.innerText = "Error: " + error.message;
    }
}
