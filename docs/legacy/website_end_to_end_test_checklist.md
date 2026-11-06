# MT Alchemy end-to-end flow test checklist

Use this checklist against a fresh app launch after the latest team merge. Mark each result as Pass, Fail, or Blocked, and note the screen, account role, and exact message for any issue. This is a manual test plan; items are not considered passed just because the screen exists.

## A. Launch, home and navigation

- [ ] Launch on Windows and confirm the home page renders without Flutter red screens or console exceptions.
- [ ] Check the home page at desktop and narrow window sizes; confirm images load and no content overflows.
- [ ] Open About, Services, Corporate, Upskilling, Store, Insights and Contact from the main navigation; use Back and confirm it returns to the prior page.
- [ ] Open Store from the navigation, add a product, and confirm the cart count changes. Remove it and confirm the count updates.
- [ ] Close/reopen the application and record which data persists. Course progress uses local preferences; authentication and commerce demo records are session-only.

## B. Login and registration

- [ ] Open Login from the website navigation. Confirm there is one shared sign-in form and a clear Register link.
- [ ] Submit empty fields, invalid email, and wrong password; check inline validation and that no role session is created.
- [ ] Sign in as `learner@mtalchemy.demo` / `AlchemyLearner!26`; confirm the Learner Dashboard opens.
- [ ] Sign in as `trainer@mtalchemy.demo` / `AlchemyTrainer!26`; confirm the Trainer Dashboard opens.
- [ ] Sign in as `employer@mtalchemy.demo` / `AlchemyEmployer!26`; confirm the Employer Dashboard opens.
- [ ] Sign in as `admin@mtalchemy.demo` / `AlchemyAdmin!26`; confirm the Admin Dashboard opens.
- [ ] Register an Individual with valid fields, matching 8+ character passwords, and a new email. Confirm an authenticated Learner session and Learner Dashboard.
- [ ] Try registering that same email again; confirm duplicate email is rejected and no new session is created.
- [ ] Register an Employer using valid organization details and a new email; confirm Employer Dashboard access.
- [ ] Try invalid email, missing required fields, short password, and mismatched password; confirm the account is not created.
- [ ] Sign out and sign in again with a newly registered account in the same run. Restart the app and confirm the demo clearly does not promise prototype account persistence.

## C. Role and route access

- [ ] While signed out, open `/admin`, `/admin/products`, `/admin/orders`, `/admin/quotes`, `/admin/enquiries`, `/employer`, `/employees`, `/assign-course`, `/reports`, `/dashboard`, `/trainer-dashboard`, `/checkout`, `/orders`, and `/digital-library` directly. Each protected destination must route through Login.
- [ ] From a protected route, sign in with the wrong role. Confirm access is denied and no protected dashboard content is shown.
- [ ] Confirm Learner cannot open Employer/Admin/Trainer-only routes; Employer cannot open Admin/Learner/Trainer-only routes; Trainer cannot open Admin/Employer/Learner-only routes.
- [ ] Confirm Sign out clears the role and directs to Login; browser/app Back must not expose a protected page after sign out.
- [ ] Confirm Register cannot grant Admin or Trainer privileges.

## D. Learner and Trainer LMS flows

- [ ] Learner Dashboard shows course progress and the profile form. Save an empty profile name and confirm validation; save valid profile fields and confirm feedback.
- [ ] Open Learning Hub, view course detail, return, and open course player. Check lesson navigation at desktop and narrow width.
- [ ] Mark a lesson complete, move between lessons, leave and return. Confirm progress and last lesson persist after restart.
- [ ] Complete the course and submit the quiz with both passing and failing answers. Confirm pass threshold, feedback, retry behavior, and certificate eligibility are correct.
- [ ] Open the certificate only after passing. Check learner name, course, date, score, and return navigation.
- [ ] Trainer dashboard: open assigned course/player and return; confirm Trainer can use the permitted learning route but cannot open Learner Dashboard or Admin pages.

## E. Member 3 commerce buyer flow

