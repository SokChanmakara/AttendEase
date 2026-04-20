import * as crypto from 'node:crypto';
import * as jwt from 'jsonwebtoken';
import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { defineSecret } from 'firebase-functions/params';

admin.initializeApp();

const db = admin.firestore();
const QR_SIGNING_SECRET = defineSecret('QR_SIGNING_SECRET');

type Role = 'admin' | 'manager' | 'employee';

function isRole(value: unknown): value is Role {
    return value === 'admin' || value === 'manager' || value === 'employee';
}

interface QrPayload {
    companyId: string;
    locationId: string;
    iat?: number;
    exp?: number;
}

function assertAuthed(auth: unknown): asserts auth is { uid: string; token: { role?: Role; company_id?: string } } {
    if (!auth) {
        throw new HttpsError('unauthenticated', 'Authentication required.');
    }
}

function assertAdmin(auth: { token?: { role?: Role } }): void {
    if (auth.token?.role !== 'admin') {
        throw new HttpsError('permission-denied', 'Admin role required.');
    }
}

export const setUserClaims = onCall(async (request) => {
    assertAuthed(request.auth);
    assertAdmin(request.auth);

    const { uid, role, companyId } = request.data as {
        uid?: string;
        role?: Role;
        companyId?: string;
    };

    if (!uid || !role || !companyId) {
        throw new HttpsError('invalid-argument', 'uid, role, and companyId are required.');
    }
    if (!isRole(role)) {
        throw new HttpsError('invalid-argument', 'role must be one of: admin, manager, employee.');
    }

    await admin.auth().setCustomUserClaims(uid, {
        role,
        company_id: companyId
    });

    await db
        .collection('users')
        .doc(uid)
        .set(
            {
                role,
                company_id: companyId,
                updated_at: admin.firestore.FieldValue.serverTimestamp()
            },
            { merge: true }
        );

    return { ok: true, uid, role, companyId };
});

function haversineDistanceMeters(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const toRad = (v: number): number => (v * Math.PI) / 180;
    const R = 6371000;
    const dLat = toRad(lat2 - lat1);
    const dLng = toRad(lng2 - lng1);
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}

function ymdInTimezone(date: Date, timeZone: string): string {
    const parts = new Intl.DateTimeFormat('en-CA', {
        timeZone,
        year: 'numeric',
        month: '2-digit',
        day: '2-digit'
    }).formatToParts(date);
    const year = parts.find((p) => p.type === 'year')?.value;
    const month = parts.find((p) => p.type === 'month')?.value;
    const day = parts.find((p) => p.type === 'day')?.value;
    return `${year}-${month}-${day}`;
}

function hmInTimezone(date: Date, timeZone: string): string {
    const parts = new Intl.DateTimeFormat('en-GB', {
        timeZone,
        hour: '2-digit',
        minute: '2-digit',
        hourCycle: 'h23'
    }).formatToParts(date);
    const hour = parts.find((p) => p.type === 'hour')?.value;
    const minute = parts.find((p) => p.type === 'minute')?.value;
    return `${hour}:${minute}`;
}

function weekdayInTimezone(date: Date, timeZone: string): string {
    return new Intl.DateTimeFormat('en-US', { timeZone, weekday: 'short' }).format(date).toLowerCase();
}

