# AFAB Database Schema Improvements (Recommended Before Development)

These are the **four recommended improvements** that provide the highest
value for scalability while keeping the current schema almost unchanged.

  ----------------------------------------------------------------------------------------------------
  Improvement               Before                     After                           Reason
  ------------------------- -------------------------- ------------------------------- ---------------
  **1. Payment Methods**    `payment_method` stored as Create a **payment_methods**    Makes it easy
                            `VARCHAR` inside `income`  table and reference it using    to support
                            and `expenses`.            `payment_method_id`.            Apple Pay,
                                                                                       Google Pay,
                                                                                       Wise, PayPal,
                                                                                       Stripe, Crypto
                                                                                       Wallets, bank
                                                                                       accounts, and
                                                                                       future
                                                                                       providers
                                                                                       without
                                                                                       changing the
                                                                                       schema.

  **2. Multiple Receipts**  `expenses.receipt_url`     Create an **expense_receipts**  Supports
                            allows only **one**        table containing `expense_id`,  multiple
                            receipt per expense.       `file_name`, `object_key`,      receipts,
                                                       `mime_type`, `size`, and        invoices, PDFs,
                                                       `uploaded_at`.                  warranty files,
                                                                                       and other
                                                                                       documents for a
                                                                                       single expense.

  **3. Multi-Currency**     Only                       Add `transaction_currency`,     Enables
                            `business.base_currency`   `exchange_rate`, and            transactions in
                            is stored.                 `converted_amount` to both      different
                                                       `income` and `expenses`.        currencies
                                                                                       while keeping
                                                                                       reports and
                                                                                       analytics in
                                                                                       the business
                                                                                       base currency.

  **4. Larger Datasets      No explicit indexing       Add indexes on `business_id`,   Improves
  (Performance)**           strategy.                  `(business_id, date)`,          dashboard
                                                       `(business_id, category_id)`,   loading,
                                                       `(business_id, status)`, and    filtering,
                                                       `created_at`.                   reporting, and
                                                                                       query
                                                                                       performance as
                                                                                       the database
                                                                                       grows.
  ----------------------------------------------------------------------------------------------------

------------------------------------------------------------------------

## Summary

These four improvements are recommended because they solve the most
common scalability challenges without requiring a major redesign of the
database.
