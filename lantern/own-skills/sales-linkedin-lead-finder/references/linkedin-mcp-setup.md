# Setting up the LinkedIn MCP (optional; only for finding people)

Project: stickerdaniel/linkedin-mcp-server. It drives a real browser logged in as the USER. The user must agree to the ban risk first.

Install in Claude Code:
    claude plugin marketplace add stickerdaniel/linkedin-mcp-server
    claude plugin install linkedin-mcp-server@linkedin-mcp-server
or add an MCP server `uvx mcp-server-linkedin@latest` (env UV_HTTP_TIMEOUT=300).

Login: run with `--login` (opens a browser window) or `--import-from-browser`. Session is stored in ~/.linkedin-mcp/profile/.
On a tablet or cloud session there is no local window: use Docker with the one-time login viewer on port 6080, or run the MCP on a computer the user controls. If login is not possible, the user pastes profile URLs instead.

Read-only tools to use: search_companies, get_company_employees, search_people, get_person_profile, get_session_status.
Do not use: connect_with_person, send_message, reply_to_conversation, archive_conversation, get_inbox, get_conversation, search_conversations, get_easy_apply_form, dismiss_job, close_session (unless ending).
