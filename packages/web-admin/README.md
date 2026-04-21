# AttendEase Web Admin

Nuxt 3 admin app for attendance operations, employee management, QR management, and settings.

## Run

```bash
npm run dev
```

Run commands from `packages/web-admin`, or use `npm run dev:web` from the repo root.

## Required env

Copy `.env.example` to `.env` and fill the Firebase web app values:

- `NUXT_PUBLIC_FIREBASE_API_KEY`
- `NUXT_PUBLIC_FIREBASE_AUTH_DOMAIN`
- `NUXT_PUBLIC_FIREBASE_PROJECT_ID`
- `NUXT_PUBLIC_FIREBASE_APP_ID`
- `NUXT_PUBLIC_FIREBASE_FUNCTIONS_REGION`