export const generateQrToken = onCall({ secrets: [QR_SIGNING_SECRET] }, async (request) => {
    assertAuthed(request.auth);
    assertAdmin(request.auth);

    const { companyId, locationId } = request.data as { companyId?: string; locationId?: string };
    if (!companyId || !locationId) {
        throw new HttpsError('invalid-argument', 'companyId and locationId are required.');
    }

    const companyRef = db.collection('companies').doc(companyId);
    const companySnap = await companyRef.get();
    if (!companySnap.exists) {
        throw new HttpsError('not-found', 'Company not found.');
    }

    const company = companySnap.data() as { qr_refresh_interval?: number };
    const refreshMinutes = company.qr_refresh_interval ?? 15;

    const token = jwt.sign(
        {
            companyId,
            locationId
        } as QrPayload,
        QR_SIGNING_SECRET.value(),
        { algorithm: 'HS256', expiresIn: `${refreshMinutes}m` }
    );

    const payloadHash = crypto.createHash('sha256').update(token).digest('hex');
    await companyRef.collection('qr_codes').doc(locationId).set(
        {
            payload_hash: payloadHash,
            issued_at: admin.firestore.FieldValue.serverTimestamp(),
            expires_at: admin.firestore.Timestamp.fromDate(new Date(Date.now() + refreshMinutes * 60_000)),
            is_active: true
        },
        { merge: true }
    );

    return { token, expiresInMinutes: refreshMinutes };
});

export const checkIn = onCall({ secrets: [QR_SIGNING_SECRET] }, async (request) => {
    assertAuthed(request.auth);

    const { uid, token } = request.auth;
    const {
        companyId,
        locationId,
        qrToken,
        latitude,
        longitude,
        accuracyM,
        isMockLocation
    } = request.data as {
        companyId?: string;
        locationId?: string;
        qrToken?: string;
        latitude?: number;
        longitude?: number;
        accuracyM?: number;
        isMockLocation?: boolean;
    };

    if (!companyId || !locationId || !qrToken || latitude == null || longitude == null) {
        throw new HttpsError('invalid-argument', 'Missing check-in payload.');
    }

    if (isMockLocation === true) {
        throw new HttpsError('permission-denied', 'Mock location detected.');
    }

    let decoded: QrPayload;
    try {
        decoded = jwt.verify(qrToken, QR_SIGNING_SECRET.value()) as QrPayload;
    } catch {
        throw new HttpsError('failed-precondition', 'QR code expired or invalid.');
    }

    if (decoded.companyId !== companyId || decoded.locationId !== locationId) {
        throw new HttpsError('failed-precondition', 'QR payload mismatch.');
    }

    const companyRef = db.collection('companies').doc(companyId);
    const [companySnap, locationSnap, userSnap] = await Promise.all([
        companyRef.get(),
        companyRef.collection('locations').doc(locationId).get(),
        db.collection('users').doc(uid).get()
    ]);

    if (!companySnap.exists || !locationSnap.exists || !userSnap.exists) {
        throw new HttpsError('not-found', 'Required company/location/user records missing.');
    }

    const company = companySnap.data() as { proximity_radius_m?: number };
    const location = locationSnap.data() as { latitude: number; longitude: number; proximity_radius_m?: number };
    const user = userSnap.data() as { first_name?: string; last_name?: string; department_id?: string };

    const distance = haversineDistanceMeters(latitude, longitude, location.latitude, location.longitude);
    const radius = location.proximity_radius_m ?? company.proximity_radius_m ?? 300;

    const scanLogRef = companyRef.collection('qr_scan_log').doc();
    if (distance > radius) {
        await scanLogRef.set({
            user_id: uid,
            qr_code_id: locationId,
            scanned_at: admin.firestore.FieldValue.serverTimestamp(),
            gps_lat: latitude,
            gps_lng: longitude,
            distance_m: distance,
            success: false,
            failure_reason: 'outside_radius'
        });
        throw new HttpsError('failed-precondition', 'You are outside the allowed radius.');
    }

    const openShiftQuery = await companyRef
        .collection('attendance')
        .where('user_id', '==', uid)
        .where('check_out_at', '==', null)
        .limit(1)
        .get();

    if (!openShiftQuery.empty) {
        throw new HttpsError('already-exists', 'User already has an open attendance record.');
    }

    const attendanceRef = companyRef.collection('attendance').doc();
    await attendanceRef.set({
        user_id: uid,
        user_name: `${user.first_name ?? ''} ${user.last_name ?? ''}`.trim(),
        department_id: user.department_id ?? null,
        location_id: locationId,
        check_in_at: admin.firestore.FieldValue.serverTimestamp(),
        check_out_at: null,
        check_in_lat: latitude,
        check_in_lng: longitude,
        check_in_distance_m: distance,
        hours_worked: 0,
        status: 'present',
        gps_accuracy_flagged: (accuracyM ?? 0) > 100,
        auto_closed: false
    });

    await scanLogRef.set({
        user_id: uid,
        qr_code_id: locationId,
        scanned_at: admin.firestore.FieldValue.serverTimestamp(),
        gps_lat: latitude,
        gps_lng: longitude,
        distance_m: distance,
        success: true,
        failure_reason: null
    });

    return { ok: true, attendanceId: attendanceRef.id, distanceM: distance };
});

