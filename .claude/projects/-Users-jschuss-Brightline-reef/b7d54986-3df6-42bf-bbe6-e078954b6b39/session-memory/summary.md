
# Session Title
_A short and distinctive 5-10 word descriptive title for the session. Super info dense, no filler_

Fixing CI failures for calendaring API availability migration

# Current State
_What is actively being worked on right now? Pending tasks not yet completed. Immediate next steps._

Branch: `TB-1870-update-calendaring-availability-to-api-times` at local commit `ba5a4bcce2`

**READY TO PUSH** - Rebase completed successfully.

Local branch is now 1 commit ahead of origin:
- `ba5a4bcce2 Fix CI failures for calendaring API feature flag tests`

**IMMEDIATE NEXT STEP:**
- Push to remote: `git push origin TB-1870-update-calendaring-availability-to-api-times`

**Summary of all changes made:**

1. **`appointment_scheduling_requests_controller.rb`:**
   - `date` method (lines 25-36): Simplified - always passes kwargs to `first_available_date`
   - `available_appointments` method (line 56): Added `.slots` to legacy path

2. **`appointments_controller.rb`:**
   - `date` method (lines 63-75): Simplified - always passes kwargs to `first_available_date`
   - `available_appointments` method (line 103): Added `.slots` to legacy path

3. **`spec/features/members/care_cases/appointment_scheduling_request_spec.rb`:** Two contexts with explicit Flipper enable/disable, shared `setup_test_data` helper

4. **`spec/features/members/appointments/rescheduling_spec.rb`:** Shared examples for both scenarios, two flag contexts (4 total tests)

5. **`spec/requests/members/care_cases/appointment_scheduling_requests_spec.rb`:** Separate test blocks - new API stubs `.new`, legacy stubs `.from_availability_context`

# Task specification
_What did the user ask to build? Any design decisions or other explanatory context_

**Initial request:** User asked to fetch CI failures and review the issues. The branch `TB-1870-update-calendaring-availability-to-api-times` replaces `Calendaring::AvailableAppointments` with `Calendaring::Api::Availability.times` based on recent commit `82c11921dd`.

**Follow-up request (current work):** After root cause analysis, user chose option 3: "Add explicit feature flag enablement within the feature spec transactions" and also requested: "create a negative path where the flag is disabled"

**Design decisions:**
- Each test context should explicitly enable/disable the `change_calendaring_times_api` flag
- Create two contexts per test file: one with flag enabled (new API), one with flag disabled (old API)
- This approach tests both code paths and makes tests deterministic regardless of Flipper adapter configuration

# Files and Functions
_What are the important files? In short, what do they contain and why are they relevant?_

**CRITICAL - Flipper test configuration:**
- `spec/support/flipper.rb:5-11` - Different adapters by spec type: Feature specs use `ActiveRecord` adapter, others use `Memory` adapter. Both call `manager.enable_test_flags!`
- `lib/feature_flagging_system/manager.rb:25-35` - `enable_test_flags!` iterates `test_flags_to_enable` and calls `Flipper.enable(flag.name)`. Line 114: `test_flags` selects flags where `test_enabled?` is true

**CRITICAL - DatabaseCleaner configuration:**
- `spec/rails_helper.rb:69` - `DatabaseCleaner.clean_with(:truncation)` at suite start
- `spec/rails_helper.rb:87` - `DatabaseCleaner.strategy = :transaction` for non-JS specs
- `spec/rails_helper.rb:116` - `DatabaseCleaner.strategy = :truncation` for JS/feature specs
- `spec/rails_helper.rb:121` - `DatabaseCleaner.start` in `before(:each)`
- `spec/rails_helper.rb:126` - `DatabaseCleaner.clean` in `append_after(:each)`
- **POTENTIAL BUG:** Truncation strategy may delete Flipper flags stored in DB between tests

**Failing test files:**
- `spec/features/members/care_cases/appointment_scheduling_request_spec.rb:8-31` - Clicks "9:00am" slot then "Book appointment"
- `spec/features/members/appointments/rescheduling_spec.rb:41,106` - Expects "Book appointment" button (disabled then enabled)
- `spec/requests/members/care_cases/appointment_scheduling_requests_spec.rb:19-43` - Expects `AppointmentAvailabilityRequestReporter.new` and response includes "9:00am"

**Controllers with feature flag (BOTH FIXED):**
- `app/controllers/members/care_cases/appointment_scheduling_requests_controller.rb` - Flag check only in `available_appointments` method (line 39). `date` method (lines 25-36) simplified to always pass kwargs. Legacy path (line 56) now calls `.slots`
- `app/controllers/members/appointments_controller.rb` - Flag check only in `available_appointments` method (line 86). `date` method (lines 63-75) simplified to always pass kwargs. Legacy path (line 103) now calls `.slots`

