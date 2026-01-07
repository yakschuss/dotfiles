# Phone Desk Call Log Autosave - Implementation Plan

## Problem
MES staff lose call notes when navigating away from the call log form mid-call. Notes should persist automatically via localStorage.

## Solution: Client-Side Draft Management

### Core Architecture
- **localStorage-primary**: All draft saves go to localStorage (no server round-trip)
- **No cursor jumping**: localStorage operations don't trigger DOM re-renders
- **Clear feedback**: "Draft saved" indicator so users know their data is safe
- **Restore confirmation**: When restoring a draft, prompt user before applying

### Storage Key Pattern
```javascript
const STORAGE_KEY = `call_log_draft:${accountId}:${stafferId}`;
```

### Save Triggers

| Trigger | Timing |
|---------|--------|
| Text field input | Debounced 1000ms |
| Text area input (notes) | Debounced 2000ms |
| Select/radio change | Immediate |
| Blur (focus out) | Immediate |
| Visibility change (tab hidden) | Immediate |
| beforeunload | Immediate |

### Draft Lifecycle
1. **Load**: On form mount, check for existing draft
2. **Confirm**: If draft exists, show confirmation banner asking user if they want to restore
3. **Save**: On input/blur/visibility, save form state to localStorage
4. **Clear**: On successful form submission, remove draft

---

## Files to Create

### 1. `app/javascript/controllers/call_log_draft_controller.js`

New Stimulus controller with:
- `connect()`: Check for draft, show restore confirmation if exists
- `save()`: Serialize form data to localStorage (debounced)
- `restore()`: Apply draft data to form fields
- `clear()`: Remove draft from localStorage
- `onSubmitEnd()`: Clear draft on successful submission

Targets:
- `form`: The form element to serialize
- `status`: Status indicator element
- `restoreBanner`: Confirmation banner for restoring drafts

Values:
- `accountId`: String
- `stafferId`: String
- `textDebounce`: Number (default 1000)
- `textareaDebounce`: Number (default 2000)

### 2. `spec/javascript/controllers/call_log_draft_controller.spec.ts`

Test coverage for:
- Draft save on input (debounced)
- Draft restore with confirmation
- Draft clear on submission
- localStorage unavailable fallback
- Stale draft cleanup (>24h)

---

## Files to Modify

### 3. `app/components/staffers/phone_desk/call_log_form_component.html.erb`

**Add to form wrapper:**
```erb
<%= turbo_frame_tag :call_log_form do %>
  <div data-controller="call-log-draft"
       data-call-log-draft-account-id-value="<%= account.id %>"
       data-call-log-draft-staffer-id-value="<%= staffer.id %>">

    <!-- Restore confirmation banner (hidden by default) -->
    <div data-call-log-draft-target="restoreBanner" class="hidden">
      <!-- Banner with "Restore draft?" / "Discard" options -->
    </div>

    <%= form_with ... data: { call_log_draft_target: "form" } do |f| %>
      ...
      <!-- Status indicator near submit button -->
      <div data-call-log-draft-target="status" class="prism-text-mini text-gray-500"></div>

      <%= f.submit ... %>
    <% end %>
  </div>
<% end %>
```

**Add to text fields and text areas:**
```erb
<%= f.text_area :call_notes, data: { action: "input->call-log-draft#save blur->call-log-draft#save" } %>
```

### 4. `app/components/staffers/phone_desk/call_log_form_component.rb`

Add helper methods:
```ruby
def draft_controller_data
  {
    controller: "call-log-draft",
    call_log_draft_account_id_value: account.id,
    call_log_draft_staffer_id_value: staffer.id
  }
end
```

### 5. `app/components/staffers/phone_desk/call_logs/note_fields_component.html.erb`

Add data-action to text area:
```erb
<%= form.text_area :body,
    data: { action: "input->call-log-draft#save blur->call-log-draft#save" } %>
```

---

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| localStorage disabled | Log warning, continue without draft (graceful degradation) |
| Multiple tabs | Last-write-wins (single-user form) |
| Browser crash | Draft restored with confirmation on next visit |
| Validation errors | Draft preserved, form shows errors |
| Draft >24h old | Automatically discarded as stale |

---

## Implementation Order

1. Create `call_log_draft_controller.js` with core save/load/clear logic
2. Add draft controller bindings to `call_log_form_component.html.erb`
3. Add restore confirmation banner component
4. Add status indicator UI
5. Wire up `note_fields_component` text areas
6. Add helper methods to component Ruby classes
7. Write JavaScript tests
8. Manual QA: test typing flow, tab switching, restore confirmation
