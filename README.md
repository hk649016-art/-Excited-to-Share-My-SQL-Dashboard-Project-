# MySQL Stored Procedure Studio — Flask App

## 1. Database setup

Create/select your database, import the three CSV files into:

- `orders`
- `products`
- `order_product`

Then open `procedures.sql` in MySQL Workbench and run it.

If `orders.clean_orderdate` is already a DATE column, skip the two conversion statements at the top of `procedures.sql`.

## 2. Install Python packages

```bash
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python app.py
```

## 3. Configure MySQL

Copy `.env.example` to `.env` and set your credentials.

This app also accepts environment variables directly:

```text
MYSQL_HOST
MYSQL_PORT
MYSQL_USER
MYSQL_PASSWORD
MYSQL_DATABASE
```

Default database name is `sales_db`.

## 4. Run

```bash
python app.py
```

Open:

http://127.0.0.1:5000

## Included procedures

1. `view_orders(Sdate, Edate)`
2. `update_model(p_id, New_model)`
3. `orders_by_country(p_country)`
4. `orders_by_segment(p_segment)`
5. `sales_by_product(Sdate, Edate)`
6. `sales_by_category(Sdate, Edate)`
7. `shipmode_summary(Sdate, Edate)`
8. `customer_orders(p_customer)`
9. `product_performance(p_id)`
10. `feedback_summary(Sdate, Edate)`

The Flask API uses a whitelist so arbitrary stored procedure names cannot be submitted from the browser.
