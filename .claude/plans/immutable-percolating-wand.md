# Fix: 60/60/60 Intake Scheduling Week Jump Bug

## Problem
When scheduling 60/60/60 intake appointments, the calendar for the child evaluation (step 2) incorrectly jumps ahead one week after scheduling the caregiver evaluation (step 1).

**Current behavior**: Caregiver eval (step 1) → Child eval calendar jumps ahead 1 week
**Expected behavior**: Caregiver eval (step 1) → Child eval calendar shows the same week (only needs to be 1 day ahead)

The 1-week jump IS desired between child eval (step 2) and feedback session (step 3).

## Root Cause
In `config/models/appointment_bundles.yml`, all three 60/60/60 bundles have `buffer: "1 week"` configured for the child/patient appointment (step 2):

```yaml
therapy_intake_60:
  appointments:
    - root_appointment_type: therapy_diagnostic_evaluation
      audience: caregiver         # Step 1 - no buffer
    - root_appointment_type: therapy_diagnostic_evaluation
      buffer: "1 week"           # Step 2 - THIS IS THE BUG
      audience: patient
    - root_appointment_type: therapy_diagnostic_evaluation_followup
      buffer: "1 week"           # Step 3 - correct
```

The buffer controls which week the calendar defaults to in `AvailabilityForm#offset_start_date_for` (line 42-51).

## Solution
Change the buffer for the child/patient appointment from `"1 week"` to `"1 day"` in all three 60/60/60 bundles:
- `therapy_intake_60`
- `psychological_testing_intake_60`
- `psychiatry_intake_60`

This will make the calendar show the same week while ensuring it's at least 1 day after the caregiver appointment.

**Note**: The existing validation rule `date_gap_between_min` with `duration: "1 day"` already enforces a minimum 1-day gap between all appointments, so this is only about the calendar's default starting week.

## Files to Modify

### 1. `config/models/appointment_bundles.yml`
Change buffer from `"1 week"` to `"1 day"` for step 2 in:
- Line 113: `therapy_intake_60` child/patient appointment
- Line 152: `psychological_testing_intake_60` child/patient appointment
- Line 191: `psychiatry_intake_60` child/patient appointment

### 2. `spec/models/phone_desk/scheduling/availability_form_spec.rb`
Update the test at line 286-311 that expects `previous_selection_date + 1.week` for `therapy_intake_60` step 2. It should now expect `previous_selection_date + 1.day`.

## Verification
Run the relevant spec to confirm the fix:
```bash
script/test spec/models/phone_desk/scheduling/availability_form_spec.rb
```
