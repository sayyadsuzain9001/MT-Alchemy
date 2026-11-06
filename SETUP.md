# Setup guide: API keys, authorization and deployment

Read this **before running the project** after cloning it. It lists every key the app needs, where to get it, where to put it, which accounts must authorize what, and what to rename when you deploy under your own name.

> **Never commit real keys.** `config/app_env.json` and `payments_server/.env` are git-ignored on purpose. Only the `*.example*` files belong in Git.

---

## 1. Overview: what needs a key

| Service | Needed for | Required? | Where the key goes |
| --- | --- | --- | --- |
| Firebase (Auth + Firestore) | Sign-in, all data | **Yes** (or use the local emulator) | `config/app_env.json` |
| Google Gemini | Alchemy Assistant chatbot | Optional (falls back to built-in answers) | `config/app_env.json` |
| Stripe | Real card checkout (test mode) | Optional (falls back to built-in test gateway) | `payments_server/.env` (secret) + `config/app_env.json` (server URL) |
| Google Cloud CLI login | Seeding demo data into a real project | Only for seeding | Your terminal (`gcloud auth login`) |
| GitHub repository secrets | Automatic deploy with GitHub Actions | Only for deploying | GitHub → Settings → Secrets |

### Files you create from examples

```powershell
copy config\app_env.example.json config\app_env.json
copy payments_server\.env.example payments_server\.env
```

---

## 2. Firebase

### 2.1 Create the project

1. Go to <https://console.firebase.google.com> and click **Add project** (the free **Spark** plan is enough).
2. **Build → Authentication → Get started → Sign-in method:** enable **Email/Password**.
3. **Build → Firestore Database → Create database:** production mode, pick a region close to your users (e.g. `asia-southeast1`).
4. **Project settings (gear) → General → Your apps → Add app → Web (`</>`):** give it a name, register it and copy the `firebaseConfig` values.

### 2.2 Put the config in `config/app_env.json`

| Key | Where to find it (Firebase `firebaseConfig`) | Example |
| --- | --- | --- |
| `FIREBASE_API_KEY` | `apiKey` | `AIza...` |
| `FIREBASE_PROJECT_ID` | `projectId` | `my-project-id` |
| `FIREBASE_APP_ID` | `appId` | `1:1234567890:web:abc123` |
| `FIREBASE_MESSAGING_SENDER_ID` | `messagingSenderId` | `1234567890` |
| `FIREBASE_AUTH_DOMAIN` | `authDomain` | `my-project-id.firebaseapp.com` |
| `FIREBASE_STORAGE_BUCKET` | `storageBucket` | `my-project-id.firebasestorage.app` |

Leave `FIREBASE_API_KEY` **empty** to run against the local Firebase emulators instead (no cloud project needed; see README → Quick start).

### 2.3 Deploy the security rules

```powershell
npm install -g firebase-tools
firebase login
firebase deploy --only firestore:rules --project <your-project-id>
```

Without this step every read and write is blocked by Firestore's default rules.

### 2.4 Authorize the domains that may sign in

**Authentication → Settings → Authorized domains → Add domain.** Add every address where the app runs:

| Where the app runs | Domain to add |
| --- | --- |
| Local development | `localhost` (added by default) |
| GitHub Pages | `<your-github-username>.github.io` |
| Firebase Hosting | `<project-id>.web.app` and `<project-id>.firebaseapp.com` (added by default) |
| Your own domain | e.g. `www.example.com` |

If a domain is missing, sign-in fails with `auth/unauthorized-domain`.

### 2.5 Create demo accounts and starter data (optional)

Admin and Trainer accounts cannot be self-registered, so seed them:

```powershell
gcloud auth login                     # sign in as an owner of the Firebase project
cd firebase_seed
npm install
node seed_rest.js --project <your-project-id>
```

This creates the demo accounts listed in the README plus products, courses, employees and assignments. To use a service-account key instead: Firebase console → Project settings → Service accounts → **Generate new private key**, then

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\service-account.json"   # never commit this file
node seed.js --project <your-project-id>
```

**Change the demo passwords** in `firebase_seed/seed_accounts.js` before seeding a project other people can reach.

---

## 3. Google Gemini (AI assistant)

1. Go to <https://aistudio.google.com/app/apikey> and click **Create API key** (free tier).
2. Put it in `config/app_env.json`:
   ```json
   "GEMINI_API_KEY": "your-key",
   "GEMINI_MODEL": "gemini-3.5-flash"
   ```
3. **Restrict the key** (important, because a web app's key is visible in the browser): Google Cloud Console → **APIs & Services → Credentials →** your key →
   - *API restrictions:* **Generative Language API** only.
   - *Application restrictions:* **Websites**, add your site addresses (e.g. `http://localhost:*/*`, `https://<username>.github.io/*`).

Models change over time. If the API says a model is no longer available, set `GEMINI_MODEL` to a current one (the app also falls back to `gemini-3.1-flash-lite`). Without a key the assistant still answers common questions from its built-in knowledge.

---

## 4. Stripe (card payments, test mode)

The Stripe **secret key must never be in the Flutter app or in Git.** It lives only in the small payment server.

1. Create a free account at <https://dashboard.stripe.com> and stay in **Test mode**.
2. **Developers → API keys:** copy the **Secret key** (`sk_test_...`). The publishable key is not needed (the app uses Stripe-hosted Checkout).
3. Put it in `payments_server/.env`:
   ```env
   STRIPE_SECRET_KEY=sk_test_...
   PORT=4242
   ALLOWED_ORIGINS=http://localhost:8090,https://<your-github-username>.github.io
   ```
   `ALLOWED_ORIGINS` lists every web address allowed to start a payment and to receive the customer back after paying. **Add your deployed site here**, or payments are refused.
