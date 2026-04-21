# AttendEase Firebase

Firebase project config, security rules, and Cloud Functions for AttendEase.

## Contents

- `firestore.rules`
- `storage.rules`
- `functions/`

## Deploy

```bash
firebase deploy --only firestore:rules,storage,functions
```

Run deploy commands from `packages/firebase`.

## Functions

Build from the repo root:

```bash
npm run build:functions
```

Or from `packages/firebase/functions`:

```bash
npm run build
```
