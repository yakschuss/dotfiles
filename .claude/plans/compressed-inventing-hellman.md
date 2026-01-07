# Plan: Reorder DE Dropdowns to Show 60-Minute First

## Summary
Reorder Diagnostic Evaluation (DE) appointment types in `config/models/appointment_types.yml` so that 60-minute options appear before 90-minute options in the single appointment scheduling dropdown.

## Background
- Dropdown order is determined by YAML file order (per comment on lines 2-4 of the file)
- Currently: 90-minute DEs listed first, then 60-minute DEs
- Affects: Therapy, Psychological Testing, and Psychiatry service lines

## File to Modify
`config/models/appointment_types.yml`

## Changes

### 1. Therapy DEs (lines 6-53)
**Current order:**
1. `therapy_diagnostic_evaluation_virtual` (90 min) - line 6
2. `therapy_diagnostic_evaluation_60minute_virtual` (60 min) - line 16
3. `therapy_diagnostic_evaluation_in_person` (90 min) - line 30
4. `therapy_diagnostic_evaluation_60minute_in_person` (60 min) - line 40

**New order:**
1. `therapy_diagnostic_evaluation_60minute_virtual` (60 min)
2. `therapy_diagnostic_evaluation_virtual` (90 min)
3. `therapy_diagnostic_evaluation_60minute_in_person` (60 min)
4. `therapy_diagnostic_evaluation_in_person` (90 min)

### 2. Psychological Testing DEs (lines 136-183)
**Current order:**
1. `psychological_testing_diagnostic_evaluation_virtual` (90 min) - line 136
2. `psychological_testing_diagnostic_evaluation_60minute_virtual` (60 min) - line 146
3. `psychological_testing_diagnostic_evaluation_in_person` (90 min) - line 160
4. `psychological_testing_diagnostic_evaluation_60minute_in_person` (60 min) - line 170

**New order:**
1. `psychological_testing_diagnostic_evaluation_60minute_virtual` (60 min)
2. `psychological_testing_diagnostic_evaluation_virtual` (90 min)
3. `psychological_testing_diagnostic_evaluation_60minute_in_person` (60 min)
4. `psychological_testing_diagnostic_evaluation_in_person` (90 min)

### 3. Psychiatry DEs (lines 313-360)
**Current order:**
1. `psychiatry_diagnostic_evaluation_virtual` (90 min) - line 313
2. `psychiatry_diagnostic_evaluation_60minute_virtual` (60 min) - line 323
3. `psychiatry_diagnostic_evaluation_in_person` (90 min) - line 337
4. `psychiatry_diagnostic_evaluation_60minute_in_person` (60 min) - line 347

**New order:**
1. `psychiatry_diagnostic_evaluation_60minute_virtual` (60 min)
2. `psychiatry_diagnostic_evaluation_virtual` (90 min)
3. `psychiatry_diagnostic_evaluation_60minute_in_person` (60 min)
4. `psychiatry_diagnostic_evaluation_in_person` (90 min)

## Testing
No code changes required beyond YAML reordering. Manual verification in development:
1. Navigate to a care case's single appointment scheduling page
2. Open the appointment type dropdown
3. Verify 60-minute DEs appear before 90-minute DEs for each service line
