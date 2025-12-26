CREATE NONCLUSTERED INDEX idx_customers_email
ON sales.customers(email);

CREATE NONCLUSTERED INDEX idx_products_category_brand
ON production.products(category_id, brand_id);

CREATE NONCLUSTERED INDEX idx_orders_date
ON sales.orders(order_date)
INCLUDE(customer_id, store_id, order_status);

CREATE TRIGGER trg_NewCustomer
ON sales.customers
AFTER INSERT
AS
BEGIN
    INSERT INTO sales.customer_log(customer_id, action)
    SELECT customer_id, 'Welcome'
    FROM inserted;
END;

CREATE TRIGGER trg_PriceChange
ON production.products
AFTER UPDATE
AS
BEGIN
    INSERT INTO production.price_history(product_id, old_price, new_price, changed_by)
    SELECT d.product_id, d.list_price, i.list_price, SYSTEM_USER
    FROM deleted d
    JOIN inserted i ON d.product_id = i.product_id
    WHERE d.list_price <> i.list_price;
END;

CREATE TRIGGER trg_PreventCategoryDelete
ON production.categories
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS(SELECT 1 FROM production.products p JOIN deleted d ON p.category_id = d.category_id)
        RAISERROR('Cannot delete category with associated products',16,1);
    ELSE
        DELETE FROM production.categories WHERE category_id IN (SELECT category_id FROM deleted);
END;

CREATE TRIGGER trg_UpdateStock
ON sales.order_items
AFTER INSERT
AS
BEGIN
    UPDATE s
    SET s.quantity = s.quantity - i.quantity
    FROM production.stocks s
    JOIN inserted i ON s.product_id = i.product_id AND s.store_id = i.store_id;
END;

CREATE TRIGGER trg_OrderAudit
ON sales.orders
AFTER INSERT
AS
BEGIN
    INSERT INTO sales.order_audit(order_id, customer_id, store_id, staff_id, order_date)
    SELECT order_id, customer_id, store_id, staff_id, order_date
    FROM inserted;
END;
