# Slot Recapture Infrastructure Audit

## Executive Summary

This audit examines existing infrastructure for three slot recapture scenarios, excluding `app/models/slot_recapture/*`. Key findings:

- **Wait list infrastructure exists** but is limited to intake appointment types
- **Discharge triggers automatic slot release** via `CareCaseDischargedEvent` → `DischargeRelease`
- **`AppointmentSlotReleasedEvent` has NO subscribers** - this is the key integration point for slot recapture
- **No "wants earlier appointment" concept exists** in the data model
- **Booking horizon is 31 days** (not 7 weeks)

---

## SCENARIO 1: Cancelled DE/Intake

### How DE Appointments Are Tracked

**Configuration:** `/Users/jschuss/Brightline/reef/config/models/root_appointment_types.yml`

DE/Intake appointments are identified by `for_intake: true` on the root appointment type:

| Root Type | Service Line | Required Capability |
|-----------|--------------|---------------------|
| `therapy_diagnostic_evaluation` | behavioral_therapy | therapy_intake |
| `psychological_testing_diagnostic_evaluation` | psychological_testing | psychological_testing |
| `psychiatry_diagnostic_evaluation` | medication_management | medication_management_intake |
| `therapy_initial_session` | behavioral_therapy (legacy) | therapy_intake |
| `coaching_goal_setting` | coaching | coaching_intake |

**Model predicates:**
- `Appointment#for_intake?` - delegates to appointment_type
- `Appointment#diagnostic_evaluation?` - dynamic predicate
- `AppointmentType.intake` scope - returns all intake types
- `RootAppointmentType.intake` scope - returns root intake types

### What Happens When DE Cancels

**Event:** `AppointmentCanceledEvent` (`app/events/appointment_canceled_event.rb`)
- Payload: `care_case`, `appointment`, `appointment_cancelation`

**Cancellation Model:** `AppointmentCancelation` (`app/models/appointment_cancelation.rb`)
```ruby
# Key fields:
canceled_by: [coach, member, provider, member_support, therapist, prescriber, system, care_guide]
canceled_at: datetime
late: boolean (within 24 hours)
late_cancelation_reason: [member_initiated_valid, member_initiated_invalid, provider_initiated_valid]
reason: String (CancelationReason YAML ref)
trigger_type/trigger_id: polymorphic trigger
```

**Notifications triggered for DE cancellations:**

| Listener | File | Action |
|----------|------|--------|
| `SchedulingFollowUpReminder` | `app/models/notification/appointment/scheduling_follow_up_reminder.rb` | Schedules 8-day follow-up reminder to assigned member_support_staffer |
| `IntakeAppointmentCanceledJourney` | `app/models/notification/appointment/intake_appointment_canceled_journey.rb` | Routes to Iterable: `intake_appointment_canceled` or `intake_appointment_provider_canceled` |
| `PostIntakeSurvey` | `app/models/notification/appointment/post_intake_survey.rb` | Cancels scheduled survey |
| `IncompletePaperwork` | `app/models/notification/appointment/incomplete_paperwork.rb` | Cancels paperwork reminders |

**Ops visibility:** Cancellation appears in:
- Care case event timeline
- Staffer dashboard (member_support notifications)
- Iterable workflows trigger member communication

### Wait List Infrastructure

**Core model:** `WaitList::Entry` (`app/models/wait_list/entry.rb`)

**Schema (`wait_list_entries`):**
```sql
id                      UUID PRIMARY KEY
care_case_id            UUID NOT NULL
appointment_type_id     STRING (optional - specific type)
root_appointment_type_id STRING NOT NULL
added_at                DATETIME
notes                   TEXT
clinic_ids              UUID[] (optional clinic filter)
priority                BOOLEAN DEFAULT FALSE
removed_at              DATETIME (NULL if active)
removed_by_id/type      POLYMORPHIC
removed_reason          ENUM (scheduled, clinical_exclusion_criteria_met,
                              found_another_provider, etc.)
```

**Wait list API eligibility** (`app/models/wait_list/api.rb`):
```ruby
def eligible?(appointment_type)
  # Currently ONLY therapy_initial_session is explicitly eligible
  appointment_type == AppointmentType.therapy_initial_session
end

def root_appointment_types
  # Supported root types:
  %i[therapy_initial_session therapy_session_legacy therapy_diagnostic_evaluation
     coaching_goal_setting coaching_session
     psychological_testing_diagnostic_evaluation psychological_testing
     psychological_testing_consultation
     psychiatry_diagnostic_evaluation psychiatry_session psychiatry_consultation]
end
```

