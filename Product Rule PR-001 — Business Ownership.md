# Product Rule PR-001 — Business Ownership

## One User = One Business (Version 1)

In Version 1 of AFAB, each registered user owns and manages exactly one business.

All financial data—including income, expenses, budgets, savings goals, investments, reports, and notifications—belongs exclusively to that single business.

This design simplifies the user experience, reduces development complexity, and enables a faster delivery of the MVP while maintaining a scalable architecture.

### Future Expansion

The database and application architecture should be designed so that multi-business support can be introduced in a future version with minimal architectural changes.

Future versions may allow:

* One user managing multiple businesses.
* Switching between businesses.
* Team collaboration.
* Business-specific user roles and permissions.

These capabilities are intentionally excluded from Version 1.


### database


User
 ├── Business A
 ├── Business B
 ├── Business C

 we'll have:

 User
   │
   ▼
Business
   │
   ├── Income
   ├── Expenses
   ├── Budgets
   ├── Savings Goals
   ├── Investments
   └── Reports


Future-Proof Architecture

Even though Version 1 supports one business, we'll still create a dedicated businesses table instead of storing business information directly in the users table.

For example:

users
-------
id
name
email
password

businesses
----------
id
user_id
name
currency
country
timezone
created_at



