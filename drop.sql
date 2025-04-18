

-- Counts of all TPCC tables from the tpcc schema

SELECT COUNT(*) AS warehouse_count   FROM tpcc.warehouse;

SELECT COUNT(*) AS customer_count    FROM tpcc.customer;
SELECT COUNT(*) AS order_count       FROM tpcc.orders;
SELECT COUNT(*) AS order_line_count  FROM tpcc.order_line;
SELECT COUNT(*) AS stock_count       FROM tpcc.stock;
SELECT COUNT(*) AS history_count     FROM tpcc.history;
SELECT COUNT(*) AS new_order_count   FROM tpcc.new_order;

--DROP USER tpcc CASCADE;