**Availability API chain:**
- `app/models/calendaring/api/availability.rb:35-61` - `times` method gets appointment types, then for each: `CapableStaffers.new(...).all` → `AvailableTimes.new(...).all` → returns `Slot::Collection`
- `app/models/calendaring/available_times.rb` - Line 64 uses `AcuityCache.fetch_times(args)` wrapping `Acuity::Api::Availability::Time.for(**args)`. Line 94 returns empty if `staffers.empty?`. Line 19-24 `by_legacy_weekly_view` returns Hash `{date => [Calendaring::Slot, ...]}`
- `app/models/calendaring/capable_staffers.rb:30-58` - Filters staffers by capabilities. Line 54-56 filters to explicitly passed staffers

**Staffer factory:**
- `spec/factories/staffers.rb` - `:sade` trait (427-437) uses `:therapist`. `:therapist` (206-225) creates `therapy`, `therapy_ongoing`, and `therapy_intake` capabilities. Rails runner confirmed: `[[:therapy, :us], [:therapy_intake, :us], [:therapy_ongoing, :us]]`

**Component/View chain:**
- `app/views/members/care_cases/appointment_scheduling_requests/show.html.erb:15-21` - Renders `AppointmentSchedulingRequestComponent` with `availability_data: @availability_data`
- `app/components/members/appointments/timeslots/appointment_scheduling_request_component.rb:11` - Sets `@appointment_slots = availability_data.slots`
- `app/components/members/appointments/timeslots/timeslots_component.html.erb:31,34` - `if appointment_slots.any?` then `appointment_slots.first(3).each do |day, slots|`
- `app/components/members/appointments/timeslots/appointment_slot_component.html.erb:14` - Time display: `I18n.l(appointment_slot.datetime.in_time_zone(member.timezone), format: :just_time_with_period)` = "9:00am"

**CRITICAL TEMPLATE DIFFERENCE (main vs branch) - FIXED VIA CONTROLLER:**
- **MAIN:** `timeslots_component.html.erb:34` = `appointment_slots.slots.first(3).each do |day, slots|`
- **BRANCH:** `timeslots_component.html.erb:34` = `appointment_slots.first(3).each do |day, slots|`
- The commit removed the `.slots` call, assuming `appointment_slots` IS the Hash (new API behavior)
- **FIX:** Both controllers' legacy paths now call `.slots` on `AvailableAppointments` before passing to Data struct

**Data struct:**
- `app/models/calendaring/appointment/availability/data.rb:5` - `class Availability::Data < Struct.new(:date, :slots, keyword_init: true)`
- Simple Struct that passes through whatever is set as `slots:`

**AvailableAppointments class:**
- `app/models/calendaring/available_appointments.rb:20-28` - Has `slots` method returning Hash `{date => [Calendaring::Slot, ...]}`
- `app/models/calendaring/available_appointments.rb:31-36` - Has `any?` and `each` methods that delegate to `slots`
- Does NOT have `first` method - that's why controllers need to call `.slots` explicitly

**Test doubles:**
- `spec/support/test_doubles/acuity.rb:91-121` - `expect_acuity_available_dates` stubs `Date.for`, `expect_acuity_availability` stubs `Time.for`. Uses `anything` for most args, returns times with passed calendar_ids
- **CRITICAL:** Both use `expect(...).to receive(:for)` which expects EXACTLY ONE call. If `filtered_appointment_types` returns multiple types, stub won't match second call

**Component specs:**
- `spec/components/members/appointments/timeslots/appointment_scheduling_request_component_spec.rb:38-81` - "with available slots" test passes Hash directly as `slots:` (not object with `.slots` method). Expects times "10:00am", "1:00pm", "3:00pm"

**Cache:**
- `config/environments/test.rb:34` - `cache_store = :null_store` - disabled in tests

# Workflow
_What bash commands are usually run and in what order? How to interpret their output if not obvious?_

- `script/fetch_failing_ci_tests --details` - Fetches failing tests from CI with full error details
- `DISABLE_SPRING=1 bundle exec rspec spec/path/to_spec.rb:LINE --format documentation` - Run specific test locally with documentation output
- `git log --oneline -5` - View recent commits on current branch
- `git diff main...HEAD --name-only` - List files changed vs main branch

# Errors & Corrections
_Errors encountered and how they were fixed. What did the user correct? What approaches failed and should not be tried again?_

