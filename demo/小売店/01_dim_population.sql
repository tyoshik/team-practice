-- 01_dim_population.sql
-- 実行順序: DIM_DATE → DIM_TIME → DIM_STORE → DIM_PRODUCT → DIM_CUSTOMER → DIM_EVENT

SET SERVEROUTPUT ON
DECLARE
  v_date DATE := DATE '2024-01-01';
  v_end  DATE := DATE '2025-12-31';
  v_id   NUMBER;
  -- 月別平均気温（神奈川県的概算: 1月..12月）
  TYPE t_arr IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  avg_month_temp t_arr;
BEGIN
  avg_month_temp(1) := 8;   avg_month_temp(2) := 8;
  avg_month_temp(3) := 10;  avg_month_temp(4) := 14;
  avg_month_temp(5) := 18;  avg_month_temp(6) := 21;
  avg_month_temp(7) := 25;  avg_month_temp(8) := 27;
  avg_month_temp(9) := 23;  avg_month_temp(10):= 18;
  avg_month_temp(11):= 13;  avg_month_temp(12):= 9;

  -- 日付ディメンション生成
  WHILE v_date <= v_end LOOP
    v_id := SEQ_DATE.NEXTVAL;
    INSERT INTO DIM_DATE(DATE_ID, CALENDAR_DATE, YYYY, QTR, MM, DD, WEEKDAY, IS_HOLIDAY, MAX_TEMP, MIN_TEMP, WEATHER)
    VALUES (
      v_id,
      v_date,
      TO_NUMBER(TO_CHAR(v_date,'YYYY')),
      TO_NUMBER(TO_CHAR(v_date,'Q')),
      TO_NUMBER(TO_CHAR(v_date,'MM')),
      TO_NUMBER(TO_CHAR(v_date,'DD')),
      TO_NUMBER(TO_CHAR(v_date,'D')),
      'N', -- 祝日フラグは後で調整
      ROUND(avg_month_temp[TO_NUMBER(TO_CHAR(v_date,'MM'))] + DBMS_RANDOM.VALUE(-3,4),2),
      ROUND(avg_month_temp[TO_NUMBER(TO_CHAR(v_date,'MM'))] - DBMS_RANDOM.VALUE(1,5),2),
      CASE
        WHEN DBMS_RANDOM.VALUE(0,1) < 0.1 THEN '雨'
        WHEN DBMS_RANDOM.VALUE(0,1) < 0.03 THEN '雪'
        ELSE '晴れ'
      END
    );
    v_date := v_date + 1;
  END LOOP;
  COMMIT;

  -- TIME DIM（同日粒度でコピー）
  FOR r IN (SELECT DATE_ID, CALENDAR_DATE FROM DIM_DATE ORDER BY CALENDAR_DATE) LOOP
    INSERT INTO DIM_TIME(TIME_ID, DATE_ID, YYYY, QTR, MM, DD)
    VALUES (SEQ_TIME.NEXTVAL, r.DATE_ID, TO_NUMBER(TO_CHAR(r.CALENDAR_DATE,'YYYY')), TO_NUMBER(TO_CHAR(r.CALENDAR_DATE,'Q')), TO_NUMBER(TO_CHAR(r.CALENDAR_DATE,'MM')), TO_NUMBER(TO_CHAR(r.CALENDAR_DATE,'DD')));
  END LOOP;
  COMMIT;

  DBMS_OUTPUT.PUT_LINE('DIM_DATE/DIM_TIME populated.');
END;
/
-- 祝日フラグの簡易設定（週末を祝日にする簡易ルール + 年始等）
UPDATE DIM_DATE SET IS_HOLIDAY='Y' WHERE TO_CHAR(CALENDAR_DATE,'DY','NLS_DATE_LANGUAGE=EN') IN ('SAT','SUN');
UPDATE DIM_DATE SET IS_HOLIDAY='Y' WHERE CALENDAR_DATE IN (DATE '2024-01-01', DATE '2025-01-01'); -- 元日
COMMIT;

-- STORE データ（10 店舗）
BEGIN
  -- 店舗名サンプル（10 店）
  DECLARE
    v_stores SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
      '綱島','日吉','新川崎','藤沢','戸塚','本厚木','相模大野','逗子','平塚','鶴見'
    );
    v_types SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('駅前','商店街','ロードサイド','ショッピングモール');
    i PLS_INTEGER;
    lt VARCHAR2(30);
    lat NUMBER;
    lon NUMBER;
    area NUMBER;
    staff NUMBER;
    rank NUMBER;
  BEGIN
    FOR i IN 1..v_stores.COUNT LOOP
      lt := v_types[MOD(i-1, v_types.COUNT) + 1];
      -- 仮の座標（神奈川県近辺の例、実在座標でなくてもよい）
      lat := 35.3 + DBMS_RANDOM.VALUE(-0.05,0.05) + (i - 5)*0.01;
      lon := 139.5 + DBMS_RANDOM.VALUE(-0.06,0.06) - (i - 5)*0.01;
      area := ROUND(200 + DBMS_RANDOM.VALUE(-50,300),2); -- m2
      staff := TRUNC(8 + DBMS_RANDOM.VALUE(-3,10));
      rank := CASE lt WHEN '駅前' THEN 4 WHEN '商店街' THEN 3 WHEN 'ロードサイド' THEN 2 ELSE 1 END;
      INSERT INTO DIM_STORE(STORE_ID, STORE_CODE, STORE_NAME, LOCATION_TYPE, LOCATION_RANK, LATITUDE, LONGITUDE, STORE_AREA, STAFF_COUNT, OPEN_DATE)
      VALUES (SEQ_STORE.NEXTVAL,
              'S' || LPAD(TO_CHAR(i),3,'0'),
              'ドラッグ・ソレイユ '|| v_stores(i) || '店',
              lt,
              rank,
              lat, lon, area, staff,
              TRUNC(SYSDATE - DBMS_RANDOM.VALUE(365,3650))
      );
    END LOOP;
    COMMIT;
  END;
  DBMS_OUTPUT.PUT_LINE('DIM_STORE populated.');
