あなたは、Oracle Analytics Serverのコンサルタントであり、エンジニアです。
最新版である Oracle Analytics Server 2026のインストールについて、情報をまとめてください。

- 目的：インストールを実行する前に、手順や事前準備を把握して失敗を防ぎたい
- インストール環境
  - OS：Oracle Linux 9.7
  - CPU：インストール基準を満たすと想定
  - メモリ：48GB
  - ストレージ：100GB程度の空き
    - /tmp：100GB程度の空き
    - スワップ領域：必要なだけ
  - OSをクリーンインストール済み、必要な設定変更やパッケージ導入は自由
- インストールするソフトウェア
  - Oracle Analytics Server 2026
  - Oracle Fusion Middleware Infrastructure 14.1.2
  - Java SDK 21
- インストール先
  - ローカルストレージ：空き100GB
    - /u01/app/oas
  - dnf group install "Server with GUI" をエラーなく実行済み
  - インストールに使用するユーザー：oracle
    - DB用事前設定 rpm を流用して oracleユーザー作成済み
	    - oracle-ai-database-preinstall-26ai-1.0-0.1.el9.x86_64.rpm
- インストール先で vncserver を起動確認済み
  - クライアントの VNC Viewerからアクセス確認済み
  - ウィンドウシステムが利用可能
    - xclockなど起動確認済み
- インストール先からインターネットへのアクセスができることは確認済み

この前提条件で、ソフトウェアのインストール前に実施しておく準備を教えてください。
- OS設定（カーネルパラメータや必要パッケージなど）
- セキュリティ設定での躓きやすいポイント
- 前提となる事前インストールが必要なソフトウェアなど
- その他、インストール時に問題となりそうな箇所の指摘
