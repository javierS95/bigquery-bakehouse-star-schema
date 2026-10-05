-- =========================================================
-- 04 · GOLD: tabla ancha (OBT, One Big Table) para BI
-- Origen: bakehouse_model (fact_sales + dim_*)
-- Destino: bakehouse_gold.sales_flat
--
-- Por qué existe:
-- Looker Studio no tiene capa semántica: no maneja bien relaciones
-- entre varias tablas y cada filtro dispara una query nueva.
-- Esta tabla ya trae la fact unida con todas sus dimensiones, así el
-- dashboard filtra por cualquier atributo (franquicia, producto, país,
-- día de la semana, ciudad del cliente) sin joins en cada clic.
--
-- Es TABLA (no vista) para no repetir los joins en cada consulta,
-- y se particiona/clusteriza igual que la fact para filtrar barato.
-- Con una herramienta con capa semántica (Power BI, Looker/LookML)
-- se usaría el modelo estrella directamente.
-- =========================================================

CREATE OR REPLACE TABLE bakehouse_gold.sales_flat
PARTITION BY transaction_date
CLUSTER BY franchise_name, product_name
OPTIONS (description = 'Ventas desnormalizadas (fact + dimensiones) para consumo en Looker Studio')
AS
SELECT
  -- hecho
  f.transaction_id,
  f.transaction_ts,
  f.transaction_date,
  f.quantity,
  f.unit_price,
  f.total_price,
  f.payment_method,
  -- calendario
  d.year,
  d.month,
  d.iso_week,
  d.day_name,
  d.is_weekend,
  -- franquicia
  f.franchise_id,
  df.franchise_name,
  df.franchise_city,
  df.franchise_country,
  -- producto
  p.product_name,
  -- cliente
  f.customer_id,
  c.customer_city,
  c.customer_country,
  c.continent AS customer_continent
FROM bakehouse_model.fact_sales f
JOIN bakehouse_model.dim_date d
  ON f.transaction_date = d.date
LEFT JOIN bakehouse_model.dim_franchise df
  ON f.franchise_id = df.franchise_id
LEFT JOIN bakehouse_model.dim_product p
  ON f.product_key = p.product_key
LEFT JOIN bakehouse_model.dim_customer c
  ON f.customer_id = c.customer_id;
