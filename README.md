# AttendEase Monorepo

Firebase-first scaffold from the architecture document.

## Structure

- `packages/mobile` — Flutter app scaffold (Melos)
- `packages/web-admin` — Nuxt 3 admin app
- `packages/firebase` — Firebase config, rules, functions

## Use npm (JS/TS)

From repo root:

1. Install dependencies
   - `npm install`
2. Run admin app
   - `npm run dev:web`
3. Build Cloud Functions
   - `npm run build:functions`

## Firebase setup

1. Set your Firebase project ID in `packages/firebase/.firebaserc`.
2. Set function secret:
   - `firebase functions:secrets:set QR_SIGNING_SECRET`
3. Deploy from `packages/firebase`:
   - `firebase deploy --only firestore:rules,storage,functions`

## Web admin Firebase env

Set these env vars before running `npm run dev:web`:

- `NUXT_PUBLIC_FIREBASE_API_KEY`
- `NUXT_PUBLIC_FIREBASE_AUTH_DOMAIN`
- `NUXT_PUBLIC_FIREBASE_PROJECT_ID`
- `NUXT_PUBLIC_FIREBASE_APP_ID`
- `NUXT_PUBLIC_FIREBASE_FUNCTIONS_REGION` (optional, defaults to `us-central1`)

Quick setup:

1. Copy [packages/web-admin/.env.example](packages/web-admin/.env.example) to `packages/web-admin/.env`
2. Fill values from Firebase Console → Project settings → Your apps (Web app)
3. Restart `npm run dev:web`

The admin home page includes:

- email/password admin sign-in
- callable trigger for QR force rotation (`forceRotateQrToken`)

## Auth claims bootstrap + initial seed

Before running bootstrap commands, authenticate with Firebase Admin credentials (for example by setting `GOOGLE_APPLICATION_CREDENTIALS`).

1. Bootstrap company + first admin (creates auth user, sets custom claims, writes `users/{uid}`):
   - `npm run bootstrap:admin -- --companyId=acme --companyName="Acme Co" --email=admin@acme.com --password="ChangeMe123!" --firstName=System --lastName=Admin --timezone=UTC`

2. Seed initial company data (`locations`, `departments`, `leave_types`, `notification_settings`):
   - `npm run seed:company -- --companyId=acme --locationId=hq --locationName="HQ" --locationLat=11.5564 --locationLng=104.9282`

3. Optional: update role claims from app/backend via callable `setUserClaims` in [packages/firebase/functions/src/index.ts](packages/firebase/functions/src/index.ts).

## Flutter setup

- Install Flutter + Melos
- Run `melos bootstrap` from repo root
- Run app in `packages/mobile`
