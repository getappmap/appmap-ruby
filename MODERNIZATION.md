# Modernization & Cleanup Report — `appmap-ruby`

Generated: 2026-03-23

---

## HIGH PRIORITY

### 1. Ruby Version Support Misalignment
- `lib/appmap/version.rb` lists `SUPPORTED_RUBY_VERSIONS = %w[2.5 2.6 2.7 3.0 3.1 3.2 3.3]`, but CI only tests 3.0–3.3 and the gemspec requires `>= 2.6.0`
- `spec/spec_helper.rb` and `spec/rails_spec_helper.rb` define `ruby_2?` / `testing_ruby_2?` helpers; `spec/around_recording_spec.rb` and `spec/remote_recording_spec.rb` conditionally skip tests based on them — dead code if Ruby 2.x is truly dropped
- `.standard.yml` specifies `ruby_version: 2.6` but CI tests 3.0+

**Fix:** Decide the real minimum (likely 3.0), update the gemspec, `SUPPORTED_RUBY_VERSIONS`, `.standard.yml`, and remove all `ruby_2?` branches.

---

### 2. Gemfile.lock Is Both Committed and Gitignored
- `.gitignore:15` lists `Gemfile.lock`, but the file is committed to the repo — contradictory and confusing
- For a gem (not an app), the convention is to *not* commit `Gemfile.lock` and keep it in `.gitignore`

**Fix:** Remove `Gemfile.lock` from version control (`git rm --cached Gemfile.lock`).

---

### 3. Security — `YAML.load_file`
- `lib/appmap/service/validator/config_validator.rb:50` uses `YAML.load_file` which can deserialize arbitrary Ruby objects

**Fix:** Replace with `YAML.safe_load_file` (Ruby 3.1+) or `YAML.load_file(..., permitted_classes: [])` for 3.0.

---

### 4. No Dependency Vulnerability Scanning in CI
- No `bundle audit` step — vulnerabilities in transitive dependencies would go undetected

**Fix:** Add `gem install bundler-audit && bundle audit check --update` as a CI step.

---

## MEDIUM PRIORITY

### 5. Gemspec Dependency Constraints Are Stale
- `bundler ">= 1.16"` (from ~2017; Bundler is now 2.6.9)
- `rake ">= 12.3.3"` (from 2018; should be `>= 13.0`)
- `minitest "~> 5.15"` (current: 5.27.0; should be `~> 5.27`)
- Runtime deps `activesupport`, `rack`, `method_source`, `reverse_markdown` have **no version constraints at all**

File: `appmap.gemspec`

---

### 6. `package.json` Issues
- Version is `1.0.0` but the gem is at `1.1.1`
- Repository URL still references old org `applandinc/appmap-ruby` instead of `getappmap/appmap-ruby` (`package.json:11`)
- `@appland/appmap` is pinned to `^3.18.3` but `yarn.lock` has `3.54.0`
- `semantic-release` and its plugins are installed in CI via `npm i -g` but not listed in `devDependencies` — no pinned versions

---

### 7. CI: PostgreSQL 14 Is Approaching EOL
- `.github/workflows/ci.yml:14` uses `postgres:14` — EOL is November 2026

**Fix:** Upgrade to `postgres:16` or `postgres:17`.

---

### 8. CI: Yarn Install Not Cached
- The `yarn install` step runs on every job with no caching

**Fix:** Add `cache: 'yarn'` to the `actions/setup-node@v4` step in the test job.

---

### 9. Rails Fixture Pinned Workarounds
- `spec/fixtures/rails6_users_app/Gemfile:16` pins `concurrent-ruby '1.3.4'` to work around an `ActiveSupport::LoggerThreadSafeLevel::Logger` error — should be tested and removed if fixed in current versions
- `spec/fixtures/rails7_users_app/Gemfile:5` pins `"~> 7.0.2", ">= 7.0.2.3"` — Rails 7.1.x exists and the constraint should be loosened

---

### 10. RuboCop Is Effectively Disabled
- `.rubocop.yml` has `DisabledByDefault: true` and excludes `lib/**`, `test/**`, `spec/**` — the entire codebase

**Fix:** Either configure it properly (or switch to StandardRB, which is already referenced by `.standard.yml`) and add linting to CI, or delete `.rubocop.yml`.

---

## LOW PRIORITY

### 11. Hash Rocket in Library Code
- `lib/appmap/open.rb:43` uses `:Port => 0` (old symbol-as-hash-key syntax)

**Fix:** Replace with `Port: 0`.

### 12. Unusual Lambda in `lib/appmap.rb:26`
- A large lambda is immediately `.call`'d at module load time, and a constant (`Initializer`) is defined inside it
- Constants should not be defined inside lambdas (scope leakage risk)

**Fix:** Extract to module level or a private method.

### 13. No `.rspec` Config File
- RSpec uses defaults throughout

**Fix:** Create `.rspec` with `--require spec_helper --color --order random`.

### 14. Documentation Gaps
- No `DEVELOPMENT.md` with local setup instructions (building the native extension, running fixture apps, etc.)
- No `SECURITY.md` for vulnerability disclosure
- `CONTRIBUTING.md` exists but is minimal — no commit message conventions (important given semantic-release)

---

## Summary Table

| Priority | Item | File(s) |
|---|---|---|
| High | Ruby version misalignment + dead `ruby_2?` code | `lib/appmap/version.rb`, `spec/spec_helper.rb`, `spec/rails_spec_helper.rb`, `.standard.yml` |
| High | Gemfile.lock committed + gitignored | `.gitignore`, `Gemfile.lock` |
| High | `YAML.load_file` → `safe_load_file` | `lib/appmap/service/validator/config_validator.rb:50` |
| High | No `bundle audit` in CI | `.github/workflows/ci.yml` |
| Medium | Stale gemspec constraints | `appmap.gemspec` |
| Medium | `package.json` version/URL/dep issues | `package.json` |
| Medium | Postgres 14 in CI | `.github/workflows/ci.yml:14` |
| Medium | Yarn not cached in CI | `.github/workflows/ci.yml` |
| Medium | Rails fixture workarounds | `spec/fixtures/rails6_users_app/Gemfile`, `spec/fixtures/rails7_users_app/Gemfile` |
| Medium | RuboCop effectively disabled | `.rubocop.yml` |
| Low | Hash rocket in `open.rb:43` | `lib/appmap/open.rb:43` |
| Low | Constant inside lambda | `lib/appmap.rb:26` |
| Low | No `.rspec` config | — |
| Low | Missing DEVELOPMENT/SECURITY docs | — |