**Local ChromeDriver version mismatch:**
- Local Chrome: version 143.0.7499.41
- Local ChromeDriver: version 140.0.7339.82
- Feature specs fail with `Selenium::WebDriver::Error::SessionNotCreatedError: session not created: This version of ChromeDriver only supports Chrome version 140`
- This is a local environment issue, not the same error as CI ("Unable to find link or button 9:00am")

**WRONG hypothesis about missing capability:**
- Initially suspected staffer missing `therapy_intake` capability caused empty staffer list from `CapableStaffers`
- Spent significant time tracing `CapableStaffers` filtering logic assuming capability was missing
- **DISPROVEN:** Rails runner test showed staffer HAS all capabilities: `[[:therapy, :us], [:therapy_intake, :us], [:therapy_ongoing, :us]]`
- Missed line 222 in `:therapist` trait: `FactoryBot.create(:care_capability, :therapy_intake, staffer: therapist, region: region) if evaluator.available_for_intakes`
- **Lesson:** Always run actual tests before deep code analysis. Request spec passed locally immediately, could have saved investigation time.

**WRONG hypothesis about cache interference:**
- Suspected `Calendaring::AcuityCache.fetch_times` at `available_times.rb:64` might bypass stubs if cache warm
- **DISPROVEN:** `config/environments/test.rb:34` sets `config.cache_store = :null_store`
- null_store means cache is effectively disabled - every `Rails.cache.fetch` call executes its block
- Cache cannot interfere with RSpec stubs in test environment

**FIXED: Legacy API path first_available_date signature mismatch**
- After adding `Flipper.disable(:change_calendaring_times_api)` context to test legacy code path
- Legacy path in controller was calling `first_available_date` without required kwargs
- **FIX APPLIED:** Removed unnecessary flag check in `date` method - now always passes kwargs
- Controller `date` method simplified from lines 25-40 to lines 25-36 (removed if/else for flag)

**FIXED: Mock expectation mismatch for AppointmentAvailabilityRequestReporter**
- New API path calls `.new` directly via `availability_request_reporter` method (line 64)
- Legacy API path calls `.from_availability_context(availability_context)` via `legacy_availability_request_reporter` method (line 88)
- **FIX APPLIED:** Updated spec to stub `.from_availability_context` with `an_instance_of(Calendaring::AvailabilityContext)` for legacy path

**DISCOVERED & FIXED: Template was changed on branch - removed `.slots` call**
- `timeslots_component.html.erb:34` on **MAIN**: `appointment_slots.slots.first(3).each do |day, slots|`
- `timeslots_component.html.erb:34` on **BRANCH**: `appointment_slots.first(3).each do |day, slots|`
- The `.slots` call was REMOVED on this branch as part of the API migration
- New API returns Hash directly via `by_legacy_weekly_view` - can call `.first(3)` directly
- Legacy API returns `Calendaring::AvailableAppointments` object - needs `.slots` to get Hash
- **FIX APPLIED to BOTH controllers:**
  - `appointment_scheduling_requests_controller.rb:56`: `AvailableAppointments.new(...).slots`
  - `appointments_controller.rb:103`: `AvailableAppointments.new(...).slots`
- **ALSO FIXED both controllers' `date` methods** - removed flag check, always pass kwargs to `first_available_date`

# Codebase and System Documentation
_What are the important system components? How do they work/fit together?_

**CRITICAL: Flipper + DatabaseCleaner Interaction (LIKELY ROOT CAUSE)**
- Feature specs use `Flipper::Adapters::ActiveRecord` - flags stored in `flipper_features`/`flipper_gates` tables
- Other specs use `Flipper::Adapters::Memory` - flags in memory, unaffected by DB operations
- Feature specs use `DatabaseCleaner.strategy = :truncation` which may WIPE Flipper tables!
- **Hypothesis:** Flipper `before` hook enables flags, then DatabaseCleaner truncates tables, flag is gone when code checks it
- Hook execution order matters: RSpec `before` hooks run in definition order, `append_after` runs after standard `after`
- **Fix options:** (1) Exclude flipper tables from truncation, (2) Use Memory adapter for feature specs, (3) Re-enable flags after DatabaseCleaner.start

**Availability API Architecture:**
- OLD: `Calendaring::AvailableAppointments` - wraps Acuity API directly, returns object with `.slots` method
- NEW: `Calendaring::Api::Availability.times` - filters by capability first, returns Hash via `by_legacy_weekly_view`