export const checkOut = onCall(async (request) => {
    assertAuthed(request.auth);

    const { companyId } = request.data as { companyId?: string };
    if (!companyId) {
        throw new HttpsError('invalid-argument', 'companyId is required.');
    }

    const uid = request.auth.uid;
    const companyRef = db.collection('companies').doc(companyId);
    const openShift = await companyRef
        .collection('attendance')
        .where('user_id', '==', uid)
        .where('check_out_at', '==', null)
        .orderBy('check_in_at', 'desc')
        .limit(1)
        .get();

    if (openShift.empty) {
        throw new HttpsError('not-found', 'No open attendance record found.');
    }

    const record = openShift.docs[0];
    const data = record.data() as { check_in_at?: admin.firestore.Timestamp };

    const checkInDate = data.check_in_at?.toDate() ?? new Date();
    const checkOutDate = new Date();
    const hoursWorked = Math.max(0, (checkOutDate.getTime() - checkInDate.getTime()) / 3_600_000);

    await record.ref.update({
        check_out_at: admin.firestore.FieldValue.serverTimestamp(),
        hours_worked: Number(hoursWorked.toFixed(2)),
        status: 'completed'
    });

    return { ok: true, attendanceId: record.id, hoursWorked: Number(hoursWorked.toFixed(2)) };
});

