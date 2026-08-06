1/ 🏗️ Recommended Immediate Next Features (Phase 3 Roadmap)
Now that Authentication, Security, Password Reset, and i18n are production-ready, the logical next step is implementing the core financial engine:

📊 A. Financial Categories & Ledger Management

1. Categories CRUD: Allow users to create customized Income/Expense categories with colors and icons.
2. Transaction Ledgers: Full CRUD for Incomes and Expenses with pagination, date filtering, search, and CSV export.
3. MinIO Receipt Attachment: Attach photo/PDF receipt uploads to expense entries using the existing MinIO S3 container.
🧾 B. Invoicing & Billing Module
1. Invoice Builder: Create professional client invoices with line items, tax calculations, and due dates.
2. Status Tracking: Track invoice lifecycle (Draft ➔ Sent ➔ Paid ➔ Overdue).
3. PDF Export: Generate downloadable client invoices.
🤖 C. AI CFO Insights (Phase 4)
1. Auto-Categorization: AI-powered auto-tagging for recurring bank transactions.
2. Cash Flow Predictions: 30-day and 90-day predictive cash flow forecasts based on recurring revenue and historical expenses.
3. Spending Anomaly Detection: Proactive alerts when an expense category spikes unexpectedly.

2/ ⚡ Technical & Code Quality Recommendations

🌐 A. Standardized i18n Guardrails

1. The Issue: Hardcoded English strings can easily creep into UI components (like we saw in the settings page).
2. Recommendation: Ensure every new component wraps user-facing text with t("key"). Consider adding an ESLint rule (@next-intl/no-literal-string) or pre-commit hook to catch un-translated UI text automatically.
📝 B. Standardized Form Validation (Zod + React Hook Form)

1. Recommendation: For upcoming complex screens (Invoice creation, Expense entry), use Zod schemas coupled with react-hook-form. This gives you type-safe, instant inline validation for inputs like amounts, tax rates, and date pickers.
2. 🛡️ C. Global API Error Boundary
3. Recommendation: Add a global React Error Boundary around the dashboard layout so that unexpected 500 errors or network drops display a fallback UI without freezing the screen.
4. 🗄️ D. Database Seed Data Migration
5. Recommendation: Create a V9__dev_seed_data.sql migration (enabled only in local profile) that populates default financial categories (e.g., Salaries, Office Rent, Software Subscriptions, Client Payments) so newly registered users immediately see rich dashboard data.

