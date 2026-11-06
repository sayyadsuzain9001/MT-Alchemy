# Member 3 completion checklist

This checklist describes the current shared Flutter prototype. `[x]` means the interaction is implemented locally, `[~]` means it works only as sample/prototype behavior, and `[ ]` means it still needs integration or team verification.

## E-commerce

- [x] Store with digital/physical filters, search, product cards and cart navigation.
- [x] Product detail with image/art, description, price, type, availability, quantity, shipping note and related products.
- [x] Product type explains stock and shipping: digital items have neither; physical items display stock and require delivery.
- [x] Shopping cart with quantity edits, remove action, subtotal, discount line, shipping and total.
- [x] Checkout contact and billing validation; physical items show shipping choices and address fields.
- [x] Checkout and order history/details allow Learner or Employer sessions; the checkout email is the signed-in account and orders are filtered to that account. Digital downloads remain Learner-only.
- [~] Payment method selection and Pending/Paid/Failed states are represented; no real payment provider charges or verifies a payment.
- [x] Order confirmation, order history and order detail navigation.
- [x] Orders show billing details, physical shipping address and tracking when applicable, with a downloadable bill/invoice PDF.
- [~] Business buyers can request a quote from a product or cart; employers can see their requests and admins can set status, indicative total and response notes.
- [~] Website Contact form submissions are saved in a local Admin inbox with a reference, status, and internal note; no backend or email delivery is connected.
- [~] Card, FPX and e-wallet are demo payment choices only. No provider is connected, no payment is collected, and orders remain Pending until an admin changes the status.
- [x] Digital Product Library unlocks bundled workbook and facilitator-guide text files only after a local order is marked Paid; desktop saves them to Downloads.
- [~] Local account filtering demonstrates ownership; production entitlement checks still need the identity service and backend.

## Employer portal

- [x] Employer dashboard with current employee, assignment and sample progress summaries.
- [x] Add and remove employees during the current app session.
- [x] Assign a course to selected employees with a required deadline; each employee gets a separate local assignment record.
- [x] Learning reports show individual and department progress; Copy CSV, Download CSV and multi-page PDF export are available.
- [~] LMS completion, scores, learning hours and certificates are sample/unintegrated data.

## Admin portal

- [x] Admin dashboard with product/order/stock/pending-payment totals.
- [x] Product management: add, edit and delete products; set price, type, description and stock; choose an image file from the device or supplied project imagery; preview it; select downloadable resources; publish/unpublish.
- [x] Order management: update payment and fulfilment states; Paid physical orders enter Processing, then Shipped creates a demo tracking ID; Paid digital orders become Available.
- [~] Picked images preview and display during this session only; durable uploads need a backend/file-storage service.
- [~] Admin and employer routes require the matching prototype role after login. Replace the local demo gate with Member 2's server-backed authentication and authorization before production.

## Database and integration

- [x] Member 3 ERD draft covers product/category, cart/item, order/item, payment, shipping, digital download, organization, employee, course and assignment relationships.
- [x] Member 3 code is organized under `lib/commerce/`, `lib/employer/`, `lib/admin/` and `lib/shared/`.
- [x] Store, Cart, theme and navigation are connected to the shared website shell; the Cart badge updates with item count.
- [x] Login is the entry point for demo Admin and Employer accounts; directly opening a protected route redirects to Login and returns to the requested page after sign-in.
- [x] The shared app bar provides back navigation on pushed pages, and signed-in sessions have a Sign out action.
- [x] Login supports demo Learner, Trainer, Employer and Admin accounts in one sign-in form. Registration creates a current-session Learner or Employer demo account, signs it in, and opens its role dashboard. Direct access to protected routes sends signed-out visitors through Login and checks the role before showing protected pages.
- [~] Login and registration use local in-memory demo accounts, not Member 2's production identity service. New registrations do not survive app restart. Connect authentication, organizations, course access and profile data to the agreed backend before production.
- [ ] Pull the latest Member 1 and Member 2 changes, resolve any shared route/model conflicts and verify the merged app as a team.
- [ ] Push the agreed reviewed changes to the team GitHub repository.

## Verification

- [~] Dart analyzer: the Member 3 source has no reported issues except unresolved `file_picker` symbols because the package is not present in the local Pub cache; dependency resolution did not complete in this environment.
- [x] Dart formatting and `git diff --check` completed for the payment-flow fix; Git only reports existing line-ending normalization notices.
- [ ] Flutter widget tests, Windows build and end-to-end UI run remain unverified. Flutter CLI commands stalled without output in this environment; run the new `test/auth_flow_test.dart` and manual checklist after Flutter CLI works locally.
- [~] Device-selected product images preview and display during the current app session; they are in-memory only and need server/storage integration for persistence.
- [ ] No real payment, persistent database, email invitation/notification or production authorization has been configured. Demo data resets when the app restarts; Admin has a Reset demo data action for repeat walkthroughs.