export const adminCorrectAttendance = onCall(async (request) => {
    assertAuthed(request.auth);
    assertAdmin(request.auth);

    const {
        companyId,
        attendanceId,
        checkInAt,
        checkOutAt,
        reason
    } = request.data as {
        companyId?: string;
        attendanceId?: string;
        checkInAt?: string;
        checkOutAt?: string;
        reason?: string;
    };

    if (!companyId || !attendanceId) {
        throw new HttpsError('invalid-argument', 'companyId and attendanceId are required.');
    }

    const attendanceRef = db.collection('companies').doc(companyId).collection('attendance').doc(attendanceId);
    const snap = await attendanceRef.get();
    if (!snap.exists) {
        throw new HttpsError('not-found', 'Attendance record not found.');
    }

    const oldValue = snap.data();
    const newValue: Record<string, unknown> = {};

    if (checkInAt) {
        newValue.check_in_at = admin.firestore.Timestamp.fromDate(new Date(checkInAt));
    }
    if (checkOutAt) {
        newValue.check_out_at = admin.firestore.Timestamp.fromDate(new Date(checkOutAt));
    }

    await attendanceRef.update(newValue);

    await db.collection('companies').doc(companyId).collection('audit_log').add({
        action: 'attendance_manual_correction',
        performed_by_uid: request.auth.uid,
        target_collection: 'attendance',
        target_id: attendanceId,
        old_value: oldValue,
        new_value: newValue,
        reason: reason ?? null,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    return { ok: true };
});

export const autoCloseShifts = onSchedule('every 15 minutes', async () => {
    const now = new Date();
    const companies = await db.collection('companies').get();

    for (const companyDoc of companies.docs) {
        const company = companyDoc.data() as { timezone?: string; auto_close_cutoff_time?: string };
        const tz = company.timezone ?? 'UTC';
        const cutoff = company.auto_close_cutoff_time ?? '23:59';
        const nowHm = hmInTimezone(now, tz);

        if (nowHm < cutoff) {
            continue;
        }

        const openShifts = await companyDoc.ref.collection('attendance').where('check_out_at', '==', null).get();
        if (openShifts.empty) {
            continue;
        }

        const batch = db.batch();
        for (const doc of openShifts.docs) {
            const data = doc.data() as { check_in_at?: admin.firestore.Timestamp };
            const checkInDate = data.check_in_at?.toDate() ?? now;
            const hoursWorked = Math.max(0, (now.getTime() - checkInDate.getTime()) / 3_600_000);
            batch.update(doc.ref, {
                check_out_at: admin.firestore.Timestamp.fromDate(now),
                hours_worked: Number(hoursWorked.toFixed(2)),
                status: 'auto_closed',
                auto_closed: true
            });
            batch.set(companyDoc.ref.collection('audit_log').doc(), {
                action: 'attendance_auto_closed',
                performed_by_uid: 'system',
                target_collection: 'attendance',
                target_id: doc.id,
                old_value: { check_out_at: null },
                new_value: { check_out_at: now.toISOString(), auto_closed: true },
                timestamp: admin.firestore.FieldValue.serverTimestamp()
            });
        }
        await batch.commit();
    }
});

export const sendScheduledNotifications = onSchedule('every 15 minutes', async () => {
    const now = new Date();
    const companies = await db.collection('companies').get();

    for (const companyDoc of companies.docs) {
        const company = companyDoc.data() as { timezone?: string };
        const tz = company.timezone ?? 'UTC';
        const today = ymdInTimezone(now, tz);
        const currentHm = hmInTimezone(now, tz);
        const weekday = weekdayInTimezone(now, tz);

        const settingsSnap = await companyDoc.ref.collection('notification_settings').get();
        for (const settingDoc of settingsSnap.docs) {
            const setting = settingDoc.data() as {
                enabled?: boolean;
                send_time?: string;
                working_days?: string[];
                title_template?: string;
                body_template?: string;
            };
            if (!setting.enabled) continue;
            if (setting.send_time !== currentHm) continue;
            if (Array.isArray(setting.working_days) && setting.working_days.length > 0 && !setting.working_days.includes(weekday)) {
                continue;
            }

            const users = await db
                .collection('users')
                .where('company_id', '==', companyDoc.id)
                .where('is_active', '==', true)
                .get();

            for (const userDoc of users.docs) {
                const user = userDoc.data() as { first_name?: string };
                const guardRef = companyDoc.ref.collection('notification_log').doc(`${userDoc.id}_${settingDoc.id}_${today}`);
                const guardSnap = await guardRef.get();
                if (guardSnap.exists) continue;

                const tokensSnap = await userDoc.ref.collection('tokens').get();
                const tokens = tokensSnap.docs.map((d) => (d.data() as { token?: string }).token).filter(Boolean) as string[];

                const title = (setting.title_template ?? 'AttendEase').replace('{{first_name}}', user.first_name ?? '');
                const body = (setting.body_template ?? 'You have an update from AttendEase.').replace(
                    '{{first_name}}',
                    user.first_name ?? ''
                );

                if (tokens.length > 0) {
                    await admin.messaging().sendEachForMulticast({
                        tokens,
                        notification: { title, body }
                    });
                }

                const batch = db.batch();
                batch.set(guardRef, {
                    user_id: userDoc.id,
                    type: settingDoc.id,
                    sent_at: admin.firestore.FieldValue.serverTimestamp(),
                    status: 'sent',
                    lastSentDate: today
                });
                batch.set(userDoc.ref.collection('notifications').doc(), {
                    title,
                    body,
                    type: settingDoc.id,
                    created_at: admin.firestore.FieldValue.serverTimestamp(),
                    is_read: false,
                    read_at: null
                });
                await batch.commit();
            }
        }
    }
});

export const onAttendanceCreateReconcileLeave = onDocumentCreated(
    'companies/{companyId}/attendance/{recordId}',
    async (event) => {
        const snap = event.data;
        if (!snap) return;

        const { companyId } = event.params;
        const attendance = snap.data() as { user_id?: string; check_in_at?: admin.firestore.Timestamp };
        if (!attendance.user_id || !attendance.check_in_at) return;

        const companyRef = db.collection('companies').doc(companyId);
        const companySnap = await companyRef.get();
        const tz = (companySnap.data() as { timezone?: string } | undefined)?.timezone ?? 'UTC';

        const day = ymdInTimezone(attendance.check_in_at.toDate(), tz);
        const leaveRequests = await companyRef
            .collection('leave_requests')
            .where('user_id', '==', attendance.user_id)
            .where('status', '==', 'approved')
            .get();

        const overlapping = leaveRequests.docs.find((doc) => {
            const data = doc.data() as { start_date?: string; end_date?: string };
            if (!data.start_date || !data.end_date) return false;
            return day >= data.start_date && day <= data.end_date;
        });

        if (!overlapping) return;

        const leaveData = overlapping.data() as { leave_type_id?: string; year?: number; used_days?: number };
        const userBalanceQuery = await db
            .collection('users')
            .doc(attendance.user_id)
            .collection('leave_balances')
            .where('leave_type_id', '==', leaveData.leave_type_id ?? '')
            .where('year', '==', Number(day.slice(0, 4)))
            .limit(1)
            .get();

        const batch = db.batch();
        batch.update(overlapping.ref, {
            status: 'cancelled',
            cancellation_reason: 'Auto-cancelled because attendance exists for approved leave date.',
            decided_at: admin.firestore.FieldValue.serverTimestamp()
        });

        if (!userBalanceQuery.empty) {
            const balanceDoc = userBalanceQuery.docs[0];
            const balance = balanceDoc.data() as { used_days?: number };
            const used = balance.used_days ?? 0;
            batch.update(balanceDoc.ref, {
                used_days: Math.max(0, used - 1)
            });
        }

        batch.set(companyRef.collection('audit_log').doc(), {
            action: 'leave_cancelled_due_to_attendance',
            performed_by_uid: 'system',
            target_collection: 'leave_requests',
            target_id: overlapping.id,
            old_value: { status: 'approved' },
            new_value: { status: 'cancelled' },
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });

        await batch.commit();
    }
);

export const onUserDeactivateRejectPendingLeave = onDocumentUpdated('users/{uid}', async (event) => {
    const before = event.data?.before.data() as { is_active?: boolean; company_id?: string } | undefined;
    const after = event.data?.after.data() as { is_active?: boolean; company_id?: string } | undefined;
    const uid = event.params.uid;

    if (!before || !after) return;
    if (before.is_active !== true || after.is_active !== false || !after.company_id) return;

    const companyRef = db.collection('companies').doc(after.company_id);
    const pendingLeave = await companyRef
        .collection('leave_requests')
        .where('user_id', '==', uid)
        .where('status', '==', 'pending')
        .get();

    if (pendingLeave.empty) return;

    const batch = db.batch();
    for (const leave of pendingLeave.docs) {
        batch.update(leave.ref, {
            status: 'rejected',
            rejection_reason: 'Employee account deactivated.',
            decided_at: admin.firestore.FieldValue.serverTimestamp()
        });
    }

    batch.set(companyRef.collection('audit_log').doc(), {
        action: 'pending_leave_auto_rejected_on_deactivation',
        performed_by_uid: 'system',
        target_collection: 'leave_requests',
        target_id: uid,
        old_value: { status: 'pending' },
        new_value: { status: 'rejected' },
        timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    await batch.commit();
});
