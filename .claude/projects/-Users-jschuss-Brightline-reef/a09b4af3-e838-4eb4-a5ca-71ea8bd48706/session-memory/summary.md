
# Session Title
_A short and distinctive 5-10 word descriptive title for the session. Super info dense, no filler_

TB-1786 Chat View Cleanup - Kyle's PR Review Discussion

# Current State
_What is actively being worked on right now? Pending tasks not yet completed. Immediate next steps._

**BRANCH:** `ENGOPS-1-chat-refactor-spike` (off **main**, NOT off feature branch)

**STATUS:** 🔄 COMMITTING - Files staged, lint passed, ready to commit

**COMPLETED:**
- ✅ `git add` - All 10 files staged (9 modified + 1 new)
- ✅ `script/lint --staged` - Passed (RuboCop 0 offenses, ERB lint auto-corrected 4 formatting issues)

**NEXT STEP:** Re-add files after lint corrections, then commit WITHOUT 'by Claude Code' signature

**FILES STAGED:**
| File | Change |
|------|--------|
| `app/models/chat/staffer_channel_list.rb` | **NEW** - First-class collection |
| `app/models/chat/accessible_staffer_channel.rb` | `care_case_id` delegate, `path` method, returns `StafferChannelList` |
| `app/components/staffers/accounts/chat_links_component.html.erb` | Simplified link + ERB formatting |
| `app/components/staffers/accounts/account_links_component.rb` | `path: channel.path` |
| `app/components/staffers/accounts/members/member_tabs_component.rb` | `href: accessible_channel.path` |
| `app/components/staffers/coach_workflows/chat_channel_component.rb` | delegate `:path` |
| `app/components/staffers/coach_workflows/chat_channel_component.html.erb` | `link_to path` + ERB formatting |
| `app/components/staffers/reminder_chat_links_component.rb` | `.for_care_case(id)` |
| `app/views/staffers/.../update.turbo_stream.erb` | `.path` + ERB formatting |
| `spec/components/staffers/reminder_chat_links_component_spec.rb` | Updated mock + assertions |

**VERIFICATION COMPLETE:**
- ✅ 334 specs pass
- ✅ Playwright testing - all chat pages verified working
- ✅ CLAUDE.md compliance verified
- ✅ RuboCop: 0 offenses

# Task specification
_What did the user ask to build? Any design decisions or other explanatory context_

User asked to review PR comments from Kyle on PR #17935 "TB-1786: Replace chat tab navigation with dropdown selectors" on branch TB-1786-chat-view-cleanup. User takes Kyle's review very seriously and wants to discuss the feedback.

**Design Discussion Context:**
After addressing Kyle's material feedback (method rename), user explored Kyle's non-blocking suggestion about chat "missing an API-style abstraction." User asked about applying:
- **DDD principles** - Domain-Driven Design (aggregates, value objects, domain services, repositories)
- **POODR principles** - Sandi Metz's Practical Object-Oriented Design (SRP, depend on abstractions, tell don't ask, Law of Demeter)

**Decision Made:** User chose Option C (Full DDD treatment) on a **branch off main** (spike branch). User said "let's just nuke this shit - it's a spike" - willing to make breaking changes to see if design can be significantly improved and more readable.

**Evolved Understanding of the Problem:**
User's deeper insight: The issue isn't just Law of Demeter violations or missing collection methods - the **abstraction level itself is wrong**. Current code exposes Sendbird infrastructure details (sendbird_chat_channel, sendbird_user) when the business cares about domain concepts:
- "A conversation between a staffer and a member"
- "Who can see this conversation"
- "Is it unread"
- "What care case is it for"
- "Is it a therapist chat or coach chat"

**Potential Design Direction:**
`AccessibleStafferChannel` either evolves into or gets replaced by a proper domain object (e.g., `Chat::Conversation`) that hides Sendbird details and speaks the language of the business.

# Files and Functions
_What are the important files? In short, what do they contain and why are they relevant?_

**MEMBER-SIDE CHAT ABSTRACTIONS (THE PATTERN TO FOLLOW):**
- `app/models/chat/channel_list.rb` - Collection class for member chats:
  - `#ordered` - Returns `SendbirdChannelInfo::Serializer` objects sorted by `last_message_sent_at`
  - `#care_guide_channel`, `#coach_channel`, `#member_support_channel` - Named channel accessors
  - `#therapist_channels_for_care_case(care_case)`, `#prescriber_channels_for_care_case(care_case)` - Care case queries
  - Private `#channel_info_for(channel)` - Wraps raw channel in `SendbirdChannelInfo`
