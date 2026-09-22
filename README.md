# Flying Crews — Job Listing & Application System

A practical Ruby on Rails implementation built for the Ruby on Rails Developer
assessment, modeled on **Flying Crews** (the aviation job board project from
the brief): recruiters post aviation jobs, candidates search/filter and apply,
and everyone gets a role-based dashboard.

Stack: **Rails 8.1**, **PostgreSQL 16**, **Docker Compose**, Minitest.

---

## 1. Project understanding, chosen feature, and design (Step 1 / Step 2)

### What I understand about Flying Crews

Flying Crews is a niche job board for the aviation industry — pilots, cabin
crew, ground staff, engineers — connecting airlines/aviation companies
(through their recruiters) with candidates. The core loop is: a recruiter
posts a job under their company, candidates search/filter and apply, and the
recruiter reviews applicants and moves them through a hiring pipeline.

### Why this project

Of the nine businesses listed, Flying Crews is the one the brief gives the
most concrete detail for (its own three sub-questions on architecture, DB
design, and search/filtering), so it's the best-specified target to build
against in the assessment's time window.

### What the real flying-crews.com actually is

I checked the live site (https://www.flying-crews.com/) to ground this build
in reality rather than guessing. It's currently a **Blogger-hosted content
site**, not a functioning job platform — its own footer says "Powered by
Blogger," and its disclaimer states: *"We exclusively operate as an aviation
job board and are not currently affiliated with any airlines... not currently
functioning as a hiring firm."* There's no signup, no login, no apply form,
no database — it's aviation news/articles/career content that links out to a
Linktree for actual opportunities. It targets the same five job categories
this app models: **Pilots, Cabin Crew/Air Hostesses, AMEs, MBAs, and Ground
Staff** — I pulled `Job#category` from free text into an enum matching that
exact taxonomy (`db/migrate/20260922092058_change_category_to_integer_on_jobs.rb`)
so the categories aren't invented.

In other words: everything in this repo (real auth, real CRUD, a real
apply/review pipeline, a real JSON API) is *more* than the live site
currently does — this is the product Flying Crews' own "job board" framing
implies but hasn't built yet, not a clone of existing functionality.

### Features built

- Recruiter self-signup (creates or joins a Company) and candidate signup
- Public job board: search/filter by title, location, category, job type,
  minimum salary
- Recruiter CRUD on their own job postings (ownership-checked)
- Candidate apply flow with a cover letter, one application per job
- Recruiter applicant pipeline: submitted → under_review → shortlisted /
  rejected / hired
- Role-based dashboards (candidate / recruiter / admin)
- JSON API: job search (`/api/v1/jobs`) and apply (`/api/v1/applications`)

### Database models

See [Database schema](#3-database-schema) below — `User`, `Company`,
`Recruiter`, `Candidate`, `Job`, `Application`.

### Improvements I'd suggest next

- **Full-text search** on job title/description (Postgres `tsvector` +
  `pg_search`, or Elasticsearch at real scale) instead of `LIKE` scans
- **Resume upload** via Active Storage instead of a plain `resume_url` string
- **Email notifications** (status changes, new applications) via Action
  Mailer + a background job (Solid Queue is already in the Gemfile)
- **Saved searches / job alerts** for candidates
- **Pagination** on the job index and dashboards (Kaminari/Pagy) — not
  needed at seed-data scale but required before this goes to production
- **Rate limiting** on signup/login and the public API (`rack-attack`)
- **FX-normalized salary filtering**: `Job` now has a real `currency` enum
  (inr/usd/eur/gbp/aed) instead of a hardcoded `₹`, so a Gulf-based posting
  in AED renders and validates correctly. The `min_salary` filter still
  compares raw numbers though (`app/models/job.rb`, `salary_at_least`
  scope) — fine while almost everything is INR, but a genuinely
  multi-currency board needs a normalized (e.g. USD-equivalent) column,
  updated from a daily FX rate job, to filter/sort across currencies
  correctly

---

## 2. Running it

Everything runs in Docker — no local Ruby/Postgres install needed.

```bash
docker compose up --build
```

This builds the dev image, starts Postgres, runs `bin/rails db:prepare`
(creates the database, migrates, and seeds it on first run), and starts the
Rails server on **http://localhost:3000**.

Seeded demo accounts (password `password123` for all):

| Role      | Email                        |
|-----------|-------------------------------|
| Recruiter | recruiter@indigo.example      |
| Candidate | candidate@example.com         |
| Admin     | admin@flyingcrews.com          |

Run the test suite:

```bash
docker compose exec web bin/rails test
```

Postgres is also reachable from the host at `localhost:5433` (mapped off the
default 5432 to avoid clashing with any local Postgres install) if you want
to inspect it with `psql` or a GUI client.

### Without Docker

If you'd rather run it bare-metal, point `DATABASE_HOST`/`DATABASE_PORT`/
`DATABASE_USERNAME`/`DATABASE_PASSWORD` at your own Postgres instance (see
`config/database.yml`) and run `bundle install && bin/rails db:prepare && bin/rails s`.

---

## 3. Database schema

```
users
  id, name, email (unique), password_digest, role (enum: candidate/recruiter/admin)

companies
  id, name (unique), description, website, location

recruiters
  id, user_id -> users, company_id -> companies, position
  (user must have role: recruiter)

candidates
  id, user_id -> users, headline, skills, experience_years, resume_url
  (user must have role: candidate)

jobs
  id, company_id -> companies, recruiter_id -> recruiters,
  title, description, location,
  category (enum: pilot/cabin_crew/ame/mba/ground_staff — flying-crews.com's taxonomy),
  job_type (enum: full_time/part_time/contract/seasonal),
  status (enum: draft/published/closed),
  currency (enum: inr/usd/eur/gbp/aed), salary_min, salary_max, posted_at
  indexes: location, category, status, title

applications
  id, job_id -> jobs, candidate_id -> candidates,
  status (enum: submitted/under_review/shortlisted/rejected/hired),
  cover_letter, applied_at
  unique index on (job_id, candidate_id) — one application per candidate per job
```

**Relationships:** `User has_one :recruiter` / `has_one :candidate` (a user
is exactly one or the other, enforced by role validation, not a DB
constraint — see improvements). `Company has_many :jobs, :recruiters`.
`Job belongs_to :company, :recruiter`, `has_many :applications`.
`Candidate has_many :applications, has_many :jobs, through: :applications`.

See `db/schema.rb` for the exact generated schema, and `db/migrate/` for the
individual migrations (one per model, matching the commit history below).

---

## 4. API

### `GET /api/v1/jobs`

Search/filter published jobs.

**Params** (all optional): `q` (title search), `location`, `category`,
`job_type` (`full_time`/`part_time`/`contract`/`seasonal`), `min_salary`

**Response** `200 OK`:
```json
[
  {
    "id": 1,
    "title": "First Officer - Airbus A320",
    "location": "Delhi, India",
    "job_type": "full_time",
    "category": "pilot",
    "salary_min": 1200000,
    "salary_max": 2000000,
    "status": "published",
    "posted_at": "2026-09-22T08:48:22.499Z",
    "company": { "id": 1, "name": "IndiGo Airlines", "location": "Gurugram, India" }
  }
]
```

### `GET /api/v1/jobs/:id`

Single job with full company details. `404` with `{"error":"Not found"}` if missing.

### `POST /api/v1/applications`

Apply to a job as the signed-in candidate (session cookie auth — log in via
`POST /login` first).

**Params:** `job_id` (required), `cover_letter`

**Responses:** `201 Created` with the application; `401` if not logged in;
`403` if the signed-in user isn't a candidate; `422` with
`{"errors": [...]}` on validation failure (e.g. duplicate application).

---

## 5. Short coding answers (Step 3)

**1. Ruby — find duplicate values in an array**
```ruby
def duplicates(array)
  array.tally.select { |_, count| count > 1 }.keys
end
```

**2. Rails — `User has_many :applications` / `Application belongs_to :user`**

In this domain applications belong to a `Candidate`, not directly to a
`User` (a recruiter user should never have applications), so the real
association is `Candidate has_many :applications` /
`Application belongs_to :candidate` — see `app/models/candidate.rb` and
`app/models/application.rb`. Generically, the pattern is:
```ruby
# db/migrate/..._create_applications.rb
add_reference :applications, :user, null: false, foreign_key: true

# app/models/user.rb
has_many :applications

# app/models/application.rb
belongs_to :user
```
`add_reference` creates the `user_id` column + FK + index in one step;
`has_many`/`belongs_to` then give you `user.applications` and
`application.user` for free.

**3. ActiveRecord — active records created in the last 30 days**
```ruby
Application.where(status: :submitted).where(created_at: 30.days.ago..)
# or, using the scope already defined on Application:
Application.recent  # app/models/application.rb: scope :recent, -> { where("created_at >= ?", 30.days.ago) }
```

**4. API — see [section 4](#4-api) above** (`GET /api/v1/jobs`,
`POST /api/v1/applications`).

**5. Debugging a slow (5–8s) Rails page**

First thing I'd check: the Rails log line for that request — it breaks down
total time into `ActiveRecord` vs `Views` vs everything else, which tells
you immediately whether it's a DB problem or a rendering problem.

Three likely causes and fixes:
- **N+1 queries** — e.g. looping over jobs and calling `job.company.name`
  fires one query per job. Fix: `includes(:company)` (I use this in
  `JobsController#index` and `DashboardsController#show` already). Bullet
  gem in development catches these automatically.
- **Missing index** on a column used in `WHERE`/`ORDER BY`/a join — check
  `EXPLAIN ANALYZE` on the slow query. Fix: add the index (this app indexes
  `jobs.location/category/status/title` and `applications.job_id` for
  exactly this reason).
- **Uncached, expensive view work** — e.g. re-rendering a large partial per
  row, or calling an external API inline during render. Fix: Russian-doll
  fragment caching (`<% cache job do %>`), or move the external call to a
  background job and render the cached result.

Beyond those three: check `rack-mini-profiler` for a request-level flame
graph, check the Puma/DB connection pool isn't saturated (thread starvation
looks like slow requests but is really queueing), and check APM
(Skylight/AppSignal/New Relic) in production to see if it's this endpoint
specifically or a global regression (e.g. a noisy-neighbor query on a shared
DB).

---

## 6. Top 5 Rails tech notes relevant to this build (2026)

1. **Rails 8's built-in Solid trio** (Solid Cache / Solid Queue / Solid
   Cable) — DB-backed cache, jobs, and websockets, removing Redis as a
   required dependency for small-to-mid apps. Already in this app's Gemfile.
