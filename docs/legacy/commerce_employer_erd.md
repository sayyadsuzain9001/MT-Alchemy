# Member 3 ERD Draft

This draft covers commerce and employer features owned by Member 3. It is a planning artifact for the Flutter prototype; the current implementation saves prototype records locally with shared_preferences and does not connect to Firebase or another backend. The ERD describes a proposed relational backend, not an existing database.

```mermaid
erDiagram
  USER ||--o{ USER_ROLE : has
  ROLE ||--o{ USER_ROLE : grants
  ORGANIZATION ||--o{ EMPLOYEE : includes
  USER ||--o| EMPLOYEE : represents
  USER ||--o{ CART : owns
  CART ||--|{ CART_ITEM : contains
  PRODUCT ||--o{ CART_ITEM : selected_as
  PRODUCT_CATEGORY ||--o{ PRODUCT : classifies
  USER ||--o{ CUSTOMER_ORDER : places
  ORGANIZATION o|--o{ CUSTOMER_ORDER : purchases_for
  CUSTOMER_ORDER ||--|{ ORDER_ITEM : contains
  PRODUCT ||--o{ ORDER_ITEM : sold_as
  CUSTOMER_ORDER ||--o{ PAYMENT : paid_by
  CUSTOMER_ORDER ||--o| SHIPPING : ships_as
  ORDER_ITEM ||--o| DIGITAL_DOWNLOAD : unlocks
  ORGANIZATION ||--o{ BUSINESS_QUOTE : requests
  BUSINESS_QUOTE ||--|{ QUOTE_ITEM : includes
  PRODUCT ||--o{ QUOTE_ITEM : quoted_as
  ORGANIZATION ||--o{ COURSE_ASSIGNMENT : commissions
  COURSE ||--o{ COURSE_ASSIGNMENT : assigned
  EMPLOYEE ||--o{ COURSE_ASSIGNMENT : receives
  USER ||--o{ COURSE_ASSIGNMENT : assigned_by
  USER o|--o{ CONTACT_ENQUIRY : submits

  USER {
    string user_id PK
    string name
    string email UK
    string status
  }
  ROLE {
    string role_id PK
    string role_name UK
  }
  USER_ROLE {
    string user_id PK,FK
    string role_id PK,FK
  }
  ORGANIZATION {
    string organization_id PK
    string name
    string registration_number
    string industry
  }
  EMPLOYEE {
    string employee_id PK
    string user_id FK
    string organization_id FK
    string department
    string employment_status
  }
  PRODUCT_CATEGORY {
    string category_id PK
    string name
  }
  PRODUCT {
    string product_id PK
    string category_id FK
    string name
    string product_type
    decimal price
    int stock_quantity
    int weight_grams
    string dimensions
    string digital_file_ref
    string publish_status
  }
  CART {
    string cart_id PK
    string user_id FK
    datetime updated_at
  }
  CART_ITEM {
    string cart_item_id PK
    string cart_id FK
    string product_id FK
    int quantity
    decimal unit_price_snapshot
  }
  CUSTOMER_ORDER {
    string order_id PK
    string user_id FK
    string organization_id FK
    string order_number UK
    string customer_name
    string customer_email
    string customer_phone
    string billing_address
    decimal subtotal
    decimal shipping_fee
    decimal total
    string payment_status
    string fulfilment_status
    datetime created_at
  }
  ORDER_ITEM {
    string order_item_id PK
    string order_id FK
    string product_id FK
    int quantity
    decimal unit_price_snapshot
    decimal line_total
  }
  PAYMENT {
    string payment_id PK
    string order_id FK
    string provider_reference
    decimal amount
    string status
    datetime paid_at
  }
  SHIPPING {
    string shipping_id PK
    string order_id FK
    string recipient_name
    string address
    string tracking_number
    string status
  }
  DIGITAL_DOWNLOAD {
    string download_id PK
    string order_item_id FK
    string user_id FK
    string file_ref
    int download_count
    datetime expires_at
  }
  BUSINESS_QUOTE {
    string quote_id PK
    string organization_id FK
    string contact_name
    string contact_email
    string contact_phone
    string requirements
    string status
    decimal quoted_total
    string response_note
    datetime created_at
  }
  QUOTE_ITEM {
    string quote_item_id PK
    string quote_id FK
    string product_id FK
    int quantity
    decimal unit_price_snapshot
  }
  CONTACT_ENQUIRY {
    string enquiry_id PK
    string user_id FK
    string reference UK
    string customer_name
    string email
    string phone
    string organization_name
    string enquiry_type
    string message
    string status
    datetime created_at
  }
  COURSE {
    string course_id PK
    string title
    string status
  }
  COURSE_ASSIGNMENT {
    string assignment_id PK
    string organization_id FK
    string course_id FK
    string employee_id FK
    string assigned_by_user_id FK
    datetime due_at
    string status
  }
```

## Relationship notes

- `USER_ROLE` supports multiple roles per account. Authorization must be enforced by the backend, not only by hiding screens.
- `EMPLOYEE` connects an authenticated user to an organization. An invite may exist before the user finishes registration, so production design may need a separate invitation record.
- `CART_ITEM` stores a unit-price snapshot only if the product price at add-to-cart time must be retained; checkout should still confirm the current price.
- `CUSTOMER_ORDER` has many `ORDER_ITEM` rows and payment attempts. Physical items may have one shipping record; digital entitlements are tied to purchased order items.
- A `BUSINESS_QUOTE` belongs to an organisation and contains one or more `QUOTE_ITEM` rows. It is a pricing enquiry, not an order/payment. A customer-accepted quote can be converted into an order by a future backend workflow.
- `COURSE_ASSIGNMENT` records one employee receiving one course, with the assigning employer user and due date. Add a separate assignment batch entity if one action must group many employees.
- The current prototype records an assignment per selected employee. Production should add invitation/notification records and connect each employee to a real user account.
- Keep shipping details separate from billing details, and store the payment provider reference and validated status in the server-side payment record.
- `CONTACT_ENQUIRY` captures public website enquiries and may be submitted before the visitor creates an account, so `user_id` is optional. The admin inbox should retain status and response/audit details in the production backend.
- Store amounts in a fixed precision decimal type and store timestamps in UTC in the backend.


## Integrated prototype mapping

Employer email is the local organization discriminator on employees and assignments. Employee email links an assignment to a learner account. Course titles map to IDs in `lib/data/mock_data.dart`; a backend should replace this with immutable course and organization IDs. Local progress is keyed by learner email and course ID. Orders preserve product/price snapshots and stock-reservation state. A production backend must enforce these relationships, role permissions, entitlements and transactions independently of the Flutter client.
