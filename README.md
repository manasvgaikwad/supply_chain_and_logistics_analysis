# DataCo Supply Chain Analytics: Late Deliveries and Profit Leakage

An end-to-end analytics project (Python, MySQL, Power BI) on DataCo Global's order data.

**Goal:** find out where deliveries are late, where the business loses money, and what should be done about both.

---

## 1. Business problem

DataCo ships sports, apparel and electronics products to customers across five markets. Management has no single view of two things:

- **Delivery:** a large share of orders ship later than scheduled, and it is unclear where.
- **Profit:** about one in five order lines loses money, and it is unclear which products and categories cause it.

This project answers both questions and turns the answers into recommendations.

## 2. Dataset

- **Source:** [DataCo Smart Supply Chain for Big Data Analysis](https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis) (Kaggle; original on Mendeley Data)
- **Size:** 180,519 order lines across 65,752 orders, 53 columns
- **Period:** January 2015 to January 2018
- **Grain:** one row per order line (an order can have several lines)

## 3. Approach

```
CSV  ->  Python (clean, features, EDA)  ->  MySQL (schema, analysis, views)  ->  Power BI (dashboard)
```

**Python**
- Standardised column names and converted dates.
- Dropped columns with no information (masked email and password, empty product description, product image, mostly empty order zipcode).
- Removed `benefit_per_order` because it duplicates `order_profit_per_order`.
- Kept negative profit values and flagged them, because they are the losses the project studies.
- Created features: order year and month, shipping delay (real days minus scheduled days), `late_shipment` flag, profit margin, `is_loss` flag.

**MySQL**
- Loaded the cleaned data into a staging table, then split it into five tables with primary and foreign keys: `customers`, `products`, `orders`, `shipping`, `order_items`.
- Ran data quality checks (row counts, nulls, duplicate IDs).
- Answered 17 business questions with joins and group-bys.
- Wrote four window function queries: month-over-month growth, category rank within market, running total of sales per year, top customer per region.
- Created four views for Power BI: `vw_sales_summary`, `vw_delivery_performance`, `vw_product_profit`, `vw_monthly_trends`.

**Power BI**
- Three pages (Overview, Delivery, Profitability) built on the MySQL views, with slicers for year, market, shipping mode and customer segment.

## 4. Key numbers

| Metric | Value |
|---|---|
| Total sales | 36.78M |
| Total profit | 3.97M |
| Profit margin | 10.78% |
| Late shipment rate (per order) | 57.33% |
| Loss-making order lines | 18.71% (33,784 lines) |
| Total lost on loss-making lines | 3.88M |

## 5. Where deliveries are late

**Shipping mode is the driver, not geography.**

| Shipping mode | Late shipment rate |
|---|---|
| First Class | 100.00% |
| Second Class | 79.93% |
| Same Day | 48.36% |
| Standard Class | 39.87% |

| Market | Late shipment rate |
|---|---|
| Pacific Asia | 57.64% |
| Europe | 57.44% |
| USCA | 57.34% |
| LATAM | 57.06% |
| Africa | 56.62% |

- Every First Class order shipped late. A rate of exactly 100% points to the delivery promise (scheduled days) being shorter than the service can deliver, not to random delay.
- The faster and more premium the shipping mode, the worse its on-time record. Standard Class, the cheapest, is the most reliable.
- Markets differ by only about one percentage point, so a regional fix would not move the overall rate.
- The monthly late rate stays between about 55% and 59.5% for the whole three years. It has not improved.

## 6. Where the business loses money

- **18.71% of order lines lose money**, and the losses total 3.88M. That is about half of the 7.85M earned on profitable lines (3.97M net profit + 3.88M losses).
- **The biggest profit categories are also the biggest loss categories.** The same five categories top both lists:

| Category | Net profit | Lost on loss-making lines |
|---|---|---|
| Fishing | 0.76M | -0.73M |
| Cleats | 0.49M | -0.45M |
| Camping & Hiking | 0.43M | -0.44M |
| Cardio Equipment | 0.38M | -0.40M |
| Water Sports | 0.33M | -0.33M |

  Losses sit in the busiest categories, not in weak ones. This looks like a pricing and discount problem on high-volume products.

- **Profit is concentrated.** Fan Shop earns 1.83M (46% of all profit) and Apparel 0.88M. Together they are about 68%. Pet Shop and Book Shop earn almost nothing.
- **Single losses can be large.** The average order line earns 21.97, but the worst line lost 4,275, about 4.7 times the best line's profit (912).

## 7. Recommendations

**Delivery**
1. **Fix the First Class and Second Class promise.** Compare scheduled and actual shipping days per mode, then either reset the promised delivery time or fix the process behind it.
2. **Set an on-time target per shipping mode** and track it monthly. The overall rate has sat near 57% since 2015, so it will not improve without action.
3. **Focus on shipping mode, not region.** Late rates barely differ across markets.

**Profit**
4. **Review pricing and discounts on the five loss-heavy categories** (Fishing, Cleats, Camping & Hiking, Cardio Equipment, Water Sports), starting with Fishing.
5. **Flag loss-making lines before they ship**, and require approval for very large negative-margin orders.
6. **Review the low-profit tail** (Pet Shop, Book Shop, Health and Beauty) and reduce dependence on Fan Shop and Apparel.

## 8. Other insights

- **No customer dependence.** The top customer in each region buys about 3,000 to 5,200 in total. The largest, customer 2773 in Western Europe, is 5,209 out of 36.78M in sales.
- **Payment mix:** Debit is the most used (38.5% of orders), then Transfer (27.5%), Payment (22.9%) and Cash (11.0%).
- **Order status:** about 2.3% of order lines are flagged as suspected fraud and 2.0% are canceled.
- **Sales fall at the end of the data** (about 1M a month through 2017, then 0.33M in January 2018). The data most likely thins out at the end, so this is not treated as a business decline.

## 9. Dashboard

| Overview | Delivery | Profitability |
|---|---|---|
| ![Overview](dashboard/screenshots/overview.png) | ![Delivery](dashboard/screenshots/delivery.png) | ![Profitability](dashboard/screenshots/profitability.png) |

## 10. Repository structure

```
notebooks/   data_co_supply.ipynb      cleaning, features, EDA, export to MySQL
sql/         sql_dataco.sql            schema, quality checks, analysis, window functions, views
dashboard/   Power_BI_Dashboard.pbix   Power BI report
             screenshots/              page screenshots
docs/        BRD.pdf                   business requirements document
```

## 11. How to run

1. Download the dataset from Kaggle and place `DataCoSupplyChainDataset.csv` next to the notebook.
2. In MySQL, create an empty database: `create database dataco;`
3. Open the notebook, enter your MySQL password in the connection cell, and run all cells. The last cell loads the data into a `staging_orders` table.
4. Run `sql/sql_dataco.sql` in MySQL to build the tables, queries and views.
5. Open the `.pbix` file in Power BI Desktop and point the connection to your local MySQL (`localhost`, database `dataco`).

## 12. Notes and limitations

- The dataset is a published sample, so the findings describe this data and not a real company.
- Late shipment rates are calculated per order (65,752 orders). Profit and loss figures are per order line (180,519 lines). Python rates by market, calculated per line, differ slightly from the SQL and Power BI rates.
- `late_shipment` means actual shipping days are greater than scheduled days. It can differ from the dataset's own `late_delivery_risk` column.
- January 2018 appears to be a partial month, so it is not used for any trend conclusion.

---

Built by Manas.
