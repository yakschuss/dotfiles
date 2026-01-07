# Plan: Add CC ID Search to Waitlist

## Summary
Add a search field at the top of the waitlist page to search by Care Case ID (brightline_id).

## Files to Modify

### 1. `app/models/wait_list/entry.rb`

**Add new scope** (after line 114):
```ruby
scope :with_care_case_brightline_id, ->(brightline_id) {
  return if brightline_id.blank?
  joins(:care_case).where("care_cases.brightline_id ILIKE ?", "%#{brightline_id.to_s.strip}%")
}
```

**Update `filter_by` scope** (line 73) to include the new parameter:
```ruby
scope :filter_by, ->(status: nil, region_id: nil, payer_id: nil, appointment_type_id: nil,
                     root_appointment_type_id: nil, clinic_id: nil, priority: nil,
                     care_case_brightline_id: nil) do
  # ... existing code ...
  scope = scope.with_care_case_brightline_id(care_case_brightline_id)
  scope
end
```

### 2. `app/controllers/staffers/wait_list/entries_controller.rb`

**Update `filter_params`** (line 60) to permit the new parameter:
```ruby
.permit(:status, :root_appointment_type_id, :priority, :care_case_brightline_id,
        region_id: [], payer_id: [], clinic_id: [])
```

### 3. `app/views/staffers/wait_list/entries/index.html.erb`

**Add search field** between "Reset filters" link (line 11) and the filter form (line 12):
```erb
<div class="mb-4">
  <%= wave_form_with scope: :filters, method: :get, data: {turbo: true, forms_target: :submittable}, class: "flex items-center gap-2" do |f| %>
    <%= f.field :text, :care_case_brightline_id,
          label: "Search by CC ID",
          placeholder: "BC-XX-XXXXXXXX",
          value: filter_params[:care_case_brightline_id],
          wrapper_class: "w-64",
          data: {action: "input->forms#requestSubmit"} %>
    <% if filter_params[:care_case_brightline_id].present? %>
      <%= link_to "Clear", wait_list_entries_path(filters: filter_params.except(:care_case_brightline_id)),
            class: "prism-link prism-text-small mt-6" %>
    <% end %>
  <% end %>
</div>
```

### 4. `spec/models/wait_list/entry_spec.rb`

Add tests for the new scope:
- Returns entries matching full brightline_id
- Supports partial/substring matching
- Returns all entries when brightline_id is blank
- Is case-insensitive

### 5. `spec/requests/staffers/wait_list/entries_spec.rb`

Add request tests:
- Filters by care case brightline_id
- Supports partial matching
- Combines search with other filters

## Behavior
- Search field auto-submits with debounce (via existing `forms` controller)
- Partial matching supported (e.g., "BC-AB" or just "12345" will match)
- Case-insensitive search
- Search works alongside existing filters
- "Clear" link appears when search has a value
