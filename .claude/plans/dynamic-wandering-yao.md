# Chat Bug Fix Plan (TB-1786)

## Issues to Fix

### Bug 1: `member_id: nil` Error in ReminderChatLinksComponent
**Error:** `ActionController::UrlGenerationError - No route matches {... member_id: nil ...}`

**Root Cause:** The `member_participant` method in `AccessibleStafferChannel` (lines 103-109) returns `nil` when the SendbirdChatChannel has no member sendbird_user with `role: Chat::Role.member`.

**Code Path:**
1. `app/components/staffers/reminder_chat_links_component.html.erb:4` builds URL with `accessible_staffer_channel.member_participant`
2. `member_participant` returns nil → URL generation fails

**Fix:** Filter out channels without `member_participant` in the component.

### Bug 2: Chat Dropdown Shows "Brightline Spectator" Instead of Staffer Names
**Issue:** In the chat dropdown, spectator views show "Brightline Spectator (therapist) - view only" instead of the actual therapist's name (e.g., "Sade Abu").

**Root Cause:** In `TabsComponent.staffer_display_name` (lines 52-59):
- For spectator sendbird_users, it calls `channel.sendbird_chat_channel.staffer`
- The `staffer` method returns `staffers.first` which queries sendbird_users with `role: Chat::Role.staffer`
- If the channel only has spectator sendbird_users (no staffer role), `staffer` returns nil
- The fallback `channel.short_name` shows generic text instead of the therapist's name

**Fix:** Improve how we get the staffer name for spectator views by using the care case's clinical_roles or storing the staffer reference.

### Not a Code Bug: Care Team Sidebar
Harry appearing in the Care Team sidebar is **expected behavior** - Harry is Sade's supervisor, and the `SupervisorCareCaseSync` listener auto-adds supervisors when trainees are added to care cases. This is controlled by the `:supervisor_trainee_relationship` feature flag.

**Context for bugs:** When supervisors are auto-added to care cases, their chat channels may be created but the member sendbird_user setup may be incomplete, causing `member_participant` to return nil.

---

## Implementation Plan

### Step 1: Fix Bug 1 - Filter nil member_participant

**File:** `app/components/staffers/reminder_chat_links_component.rb`

Add filtering to exclude channels where `member_participant` is nil:

```ruby
def accessible_staffer_channels
  all_channels = Chat::AccessibleStafferChannel.for_all_members_scoped_to_staffer(account: account, staffer: staffer)

  channels = if reminder.care_case_id.present?
    care_case_channels = all_channels.for_care_case(reminder.care_case_id)
    care_case_channels.any? ? care_case_channels : all_channels
  else
    all_channels
  end

  # Filter out channels without member_participant to prevent URL generation errors
  channels.reject { |channel| channel.member_participant.nil? }
end
```

### Step 2: Fix Bug 2 - Show actual staffer names for spectator views

**File:** `app/components/staffers/care_cases/chats/tabs_component.rb`

The `staffer_display_name` method needs to find the staffer differently when `sendbird_chat_channel.staffer` is nil. Options:

**Option A (Recommended):** Get staffer from care case's clinical_roles based on chat_type
```ruby
def staffer_display_name(channel)
  if channel.sendbird_user.spectator?
    staffer = channel.sendbird_chat_channel.staffer || staffer_from_care_case(channel)
    staffer&.full_name || channel.short_name
  else
    channel.sendbird_user.nickname
  end
end

def staffer_from_care_case(channel)
  # Find staffer from clinical_roles based on channel's chat_type (therapist, prescriber, etc.)
  care_case.clinical_roles.joins(:staffer).find_by(
    staffers: { treatment_role: chat_type_to_treatment_role(channel.sendbird_chat_channel.chat_type) }
  )&.staffer
end
```

**Option B:** Improve `SendbirdChatChannel#staffer` to look up the staffer from clinical_roles as fallback.

### Step 3: Update tests

**File:** `spec/components/staffers/reminder_chat_links_component_spec.rb`
- Add test case for channel with nil `member_participant`

**File:** `spec/components/staffers/care_cases/chats/tabs_component_spec.rb`
- Add test case for spectator view showing actual staffer name

---

## Files to Modify

1. `app/components/staffers/reminder_chat_links_component.rb` - Filter nil member_participant
2. `app/components/staffers/care_cases/chats/tabs_component.rb` - Fix spectator name display
3. `spec/components/staffers/reminder_chat_links_component_spec.rb` - Add test
4. `spec/components/staffers/care_cases/chats/tabs_component_spec.rb` - Add test

---

## Testing

```bash
# Run existing specs
script/test spec/components/staffers/reminder_chat_links_component_spec.rb
script/test spec/components/staffers/care_cases/chats/tabs_component_spec.rb

# Run related request specs
script/test spec/requests/staffers/care_cases/chats_spec.rb
```
