# Fix chat_spec.rb CI Failure

## Problem

The test at `spec/features/staffers/chat_spec.rb:102` fails because:

```ruby
within("#close-conversation-button") do
  expect(page).to have_button("Mark as closed")
end
```

The PR changed `chat_actions_component.html.erb` - previously the "Mark as closed" button was wrapped in a `<div id="close-conversation-button">`, but now the `id="close-conversation-button"` is on the `Prism::Button` itself (not a wrapper div).

So the test is looking for a button INSIDE `#close-conversation-button`, but `#close-conversation-button` IS the button now.

## Fix

Update `spec/features/staffers/chat_spec.rb:109-111`:

**Before:**
```ruby
within("#close-conversation-button") do
  expect(page).to have_button("Mark as closed")
end
```

**After:**
```ruby
expect(page).to have_button("Mark as closed", id: "close-conversation-button")
```

## File to modify

- `spec/features/staffers/chat_spec.rb` (line 109-111)