- `app/models/chat/sendbird_channel_info.rb` - Clean channel wrapper:
  - Wraps `(user, channel)` pair - same core concept as `AccessibleStafferChannel`
  - Exposes domain methods: `.chat_type`, `.unread?`, `.assigned_staffer`, `.assigned_backup_staffer`
  - `.current_participant` - Returns participant info for frontend
  - `.membership` - Finds `SendbirdChatChannelMembership` by channel + user
  - Delegates `.url`, `.name`, `.account`, `.chat_type` to channel
- `app/models/chat/member_participant.rb` - Handles member identity:
  - `#sendbird_user_in_channel(sendbird_chat_channel)` - Finds member's user in channel
  - `#membership_in_channel(sendbird_chat_channel)` - Finds membership record
  - `#all_sendbird_users` - Returns member's sendbird user(s)
- `app/controllers/members/accounts/chats_controller.rb` - Uses the clean pattern:
  - Line 73-74: `Chat::ChannelList.new(account:, member:)` then `.ordered`
  - Line 25: `Chat::SendbirdChannelInfo.new(user:, channel:)` for current channel

**STAFFER-SIDE (BEING REFACTORED):**
- `app/models/chat/accessible_staffer_channel.rb` - Value object, improving:
  - `.for(account:, member:, staffer:, prefer_unmuted:)` - **NOW RETURNS `StafferChannelList`**
  - `.for_all_members_scoped_to_staffer(account:, staffer:)` - **NOW RETURNS `StafferChannelList`**
  - Line 55: Now delegates `care_case_id` directly (Law of Demeter fix)
  - Line 75-76: Renamed `chat_path` → `path` with `secondary_tab: parameterized_name`
- `app/models/chat/staffer_channel_list.rb` - **NEW** First-Class Collection:
  - `include Enumerable` - supports `each`, `map`, `select`, `blank?`, `any?`, `first`
  - `delegate :length, :size, :empty?, to: :@channels` - Array-like size methods
  - `#for_care_case(care_case_id)` - returns filtered `StafferChannelList` (chainable)
- `app/components/staffers/coach_workflows/chat_channel_component.rb` - **UPDATED**:
  - Line 7: Changed delegate from `:chat_path` to `:path`
  - Full delegate list: `delegate :unread_messages?, :path, :staffer_responded_to_last_message?, :last_message_sent_at, :overdue?, :last_message_content, :starred?, :flagged_as_safety_risk?, to: :accessible_staffer_channel`
- `app/components/staffers/coach_workflows/chat_channel_component.html.erb` - **UPDATED**:
  - Line 2: Changed `<%= link_to chat_path, ...` to `<%= link_to path, ...`
- `app/components/staffers/accounts/members/member_tabs_component.rb`:
  - Line 29-44: `chat_tabs` iterates `AccessibleStafferChannel.for()` to build tabs
  - **UPDATED:** Now uses `accessible_channel.path` directly instead of manual path building

**PARTICIPANT HIERARCHY:**
- `app/models/chat/participant.rb` - Factory: creates participant type by `sendbird_user.role`
- `app/models/chat/staffer_participant.rb` - Staffer identity (can have multiple sendbird_users)
- `app/models/chat/member_participant.rb` - Member identity (simpler, one sendbird_user)
- `app/models/chat/spectator_participant.rb` - For spectator/muted role
- `app/models/chat/member_support_participant.rb` - For support role

**Call sites for `AccessibleStafferChannel.for()` on main (6 places):**
1. `member_tabs_component.rb:30`
2. `chat_links_component.html.erb:1`
3. `reminder_chat_links_component.rb:16`
4. `_account_chats.html.erb:9`
5. `care_cases/chats_controller.rb:29` and `:37`

# Workflow
_What bash commands are usually run and in what order? How to interpret their output if not obvious?_

# Errors & Corrections
_Errors encountered and how they were fixed. What did the user correct? What approaches failed and should not be tried again?_

