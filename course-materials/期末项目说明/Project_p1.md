# MIS 205 Term Project — Part 1: Research Paper Management System (RPMS)

> **Course:** MIS 205 — Data Management and Database (Spring 2026)
> **Total project:** 15 points (Part 1 = 10 pts, Part 2 = 5 pts) **+ up to 2 bonus points on each part**
> **This document covers Part 1 only.**
> **Stack:** PostgreSQL · Python · Flask · HTML · CSS

The Research Paper Management System (RPMS) is a web-based application that helps academic institutions manage research papers. Users (students and professors) register, log in, submit papers, and view what's been submitted. In Part 1 you will design and implement the relational database behind it, then complete the Flask code that ties the database to the web interface.

Part 2 (worth 5 points, released separately) will extend this project using the Vibe Coding tools from weeks 9–16.

---

## Groups

Form a group of **1–3 students** at the start of the term project — you'll keep the same group for both Part 1 and Part 2. Working solo is fine.

For Part 1, you can work together (discuss the schema, help each other through the blanks), but **each student submits their own filled-in code and report** individually. Part 2 is a single group submission per group.

---

## Learning Objectives

1. **Database Design.** Design a relational schema that captures users and research papers with the right relationships.
2. **CRUD Operations.** Implement Create / Read / Update / Delete — especially for the login/registration flow.
3. **SQL Practice.** Write parameterized SQL for retrieval and manipulation.
4. **Web Integration.** Connect the database to a Flask web app that lets users interact with the data through a browser.

---

## Requirements (10 points + 2 bonus)

### Core requirements (10 points)

#### 1. User Registration and Authentication — 6 points
- Users can **register** and **log in** to the system.
  - Create **at least three users** during testing.
- Understand and implement **session data** in Flask (so login state persists across pages).
- Implement **logout** (clear the session).

#### 2. Research Paper Submission — 3 points
- Logged-in users can submit a research paper with the following fields (**2 points**):
  - Title
  - Authors
  - Abstract
  - Topics
- Submit **at least three papers** during testing.
- Each paper must be **linked to the user who submitted it** (**1 point**).

#### 3. View Papers — 1 point
- Logged-in users can view a list of all submitted papers.

### Bonus (max 2 points)

#### SQL Injection Awareness — 2 points *(difficult)*
Demonstrate that you understand **why** the parameterized queries in the starter code matter.

1. **Break it.** Temporarily rewrite the login query using **string concatenation** (`f"...{username}..."` or `+` instead of `%s`). Show — with a screenshot and the attack string you used — how an attacker can **bypass the login** without knowing any password.
   - **Working attack string:** paste `' OR '1'='1' --` into the **username** field, and anything (even empty) into the password field. The `--` is a SQL comment that makes PostgreSQL ignore everything after it — including the `AND password = ...` check.
   - **What success looks like:** you should be redirected to the home page, logged in as `alice` (the first row of the `accounts` table) — even though you never typed her password.
   - **Screenshot tip:** the password field is `<input type="password">`, so it shows dots, not your payload. Take the screenshot either *before* you submit (so the username payload is visible), or include the attack strings in plain text in your report.
2. **Fix it.** Restore the parameterized version with `%s` placeholders. Try the same attack again — this time the page should show **"Incorrect username/password!"** and you stay on the login screen.
3. **Reflect.** In 3–5 sentences in your report, explain why parameterization defeats the attack.

This bonus is graded all-or-nothing: you must show the working bypass **and** the restored safe version **and** the reflection.

---

## Steps

> The steps below use **DBeaver** + your text editor — the workflow most consistent with Labs 1–10. You may also use **AI coding assistants** (Pi) or **command-line tools** (`psql`, `createdb`) if you prefer. What matters is your final submission, not the tooling you used to get there.

### Step 1. Database design

Identify the key entities (e.g., `accounts`, `papers`) and define their attributes:

