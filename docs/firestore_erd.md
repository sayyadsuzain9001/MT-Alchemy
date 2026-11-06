# MT Alchemy — Firestore data model (final ERD)

Cloud Firestore is a document database, so relationships are stored as keys (email or document id) instead of foreign-key constraints. Security rules in `firestore.rules` enforce who may read or write each relationship. The diagram shows the logical model; the table under it maps every entity to its collection.

```mermaid
erDiagram
  USER ||--o| ORGANIZATION : "is (role Employer)"
  ORGANIZATION ||--o{ EMPLOYEE : employs
  ORGANIZATION ||--o{ COURSE_ASSIGNMENT : commissions
  EMPLOYEE ||--o{ COURSE_ASSIGNMENT : receives
  COURSE ||--o{ COURSE_ASSIGNMENT : assigned
  COURSE ||--o{ COURSE_FILE_CHUNK : "PDF stored as"
  COURSE ||--|{ QUESTION : "quiz contains"
  USER ||--o| PROGRESS : tracks
  PROGRESS }o--o{ COURSE : "enrolled / completed"
  USER ||--o{ QUIZ_ATTEMPT : submits
  COURSE ||--o{ QUIZ_ATTEMPT : assessed_by
  USER ||--o{ CERTIFICATE : earns
  COURSE ||--o{ CERTIFICATE : certifies
  USER ||--o{ ORDER : places
  ORDER ||--|{ ORDER_ITEM : contains
  PRODUCT ||--o{ ORDER_ITEM : "sold as (snapshot)"
  COURSE ||--o{ ORDER_ITEM : "sold as course seat"
  ORDER ||--|| PAYMENT : "paid by (embedded)"
  ORDER ||--o| SHIPPING : "ships to (embedded)"
  ORDER_ITEM ||--o| DIGITAL_DOWNLOAD : unlocks
  USER ||--o{ QUOTE : requests
  QUOTE ||--|{ QUOTE_ITEM : includes
  USER ||--o{ NOTIFICATION : receives
  CONTACT_ENQUIRY }o--o| USER : "may come from"

  USER {
    string uid PK "Firebase Auth uid = doc id"
    string email UK
    string role "Learner | Employer | Trainer | Admin"
    string displayName
    string status "Active | Suspended"
    string phone
    string country
    string dateOfBirth
    string gender
    string jobTitle
    string company
    string industry
    string yearsWorking
    string learningAreas
    string photoBase64
    string registrationNumber "Employer"
    string employeeCount "Employer"
    string contactPerson "Employer"
  }
  EMPLOYEE {
    string id PK "organization__email"
    string organization FK "employer email"
    string email "employee login email"
    string name
    string department
    string status
    string addedAt
  }
  COURSE {
    string id PK
    string title
    string description
    string instructor
    string level
    string duration
    number price
    string status "Draft | Published | Archived"
    number passMark
    string videoUrl
    array modules
    array prerequisites
    number position
    number pdfChunks
  }
  COURSE_ASSIGNMENT {
    string id PK "organization__employee__course"
    string organization FK
    string employee FK
    string course FK "title"
    string due
    number progress
    number score
    string assignedAt
  }
  PROGRESS {
    string email PK
    map done "courseId -> lesson indexes"
    map last "courseId -> last lesson"
    array enrolled
    array completed
    map completionDates
  }
  QUIZ_ATTEMPT {
    string id PK
    string learner FK
    string courseId FK
    number score
    number total
    bool passed
    array answers
    string status "Submitted | Reviewed"
    string feedback
    string reviewedBy
  }
  CERTIFICATE {
    string certificateId PK
    string learnerEmail FK
    string courseId FK
    string learnerName
    string completedOn
    string trainer
  }
  PRODUCT {
    string id PK
    string name
    string category "Digital | Physical"
    number price
    number stock
    bool digital
    bool published
    string downloadAssetPath
    string imageBytes
  }
  ORDER {
    string number PK
    string customerEmail FK
    string date
    number total
    string paymentStatus "Pending | Paid | Failed"
    string paymentMethod "method + gateway reference"
    string fulfilmentStatus "Pending | Processing | Shipped | Delivered | Available"
    string billingAddress
    string shippingAddress
    string trackingNumber
    bool stockReserved
  }
  QUOTE {
    string reference PK
    string ownerEmail FK
    string organizationName
    string requirements
    string status "New | In Review | Quoted | Accepted | Declined"
    number quotedTotal
    string adminNote
  }
  NOTIFICATION {
    string id PK
    string recipient FK
    string sender FK
    string title
    string body
    string route
    bool read
  }
  CONTACT_ENQUIRY {
    string reference PK
    string name
    string email
    string enquiryType
    string message
    string status
    string adminNote
  }
```

## Entity → collection map

| Scope entity | Firestore location | Notes |
| --- | --- | --- |
| User, Role | `users/{uid}` | Role is a field; registration may only choose Learner or Employer. |
| Organization | `users/{uid}` with role `Employer` | Organization profile fields live on the employer account. |
| Employee | `employees/{org__email}` | Linked to a learner account by email. |
| Course, Module, Lesson | `courses/{id}` (`modules` array; lessons are generated per module) | PDFs chunked in `courseFiles/{id}/chunks/{n}`. |
| Assessment, Question, Answer | `courses/{id}.quiz`; answers in `quizAttempts/{id}.answers` | Trainer feedback on the attempt. |
| Enrolment, Progress | `progress/{email}` | Enrolment also derived from paid course orders and employer assignments. |
| Certificate | `certificates/{certificateId}` | Public read for QR verification. |
| Product, Product category | `products/{id}` (`category`) | Digital or Physical. |
| Cart | Browser storage (`alchemy_cart_v2`) | Guest carts work before sign-in. |
| Order, Order item, Payment, Shipping, Digital download | `orders/{number}` with embedded `lines`, payment and shipping fields | Digital download entitlement = paid order line. Course purchases are lines with category `Course`. |
| Quote | `quotes/{reference}` | Owner + admin only. |
| Notification | `notifications/{id}` | Sent by admin/trainer/employer; read by recipient. |
| Contact enquiry | `enquiries/{reference}` | Public create, admin read. |
| Review/Testimonial, Impact story, Article | Static content in `lib/pages.dart` | Candidates for a future `content` collection. |