**Limitation:** The `eligible?` method only returns true for `therapy_initial_session`. Other root types are defined but require explicit enablement.

### Matching Fields on Wait List

| Field | Storage | Scope Method |
|-------|---------|--------------|
| **State/Region** | Via `care_case.region_id` (not on entry) | `with_region(region_id)` joins care_case |
| **Appointment Type** | `root_appointment_type_id` (required), `appointment_type_id` (optional) | `with_root_appointment_type_id`, `with_appointment_type_id` |
| **Clinic** | `clinic_ids` UUID array | `with_clinic_id(clinic_id)` - uses array overlap |
| **Priority** | `priority` boolean | `with_priority(priority)` |

**Combined filter method:**
```ruby
# app/models/wait_list/entry.rb:73-83
scope :filter_by, ->(status:, region_id:, payer_id:, appointment_type_id:,
                     root_appointment_type_id:, clinic_id:, priority:) {
  send(status)
    .with_region(region_id)
    .with_payer_id(payer_id)
    .with_appointment_type_id(appointment_type_id)
    .with_root_appointment_type_id(root_appointment_type_id)
    .with_clinic_id(clinic_id)
    .with_priority(priority)
}
```

### LIFO/FIFO Ordering

**Default ordering:** `{added_at: :asc}` (FIFO - first added gets matched first)
- See: `app/controllers/staffers/wait_list/entries_controller.rb:122`
- Can be overridden by sort params in UI

---

## SCENARIO 2: Discharge / Slot Release

### Events That Fire on Discharge

**Primary Event:** `CareCaseDischargedEvent` (`app/events/care_case_discharged_event.rb`)
```ruby
class CareCaseDischargedEvent < ApplicationEvent
  reference :care_case
  reference :discharge
end
```

**Triggers:**
1. `Healthie::Processors::DischargeProcessor` - When discharge form is signed in Healthie
2. `CareCase::Autodeactivation::MassDischarge` - Auto-discharge for inactivity/provider departure

**Discharge Model** (`app/models/discharge.rb`):
```ruby
# Key fields:
care_case_id, staffer_id, service_line_id
discharge_reason, discharge_reason_id
discharge_reason_details (array)
primary_reason, secondary_reasons
last_session_on, premature, premature_reason
```

### AppointmentSlotReleasedEvent

**File:** `app/events/appointment_slot_released_event.rb`
```ruby
class AppointmentSlotReleasedEvent < ApplicationEvent
  reference :release, class_name: "Calendaring::AppointmentSlot::Release"
  reference :care_case
  reference :staffer
end
```

**Payload contains:**
- `release` - The `Calendaring::AppointmentSlot::Release` record
- `care_case` - The associated care case
- `staffer` - Provider who owned the released slot

**Triggered by:** `Calendaring::AppointmentSlot::NewRelease#create!` (line 39)

**CRITICAL: This event has NO SUBSCRIBERS** - This is the integration point for slot recapture notifications.

### Discharge → Slot Release Flow

**Service:** `Calendaring::AppointmentSlot::DischargeRelease` (`app/models/calendaring/appointment_slot/discharge_release.rb`)

```ruby
class DischargeRelease
  include EventSystem::Listener

  on(CareCaseDischargedEvent) do |event|
    new(discharge: event.discharge).release_slots!
  end

  def release_slots!
    Calendaring::AppointmentSlot::Reservation.active
      .where(staffer: discharge.staffer, care_case: discharge.care_case)
      .each do |slot|
        context = Calendaring::AppointmentSlot::ReleaseContext.new(
          requested_by: :system,
          reason: CancelationReason.member_discharged,
          notes: "Slot automatically released based on discharge",
          submitted_by: discharge.staffer,
          trigger: discharge
        )
        Calendaring::Api::AppointmentSlot.release(reservation: slot, release_context: context)
      end
  end
end
```

**Release implementation** (`app/models/calendaring/appointment_slot/new_release.rb`):
1. Creates `Release` record
2. Releases all future holds for the slot
3. Cancels all future confirmed appointments
4. Updates reservation with `released_at` timestamp
5. Broadcasts `AppointmentSlotReleasedEvent`

### Capacity Tracking