- **User rejected "what" comments** - When I tried to rename `unique_staffers` and add a comment explaining what it does (`# Returns one channel per unique staffer...`), user rejected with "No 'what' comments". User prefers code to be self-documenting without explanatory comments about what the code does.
- **File not read error** - When trying to edit `update.turbo_stream.erb`, got error "File has not been read yet. Read it first before writing to it." - Must always read files before editing them.
- **Spec mock returns Array instead of StafferChannelList** - `reminder_chat_links_component_spec.rb` mocks `AccessibleStafferChannel.for_all_members_scoped_to_staffer` to return a plain Array. Now that the real method returns `StafferChannelList`, the mock needs to return `StafferChannelList.new([...])` so `for_care_case` method exists. **FIX APPLIED:** Updated spec to wrap array in `Chat::StafferChannelList.new(channels)` and changed instance_doubles to use `care_case_id:` directly instead of `sendbird_chat_channel:`.
- **StafferChannelList missing `length` method** - Specs using `.length` failed because `Enumerable` doesn't include `length`. **FIX:** Added `delegate :length, :size, :empty?, to: :@channels` to `StafferChannelList`.
- **Missed delegate in another component** - `chat_channel_component.rb` line 7 delegates `:chat_path` to `accessible_staffer_channel`, but we renamed the method to `path`. Broader spec run revealed 9 failures. **FIX NEEDED:** Change delegate from `:chat_path` to `:path`.

# Codebase and System Documentation
_What are the important system components? How do they work/fit together?_

**Chat Domain - Two Parallel Patterns (Member vs Staffer):**

**MEMBER SIDE (Clean Pattern - Use as Template):**
```
Member → Chat::ChannelList → Chat::SendbirdChannelInfo
                              (wraps user + channel)
```
- `ChannelList` is a collection class with query methods
- `SendbirdChannelInfo` wraps `(user, channel)` and exposes domain methods
- Sendbird internals are hidden from callers

**STAFFER SIDE (Needs Refactoring):**
```
Staffer → AccessibleStafferChannel.for(...) → Array of AccessibleStafferChannel
                                              (leaks sendbird_chat_channel, sendbird_user)
```
- No collection class - grouping/filtering scattered in components
- `AccessibleStafferChannel` exposes Sendbird internals publicly

**Key Difference:** Staffers can have multiple identities per channel (participant, spectator) while members have one.

**Participant Hierarchy (Factory Pattern):**
- `Chat::Participant.for(sendbird_user:)` - Factory routing by role
- `Chat::StafferParticipant` - Can have multiple sendbird_users
- `Chat::MemberParticipant` - Has one sendbird_user
- `Chat::SpectatorParticipant`, `Chat::MemberSupportParticipant` - Specialized roles

**Infrastructure Models (Sendbird):**
- `SendbirdChatChannel` - belongs_to `account`, optional `care_case`
- `SendbirdUser` - has `role` (staffer/member/spectator), `spectator?` method
- `SendbirdChatChannelMembership` - join table with `unread_message_count`, `starred`

