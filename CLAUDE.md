# CLAUDE.md

Read `SPEC.md` fully before making any change in this repo. It is the source of truth for the refactor — schema, authentication, transactions, concurrency control, repo structure, and stage order all live there.

- Work one stage at a time, in the order SPEC.md's stage table lists. Do not start the next stage until told to.
- Do not introduce abstractions beyond what SPEC.md allows: no ORM, no Flask blueprints or factory pattern, no new dependencies beyond what SPEC.md names, no helper function unless it is used in 3+ places. Single `app.py` stays single `app.py`.
- After each stage, explain what changed and why in plain language.
