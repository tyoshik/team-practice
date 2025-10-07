DECLARE
    -- ログ出力用
    v_start_time   TIMESTAMP := SYSTIMESTAMP;
    v_end_time     TIMESTAMP;
    v_count        NUMBER := 0;

    -- 処理対象となる日付リスト（取引対象日）
    -- ここでは2024/07/01-2024/09/30および2025/07/01-2025/09/30を含む
    -- 必要なら追加・変更可能
    CURSOR c_txn IS
        SELECT t.*
          FROM transactions t
         WHERE (
                   (t.trade_date BETWEEN DATE '2024-07-01' AND DATE '2024-09-30')
                OR (t.trade_date BETWEEN DATE '2025-07-01' AND DATE '2025-09-30')
               )
           AND t.status = 'PENDING'
         ORDER BY t.trade_date;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=== 処理開始 ===');
    DBMS_OUTPUT.PUT_LINE('開始時刻: ' || TO_CHAR(v_start_time, 'YYYY-MM-DD HH24:MI:SS'));

    -- カーソル処理
    FOR rec IN c_txn LOOP
        BEGIN
            -- メイン処理：例として取引の状態更新
            UPDATE transactions
               SET status = 'PROCESSED',
                   processed_at = SYSTIMESTAMP
             WHERE transaction_id = rec.transaction_id;

            v_count := v_count + 1;

            -- 適宜コミット（例えば1000件ごと）
            IF MOD(v_count, 1000) = 0 THEN
                COMMIT;
                DBMS_OUTPUT.PUT_LINE('中間コミット: ' || v_count || '件完了');
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                -- 1件単位でエラーログ出力
                DBMS_OUTPUT.PUT_LINE('エラー: ' || SQLERRM || ' 対象ID=' || rec.transaction_id);
                ROLLBACK TO SAVEPOINT sp_before_row;
        END;
    END LOOP;

    -- 残りをコミット
    COMMIT;
    v_end_time := SYSTIMESTAMP;

    DBMS_OUTPUT.PUT_LINE('=== 処理完了 ===');
    DBMS_OUTPUT.PUT_LINE('終了時刻: ' || TO_CHAR(v_end_time, 'YYYY-MM-DD HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('処理件数: ' || v_count);

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('致命的エラー: ' || SQLERRM);
        ROLLBACK;
END;
/