4. Start the server:
   ```powershell
   cd payments_server
   npm install
   npm start          # http://localhost:4242
   ```
5. Tell the app where the server is, in `config/app_env.json`:
   ```json
   "PAYMENTS_API_URL": "http://localhost:4242"
   ```
6. Test with card `4242 4242 4242 4242`, any future expiry date and any CVC.

For the public site, host `payments_server` somewhere reachable (for example Render, Railway or Google Cloud Run), set `STRIPE_SECRET_KEY` and `ALLOWED_ORIGINS` in that host's environment settings, and use its URL as `PAYMENTS_API_URL`. Leave `PAYMENTS_API_URL` empty to use the built-in test gateway instead.

**If a secret key is ever shared** (chat, email, screenshot), roll it in Stripe: Developers → API keys → **Roll key**.

---

## 5. Run locally

```powershell
flutter pub get
flutter run -d chrome --dart-define-from-file=config/app_env.json
```

Or start everything (emulators, seed, payment server, app) with:

```powershell
powershell -ExecutionPolicy Bypass -File tool\dev.ps1
```

---

## 6. Deploy with GitHub Actions (GitHub Pages)

The workflow is [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml). On every push to `main` it analyzes the code, runs the tests, builds the web app and publishes it to GitHub Pages.

### 6.1 Change these names for your own deployment

| What | Where | Change to |
| --- | --- | --- |
| Site path (base href) | Set automatically from the repository name in `deploy.yml` (`/${{ github.event.repository.name }}/`) | Nothing to change, unless you use a custom domain: then replace it with `/` |
| Badge and links | `README.md` (`sayyadsuzain9001/MT-Alchemy`) | `<your-github-username>/<your-repo-name>` |
| Public site address | `README.md`, this file | `https://<your-github-username>.github.io/<your-repo-name>/` |
| Firebase project | GitHub secret `FIREBASE_PROJECT_ID`, `.firebaserc` if you add one | Your Firebase project ID |
| Authorized domain | Firebase → Authentication → Authorized domains | `<your-github-username>.github.io` |
| Stripe allowed origins | `payments_server/.env` (or the host's environment) → `ALLOWED_ORIGINS` | `https://<your-github-username>.github.io` |
| Gemini key restriction | Google Cloud Console → Credentials | `https://<your-github-username>.github.io/*` |
| App title | `web/index.html` (`<title>`), `web/manifest.json` (`name`, `short_name`) | Your app name |

### 6.2 One-time GitHub setup

1. **Settings → Pages → Build and deployment → Source: GitHub Actions.**
2. **Settings → Secrets and variables → Actions → New repository secret**, add:

   | Secret | Value | Required |
   | --- | --- | --- |
   | `FIREBASE_API_KEY` | Firebase `apiKey` | Yes |
   | `FIREBASE_PROJECT_ID` | Firebase `projectId` | Yes |
   | `FIREBASE_APP_ID` | Firebase `appId` | Yes |
   | `FIREBASE_MESSAGING_SENDER_ID` | Firebase `messagingSenderId` | Yes |
   | `GEMINI_API_KEY` | Gemini key | Optional |
   | `PAYMENTS_API_URL` | URL of your hosted `payments_server` | Optional |

3. Add `<your-github-username>.github.io` to Firebase **Authorized domains** (section 2.4).
4. **Actions → Test and deploy → Run workflow**, or push to `main`.

Until the Firebase secrets exist, the workflow still runs the tests and skips the deploy with a warning.

### 6.3 Alternative: Firebase Hosting

```powershell
flutter build web --dart-define-from-file=config/app_env.json
firebase deploy --only hosting --project <your-project-id>
```

The site is then at `https://<project-id>.web.app` (already an authorized domain).

---

## 7. Checklist before you run or deploy

- [ ] `config/app_env.json` created from the example and filled in
- [ ] Firebase Email/Password sign-in enabled and Firestore database created
- [ ] `firestore.rules` deployed
- [ ] Demo data seeded (optional) and demo passwords changed for shared projects
- [ ] Your site's domain added to Firebase **Authorized domains**
- [ ] Gemini key created and restricted (optional)
- [ ] `payments_server/.env` created with `sk_test_...` and `ALLOWED_ORIGINS` including your site (optional)
- [ ] GitHub Pages source set to **GitHub Actions** and repository secrets added (for deployment)
- [ ] Names and URLs in section 6.1 changed to yours

## 8. Common problems

| Message or symptom | Fix |
| --- | --- |
| `auth/unauthorized-domain` | Add the site's domain in Firebase → Authentication → Authorized domains |
| `permission-denied` in the app | Deploy `firestore.rules`; make sure the account has a profile in `users` (register again or re-seed) |
| "Running in emulator mode" banner | `FIREBASE_API_KEY` is empty, so the app uses the local emulators |
| Assistant says "busy" or gives short built-in answers | Gemini key missing, restricted to the wrong site, quota reached, or the model name is outdated |
| "Card payment is unavailable right now" | `payments_server` not running, wrong `PAYMENTS_API_URL`, or your site missing from `ALLOWED_ORIGINS` |
| GitHub Pages shows a blank page | Check the Actions log; the base href must match the repository name (handled automatically) |
| Deploy job says "Deploy skipped" | Add the `FIREBASE_*` repository secrets |