END;
/

-- PRODUCT データ（500）
DECLARE
  categories SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('ヘルス','ビューティ','日用品','食品','ベビー','季節品');
  subcats SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST(
    'サプリ','OTC','化粧品','スキンケア','洗剤','紙製品','スナック','飲料','ミルク','おむつ','花粉対策','夏用品'
  );
  v_count PLS_INTEGER := 500;
BEGIN
  FOR i IN 1..v_count LOOP
    INSERT INTO DIM_PRODUCT(PRODUCT_ID, SKU, CATEGORY, SUBCATEGORY, PRODUCT_NAME, PRICE, POPULARITY)
    VALUES (
      SEQ_PRODUCT.NEXTVAL,
      'P' || LPAD(i,5,'0'),
      categories[MOD(i-1, categories.COUNT)+1],
      subcats[MOD(i-1, subcats.COUNT)+1],
      '商品_' || categories[MOD(i-1, categories.COUNT)+1] || '_' || LPAD(i,4,'0'),
      ROUND(DBMS_RANDOM.VALUE(150,3000),2),
      TRUNC(DBMS_RANDOM.VALUE(1,101))
    );
  END LOOP;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('DIM_PRODUCT populated: '||v_count);
END;
/

-- CUSTOMER データ（約 50,000）
DECLARE
  v_total NUMBER := 50000;
  v_active NUMBER := 30000;
  domains SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('example.com','mail.local','sample.jp');
  PREFS SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('神奈川県','横浜市','川崎市','鎌倉市','藤沢市');
  cities SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('横浜市中区','横浜市港北区','川崎市中原区','鎌倉市','藤沢市','平塚市');
  v_gender SYS.ODCIVARCHAR2LIST := SYS.ODCIVARCHAR2LIST('M','F','U');
BEGIN
  FOR i IN 1..v_total LOOP
    INSERT INTO DIM_CUSTOMER(CUSTOMER_ID, CUSTOMER_NO, GENDER, BIRTH_YEAR, AGE, EMAIL, PREFECTURE, CITY, POSTCODE, ACTIVE_FLAG)
    VALUES (
      SEQ_CUSTOMER.NEXTVAL,
      'C' || LPAD(i,6,'0'),
      v_gender[MOD(i,3)+1],
      TRUNC(TO_NUMBER(TO_CHAR(SYSDATE,'YYYY')) - TRUNC(DBMS_RANDOM.VALUE(18,80))),
      NULL,
      'user' || i || '@' || domains[MOD(i,domains.COUNT)+1],
      PREFS[MOD(i-1,PREFS.COUNT)+1],
      cities[MOD(i-1,cities.COUNT)+1],
      LPAD(TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1000000,9999999))),7,'0'),
      CASE WHEN i <= v_active THEN 'Y' ELSE 'N' END
    );
  END LOOP;
  -- 年齢列を再計算
  UPDATE DIM_CUSTOMER SET AGE = TO_NUMBER(TO_CHAR(SYSDATE,'YYYY')) - BIRTH_YEAR;
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('DIM_CUSTOMER populated: '||v_total);
END;
/

-- EVENT データ（いくつかの例。競合の開店/閉店イベントも含む）
BEGIN
  INSERT INTO DIM_EVENT(EVENT_ID, EVENT_NAME, EVENT_TYPE, START_DATE, END_DATE, DESCRIPTION) VALUES (SEQ_EVENT.NEXTVAL, '綱島 夏祭り', '地域イベント', DATE '2024-08-03', DATE '2024-08-03', '地域の夏祭り（露店・盆踊り）');
  INSERT INTO DIM_EVENT(EVENT_ID, EVENT_NAME, EVENT_TYPE, START_DATE, END_DATE, DESCRIPTION) VALUES (SEQ_EVENT.NEXTVAL, '近隣スーパーA 閉店', '環境変化', DATE '2025-07-15', DATE '2025-07-15', '近隣大型スーパーが閉店した');
  INSERT INTO DIM_EVENT(EVENT_ID, EVENT_NAME, EVENT_TYPE, START_DATE, END_DATE, DESCRIPTION) VALUES (SEQ_EVENT.NEXTVAL, '競合ドラッグ開店（戸塚）', '競合関連', DATE '2024-07-20', DATE '2024-07-20', '競合店舗が新規オープン');
  INSERT INTO DIM_EVENT(EVENT_ID, EVENT_NAME, EVENT_TYPE, START_DATE, END_DATE, DESCRIPTION) VALUES (SEQ_EVENT.NEXTVAL, '小学校 運動会（相模）', '地域イベント', DATE '2024-10-05', DATE '2024-10-05', '地域行事');
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('DIM_EVENT populated.');
END;
/