2. **Propshaft** as the default asset pipeline (replacing Sprockets) — no
   asset compilation step needed for plain CSS/JS, which is why this app's
   asset setup is so thin.
3. **Kamal 2** for zero-Redis, container-based deploys straight from a
   Dockerfile — this app's production `Dockerfile` is Kamal-ready out of the
   box (`rails new` generates `config/deploy.yml` and `.kamal/` for it).
4. **Authentication generator** (`rails generate authentication`) shipped in
   Rails 8 as a lighter alternative to Devise — I hand-rolled auth here
   instead (`has_secure_password` + a session controller) since the
   requirements were simple enough not to need its full surface, but it's
   the first thing I'd reach for on a larger version of this app.
5. **Thruster** for HTTP/2, compression, and X-Sendfile in front of Puma
   without needing a separate nginx layer — also already wired into the
   generated `Dockerfile`.

---

## 7. Approach to working on an existing production codebase (Step 4)

1. **Read before touching** — run the test suite first, skim `schema.rb`
   and the models/associations before any controller, and check
   `CHANGELOG`/recent PRs for context I can't get from the code alone.
2. **Establish a safety net** — if test coverage is thin (very common on
   older Rails apps), add characterization tests around the area I'm about
   to change *before* changing it, the same way `test_destroying_a_company_destroys_its_jobs`
   in this repo caught a real cascade-delete bug before it ever reached
   the app's callers.