**Cached metrics:** `Calendaring::Availability::CachedOngoingCapacityMetric`
```ruby
# Table: calendaring_availability_cached_ongoing_capacity_metrics
# Columns:
available_slots   DECIMAL  # Slots not yet reserved
reserved_slots    DECIMAL  # Currently reserved/claimed
unavailable_slots DECIMAL  # Blocked/unavailable
staffer_id        UUID UNIQUE
```

**Updated by:** Periodic job that recalculates for active staffers with calendar + therapy_ongoing capability.

**No existing logic treats discharge as "capacity available" for waitlist notification.**

---

## SCENARIO 3: Ad-hoc / "Sooner Appointment" Seekers

### "Wants Earlier Appointment" Concept

**Finding: Does NOT exist in the data model.**

Searched for: `earlier_appointment`, `sooner`, `standby`, `flexible_timing`, `reschedule_preference` - none found.

**Related but insufficient:**
- `WaitList::Entry.priority` (boolean) - indicates urgency but not timing flexibility
- `WaitList::RemovedReason` includes `wait_too_long`, `preferred_times_not_available` - suggests preferences exist but not stored as flags

**Scheduling Preferences** (`app/models/care_case/scheduling_preferences.rb`):
- Stores: `visit_type` (clinic/virtual/either), `participants`, `allows_associates`
- NO timing flexibility flags

### Testing Appointments Scheduling

Testing appointments use the **same scheduling mechanisms** as therapy, with different configuration:

**Types:** (`config/models/root_appointment_types.yml`)
- `psychological_testing_diagnostic_evaluation` - intake, `for_intake: true`
- `psychological_testing` - main sessions (3-4 hour blocks)
- `psychological_testing_continued` - 1-4 hour continuation
- `psychological_testing_followup`

**Differences from therapy:**
- Longer duration options (60-240 minutes vs 30-90)
- Different service_line (`psychological_testing`)
- Different required_capability (`psychological_testing`)
- Different pricing categories

**Same scheduling API:** `Calendaring::Api::Appointment.book()` or `Calendaring::Api::AppointmentSlot.reserve()`

### Existing Standby/Flexible Timing

**None found.** No flags on:
- `WaitList::Entry`
- `Member`
- `CareCase`
- `Appointment`

---

## MATCHING CRITERIA (Erica's List)

### State/Region

| Model | Field | Notes |
|-------|-------|-------|
| `WaitList::Entry` | None directly | Joined via `care_case.region_id` |
| `CareCase` | `region_id` | YAML model reference |
| `Appointment` | None directly | Via care_case |

**Query:** `WaitList::Entry.joins(:care_case).where(care_cases: { region_id: region_id })`

### Credential/Capability

| Model | Field | Notes |
|-------|-------|-------|
| `RootAppointmentType` | `required_capability_id` | Maps to capability YAML |
| `WaitList::Entry` | `root_appointment_type_id` | Implicitly defines required capability |
| `Staffer` | `care_capabilities` association | What provider can do |

**Capability mapping:**
```yaml
therapy_diagnostic_evaluation → therapy_intake
psychiatry_diagnostic_evaluation → medication_management_intake
coaching_goal_setting → coaching_intake
psychological_testing_diagnostic_evaluation → psychological_testing
```

### Clinic Matching

| Model | Field | Notes |
|-------|-------|-------|
| `WaitList::Entry` | `clinic_ids` UUID[] | Optional filter, added June 2025 |
| `CareCase` | via `care_case_clinics` join | Member's associated clinics |

**Query:** `where("clinic_ids && ARRAY[?]::uuid[]", clinic_ids)` (array overlap)

### Appointment Type Matching

| Model | Field | Notes |
|-------|-------|-------|
| `WaitList::Entry` | `root_appointment_type_id` (required) | Always present |
| `WaitList::Entry` | `appointment_type_id` (optional) | Specific variant if needed |

**Logic:** Entries can match on root type (broader) or specific appointment type (narrower).

### LIFO/FIFO Order

**Default:** FIFO via `{added_at: :asc}` ordering
**Location:** `app/controllers/staffers/wait_list/entries_controller.rb:122`
**Note:** Not enforced in model - purely in controller query

---

## PROVIDER SLOTS BEHAVIOR

### Slot-Based vs Ad-hoc Bookings

**Two distinct models:**