| Entity | Required attributes |
|---|---|
| `accounts` | `id` (auto-increment, PK), `username` (UNIQUE), `email`, `password` |
| `papers` | `id` (auto-increment, PK), `title`, `authors`, `abstract`, `topics`, `user_id` (FK → `accounts.id`) |

A starting `schema.sql` is provided in `student/schema.sql`. You can use it as-is, or extend it (for example, add constraints or indexes you think are warranted).

### Step 2. Where the blanks are

Open the `student/` folder. Look for `# Fill in here` markers and `cursor.execute('')` blanks. **All seven** blanks live in two files:

- `website/auth.py` — five blanks (login SELECT, session setup, register existence check, register INSERT, logout session clear).
- `website/views.py` — two blanks (add_paper INSERT, list_papers SELECT).

`website/models.py` provides the `get_connection()` helper that every route uses to talk to PostgreSQL. You don't need to edit it — but read it so you understand what `con = get_connection()` is doing.

### Step 3. Create the database in DBeaver and load `schema.sql`

You will use **DBeaver** (the same client you used in Labs 1–10) for all database work — *not* the command line.

1. Open **DBeaver** and connect to your local PostgreSQL server.
2. In the **Database Navigator** (left pane), expand your PostgreSQL connection → right-click the **Databases** folder → **Create New Database** (on some DBeaver versions: right-click the connection itself → **Create → Database…**).
   - **Database name:** `mis205_project_db`
   - Owner: leave as default (your own role)
   - Click **OK**.
3. **Important:** DBeaver may open a "Properties" tab showing a `CREATE DATABASE …` preview instead of executing immediately. If you see that tab, **click "Persist"** (or press `Ctrl+S` / `Cmd+S` → Persist) to actually run the CREATE.
4. Refresh the Database Navigator (`F5` or right-click → Refresh). You should now see `mis205_project_db` under the **Databases** folder.
5. **SQL Editor → New SQL Editor** (`Ctrl+]` on Windows/Linux, `Cmd+]` on macOS). In the editor toolbar, confirm the active connection target is `mis205_project_db`.
6. **File → Open File** → navigate to `Project/Part1/rpms/student/schema.sql` → Open.
7. Run the whole script: click the green ▶ "Execute SQL Script" button (or press `Alt+X` on Windows/Linux, `⌥X` / Option+X on macOS).
8. Refresh the database tree. Under `mis205_project_db → public → Tables` you should see **accounts** and **papers**. Right-click either → "View Data" to confirm rows.

### Step 4. Tell Flask how to connect to your database

Open `student/website/config.py` in your text editor. You will see the connection settings:

```python
class Config:
    host     = os.environ.get('PGHOST',     'localhost')
    port     = int(os.environ.get('PGPORT', '5432'))
    user     = os.environ.get('PGUSER',     'postgres')   # ← your PostgreSQL username
    password = os.environ.get('PGPASSWORD', '')           # ← your PostgreSQL password
    dbname   = os.environ.get('PGDATABASE', 'mis205_project_db')
```

**Edit the `user` and `password` lines** so they match what you use to connect from DBeaver. For example, if you log in to DBeaver as `postgres` with password `mypass123`, change the two lines to:

```python
    user     = os.environ.get('PGUSER',     'postgres')
    password = os.environ.get('PGPASSWORD', 'mypass123')
```

Leave the other three lines alone unless your PostgreSQL server runs on a non-default host/port or you named your database something else.

> **macOS users (Homebrew or Postgres.app):** the default PostgreSQL superuser is **your macOS username** (run `whoami` in Terminal to see it), *not* `postgres`. The password is usually empty. Set `user='your-username'` and leave `password=''`.

> **Reminder:** don't share or commit your real password — this file is for local use only.

### Step 5. Install Python dependencies and boot Flask

Open a terminal in the `student/` folder, then run the commands for your operating system:

**Windows (PowerShell or Command Prompt):**

```cmd
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
flask --app main run
```