3. **Understand the database structure by tracing associations and
   indexes**, not just reading migrations in isolation — I look at what's
   actually indexed, what has `dependent:` callbacks, and where
   `NOT NULL`/uniqueness constraints live at the DB level vs. only in
   Ruby validations (the two can drift, as they did in this repo — I fixed
   an association-order bug that only a DB constraint caught).
4. **Performance**: start from the request log / APM, not guesses — fix
   N+1s and missing indexes first since they're the highest-ROI, lowest-risk
   changes on most Rails apps.
5. **Security**: keep `bundler-audit`/`brakeman` (already in this Gemfile)
   in CI, never trust client input past `strong_parameters`, and treat
   auth/authorization bugs (e.g. a recruiter editing another company's job)
   as P0 — this app's `authorize_owner!` before_action and its test
   (`"recruiter cannot update a job they do not own"`) are the pattern I'd
   apply everywhere.
6. **APIs**: version from day one (`/api/v1/...`, already done here),
   keep response shapes stable, and add contract tests so a controller
   change can't silently break a client.
7. **Testing**: small, fast, focused tests per layer (model validations,
   request-level controller tests, a thin system-test layer for critical
   flows) — mirrors this repo's `test/models` + `test/controllers`
   structure. Run the fast suite on every commit; push slower system specs
   to CI.
8. **Deployment**: containerize consistently across dev/CI/prod (this repo
   uses the same Postgres/Docker setup in all three) so "works on my
   machine" stops being a category of bug.
9. **Scalability**: don't over-engineer early — add indexes and caching
   when the data shows they're needed, but keep the seams (service objects,
   background jobs already wired via Solid Queue) that make it easy to
   extract a slow path later without a rewrite.
10. **Communicate in small PRs** — the commit history in this repo (one
    model/feature per commit, each with its own tests) is deliberately how
    I'd want to land changes on a shared codebase: reviewable, revertible,
    and bisectable.

---

## 8. Commit history

The git history is organized as small, feature-scoped commits, each
shipping its own tests (`git log --oneline` in this repo). Notably, the
`fix(models): prevent NOT NULL violation when destroying a company` commit
is a real TDD catch: the regression test was written and confirmed failing
against the original `dependent: :nullify` association *before* the fix was
written — not a hypothetical.

## 9. What's not included

Per the assessment's scope, this covers one full vertical slice (jobs +
applications) rather than the other eight listed projects. Screenshots/demo
link and the GitHub repository push are left for submission, per the
assessment's instructions.
