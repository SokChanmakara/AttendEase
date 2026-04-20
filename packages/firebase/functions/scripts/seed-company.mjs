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

async function seedLocations(companyRef, args) {
  const locationId = String(args.locationId ?? "hq");
  const locationName = String(args.locationName ?? "Headquarters");
  const latitude = Number(args.locationLat ?? 11.5564);
  const longitude = Number(args.locationLng ?? 104.9282);
  const radius = Number(args.locationRadiusM ?? 300);

  await companyRef.collection("locations").doc(locationId).set(
    {
      name: locationName,
      latitude,
      longitude,
      proximity_radius_m: radius,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return { locationId, locationName, latitude, longitude, radius };
}

async function seedDepartments(companyRef) {
  const departments = [
    { id: "operations", name: "Operations" },
    { id: "hr", name: "Human Resources" },
    { id: "finance", name: "Finance" },
  ];

  const batch = db.batch();
  for (const dep of departments) {
    batch.set(
      companyRef.collection("departments").doc(dep.id),
      {
        name: dep.name,
        manager_uid: null,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
  await batch.commit();

  return departments.map((d) => d.id);
}

async function seedLeaveTypes(companyRef) {
  const leaveTypes = [
    { id: "annual", name: "Annual Leave", days_per_year: 18 },
    { id: "sick", name: "Sick Leave", days_per_year: 10 },
    { id: "unpaid", name: "Unpaid Leave", days_per_year: 0 },
  ];

  const batch = db.batch();
  for (const type of leaveTypes) {
    batch.set(
      companyRef.collection("leave_types").doc(type.id),
      {
        name: type.name,
        days_per_year: type.days_per_year,
        is_active: true,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
  await batch.commit();

  return leaveTypes.map((t) => t.id);
}

async function seedNotificationSettings(companyRef) {
  const settings = [
    {
      id: "attendance_reminder",
      enabled: true,
      send_time: "08:00",
      working_days: ["mon", "tue", "wed", "thu", "fri"],
      title_template: "Check-in reminder",
      body_template: "Hi {{first_name}}, please check in when you arrive.",
      notify_team: false,
    },
    {
      id: "birthday",
      enabled: true,
      send_time: "09:00",
      working_days: [],
      title_template: "Happy Birthday, {{first_name}} 🎉",
      body_template: "Wishing you a great year ahead from AttendEase!",
      notify_team: true,
    },
    {
      id: "anniversary",
      enabled: true,
      send_time: "09:30",
      working_days: [],
      title_template: "Work Anniversary 🎊",
      body_template: "Congrats {{first_name}} on your work anniversary!",
      notify_team: true,
    },
  ];

  const batch = db.batch();
  for (const setting of settings) {
    batch.set(
      companyRef.collection("notification_settings").doc(setting.id),
      setting,
      { merge: true },
    );
  }
  await batch.commit();

  return settings.map((s) => s.id);
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
  const companyRef = db.collection("companies").doc(companyId);

  const [location, departments, leaveTypes, notificationSettings] =
    await Promise.all([
      seedLocations(companyRef, args),
      seedDepartments(companyRef),
      seedLeaveTypes(companyRef),
      seedNotificationSettings(companyRef),
    ]);

  console.log("✅ Company seed complete");
  console.log(
    JSON.stringify(
      {
        companyId,
        location,
        departments,
        leaveTypes,
        notificationSettings,
      },
      null,
      2,
    ),
  );
}

main().catch((error) => {
  console.error("❌ Seeding failed");
  console.error(error);
  console.error(
    "Tip: Ensure GOOGLE_APPLICATION_CREDENTIALS points to a valid service-account JSON and pass --projectId when needed.",
  );
  process.exit(1);
});
