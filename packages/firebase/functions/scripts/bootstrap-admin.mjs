import admin from "firebase-admin";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
let db;

function parseArgs(argv) {
  const out = {};
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (!arg.startsWith("--")) continue;

    const trimmed = arg.slice(2);
    if (trimmed.includes("=")) {
      const [key, ...rest] = trimmed.split("=");
      out[key] = rest.join("=");
      continue;
    }

    const next = argv[i + 1];
    if (!next || next.startsWith("--")) {
      out[trimmed] = true;
    } else {
      out[trimmed] = next;
      i += 1;
    }
  }
  return out;
}

function readProjectIdFromFirebaserc() {
  try {
    const firebasercPath = path.resolve(__dirname, "../../.firebaserc");
    const raw = fs.readFileSync(firebasercPath, "utf8");
    const parsed = JSON.parse(raw);
    const projectId = parsed?.projects?.default;
    if (!projectId || projectId === "replace-with-your-firebase-project-id") {
      return null;
    }
    return String(projectId);
  } catch {
    return null;
  }
}

function resolveProjectId(args) {
  return (
    args.projectId ??
    process.env.GOOGLE_CLOUD_PROJECT ??
    process.env.GCLOUD_PROJECT ??
    process.env.FIREBASE_PROJECT_ID ??
    readProjectIdFromFirebaserc() ??
    null
  );
}

function applyCredentialsArg(args) {
  const credentialsPath = args.credentials;
  if (!credentialsPath) return;

  const resolved = path.resolve(String(credentialsPath));
  if (!fs.existsSync(resolved)) {
    throw new Error(`Credentials file not found: ${resolved}`);
  }
  process.env.GOOGLE_APPLICATION_CREDENTIALS = resolved;
}

function required(args, key) {
  const value = args[key];
  if (!value || value === true) {
    throw new Error(`Missing required argument --${key}`);
  }
  return String(value);
}

async function upsertCompany({
  companyId,
  companyName,
  timezone,
  cutoffTime,
  radiusM,
  qrRefreshInterval,
}) {
  await db.collection("companies").doc(companyId).set(
    {
      name: companyName,
      timezone,
      proximity_radius_m: radiusM,
      qr_refresh_interval: qrRefreshInterval,
      auto_close_cutoff_time: cutoffTime,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

async function resolveOrCreateAuthUser({
  email,
  password,
  firstName,
  lastName,
}) {
  try {
    const existing = await admin.auth().getUserByEmail(email);
    if (password) {
      await admin.auth().updateUser(existing.uid, {
        password,
        displayName: `${firstName} ${lastName}`.trim(),
      });
    }
    return { uid: existing.uid, created: false };
  } catch (error) {
    if (error?.code !== "auth/user-not-found") {
      throw error;
    }

    const created = await admin.auth().createUser({
      email,
      password,
      displayName: `${firstName} ${lastName}`.trim(),
      emailVerified: true,
    });

    return { uid: created.uid, created: true };
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  applyCredentialsArg(args);
  const projectId = resolveProjectId(args);

  if (!projectId) {
    throw new Error(
      "Missing Firebase project ID. Provide --projectId, or set GOOGLE_CLOUD_PROJECT, or set packages/firebase/.firebaserc projects.default.",
    );
  }

  if (!admin.apps.length) {
    admin.initializeApp({ projectId });
  }

  db = admin.firestore();

  const companyId = required(args, "companyId");
  const companyName = required(args, "companyName");
  const email = required(args, "email");
  const password = required(args, "password");

  const firstName = String(args.firstName ?? "Admin");
  const lastName = String(args.lastName ?? "User");
  const timezone = String(args.timezone ?? "UTC");
  const cutoffTime = String(args.cutoffTime ?? "23:59");
  const radiusM = Number(args.radiusM ?? 300);
  const qrRefreshInterval = Number(args.qrRefreshInterval ?? 15);

  await upsertCompany({
    companyId,
    companyName,
    timezone,
    cutoffTime,
    radiusM,
    qrRefreshInterval,
  });

  const { uid, created } = await resolveOrCreateAuthUser({
    email,
    password,
    firstName,
    lastName,
  });

  await admin.auth().setCustomUserClaims(uid, {
    role: "admin",
    company_id: companyId,
  });

  await db.collection("users").doc(uid).set(
    {
      company_id: companyId,
      first_name: firstName,
      last_name: lastName,
      email,
      role: "admin",
      is_active: true,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      start_date: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  console.log("✅ Bootstrap complete");
  console.log(
    JSON.stringify(
      {
        companyId,
        companyName,
        adminUid: uid,
        adminEmail: email,
        authUserCreated: created,
        role: "admin",
      },
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error("❌ Bootstrap failed");
  console.error(error);
  if (error?.code === "auth/configuration-not-found") {
    console.error(
      "Auth is not configured for this project. In Firebase Console, open project 'attendease-dev' -> Authentication -> Get started, then enable Email/Password provider.",
    );
    console.error(
      "Also ensure this GCP project is linked as a Firebase project (not Firestore-only).",
    );
  }
  console.error(
    "Tip: If your command contains spaces, keep values quoted. Also ensure GOOGLE_APPLICATION_CREDENTIALS points to a valid service-account JSON.",
  );
  process.exit(1);
});
