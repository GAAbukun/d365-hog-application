# Instructions for AI-assisted work in this repository

This is the shared Dynamics 365 Finance & Operations X++ application package for Honegger: package and model `HOGApplication`. It holds several solutions; each keeps its own prefix (`HOGpma` for indirect costs, `HOGsba` for Subscription billing). Solution docs live in the solution repos (e.g. d365-pma-indirectCostAssignment). Read `README.md` first.

## Before writing or changing anything

- Follow the conventions. **Master:** [youniform](https://github.com/youserpath/youniform) `conventions/` (read it if it is cloned next to this repo, e.g. `../youniform`). **Snapshot:** `docs/conventions/` in this repo, kept so the repo is complete at handover. Never change the snapshot alone: change youniform first, then refresh the snapshot.
- Customer facts (prefix, existing models, environments): youniform `customers/honegger.md`.
- **Never guess standard object, field or method names.** A name not confirmed on the dev VM is marked `VERIFY` and gets a discovery item (`D-nn` in doc 02). Microsoft Learn first, then community sources, and always say which.
- X++ in docs is a draft until it has been compiled on the VM. Say so in the doc.
- Never commit Microsoft or ISV source code, secrets, or customer production data.

## Working model

- Discovery, builds and best-practice checks run in the Claude session on the dev VM. Cloud sessions can't reach the VM; they do research, docs and review, and exchange results through this repo.
- On the VM: only our own packages under `Metadata/` are changed. Business data in the database is not queried unless the customer has agreed.
- The user works on Windows: give **PowerShell** commands, not bash.
- Keep IDs stable and cross-referenced (youniform C-00). Commit messages and PRs reference IDs, not issue numbers.
- Question the request and say where it may cause trouble later (upgrades, consolidation, posting, handover to the customer's Azure DevOps).