**Design Issues (from user's insight):**
1. **Wrong abstraction level** - Sendbird concepts exposed when business cares about domain
2. **Law of Demeter** - `channel.sendbird_chat_channel.care_case_id`
3. **Feature Envy** - Components do grouping that belongs on domain objects
4. **Duplicated transformations** - Same filtering logic repeated
5. **Leaky abstraction** - `AccessibleStafferChannel` exposes internals

**Name Collision:** Cannot use "Conversation" - taken by `Chat::MemberSupportConversation`
**Domain Language:** Team calls it "chat" - keep naming simple

**Blast Radius:** 17 files touch `AccessibleStafferChannel` (10 app files + 7 specs)

**Actual Usage Pattern (from catalog):**
- Path building: `account_member_chat_path(account, member, channel.sendbird_chat_channel, sendbird_user_id: channel.sendbird_user, secondary_tab: channel.parameterized_name)` - appears in 4+ places
- The ONLY reason `.sendbird_chat_channel` and `.sendbird_user` are exposed is for path helpers
- **COMPLICATION:** `AccessibleStafferChannel` already HAS a `chat_path` method (line 73) but callers don't use it!
- Existing `chat_path` doesn't include `secondary_tab` param, and callers pass varying values for it
- Some callers also pass explicit `account`/`member` rather than deriving from channel internals

# Learnings
_What has worked well? What has not? What to avoid? Do not duplicate items from other sections_

- User prefers self-documenting code - avoid "what" comments. Make code clear via better method names.
- User prefers descriptive variable names - do NOT use single-letter variables like `c`. Use `channel` instead.
- Domain language: team calls it "chat" - not "conversation", "channel", "chat access".
- Members DO see a collection of chats - collection concept is NOT staffer-only.
- **CRITICAL:** Ground changes in actual usage patterns. Defend every change with a specific purpose.
- **CRITICAL:** User wants holistic redesign BUT grounded in actual usage - not speculative interface design. Catalog actual operations first, THEN design.
- When proposing design changes, cite which DDD/POODR principle each change addresses (Tell Don't Ask, Law of Demeter, First-Class Collection, etc.).
- **NAMING MATTERS:** User's naming concern was about `secondary_tab` and `parameterized_name` being opaque UI concepts leaking into domain. Solution: hide them entirely inside the `path` method.
- **UI SAFETY:** User emphasized "We need to make sure that screen doesn't break" - always verify existing callers won't break before refactoring.
- **GIVE CLEAR RECOMMENDATIONS:** When user asks "should we do X?" twice, they want a YES/NO with reasoning, not more options.
- **TESTING RIGOR:** Specs passing is NOT sufficient verification. User expects Playwright/manual UI testing to confirm changes actually work. When asked "Want me to commit this?" - don't assume specs are enough. Be upfront about what testing was NOT done.

# Key results
_If the user asked a specific output such as an answer to a question, a table, or other document, repeat the exact result here_

**FINAL SPIKE SUMMARY (presented to user):**

Changes made (9 modified, 1 new file, net -6 lines):

**New file: `app/models/chat/staffer_channel_list.rb`**
First-class collection with `#for_care_case(id)` method.

**`AccessibleStafferChannel` changes:**
1. Added `care_case_id` delegate - Law of Demeter fix
2. Renamed `chat_path` → `path` with `secondary_tab` included - Tell, Don't Ask
3. `.for` and `.for_all_members_scoped_to_staffer` now return `StafferChannelList` - First-class collection

**Callers updated to use new interface:**
- `chat_links_component.html.erb` - now uses `channel.path` (simplified from 6-line path builder)
- `account_links_component.rb` - now uses `channel.path`
- `member_tabs_component.rb` - now uses `channel.path`
- `chat_channel_component.rb/html.erb` - delegate changed to `path`
- `reminder_chat_links_component.rb` - now uses `all_channels.for_care_case(id)`
- `update.turbo_stream.erb` - uses `channel.path`

**Principles applied:**
- **Law of Demeter** - `channel.care_case_id` instead of `channel.sendbird_chat_channel.care_case_id`
- **Tell, Don't Ask** - `channel.path` instead of building the path externally
- **First-class Collection** - `StafferChannelList` with domain-specific `#for_care_case`

---

**Kyle's Review Summary**: "Only material thing is the potentially incorrect function name. Everything else is clarifying / non-blocking."

**5 Comments:**
1. **MATERIAL** `staffer_chat_selector_component.rb:76` - "Is this method name correct? Seems like this might be returning an array of channels?" → **FIXED**: Renamed to `one_channel_per_staffer`
2. `prism/select_controller.js:13` - "Had a bit of trouble following - what is this method doing in the context of the design, i.e. what icons / bolded text is affected here?"
3. `prism/select_controller.js:121` - "Curious about this change as well — what wasn't working before / what new feature was added?"
4. `staffer_chat_selector_component.rb:101` - Non-blocking: "definitely feels like chat is missing an API-style abstraction. Lots of 'math' here to slice and dice channels"
5. `member_tabs_component.rb:44` - Non-blocking: "curious if we still need non-Turbo navigation here. (Maybe we do in order to force Sendbird to load properly?)"

**Drafted Explanations for All 5 of Kyle's Comments:**

**1. MATERIAL - `unique_staffers` method name:** → **FIXED** by renaming to `one_channel_per_staffer`

**2. `initializeSelectedOption()` (line 13):**
Syncs the custom "fake" select UI with the underlying real `<select>` on page load. When page renders with pre-selected value:
- Shows checkmark icon (`.option-icon`) next to selected option
- Bolds selected option text (`.option-name` gets `font-semibold`)
Without this, navigating back to a chat page shows dropdown in default visual state even though a value is selected.

**3. `updateRealSelectValue` (line 121):**
- **Before:** Set `realSelect.value = displayText` directly - worked when value === display text
- **After:** Finds the `<option>` by matching display text, then uses its `.value` attribute
- **Why:** New chat selectors use options like `<option value="/path/to/chat">Staff Name</option>` where value ≠ display text. Old code would set value to "Staff Name" instead of URL path.

**4. Non-blocking - Chat API abstraction suggestion (`staffer_chat_selector_component.rb:101`):**
Kyle's right - there's duplicated channel filtering/grouping logic between `StafferChatSelectorComponent` and `TabsComponent`. Future refactor could extract to something like `Chat::ChannelCollection` or extend `Chat::AccessibleStafferChannel` with query methods like `.grouped_by_staffer`, `.for_care_case(id)`, etc.

**5. Non-blocking - Turbo navigation question (`member_tabs_component.rb:44`):**
Yes, still need `turbo: false` because Sendbird's JavaScript SDK needs a full page load to properly initialize the chat widget. Turbo navigation doesn't re-run the SDK initialization, causing the chat to break. The `turbo-mount` approach Alicia was exploring could potentially solve this by explicitly mounting/unmounting the Sendbird component on Turbo navigations.

---

## COMPLETED USAGE CATALOG (Grounding for Redesign)

**Class methods (how channels are obtained):**
| Method | Usage |
|--------|-------|
| `.for(account:, staffer:, member:, prefer_unmuted:)` | Get channels for a specific member - returns array |
| `.for_all_members_scoped_to_staffer(account:, staffer:)` | Get all channels across members - returns array |
| `.new(sendbird_chat_channel:, sendbird_user:)` | Direct instantiation |

**Instance methods actually called:**
| Method | Purpose |
|--------|---------|
| `.short_name` | Display name |
| `.parameterized_name` | URL param |
| `.unread_messages?` | Badge indicator |
| `.deactivated?` | Badge indicator |
| `.sendbird_chat_channel` | **LEAKY** - only used for path building |
| `.sendbird_user` | **LEAKY** - only used for path building |

**Law of Demeter violations:**
| Usage | Where |
|-------|-------|
| `channel.sendbird_chat_channel.care_case_id` | `reminder_chat_links_component.rb:19` |

**Collection operations done by callers:**
| Operation | Where |
|-----------|-------|
| `.select { \|c\| c.sendbird_chat_channel.care_case_id == id }` | Filter by care case |
| `.map`, `.each` | Iteration |
| `.blank?`, `.any?`, `.first` | Basic collection checks |

**THE LEAKS ARE CLEAR:**
1. `sendbird_chat_channel` / `sendbird_user` exposed just for path building
2. `care_case_id` requires reaching through

---

## PROPOSED MINIMAL DESIGN (DDD/POODR Grounded)

**Problem 1: Path building leaks internals**
- **Violation:** Tell, Don't Ask
- **Current:** `account_member_chat_path(account, member, channel.sendbird_chat_channel, sendbird_user_id: channel.sendbird_user, secondary_tab: channel.parameterized_name)`
- **Fix:** Add `#path` method - object builds its own URL
- **After:** `channel.path`

**Problem 2: care_case_id requires reaching through**
- **Violation:** Law of Demeter
- **Current:** `channel.sendbird_chat_channel.care_case_id`
- **Fix:** Delegate `care_case_id`
- **After:** `channel.care_case_id`

**Problem 3: Collection filtering scattered across callers**
- **Violation:** Feature Envy
- **Current:** `all_channels.select { |c| c.sendbird_chat_channel.care_case_id == reminder.care_case_id }`
- **Fix:** First-Class Collection with domain method
- **After:** `all_channels.for_care_case(reminder.care_case_id)`

**Summary:** 2 small, defensible changes. Each tied to a specific POODR principle.

**Path refactor reconsidered:** After user asked twice about path refactor, I analyzed more carefully:
- The leak (`sendbird_chat_channel`/`sendbird_user` exposed) exists ONLY for path building
- If we don't fix this, we haven't actually hidden Sendbird details - Tell, Don't Ask violation remains
- All callers use `parameterized_name` for `secondary_tab` - consistent pattern
- Risk is low - existing `chat_path` usage (1 place) works with default param

**Recommended additional change:**
```ruby
def chat_path(secondary_tab: parameterized_name)
  account_member_chat_path(account, member_participant, sendbird_chat_channel,
                           sendbird_user_id: sendbird_user.id,
                           secondary_tab: secondary_tab)
end
```

---

## PLAYWRIGHT VERIFICATION RESULTS

**All pages verified working after user logged in:**

| Page | Status | What was verified |
|------|--------|-------------------|
| Coach workflows chats (`/coach_workflows/chats`) | ✅ | Page loads, tabs render |
| Accounts list | ✅ | Chat links render with correct URLs including `secondary_tab` |
| Member chat tabs | ✅ | Tabs show "Coach chat (view only)", "MS chat (view only)" with proper paths |
| Chat page | ✅ | Sendbird widget initializes, correct page title, navigation works |
| Reminders page | ✅ | Page loads correctly (empty table, component renders without errors) |

**Key URL verified:** `/accounts/4558f8da-80ac-44d1-bc2e-bdf91470cd58/members/b10023e3-c9ce-499c-8fff-fcc9efcbbd1a/chats/14c3af9c-708f-4b32-a9c8-72840e6afc23?secondary_tab=coach-chat-view-only&sendbird_user_id=d0383e35-1fe1-4778-9734-1855383682d1`

**Confirms:** The refactored `path` method generates correct URLs with `secondary_tab` parameter, and the `StafferChannelList` collection iterates properly.

---

## FINAL CLAUDE.MD COMPLIANCE CHECK

| Rule | Status | Notes |
|------|--------|-------|
| **Code Style** | ✅ | snake_case methods (`for_care_case`), PascalCase class (`StafferChannelList`) |
| **Naming** | ✅ | Descriptive names: `channel` not `c`, `care_case_id` delegate |
| **Single Responsibility** | ✅ | `StafferChannelList` handles collection, `AccessibleStafferChannel` handles single channel |
| **Rails Conventions** | ✅ | File in `app/models/chat/`, follows module namespace |
| **Testing** | ✅ | No `let` usage, explicit setup, `instance_double` for type safety |
| **Security** | N/A | No user input, no SQL, no auth changes |
| **No unnecessary files** | ✅ | Only 1 new file (required for First-Class Collection pattern) |
| **Prefer editing** | ✅ | Modified 9 existing files, only created 1 new essential file |
| **RuboCop** | ✅ | 0 offenses on all 6 changed files |

**Principles Applied:**
- **Law of Demeter**: `channel.care_case_id` instead of `channel.sendbird_chat_channel.care_case_id`
- **Tell, Don't Ask**: `channel.path` instead of building path externally
- **First-Class Collection**: `StafferChannelList` with domain-specific `#for_care_case`

# Worklog
_Step by step, what was attempted, done? Very terse summary for each step_

**PR REVIEW (TB-1786-chat-view-cleanup):**
1. Fetched Kyle's 5 PR comments; material issue: renamed `unique_staffers` → `one_channel_per_staffer`
2. User rejected "what" comments; changed `c` → `channel` variables; committed 78d5aedbb5

**DDD/POODR SPIKE (ENGOPS-1-chat-refactor-spike off main):**
3. User chose full DDD refactor spike ("nuke this shit"); 17 files touch `AccessibleStafferChannel`
4. Key insight: member side has clean pattern (`Chat::ChannelList` + `SendbirdChannelInfo`) - use as template
5. Cataloged actual usage: Law of Demeter violations, leaky `sendbird_chat_channel`/`sendbird_user` for paths only

**IMPLEMENTATION:**
6. Added `care_case_id` delegate to `accessible_staffer_channel.rb:55`
7. Created `staffer_channel_list.rb` with `Enumerable`, `#for_care_case`, `delegate :length, :size, :empty?`
8. Updated `.for` and `.for_all_members_scoped_to_staffer` to return `StafferChannelList`
9. Renamed `chat_path` → `path` with `secondary_tab: parameterized_name` hidden internally
10. Updated all callers: `chat_links_component.html.erb`, `account_links_component.rb`, `member_tabs_component.rb`, `chat_channel_component.rb/html.erb`, `reminder_chat_links_component.rb`, `update.turbo_stream.erb`
11. Fixed spec: wrap mock in `StafferChannelList.new()`, use `care_case_id:` directly, change `.length` → `.count`
12. Fixed missed delegate: `chat_channel_component.rb` `:chat_path` → `:path`

**TESTING:**
13. Ran 334 specs - all pass
14. Playwright: User logged in manually → verified coach workflows chats, accounts list, member chat tabs, chat page with Sendbird widget, reminders page - all working
15. URL verified: `/accounts/.../members/.../chats/...?secondary_tab=coach-chat-view-only&sendbird_user_id=...`

**COMPLIANCE & COMMIT:**
16. Read `.rules/code_style_and_structure.md`, `key_conventions.md`, `naming_conventions.md` - verified compliance
17. RuboCop on all changed files → 0 offenses
18. User: "Add. script/lint --staged. Commit (without 'by Claude Code')"
19. `git add` all 10 files (only the adjusted ones)
20. `script/lint --staged` → RuboCop 0 offenses, ERB lint auto-corrected 4 formatting issues
21. **NEXT:** Re-add files after lint corrections, commit without Claude signature
