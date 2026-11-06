# Member 3 flow review and manual walkthrough

Use the role-specific local demo credentials supplied to the project owner. Login uses one shared email/password form; the account role controls the destination. Account/session data and commerce records reset when the app restarts. This list is for the manual walkthrough before the team merges its final authentication and backend.

## 1. Store and cart as a visitor

- [ ] Open Store from the main navigation; search and filter Digital/Physical products.
- [ ] Open product details and review artwork, description, price, product type, stock/availability, quantity and related products.
- [ ] Add one digital and one physical item. Confirm the Cart badge changes.
- [ ] Edit quantities, remove an item and check subtotal, discount, shipping and total.
- [ ] Start a business quote from a product detail and submit company/contact/requirements; confirm no order or payment is created.
- [ ] Start a second quotation from a populated cart and verify it includes all selected cart lines.
- [ ] Choose Checkout while signed out. Login should explain that a Learner or Employer account is needed and remember the checkout destination.
- [ ] Submit the public Contact form and verify it receives a reference; sign in as Admin and retrieve it from Contact enquiry inbox.

## 2. Learner checkout and private purchases

- [ ] On Login, sign in with the Learner demo account. Checkout should open afterward.
- [ ] Check that email is the signed-in account email and cannot be changed to another account.
- [ ] For a physical cart, complete billing details, test both shipping-address options and confirm required-field validation.
- [ ] For digital-only items, confirm shipping address fields are hidden and shipping is zero.
- [ ] Place an order and review order number, items, total, payment state and addresses.
- [ ] Confirm stock is reserved at order placement, restored if payment is marked Failed, and reserved again only when inventory is available if payment is retried.
- [ ] Download the bill/invoice PDF from order confirmation and My Orders; check billing, delivery (physical only), line items, totals, payment and fulfilment statuses.
- [ ] Check that payment choices are marked demo-only and that no card details are requested or charged.
- [ ] Open My Orders and an order detail; confirm the new order appears for the signed-in account.
- [ ] Sign out. Open `/admin`, `/admin/products`, `/admin/orders`, `/employer`, `/checkout`, `/orders` and `/digital-library` directly; each should require the matching role at Login.
- [ ] Sign in as a different Learner and confirm the first Learner’s order is not shown.

## 3. Admin product and order management

- [ ] Sign in with the Admin demo account from Login. Confirm the Admin dashboard opens.
- [ ] Add a product. Try empty name/description, zero or invalid price, and invalid stock; confirm useful validation.
- [ ] Choose a product image from the device and confirm the preview is the image you chose. An image over 10 MB should be rejected.
- [ ] Check physical product stock and optional supplied project images. Check that a new digital product uses branded artwork by default, has no stock field and can select its download resource.
- [ ] Save, open the Store and confirm its image, name, price, type and availability match Admin.
- [ ] Edit, unpublish, republish and delete a test product. Confirm unpublished products disappear from the Store and deletion asks for confirmation.
- [ ] In Admin orders, mark a digital order Paid and confirm it becomes Available. Mark a physical order Paid and advance Processing → Shipped → Delivered; check the tracking number. Confirm a Paid order cannot be downgraded and repeated confirmation does not reset fulfilment.
- [ ] In Admin quote requests, move a quote through In Review and Quoted, add a price/note, and confirm the matching Employer account sees the updated status and response.
- [ ] Sign out and confirm direct Admin URLs still require Login.

## 4. Employer people, assignments and reports

- [ ] Sign in with the Employer demo account from Login.
- [ ] Add a test employee; try invalid and duplicate email values. Remove the test employee and confirm their assignment rows are removed.
- [ ] Assign a course to one or more selected employees with a deadline; confirm one assignment exists per employee.
- [ ] Review the Learning Reports department and individual views.
- [ ] Copy/download CSV and download PDF. Confirm the exported rows match the report.

## 5. Navigation and presentation

- [ ] Use the app-bar back arrow after opening each page from another page; verify it returns to the previous page.
- [ ] Use the drawer/main navigation, cart badge and signed-in Sign out control.
- [ ] Repeat the important pages at phone/narrow-window and desktop sizes. Check dialogs, forms, image previews, cards, dropdowns and buttons for clipping or hard-to-reach controls.

## Current prototype boundaries

- Demo login, orders, products, employees and assignments are in-memory examples, not a real identity service or database.
- Picked product images stay in memory for the current app session; durable image storage needs the team's backend/storage service.
- Payment is simulated. Admin status changes simulate payment confirmation and fulfilment.
- The client-side role gate demonstrates the flow; production authorization and download/order ownership must be enforced on the backend.
- Desktop file saves are supported. Browser download handling and Member 2 authentication/LMS integration remain team merge work.
