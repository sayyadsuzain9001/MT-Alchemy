# Member 3 Prototype Notes

## Member 3 acceptance checklist (current Flutter prototype)

### E-commerce

- [x] Store: digital/physical filters, search, published products, cart action.
- [x] Product detail: product image/art, type, availability, quantity selector, shipping note, related products.
- [x] Cart: quantity controls, remove item, subtotal, discount line, physical shipping fee and total.
- [x] Checkout: available to signed-in Learner and Employer demo accounts; validates contact and billing details; shows delivery address only for physical items; payment methods and Pending state are represented.
- [x] Order confirmation and My Orders: order details can be reopened; manual payment confirmation updates digital availability or starts physical processing.
- [x] Digital Product Library: only the signed-in Learner's locally Paid orders are listed; bundled workbook and facilitator-guide text resources can be downloaded on desktop.
- [~] Desktop download actions save bundled sample text files to Downloads; browser file saving is not connected in this prototype.
- [~] Orders and digital entitlements are filtered by the signed-in demo email in local state; the server must verify ownership in the real app.

Mixed carts include a flat RM 10 sample shipping fee. Physical stock is reduced at order creation. The main navigation Cart icon shows the item count.

### Employer portal

- [x] Employer dashboard with employee, assignment and progress metrics.
- [x] Employee add/remove in the current app session.
- [x] Course assignment requires employees and a due date; one assignment row is recorded for each selected employee.
- [x] Reports show department and individual progress; Copy CSV, Download CSV and multi-page Download PDF are available.
- [~] Progress, scores, hours and certificates are sample data until Member 2's LMS is integrated.

Assignment records live in memory and are reset when the app restarts.

### Admin portal

- [x] Admin dashboard shows product, order, stock and pending payment totals.
- [x] Product management can add, edit, delete, publish/unpublish and adjust physical stock; set price and description; select supplied imagery/resources; or pick and preview an image file from the device.
- [x] Order management can set payment state and fulfilment state. Marking a physical order Paid moves it to Processing; marking a digital order Paid makes its library entitlement available.
- [~] Device-picked product images display for the current session. Durable image uploads and downloadable-file hosting need a backend/storage service.
- [~] Payment status is a prototype control. No payment provider is configured, so the app does not charge or verify real payments.

Admin and employer pages require the matching prototype role. All roles use the same Login form, and a protected URL redirects through Login before returning to the requested page. This client-only gate demonstrates the journey; it is not secure authorization and must be replaced by Member 2's real authentication plus backend role checks. Sign out is available from the shared navigation. Pushed pages show a back arrow.

### Shared-project integration and database

- [x] Member 3 pages are organized into commerce, employer, admin and shared-widget folders.
- [x] Store and Cart are connected to Member 1's shared navigation and theme; Cart has a live count badge.
- [x] Learner checkout/order/library and Admin/Employer entry points return through Login when the visitor is not signed in with a matching role; after sign-in the original destination opens.
- [x] Employer and Admin dashboard routes are reachable from the Store and Cart portal links.
- [x] ERD draft includes product, cart, order, payment, shipping, digital download, organization, employee, course and assignment relationships.
- [~] Login uses local demo accounts, and registration creates a Learner or Employer session-only demo account. Replace these with Member 2's shared identity service, then connect user, organization, course and learner progress models.
- [ ] Validate together after the other members' latest GitHub commits are pulled, resolve shared-route/model conflicts, then run the app as a team.
- [ ] Push the reviewed branch/commit to the team's GitHub repository.

### Validation

- [x] Dart analysis reports no issues in `lib/` and `test/`.
- [x] Dart formatter and `git diff --check` completed cleanly.
- [ ] Flutter widget tests and Windows build were not confirmed: Flutter CLI stalled without output in this environment. Run `test/auth_flow_test.dart` and the website end-to-end checklist when Flutter CLI is available.
- [ ] No end-to-end manual run has been completed after the latest changes.

## Prototype data and integration boundary

- Commerce records live in `CommercePrototypeStore` in memory and reset when the app restarts.
- Checkout records a `Pending` payment. It does not collect card details or contact a payment provider.
- Checkout and My Orders require a signed-in Learner or Employer demo account and filter orders against that account email. The Digital Library is Learner-only. Production access must be checked server-side for the authenticated buyer.
- Employee, organization, course, assignment and report examples are sample data. Integrate them with Member 2's authentication/LMS records when the team agrees on model and route contracts.
- Connect Firebase/Supabase or the team's selected backend and role-based authorization; do not treat client-side navigation as access control.
- Select and configure a payment provider before treating checkout as a real purchase flow.
- Add actual downloadable assets and a secure signed-in-user entitlement check before treating the library as a download service.

## Supplied imagery

The project already includes the curated image assets under `assets/images/`. The shop uses the supplied workshop and teacher-retreat photos as contextual brand photography for physical learning resources. Digital product covers use styled icons because the supplied materials do not contain actual workbook/package product photos. The underlying source images were retained unchanged.

## ERD

See [commerce_employer_erd.md](commerce_employer_erd.md) for the commerce and employer relationship draft.
