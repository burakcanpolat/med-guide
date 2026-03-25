# Med-Rehber

Medical image analysis and general medical assistant project.

## First-Run Check

When a conversation starts, check if the `.env` file exists. If it doesn't:
1. Tell the user: "Welcome! This looks like your first time. Shall we set things up together?"
2. If they agree, read `skills/setup-skill.md` and start the setup wizard
3. Do not perform any analysis until setup is complete

If the user says "setup", "install", "how to use", "get started" → read `skills/setup-skill.md`.
If the user says "help" → show the help section from the setup skill.

## Skill Routing

- **Setup / install** → `skills/setup-skill.md`
- **Medical images** (X-ray, CT, MRI) → Read and apply `skills/radiology-skill.md`
- **Lab results, medications, symptoms** → Read and apply `skills/medical-assistant-skill.md`

## Patient Intake (Before Any Analysis)

Before analyzing anything, collect the following from the user (ask one by one):

1. **Who is this report for?** (themselves / a relative / general information)
2. **Age and gender**
3. **Complaint/reason** — "Why was this test done?"
4. **Known medical conditions** (if any)
5. **Current medications** (if any)

Save this information to `reports/hasta_bilgisi.md`. On subsequent analyses, read this file — do not ask again.

If emergency signs are present → stop intake, recommend calling 112 (or local emergency number).

## Skill Routing

- **Medical images** (X-ray, CT, MRI) → Read and apply `skills/radiology-skill.md`
- **Lab results, medications, symptoms** → Read and apply `skills/medical-assistant-skill.md`

## MedGemma Pipeline

For image analysis, use `scripts/medgemma_api.py`:

```
python scripts/medgemma_api.py images/xray.jpeg
python scripts/medgemma_api.py images/d0.jpg images/d1.jpg
python scripts/medgemma_api.py archive.zip
```

Each series is independent: ≤85 images → single request, >85 → batched in groups of 85.
MedGemma outputs in English → translate to plain, simple language for the user.

## Report Saving

Save reports as `reports/YYYY-MM-DD_short-description_report.md`.

## Language

Use simple, plain language that anyone can understand. If medical terms are needed, explain them in parentheses.
