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

## Flutter setup

- Install Flutter + Melos
- Run `melos bootstrap` from repo root
- Run app in `packages/mobile`
