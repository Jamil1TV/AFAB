# AFAB AI Project Context Pack

Place these Markdown files at the root of the AFAB repository so coding agents can find them before editing:

- `AFAB_AI_PROJECT_CONTEXT.md` — shared product, architecture, constraints, and AI-agent protocol.
- `AFAB_FRONTEND_CONTEXT.md` — frontend architecture, localization, API usage, UI system, and frontend rules.
- `AFAB_BACKEND_CONTEXT.md` — backend architecture, API endpoints, database, security, and backend rules.

Recommended instruction for your coding agent:
> Before making changes, read `AFAB_AI_PROJECT_CONTEXT.md` and the relevant frontend/backend context file. Inspect the actual code before assuming a feature is implemented. Follow the product/security rules and report tests actually run.

These documents were created from a static review of the uploaded archive. No build or tests were executed. Keep the files updated as the project evolves.
