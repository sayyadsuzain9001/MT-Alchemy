# MT Alchemy verification and handoff

Checked 11 October 2026 (Asia/Kuala_Lumpur).

Repository: https://github.com/sayyadsuzain9001/Alchemy
Local checkout: `C:/Users/user/OneDrive/Desktop/Alchemy`
No commit, push, merge or remote changes were performed.

## Implemented changes

- Preserved the existing corporate design and added a public sitemap and role-specific dashboard navigation.
- Fixed login redirect arguments so a selected course survives sign-in. Removed public admin shortcuts and retained role checks.
- Added account-specific enrollment/progress storage. Certificates require a recorded quiz pass and can export a prototype PDF.
- Persisted products, uploaded product images, cart, orders, stock reservations, quotations, enquiries, employees and assignments using shared_preferences.
- Scoped employer records by account; assignments use the actual LMS catalogue and learner email links. Lesson progress and quiz scores feed assignment reports.
- Added service quotations when no cart product is selected, browser file exports, and local trainer review feedback.
- Fixed responsive dropdowns, store banner and pricing layout, employee action buttons, quiz headers and progress labels. Added Material ancestors for visible ListTile ink effects.

## Member and journey coverage

| Area | Current status |
| --- | --- |
| Member 1 corporate website | Existing pages retained; sitemap added; enquiry form validation/submission tested. |
| Member 2 LMS | Login/registration, enrollment redirect, quiz completion and certificate restriction tested. Progress is scoped by account. Content remains sample material. |
| Member 2 trainer | Protected dashboard and course preview; feedback on sample assessments saves locally. Statistics/learner list remain sample data. |
| Member 3 commerce | Stock reservation, failed-payment stock recovery, paid digital entitlements, order persistence and customer filtering tested at state level. |
| Member 3 employer/admin | Protected routes render; employer isolation, course assignment linkage, enquiry and quotation persistence tested. Existing management screens retained. |
| ERD | Existing draft updated to explain local persistence and proposed backend relationships. |

## Verification evidence

- `flutter analyze --no-pub`: passed, no issues.
- `flutter test --no-pub --timeout 20s`: passed, 16 tests.
- Public and role-specific portal route widget tests cover 390 px and 1440 px widths.
- Full quiz interaction includes missing-answer validation and passing completion.
- Enquiry widget test includes empty-form validation and successful submission. Separate storage tests confirm enquiry/admin response and quotation status survive reload.
- `git diff --check`: no whitespace errors; Git reports Windows line-ending conversion notices on generated plugin files.
- `flutter build web --no-pub`: passed; output is build/web. Wasm dry run also succeeded. The compiler emitted a CupertinoIcons font-family warning; rendered icon appearance still needs browser review.

These checks do not constitute a manual browser walkthrough of every interaction. Browser automation failed to initialize; an attempted headless screenshot did not produce a usable image. Actual browser downloads, PDF appearance, every checkout field, and all admin dialogs still need manual review. Responsive widget rendering does not establish visual pixel fidelity.

## Prototype limitations

- No real authentication backend, server-side permissions, email, payments, shipping integration or cross-device synchronization.
- Newly registered accounts and sign-in sessions are temporary. Demo accounts remain available. Use fictional data only.
- Local storage can be cleared by the user/browser; cart state is shared by the device. Employer identity currently uses email rather than a backend organization ID.
- LMS courses, quiz content, trainer statistics and assessment list are sample data. Catalogue prices are not charged during prototype enrollment.
- Certificates are unaccredited demo PDFs; QR graphics are placeholders. PDF generation uses the existing ASCII report writer, so non-ASCII names are not preserved accurately.
- Some legacy documentation describes earlier session-only behavior; README.md and this report describe the current implementation.
- Formal assignment Word report, new browser screenshots, student/group details and Turnitin evidence are not produced by this code check.

## Run locally

```powershell
cd "C:\Users\user\OneDrive\Desktop\Alchemy"
flutter pub get
flutter run -d edge
```

See README.md for demo credentials and the project map.

## Exact changed/new files

Includes retained formatting changes and SDK-generated plugin registration changes. Generated build artifacts are ignored.

- [.gitignore](<C:/Users/user/OneDrive/Desktop/Alchemy/.gitignore>)
- [README.md](<C:/Users/user/OneDrive/Desktop/Alchemy/README.md>)
- [docs/commerce_employer_erd.md](<C:/Users/user/OneDrive/Desktop/Alchemy/docs/commerce_employer_erd.md>)
- [docs/completion_report.md](<C:/Users/user/OneDrive/Desktop/Alchemy/docs/completion_report.md>)
- [lib/admin/admin_pages.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/admin/admin_pages.dart>)
- [lib/commerce/commerce_prototype_store.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/commerce/commerce_prototype_store.dart>)
- [lib/commerce/quote_pages.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/commerce/quote_pages.dart>)
- [lib/commerce/store_pages.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/commerce/store_pages.dart>)
- [lib/data/progress_store.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/data/progress_store.dart>)
- [lib/employer/employer_pages.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/employer/employer_pages.dart>)
- [lib/main.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/main.dart>)
- [lib/pages.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/pages.dart>)
- [lib/screens/lms/certificate_screen.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/screens/lms/certificate_screen.dart>)
- [lib/screens/lms/course_detail_screen.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/screens/lms/course_detail_screen.dart>)
- [lib/screens/lms/course_player_screen.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/screens/lms/course_player_screen.dart>)
- [lib/screens/lms/learner_dashboard_screen.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/screens/lms/learner_dashboard_screen.dart>)
- [lib/screens/lms/learning_hub_screen.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/screens/lms/learning_hub_screen.dart>)
- [lib/screens/lms/login_register_screen.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/screens/lms/login_register_screen.dart>)
- [lib/screens/lms/quiz_screen.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/screens/lms/quiz_screen.dart>)
- [lib/screens/lms/trainer_dashboard_screen.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/screens/lms/trainer_dashboard_screen.dart>)
- [lib/shared/auth_prototype_store.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/shared/auth_prototype_store.dart>)
- [lib/shared/file_export.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/shared/file_export.dart>)
- [lib/shared/file_export_web.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/shared/file_export_web.dart>)
- [lib/shared/member3_login_page.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/shared/member3_login_page.dart>)
- [lib/shared/portal_components.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/shared/portal_components.dart>)
- [lib/widgets.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/widgets.dart>)
- [lib/widgets/lms/content_viewer.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/widgets/lms/content_viewer.dart>)
- [lib/widgets/lms/course_card.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/widgets/lms/course_card.dart>)
- [lib/widgets/lms/module_sidebar.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/widgets/lms/module_sidebar.dart>)
- [lib/widgets/lms/progress_bar_card.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/lib/widgets/lms/progress_bar_card.dart>)
- [macos/Flutter/GeneratedPluginRegistrant.swift](<C:/Users/user/OneDrive/Desktop/Alchemy/macos/Flutter/GeneratedPluginRegistrant.swift>)
- [pubspec.lock](<C:/Users/user/OneDrive/Desktop/Alchemy/pubspec.lock>)
- [pubspec.yaml](<C:/Users/user/OneDrive/Desktop/Alchemy/pubspec.yaml>)
- [test/integration_regression_test.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/test/integration_regression_test.dart>)
- [test/state_regression_test.dart](<C:/Users/user/OneDrive/Desktop/Alchemy/test/state_regression_test.dart>)