| Model | Table | Purpose |
|-------|-------|---------|
| `Calendaring::AppointmentSlot::Reservation` | `calendaring_appointment_slot_reservations` | Recurring pattern (e.g., "every Tuesday 3pm") |
| `Appointment` | `appointments` | Single ad-hoc booking |

**Reservation schema:**
```ruby
start_time              # Day + time pattern
repeats_every_n_weeks   # 1 = weekly, 2 = biweekly
appointment_type_id
staffer_id, care_case_id, member_id
duration_minutes
released_at             # NULL = active, timestamp = released
```

**Detection query:**
```ruby
# Check if provider uses slots
has_active_slots = Calendaring::AppointmentSlot::Reservation
  .active
  .where(staffer_id: provider.id)
  .exists?
```

**Policy check:**
```ruby
# app/models/calendaring/api/appointment_slot.rb
def self.staffer_can_have_slots?(staffer)
  return false if staffer.contract_therapist?
  staffer.has_capability?(Capability.coaching, Capability.therapy)
end
```

### Booking Horizon Configuration

**Value:** 31 days (NOT 7 weeks)

**Location:** `app/models/onboarding/provider_choice/max_range_of_booking.rb`
```ruby
def self.booking_window_length(_appointment_type)
  31.days  # Uniform for all appointment types
end

def self.date_range(appointment_type)
  Time.zone.today..(Time.zone.today + booking_window_length(appointment_type))
end
```

**Used by:**
- `WaitList::Reminder` - wait list reminder logic
- `TherapistMatching::DownSelection` - comparing wait times
- `PhoneDesk::Scheduling::AvailabilityForm` - forward navigation limits

### Detecting Slot-Based vs Manual Booking

**Method 1:** Check active reservations
```ruby
uses_slots = Calendaring::AppointmentSlot::Reservation
  .active
  .where(staffer_id: provider.id)
  .exists?
```

**Method 2:** Capability check
```ruby
can_have_slots = !provider.contract_therapist? &&
  provider.has_capability?(Capability.coaching, Capability.therapy)
```

**Method 3:** Policy
```ruby
policy = Calendaring::AppointmentSlot::ReservationPolicy.new(staffer)
can_create_slots = policy.create?
```

---

## Key Files Reference

### Events
- `app/events/appointment_canceled_event.rb`
- `app/events/care_case_discharged_event.rb`
- `app/events/appointment_slot_released_event.rb` ← **No subscribers - integration point**
- `app/events/appointment_slot_reserved_event.rb`

### Models
- `app/models/appointment.rb`
- `app/models/appointment_cancelation.rb`
- `app/models/discharge.rb`
- `app/models/wait_list/entry.rb`
- `app/models/wait_list/api.rb`
- `app/models/wait_list/outreach_attempt.rb`
- `app/models/calendaring/appointment_slot/reservation.rb`
- `app/models/calendaring/appointment_slot/release.rb`
- `app/models/calendaring/appointment_slot/discharge_release.rb`
- `app/models/calendaring/appointment_slot/new_release.rb`
- `app/models/calendaring/availability/cached_ongoing_capacity_metric.rb`

### Configuration
- `config/models/root_appointment_types.yml`
- `config/models/appointment_types.yml`
- `config/models/capabilities.yml`
- `config/models/cancelation_reasons.yml`

### Controllers
- `app/controllers/staffers/wait_list/entries_controller.rb`
- `app/controllers/staffers/wait_list/entries/outreach_attempts_controller.rb`

### Notification Listeners
- `app/models/notification/appointment/scheduling_follow_up_reminder.rb`
- `app/models/notification/appointment/intake_appointment_canceled_journey.rb`
- `app/models/wait_list/appointment_scheduled.rb`

---

## Gap Analysis for Slot Recapture

| Need | Current State | Gap |
|------|---------------|-----|
| Notify waitlist on DE cancellation | `AppointmentCanceledEvent` fires but no waitlist notification | Need listener |
| Notify waitlist on discharge slot release | `AppointmentSlotReleasedEvent` has NO subscribers | Need listener |
| "Wants earlier appointment" flag | Does not exist | Need field on waitlist entry or care case |
| Match waitlist to released slots | Filter scopes exist but no matching service | Need matching service |
| Priority ordering (LIFO/FIFO) | Only in controller, not enforced | May need model-level enforcement |
| Testing appointment waitlist | Root types defined but not `eligible?` | Need to expand eligibility |
