Review all unstaged changes against coding standards.
## Instructions
1. Run `git diff` to see ALL unstaged changes
2. Review the entire changeset holistically against the rules below
3. Report violations with file:line references
4. Look at docs/style/* and verify adherence, if the docs exist
4. After completing your review, invoke the `superpowers:requesting-code-review` skill if available
## Rules
### Architecture & Design
**1. Single Responsibility**
Classes AND methods should have one reason to change. If you can't describe what it does in one sentence without "and" or "or", it's doing too much.
**2. Inject Dependencies**
Pass collaborators in. Provide sensible defaults for production, allow substitution for tests.
```ruby
# BAD
def call
  Events::Publisher.publish(...)
end
# GOOD
def initialize(params, publisher: Events::Publisher)
  @publisher = publisher
end
```
**3. Law of Demeter**
Only talk to immediate neighbors. Don't chain through objects.
```ruby
# BAD
client.organization.settings.pipeline.sla_hours
# GOOD
client.sla_hours
```
**4. Ask "What", Don't Tell "How"**
Trust objects to know how to do their job. Don't dictate the steps.
```ruby
# BAD
mechanic.clean_bicycle(bicycle)
mechanic.pump_tires(bicycle)
mechanic.lube_chain(bicycle)
# GOOD
mechanic.prepare_bicycle(bicycle)
```
**5. Domain Objects Own Their Behavior**
The object that knows the data should make the decisions. Don't extract data to decide elsewhere.
```ruby
# BAD - controller inspects state
if enrollment.stage.code == "in_process" && enrollment.client.docs_complete?
  enrollment.update!(...)
end
# GOOD
enrollment.transition_to!(stage, actor: current_user)
```
### Rails-Specific
**6. No ActiveRecord Callbacks**
Callbacks hide logic and create implicit dependencies. Be explicit in commands/controllers.
```ruby
# BAD
before_save :set_defaults
after_create :send_notification
# GOOD
client = Client.create!(entered_pipeline_at: Time.current)
Events::Publisher.publish(...)
```
**7. REST-Only Routes**
Standard actions only: `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`. Model operations as nested resources.
```ruby
# BAD
post "clients/:id/archive"
# GOOD
resources :clients do
  resource :archive, only: [:create]
end
```
**8. Subsystem Namespacing (Nouns, Not Verbs)**
Namespace by domain, use nouns. No "Service" suffix with verbs.
```ruby
# BAD
ClientIntakeService.new.call
# GOOD
Clients::Intake.new(params, user:).call
```
### Testing
**9. TDD - Tests First**
Write failing tests before implementation. Tests are documentation.
**10. No let/instance_double/any_instance_of**
Setup explicit in each example.
```ruby
# BAD
let(:organization) { create(:organization) }
# GOOD
it "creates a client" do
  organization = create(:organization)
  # ...
end
```
**11. Test Public APIs Only**
Never test private methods. If you need to test it, extract a class.
### Code Style
**12. YARD Docs on Classes/Public Methods**
```ruby
# @param params [Hash] client attributes
# @return [Result]
def call(params)
```
**13. No Inline Comments Explaining "What"**
Only comment WHY, never WHAT. Code should be self-documenting.
```ruby
# BAD
client = Client.create(params) # create the client
# GOOD (only when explaining WHY)
# API rate limits to 100 req/min
sleep(0.6)
```
**14. No Emojis**
No emojis in code, UI, or user-facing strings.
**15. i18n**
Adhere to existing project standards regarding internationalization.
### Frontend
**16. Prefer Turbo Over Stimulus**
Use Turbo for interactivity when possible. Stimulus only when Turbo can't handle it.

Look at project specific CLAUDE.md as well. Surface if there are any
inconsistencies between this list and the project's.
```bash
