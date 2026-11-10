---
name: sales-linkedin-lead-finder
description: "[SALES] Build a B2B lead list of names, job titles, companies and verified emails. Finds the right people on LinkedIn (via the linkedin-mcp-server, sparingly and read-only), then gets emails from ContactOut's API. Use when the user wants leads from LinkedIn, 'find the decision makers at X', 'get emails for these LinkedIn profiles', 'build a prospect list', or enrich a CSV of names/LinkedIn URLs with emails. Never messages, connects or posts on LinkedIn."
---

# LinkedIn lead finder (names from LinkedIn, emails from ContactOut)

Output: a CSV with `full_name, title, company, linkedin_url, email, email_type, source, status`.

LinkedIn rarely shows emails, so LinkedIn is used only to FIND people. ContactOut supplies the emails.

## Ground rules (read first, tell the user)
- LinkedIn's User Agreement bans automated access. Accounts using scrapers can be restricted or banned. Say this once, plainly, before using the LinkedIn MCP, and get a yes.
- Use the user's own logged-in account only. Never ask for or handle their LinkedIn password; login happens in the browser window the MCP opens.
- Read-only. NEVER call `connect_with_person`, `send_message`, `reply_to_conversation`, `archive_conversation`, `dismiss_job` or anything that writes. Do not use the inbox tools.
- Go small: batches of 10-25 people, sequential, with pauses. Stop at the first sign of a captcha, rate limit or logout. Do not retry in a loop.
- Collect only what a business needs to contact someone about their job: name, title, company, work email. No personal emails or phone numbers unless the user asks and has a lawful basis (GDPR/UK PECR/CASL apply to people in those regions). Keep a `source` column.
- Suppress anyone who asks to be removed. Do not store lists longer than needed.

## Workflow
The script is in this skill's folder: `~/.claude/skills/sales-linkedin-lead-finder/scripts/contactout-enrich.mjs` (below shortened to `scripts/...`). Work in the user's working folder, not inside the skill folder.
1. **Brief (2-3 questions max):** who is the ideal customer (role, industry, company size, country), and how many leads. Offer to use `founder-consumer` first if the ICP is vague.
2. **Find people.** Preferred order:
   a. The user pastes LinkedIn profile URLs or a CSV (no LinkedIn access needed). Go to step 3.
   b. `search_companies` then `get_company_employees` / `search_people` from the linkedin MCP (see `references/linkedin-mcp-setup.md`). For each hit keep name, title, company, profile URL only. Use `get_person_profile` only if a title is missing.
   c. If the MCP is not set up, say so and fall back to (a). Do not try to scrape pages with ad-hoc code.
3. **Write `leads.csv`** with columns: `full_name, title, company, company_domain, linkedin_url`.
4. **Dry run, always first:**
   `node scripts/contactout-enrich.mjs --in leads.csv --out enriched.csv --dry-run`
   Show the user the number of API calls and the credit worst case. Wait for a go-ahead.
5. **Enrich** (key comes from the environment, never from a file or chat):
   `CONTACTOUT_API_KEY=... node scripts/contactout-enrich.mjs --in leads.csv --out enriched.csv --max 25`
   Raise `--max` only when the user agrees. Add `--include-phone` only if asked.
6. **Check the result:** report found / not found / errors. Rows with `status=no_email` are normal. Prefer `email_type=work`. Flag generic addresses (info@, sales@).
7. **Hand off:** pass `enriched.csv` to `sales-cold-email-playbook` (list cleaning, deliverability, sequence). Verify addresses before sending (ContactOut's verifier or another tool).

## ContactOut facts (checked against their API docs)
- Base `https://api.contactout.com`, header `token: <key>`. API access is requested from ContactOut; the Chrome-extension plan may not include it. If calls return 401/403, tell the user to ask ContactOut about API access.
- Profile URL to contacts: `GET /v1/people/linkedin?profile=<url>`. 1 email credit when an email is found.
- Name + company: `POST /v1/people/enrich` (full_name plus company/domain/location). 1 search credit when a profile is found, plus email credit when an email is found.
- People search is limited to 60 requests/minute; the script paces itself.
- Bulk endpoints exist (up to 100 per call sync, 1000 async); use them only for big lists and with the user's go-ahead.

## Never
- Guess or pattern-generate emails and present them as verified.
- Print or save the API key. Commit `leads.csv` or `enriched.csv` to a repository (they hold personal data).
