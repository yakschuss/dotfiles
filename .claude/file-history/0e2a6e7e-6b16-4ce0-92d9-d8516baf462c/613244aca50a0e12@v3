# Fix: SMS Reminders Not Updated When Member Reschedules Appointment

## Problem Summary

When a member reschedules an appointment via their online account, pending SMS reminders for the original appointment time are not being cancelled. The member receives a reminder at the original appointment time instead of the new time.

**Example from bug report:**
- Original appointment: 11/21 at 6pm
- Rescheduled to: 11/24 at 4pm
- Member received reminder at 5:45pm on 11/21 (15 min before original time)

## Root Cause

The codebase has two notification systems controlled by the `configurable_appointment_notifications` feature flag:

1. **Legacy System** (`LegacySchedulingNotification`) - schedules 15-minute, 36-hour SMS reminders (pure Ruby, no YAML)
2. **New Configurable System** (`SchedulingNotification`) - schedules 6-hour, 24-hour, 72-hour SMS reminders (reads from YAML)

**The bug:** The new system (currently active in production) only cancels notification types defined in its YAML config. Legacy notification types created before the flag was enabled are orphaned.

**Confirmed via production query:**
```
appointment_reminder_15_minutes => 14   ← Legacy type, NOT in YAML
appointment_reminder_36_hours_sms => 14 ← Legacy type, NOT in YAML
```

**Code path:**
1. `Calendaring::MemberReschedulation.save!` → publishes `AppointmentRescheduledEvent`
2. `SchedulingNotification` handler receives event → calls `cancel_existing_notifications!`
3. `cancel_existing_notifications!` uses `NotificationConfig.all_scheduled_notification_types` which only returns types from YAML
4. Legacy types not in YAML → not cancelled

## Solution

Add the legacy notification types to the YAML config with `enabled: false`. This way:
1. They're included in `all_scheduled_notification_types` (used for cancellation)
2. They won't be scheduled (because `enabled: false` is checked in `process_notification?`)

This keeps the YAML config as the single source of truth for all notification types.

## Files to Modify

### 1. `config/notification_schedules.yml`

Add legacy notification types to the `common_configs.sms_reminder_schedule` section with `enabled: false`:

```yaml
common_configs:
  sms_reminder_schedule: &sms_reminder_schedule
    # Regular appointment reminders SMS
    reminder_6h_sms:
      notification_class: "AppointmentReminder6HoursSms"
      recipients: ["appointment"]
      time_before: "6 hours"
    reminder_incomplete_paperwork_24h_sms:
      notification_class: "IncompletePaperworkReminderSms"
      recipients: ["appointment"]
      time_before: "24 hours"
    reminder_72h_sms:
      notification_class: "AppointmentReminder72HoursSms"
      recipients: ["appointment"]
      time_before: "72 hours"
    # Legacy notification types - disabled but included for cancellation during reschedule
    legacy_reminder_15m_sms:
      notification_class: "AppointmentReminder15MinutesSms"
      recipients: ["caregiver"]
      time_before: "15 minutes"
      enabled: false
    legacy_reminder_36h_sms:
      notification_class: "AppointmentReminder36HoursSms"
      recipients: ["caregiver"]
      time_before: "36 hours"
      enabled: false
    legacy_reminder_1h_preintake_sms:
      notification_class: "AppointmentReminder1HourPreintakeSms"
      recipients: ["caregiver"]
      time_before: "1 hour"
      enabled: false
    legacy_reminder_1w_preintake_sms:
      notification_class: "AppointmentReminder1WeekPreintakeSms"
      recipients: ["caregiver"]
      time_before: "1 week"
      enabled: false
    legacy_reminder_36h_preintake_sms:
      notification_class: "AppointmentReminder36HoursPreintakeSms"
      recipients: ["caregiver"]
      time_before: "36 hours"
      enabled: false
    legacy_reminder_night_before_sms:
      notification_class: "AppointmentReminderNightBeforePreintakeSms"
      recipients: ["caregiver"]
      special_time: "night_before_appointment_time"
      enabled: false
```

### 2. `spec/models/notification/appointment/scheduling_notification_spec.rb`

Add test to verify legacy notification types are cancelled during reschedule:

```ruby
# In the AppointmentRescheduledEvent context (around line 487)
it "cancels legacy 15-minute SMS reminders when rescheduling" do
  appointment = create_appointment(start_time: 12.days.from_now)

  # Simulate a legacy reminder that was scheduled before flag was enabled
  legacy_reminder = Notification::ScheduledNotification.create!(
    notification_type: :appointment_reminder_15_minutes,
    subject: appointment,
    recipient: appointment.care_case.caregiver,
    scheduled_for: appointment.start_time - 15.minutes,
    status: :scheduled
  )

  new_start_time = 14.days.from_now
  event = reschedule_appointment(appointment, new_start_time, new_start_time + 1.hour)

  broadcast_and_process(event)

  expect(legacy_reminder.reload.status).to eq("canceled")
end
```

## Key Files Reference

| File | Purpose |
|------|---------|
| `config/notification_schedules.yml` | YAML config for notifications - **needs modification** |
| `app/models/notification/appointment/scheduling_notification.rb` | New configurable notification handler |
| `app/models/notification/appointment/legacy_scheduling_notification.rb` | Legacy notification handler (reference) |
| `app/models/notification/appointment/notification_config.rb` | Parses YAML config, provides `all_scheduled_notification_types` |
| `app/models/calendaring/member_reschedulation.rb` | Reschedule flow entry point |

## SMS Notification Types Summary

**Currently in YAML (scheduled by new system):**
- `AppointmentReminder6HoursSms`
- `IncompletePaperworkReminderSms` (24h)
- `AppointmentReminder72HoursSms`

**To be added to YAML with `enabled: false` (for cancellation only):**
- `AppointmentReminder15MinutesSms` ← **Bug cause**
- `AppointmentReminder36HoursSms`
- `AppointmentReminder1HourPreintakeSms`
- `AppointmentReminder1WeekPreintakeSms`
- `AppointmentReminder36HoursPreintakeSms`
- `AppointmentReminderNightBeforePreintakeSms`

## Verification

1. Run the specific test: `script/test spec/models/notification/appointment/scheduling_notification_spec.rb`
2. Run the legacy test: `script/test spec/models/notification/appointment/legacy_scheduling_notification_spec.rb`
3. Run the integration test: `script/test spec/integrations/notification/appointment/scheduling_notifications_spec.rb`

## Acceptance Criteria Validation

- ✅ When member reschedules appointment, all pending SMS reminders for original time are cancelled
- ✅ New SMS reminders are scheduled for the new appointment time
- ✅ Works for both legacy notification types (15-min, 36-hour) and new types (6h, 24h, 72h)