**macOS / Linux / WSL:**

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
flask --app main run
```

You should see Flask report `Running on http://127.0.0.1:5000`. Open that URL in your browser and you'll be redirected to the login page at `http://127.0.0.1:5000/pythonlogin/`.

> **First-run troubleshooting**
> - `connection refused` / `could not connect to server` → PostgreSQL isn't running. Open DBeaver and confirm you can connect; start the PostgreSQL service if needed.
> - `FATAL: role "postgres" does not exist` → typical on macOS with Homebrew or Postgres.app. Change `user` in `config.py` to your macOS username (`whoami`) and clear the password.
> - `password authentication failed for user "..."` → the `password` in `config.py` doesn't match your PostgreSQL password (Windows EDB installs). Fix and re-run.
> - `database "mis205_project_db" does not exist` → you skipped Step 3.2 — create the database in DBeaver first (and don't forget to click **Persist**).
> - `psycopg2.ProgrammingError: can't execute an empty query` → expected! It means you reached an unfilled `cursor.execute('')` blank. Go to Step 6.

### Step 6. Fill in the blanks

With the app running, register at least three users, submit at least three papers, verify the list page shows them, and exercise login/logout.

You'll quickly hit empty-query errors — that's the signal to open the next file with a `# Fill in here` marker and write the SQL. Work through them in this order:

1. `auth.py` — three `cursor.execute('')` SQL blanks (login SELECT, register existence-check SELECT, register INSERT)
2. `auth.py` — two non-SQL blanks (session setup after a successful login; session clear on logout)
3. `views.py` — two `cursor.execute('')` SQL blanks (`add_paper` INSERT, `list_papers` SELECT). The `con = get_connection()` / `try` / `finally con.close()` scaffold is already provided — you only need to write the SQL and its parameter tuple.

After each edit, Flask auto-reloads. Just refresh the browser and try the action again.

### Step 7. (Bonus only) Demonstrate SQL injection

See bonus task above. Document the attack and the fix in your report.

---

## Submission

Submit a single zip containing:

1. Your filled-in `student/` folder (including `schema.sql` if you modified it).
2. A short PDF or markdown report (~1–2 pages) with:
   - Screenshots of: register, login, home with greeting, add paper, list papers (showing at least 3 papers).
   - Your final ER diagram for the schema you implemented.
   - **(If attempting bonus)** the SQL injection demonstration + reflection.
3. Your name, student ID, and class section in the report header.

Naming: `MIS205_Project_Part1_<student-id>_<name>.zip`

---

## What's provided

```
Project/Part1/
├── Project.md                     ← you are reading this
├── Project.docx                   ← legacy brief (kept for reference)
└── rpms/
    ├── working/                   ← instructor's reference solution
    │   └── (do not look at this until you've tried the blanks yourself)
    └── student/                   ← your starting point
        ├── main.py
        ├── requirements.txt
        ├── schema.sql
        └── website/
            ├── __init__.py
            ├── config.py          ← edit user + password to match DBeaver
            ├── models.py          ← provides get_connection(); no blanks
            ├── auth.py            ← 5 # Fill in here blanks
            ├── views.py           ← 2 # Fill in here blanks
            ├── static/            ← CSS, fonts, JS
            └── templates/
                ├── auth/          ← login, register, profile, auth_layout
                ├── home/          ← home, add_paper, list_papers, layout
                └── includes/      ← alert
```

---

## Notes

- The **working** folder is for instructor use. Use it only to verify your own solution *after* you've made a genuine attempt. Graders will compare your submission against the reference and will penalize verbatim copies.
- Passwords are stored in **plain text** for this assignment. This is intentional — it makes the SQL-injection bonus easier to reason about. In a real system you would always hash + salt passwords.
- If you have trouble booting Flask, check that PostgreSQL is running and the database name in `config.py` matches the one you created in DBeaver.

Good luck — and ask early in office hours if you get stuck.