**New API Call Chain:**
```
Calendaring::Api::Availability.times(...)
  -> root_appointment_type.filtered_appointment_types(**filters.for_appointment_types)
     (filters.for_appointment_types includes id: appointment_type.id to filter to ONE type)
  -> For EACH appointment_type:
     -> CapableStaffers.new(appointment_type:, **filters.for_staffers).all
        (If staffers empty → no Acuity calls → empty Hash)
     -> AvailableTimes.new(...).all
        -> AcuityCache.fetch_times(args) { Acuity::Api::Availability::Time.for(**args) }
  -> Returns Slot::Collection
  -> .by_legacy_weekly_view transforms to Hash: {date => [Calendaring::Slot, ...]}
```

**Root appointment type filtering (line app/models/root_appointment_type.rb:60-65):**
- `filtered_appointment_types(**filters)` - filters appointment_types by provided attributes
- `AvailabilityFilters.for_appointment_types` returns `{mode:, duration:, communication_assistance:, id: appointment_type&.id}`
- Passing `id:` should filter to exactly ONE appointment type, but need to verify in failing scenario

**CapableStaffers filtering:**
```
Staffer.active.with_calendar.with_clinic(clinics)
  .with_care_capabilities_in_region(capabilities:, region:)
  .where(id: staffers.map(&:id))  # if staffers provided
```

**Capability requirements (VERIFIED WORKING):**
- `therapy_initial_session` requires `therapy_intake` - staffer HAS this
- `therapy_session_legacy` requires `therapy_ongoing` - staffer HAS this
- Rails runner confirmed `CapableStaffers.all` returns the staffer correctly

**Feature Flags:**
- `change_calendaring_times_api` - gates old/new API (test_enabled: true, dev_enabled: true)
- `use_reef_templates` - template-based availability (test_enabled: false)

# Learnings
_What has worked well? What has not? What to avoid? Do not duplicate items from other sections_

- **RUN TESTS LOCALLY FIRST** before deep code analysis - request spec passed immediately, could have saved hours
- **CHECK TEST FRAMEWORK CONFIG EARLY** - `spec/support/flipper.rb` revealed critical difference: feature specs use ActiveRecord adapter while others use Memory adapter
- When tests fail with "unable to find element", trace data flow to see if data exists (not just rendering issue)
- Factory traits can have conditional logic - always trace FULL trait including transient attributes (e.g., `available_for_intakes { true }`)
- Use `RAILS_ENV=test bundle exec rails runner` to quickly verify test data and query behavior
- **Request spec vs Feature spec divergence** is a KEY signal - investigate test framework configuration, not just business logic
- Feature flags with `test_enabled: true` require correct adapter initialization - different adapters may behave differently
- Check `config/environments/test.rb` for cache config before investigating cache issues - `:null_store` means cache disabled
- RSpec `expect(...).to receive` expects ONE call by default - use `.at_least(:once)` if code might call multiple times
- Simple Struct pass-through objects rarely cause bugs - focus on what's passed IN
- When 4+ hypotheses fail, step back and look at test framework level (adapters, before hooks, metadata)
- **CI vs Local divergence** often indicates: test isolation issues, database cleaner config, parallel worker isolation, or framework-level hooks
- **Flipper ActiveRecord adapter** stores flags in database - may be affected by database cleaner strategies or transaction rollbacks
- **DatabaseCleaner + Flipper interaction** is a known gotcha - truncation strategy can wipe flipper tables between tests
- Always check `rails_helper.rb` for DatabaseCleaner configuration when feature specs behave differently
- RSpec hook ordering: `before` hooks run in definition order, but support files load in alphabetical order - `flipper.rb` loads before most hooks
- **Verify flag loading with Rails runner** before assuming flag issues: `FeatureFlaggingSystem::FlagList.new.by_name(:flag_name)` returns flag object if loaded
- When all local tests pass but CI fails, investigate CI-specific configurations next (parallel workers, database isolation, environment variables)

# Key results
_If the user asked a specific output such as an answer to a question, a table, or other document, repeat the exact result here_

**Request spec test run output (ALL 6 TESTS PASSING):**
```
Randomized with seed 25711

Members::CareCases::AppointmentSchedulingRequestsController
  GET /care_cases/:care_case_id/appointment_scheduling_requests/:id
    with new calendaring API (feature flag enabled)
      when request completed
        redirects to connect dashboard page
      success
        shows slots
      failure
        shows error page
    with legacy calendaring API (feature flag disabled)
      failure
        shows error page
      success
        shows slots
      when request completed
        redirects to connect dashboard page

Finished in 10.01 seconds (files took 9.16 seconds to load)
6 examples, 0 failures
```

**Commit created (after rebase):**
```
ba5a4bcce2 Fix CI failures for calendaring API feature flag tests
53d4809251 Merge branch 'main' into TB-1870-update-calendaring-availability-to-api-times
e6a05b014f Add feature flag for calendaring API
82c11921dd Replace Calendaring::AvailableAppointments with Calendaring::Api::Availability.times
```

