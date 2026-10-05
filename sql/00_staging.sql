-- =========================================================
-- 00 · STAGING de transacciones
-- Origen: bakehouse_raw.transactions (CSV exportado desde Databricks silver)
-- Destino: bakehouse_model.stg_transactions
--
-- Por qué existe este paso (limitación del BigQuery sandbox):
-- En el sandbox, todas las particiones expiran a los 60 días, contados
-- desde la FECHA de la partición (no desde la carga). Los datos de origen
-- son de 2024, así que una tabla particionada por fecha los borraría
-- de inmediato. Se desplazan las fechas para que el día más reciente
-- quede en "ayer", conservando intactos el orden y las distancias entre días.
-- En un proyecto con facturación activa este desplazamiento no haría falta.
-- =========================================================

CREATE OR REPLACE TABLE bakehouse_model.stg_transactions
OPTIONS (description = 'Transacciones con fechas desplazadas a un rango reciente (workaround de expiración de particiones del sandbox)')
AS
WITH shift AS (
  SELECT DATE_DIFF(CURRENT_DATE(), MAX(transaction_date), DAY) - 1 AS days_offset
  FROM bakehouse_raw.transactions
)
SELECT
  t.transaction_id,
  t.customer_id,
  t.franchise_id,
  TIMESTAMP_ADD(t.transaction_ts, INTERVAL s.days_offset DAY) AS transaction_ts,
  DATE_ADD(t.transaction_date, INTERVAL s.days_offset DAY)    AS transaction_date,
  t.transaction_date                                          AS original_transaction_date,
  t.product,
  t.quantity,
  t.unit_price,
  t.total_price,
  t.payment_method
FROM bakehouse_raw.transactions t
CROSS JOIN shift s;
