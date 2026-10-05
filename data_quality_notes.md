# Data Quality Notes
Checks run on the Olist data after loading it into MySQL.

## Row counts
All 8 tables loaded with the expected row counts (for example, 99,441 orders and 112,650 order items).

## Findings and decisions
- 8 orders are marked delivered but have no delivery date. Excluded from delivery-time analysis; kept in revenue and order counts.
- Some orders have more than one review record (up to 3). Kept the latest answered review per order in the view order_reviews_clean (98,672 orders have a review).
- About 769 orders have no review.
- Only delivered orders (96,478 of 99,441) are counted as completed sales. Canceled, unavailable and in-progress orders are excluded from revenue.
- Each order has its own customer_id, so real people are counted with customer_unique_id: 96,096 unique people for 99,441 orders. Only about 3,345 orders came from returning customers, so retention is low in this dataset.
- 775 orders have no items: 603 unavailable, 164 canceled, and 8 in other early statuses. None are delivered, so they carry no revenue. 1 order has no payment record.
- Revenue figures use total payment value, which includes shipping fees.
- Payment_value includes shipping: total paid (16.01M) is within about 1% of item price + freight (15.84M), but about 18% above item prices alone (13.59M). Revenue figures are therefore "total payments received", not product sales only.
