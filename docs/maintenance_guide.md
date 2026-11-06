# MT Alchemy — maintenance guide

## Everyday administration (no code)

| Task | Where |
| --- | --- |
| Add a trainer or admin | Admin portal → Users → Add user (temporary password; they change it in My profile) |
| Change a role, suspend or remove someone | Admin portal → Users |
| Review employer organizations | Admin portal → Organizations |
| Add or edit courses, set price, pass mark, status, PDF, video, quiz | Admin portal → Course management (trainers: Trainer dashboard → Courses → Add or edit courses). Save as **Draft**, then set **Published** when ready; **Archived** hides it. |
| Add products, stock, images, publish/unpublish | Admin portal → Product management |
| Confirm bank-transfer payments, ship orders | Admin portal → Order management (Paid → Processing → Shipped → Delivered). Customers are notified. |
| Answer quotes and enquiries | Admin portal → Quote requests / Contact enquiry inbox |
| Review quiz submissions | Trainer dashboard → Assessments |

## Configuration

`config/app_env.json` (git-ignored) holds the Firebase web config and the Gemini key. Copy `config/app_env.example.json` to start. Build with:

```powershell
flutter build web --dart-define-from-file=config/app_env.json
```

## Security rules

All access control is in `firestore.rules`. After editing:

```powershell
firebase deploy --only firestore:rules --project mtalchemy-ee353
```

Check them locally first with the emulator and `e2e/t_rules.js` (23 checks for privilege escalation and data isolation).

## Seeding or resetting demo data

```powershell
cd firebase_seed
node seed.js --emulator                         # local emulator
node seed_rest.js --project mtalchemy-ee353      # real project, uses your `gcloud auth login`
```

If you change starter products or courses in Dart, regenerate `seed_data.json` with `flutter test tool/export_seed_test.dart`.

## Chatbot

The assistant calls Gemini (`GEMINI_MODEL`, default `gemini-3.5-flash`, falling back to `gemini-3.1-flash-lite` when busy). Its knowledge comes from `buildSystemPrompt()` in `lib/chat/chat_service.dart` (services, live courses and products, the user's role). Without a key, or when Google's free quota is used up, it answers from `OfflineAssistant`. Restrict the key in Google Cloud Console to the Generative Language API and your site's domain.

## Payments

Stripe Checkout through `payments_server/` (Node + Express + Stripe SDK):

- `POST /api/checkout-session` creates a hosted checkout page for an order (currency MYR; return URLs must match `ALLOWED_ORIGINS`).
- `GET /api/checkout-session/:id` lets the app confirm with Stripe that a session was paid before marking the order Paid.
- Keys: `payments_server/.env` (`STRIPE_SECRET_KEY`, test key `sk_test_...`). Rotate keys in the Stripe dashboard if they are ever shared.
- Security rule: a customer may only change their own Pending/Failed order to Paid. For production, add a Stripe webhook (`checkout.session.completed`) on the server that updates Firestore with admin credentials, and remove the client-side update permission.

## Tests

```powershell
flutter analyze
flutter test                     # 38 unit/widget tests on an in-memory Firestore
```

Browser end-to-end scripts are in `e2e/` (Playwright + Chrome). Build with `--dart-define=ENABLE_SEMANTICS=true`, serve `build/web` on port 8085, start and seed the emulators, then `node e2e/t_journeyA.js` (and `t_journeyBC.js`, `t_journeyDE.js`, `t_admin_users.js`, `t_rules.js`).
