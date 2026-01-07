# Fix failing CI tests for coaching_ongoing capability

## Problem
Tests fail because the `:coach` factory trait creates staffers with `coaching` capability but the appointment types now require `coaching_ongoing`.

## Solution
Update `spec/factories/staffers.rb` to add `coaching_ongoing` capability in the `:coach` trait, following the same pattern as `:therapist` which adds `therapy_ongoing`.

## File to modify
- `spec/factories/staffers.rb` - Add line to create `:coaching_ongoing` capability in the `:coach` trait's `after :create` block

## Change
Add this line after line 196:
```ruby
FactoryBot.create(:care_capability, :coaching_ongoing, staffer: coach, region: region)
```