- [ ] Store: search/filter; open each product detail; check artwork, current price, physical/digital label, stock and availability.
- [ ] Add digital and physical products; edit cart quantities, remove lines, and check stock limits, subtotal, shipping, total and badge.
- [ ] Request quote from a product and from a populated cart. Confirm quote submission does not create an order or payment.
- [ ] Choose Checkout signed out; confirm Login returns to Checkout after a valid Learner or Employer sign-in.
- [ ] Checkout digital-only items: shipping fields hidden, shipping fee zero, billing validation works, payment clearly marked simulated.
- [ ] Checkout a physical item: test same/different billing and shipping address, required fields, available stock, and shipping calculation.
- [ ] Place order; confirm cart clears, order number is unique, order is Pending, billing/shipping and line totals are correct, and physical stock is reserved once.
- [ ] Attempt a second order exceeding remaining stock; confirm it is rejected and stock does not go negative.
- [ ] Download invoice and inspect customer, billing, delivery when physical, item quantities, totals, payment and fulfilment states.
- [ ] My Orders and order detail show only the signed-in buyer's orders. Try another user and confirm no order is exposed.
- [ ] Admin marks a digital order Paid; confirm Digital Library download becomes available only to the buyer.
- [ ] Admin marks a physical order Paid then Processing → Shipped → Delivered; confirm tracking and delivery address remain visible.
- [ ] Repeat payment Paid; confirm fulfillment stays at its current state. Confirm a Paid order cannot be downgraded to Failed.
- [ ] Mark a pending physical order Failed; confirm stock is released once. Retry after release when stock is available; confirm it is reserved once. Retry after stock is consumed by another order; confirm it is rejected without incorrect stock/order state.
- [ ] Test unavailable/deleted product and empty-cart checkout; confirm a clear error and no malformed order.

## F. Employer, Admin and business enquiry flows

- [ ] Employer: add employee with valid email; reject invalid and duplicate emails; remove a test employee and confirm its assignments are removed.
- [ ] Assign course to one employee and multiple employees, set deadline, and verify one row per employee. Reject missing employee selection or deadline.
- [ ] Review individual and department reports; compare displayed totals and progress against the assignment data. Copy/download CSV and download PDF; inspect files.
- [ ] Employer requests a quote; Admin updates status, price and response; verify the matching Employer sees it and a different employer cannot.
- [ ] Contact page: submit invalid and valid enquiries. Confirm valid request has a reference in Admin inbox and Admin notes/status persist during the current app session.
- [ ] Admin products: add/edit/publish/unpublish/delete physical and digital products; validate price and stock; preview selected image; check product availability in Store after every change.
- [ ] Admin orders: check payment/fulfilment dropdown options reflect valid state transitions; check order and stock dashboard totals update.
- [ ] Admin direct route while signed out or wrong-role signed in must remain protected. Admin access is only through the shared Login screen.

## G. Visual and exception sweep

- [ ] Test desktop, tablet-ish and narrow window widths. Check header, drawer, dropdown menus, forms, dialogs, cards, charts, footer and images for clipping/overflow.
- [ ] Open and cancel/save each Admin product editor and quote dialog repeatedly. Confirm no disposed-controller, dirty-build-scope, or ListTile ink-splash exceptions.
- [ ] Use Back from every pushed page, dialog and protected-route redirect; confirm stack behavior is sensible.
- [ ] Repeat order/payment/assignment/enquiry actions rapidly and check duplicate submissions, duplicate references, negative stock and stale dashboard values.
- [ ] Review debug console after each section; record and fix every uncaught exception and unexpected Flutter error.

## Current prototype boundary

- Checkout payment methods are demo selections only. No gateway charges or verifies payment; Admin status changes simulate confirmation.
- Commerce and registration accounts are in-memory prototype data. They are not a production database or secure identity system. Do not enter real passwords, payment data, or customer data.
- Product image picking previews the image for the current session only. Email, invitations, notifications, quote-to-order conversion, and server authorization are not connected.
- LMS course progress is stored in local device preferences. Course content, profiles, certificates, and reports remain demo data until integrated with the team's backend/LMS.