**Complete fix summary:**
1. **Flipper isolation:** All 3 spec files now have explicit `Flipper.enable/disable(:change_calendaring_times_api)` contexts
2. **Controller `date` methods:** Both controllers simplified - removed flag check, always pass kwargs to `first_available_date`
3. **Request spec stubs:** New API uses `.new` stub, legacy API uses `.from_availability_context` stub
4. **Controller `available_appointments` methods:** Both controllers' legacy paths now call `.slots` on `AvailableAppointments`

**Root cause analysis:**
- Feature specs use `Flipper::Adapters::ActiveRecord` + `DatabaseCleaner.strategy = :truncation` - may wipe flags
- Template was changed on branch to remove `.slots` call, expecting Hash directly from all code paths
- Legacy path returned `AvailableAppointments` object (not Hash) causing `undefined method 'first'` error
- Fix: Controllers normalize output by calling `.slots` on legacy `AvailableAppointments` objects

# Worklog
_Step by step, what was attempted, done? Very terse summary for each step_

1-34. Initial investigation: Fetched CI failures, read test files, traced availability API chain, suspected capability mismatch (WRONG)
35-40. Request spec passed locally, Rails runner confirmed staffer has capabilities - disproved capability hypothesis
41-76. Checked cache/timezone/time format, traced data flow, **BREAKTHROUGH:** Found `spec/support/flipper.rb` - different adapters for feature vs request specs
77-100. Identified root cause: DatabaseCleaner truncation + Flipper ActiveRecord adapter interaction
101-103. User chose explicit flag enablement approach with negative test paths

**SESSION CONTINUATION (completed):**
104. Created TodoWrite with 4 tasks for tracking progress
105-106. Read and rewrote `appointment_scheduling_request_spec.rb` with explicit Flipper enable/disable contexts, extracted `setup_test_data` helper
107-108. Read and rewrote `rescheduling_spec.rb` with shared_examples and two flag contexts (4 total scenarios)
109-110. Read and rewrote request spec with separate contexts for new and legacy API paths
111-112. Ran request spec - new API passed, legacy failed with `ArgumentError: missing keywords: :appointment_type, :staffers`
113-114. **FIX 1:** Read controller, found legacy `date` method calling `first_available_date` without kwargs - edited to remove flag check, always pass kwargs
115-116. Re-ran - new error: mock mismatch for `AppointmentAvailabilityRequestReporter`
117-118. **FIX 2:** Rewrote request spec - new API stubs `.new`, legacy stubs `.from_availability_context` with `an_instance_of(Calendaring::AvailabilityContext)`
119-120. Re-ran - new error: `undefined method 'first' for Calendaring::AvailableAppointments`
121-123. Read component/template, found `.slots` was removed from template on branch (expects Hash directly)
124-125. **FIX 3:** Edited `appointment_scheduling_requests_controller.rb:56` - added `.slots` to legacy `AvailableAppointments` return
126-127. Read `appointments_controller.rb` - found same issues in `date` method (lines 63-79) and `available_appointments` method (lines 98-108)
128. **FIX 4:** Edited `appointments_controller.rb` `date` method - removed flag check, always pass kwargs
129. **FIX 5:** Edited `appointments_controller.rb:103` - added `.slots` to legacy path
130. Re-ran request spec - **ALL 6 TESTS PASS** (3 new API + 3 legacy API)
131. Verified Ruby syntax on all 5 modified files - all OK
132. Updated TodoWrite - all 4 tasks completed
133. User requested: stage, run lint, commit without signing
134. Staged all 5 files with `git add`
135. Ran `script/lint --staged` - PASSED: "5 files inspected, no offenses detected"
136. Committed with `git commit --no-gpg-sign` - commit `c1d804900d`
137. Verified commit with `git log --oneline -3` - shows new commit on top of branch
138. User reported can't push, asked to "clean the origin/local diff"
139. Ran `git status` + `git log origin/TB-1870...HEAD` - showed 1 local commit ahead
140. Ran `git fetch origin` - discovered origin has 30+ new commits including merge from main (`53d4809251`)
141. Origin branch moved from `e6a05b014f` to `53d4809251` - need to rebase local commit onto updated origin
142. Ran `git rebase origin/TB-1870-update-calendaring-availability-to-api-times` - **SUCCESS: "Rebasing (1/1) Successfully rebased"**
143. Verified with `git log origin/TB-1870...HEAD --oneline` - shows `ba5a4bcce2` (rebased commit) 1 ahead of origin
144. Branch is now ready to push
