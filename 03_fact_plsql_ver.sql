-- safer_batch_insert.sql
-- 前提: DIM_PRODUCT, DIM_STORE, DIM_CUSTOMER, TMP_SALE_DATES が存在し、
-- 各テーブルに連続した ID 範囲 (1..N) があること

DECLARE
  v_total NUMBER := 5000000;
  v_batch NUMBER := 10000;
  v_done  NUMBER := 0;
  cnt_prod NUMBER; cnt_store NUMBER; cnt_cust NUMBER; cnt_date NUMBER;
BEGIN
  SELECT COUNT(*) INTO cnt_prod FROM DIM_PRODUCT;
  SELECT COUNT(*) INTO cnt_store FROM DIM_STORE;
  SELECT COUNT(*) INTO cnt_cust FROM DIM_CUSTOMER;
  SELECT COUNT(*) INTO cnt_date FROM TMP_SALE_DATES;

  WHILE v_done < v_total LOOP
    INSERT /*+ append */ INTO FACT_SALES (SALES_ID, SALES_DATE_ID, SALES_TIME_ID, STORE_ID, PRODUCT_ID, CUSTOMER_ID, EVENT_ID, QUANTITY, AMOUNT, CUSTOMER_COUNT)
    SELECT SEQ_SALES.NEXTVAL,
           sd.DATE_ID,
           t.TIME_ID,
           s.STORE_ID,
           p.PRODUCT_ID,
           CASE WHEN MOD(rn, 10) < 7 THEN MOD(rn, cnt_cust) + 1 ELSE NULL END,
           NULL,
           1 + MOD(rn,5),
           ROUND(p.PRICE * (1 + MOD(rn,5)/100),2),
           1
    FROM (
      SELECT ROWNUM rn
      FROM dual
      CONNECT BY LEVEL <= :b
    ) g
    CROSS JOIN (
      SELECT DATE_ID, TIME_ID, ROW_NUMBER() OVER (ORDER BY DATE_ID) rn0
      FROM DIM_TIME
      WHERE DATE_ID IN (SELECT DATE_ID FROM TMP_SALE_DATES)
    ) t -- we will map rn to an index below using analytic arithmetic
    JOIN (SELECT PRODUCT_ID, PRICE, ROW_NUMBER() OVER (ORDER BY PRODUCT_ID) rn_p FROM DIM_PRODUCT) p
      ON MOD(g.rn + v_done, cnt_prod) + 1 = p.rn_p
    JOIN (SELECT STORE_ID, ROW_NUMBER() OVER (ORDER BY STORE_ID) rn_s FROM DIM_STORE) s
      ON MOD(g.rn + v_done, cnt_store) + 1 = s.rn_s
    JOIN (SELECT DATE_ID, ROW_NUMBER() OVER (ORDER BY CALENDAR_DATE) rn_d FROM TMP_SALE_DATES) sd
      ON MOD(g.rn + v_done, cnt_date) + 1 = sd.rn_d
    ;
    COMMIT;
    v_done := v_done + v_batch;
    DBMS_OUTPUT.PUT_LINE('Inserted: '||v_done);
  END LOOP;
END;
/
