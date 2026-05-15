const admin = require('firebase-admin');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const logger = require('firebase-functions/logger');
const crypto = require('crypto');
const nodemailer = require('nodemailer');

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();
const usersCollection = 'users';
const farmsCollection = 'farms';
const deletionJobsCollection = 'user_deletion_jobs';

const rtdb = admin.database();
const alertsCollection = 'alerts';
const alertsHistoryCollection = 'alerts_history';
const dailyReportsCollection = 'daily_reports';
const sensorHistoryCollection = 'sensor_history';
const flockSettingsCollection = 'flock_settings';
const adminAuditCollection = 'admin_audit_logs';

// Scheduler (v2) for scheduled functions
const { onSchedule } = require('firebase-functions/v2/scheduler');

async function getCallerProfile(uid) {
  const snap = await db.collection(usersCollection).doc(uid).get();
  if (!snap.exists) {
    return { exists: false, role: null, farmId: null, disabled: true };
  }

  const data = snap.data() || {};
  return {
    exists: true,
    role: data.role?.toString() ?? 'viewer',
    farmId: data.farm_id?.toString() ?? null,
    disabled: data.disabled === true,
  };
}

async function isAdmin(uid) {
  const profile = await getCallerProfile(uid);
  return profile.exists && !profile.disabled && ['admin', 'super_admin'].includes(profile.role);
}

async function isSuperAdmin(uid) {
  const profile = await getCallerProfile(uid);
  return profile.exists && !profile.disabled && profile.role === 'super_admin';
}

function normalizeRole(role) {
  const next = typeof role === 'string' ? role.trim().toLowerCase() : '';
  return ['super_admin', 'admin', 'operator', 'viewer'].includes(next) ? next : null;
}

function generateTempPassword() {
  return crypto.randomBytes(18).toString('base64url');
}

function buildMailer() {
  const host = process.env.SMTP_HOST;
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  const from = process.env.SMTP_FROM;

  if (!host || !from) {
    return null;
  }

  return {
    transporter: nodemailer.createTransport({
      host,
      port: Number(process.env.SMTP_PORT || 587),
      secure: String(process.env.SMTP_SECURE || 'false') === 'true',
      auth: user && pass ? { user, pass } : undefined,
    }),
    from,
  };
}

async function sendInvitationEmail({ to, subject, html, text }) {
  const mailer = buildMailer();
  if (!mailer) {
    logger.warn('SMTP is not configured. Invitation email was not sent.', { to, subject });
    return;
  }

  await mailer.transporter.sendMail({
    from: mailer.from,
    to,
    subject,
    html,
    text,
  });
}

async function writeAdminAudit(action, callerUid, extra = {}) {
  await db.collection(adminAuditCollection).add({
    action,
    performedBy: callerUid,
    ts: admin.firestore.FieldValue.serverTimestamp(),
    ...extra,
  });
}

async function createInvitedUser({
  email,
  role,
  farmId,
  farmName,
  createdBy,
}) {
  const tempPassword = generateTempPassword();
  const record = await auth.createUser({
    email,
    password: tempPassword,
    displayName: farmName ? `${farmName} Admin` : undefined,
  });

  const resetLink = await auth.generatePasswordResetLink(email, {
    url: process.env.PASSWORD_RESET_CONTINUE_URL || 'https://localhost',
  });

  await db.collection(usersCollection).doc(record.uid).set({
    email,
    role,
    farm_id: farmId ?? null,
    disabled: false,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    last_login: null,
    invitation_sent_at: admin.firestore.FieldValue.serverTimestamp(),
    invited_by: createdBy,
  });

  return { uid: record.uid, resetLink };
}

async function retry(operation, { attempts = 3, delayMs = 250 } = {}) {
  let lastError;

  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try {
      return await operation();
    } catch (error) {
      lastError = error;
      if (attempt === attempts) break;
      await new Promise((resolve) => setTimeout(resolve, delayMs * attempt));
    }
  }

  throw lastError;
}

// --- Validation constants and helpers ---
// Keep these ranges synchronized with the mobile client (_validateThresholds)
const RANGES = {
  temperature: { min: 14, max: 30 }, // °C
  humidity: { min: 50, max: 90 }, // %
  nh3: { min: 5, max: 50 }, // ppm
  co2: { min: 1000, max: 5000 }, // ppm
  lightIntensity: { min: 1, max: 40 }, // lux
  lightDuration: { min: 14, max: 23 }, // hours/day
  waterLevel: { min: 10, max: 90 }, // %
  feedLevel: { min: 5, max: 100 }, // %
};

function toNumber(v) {
  if (v === null || v === undefined) return null;
  if (typeof v === 'number') return v;
  if (typeof v === 'string') {
    const n = Number(v);
    return Number.isFinite(n) ? n : null;
  }
  return null;
}

function inRange(val, min, max) {
  if (val === null || val === undefined) return false;
  if (typeof val !== 'number') return false;
  return val >= min && val <= max;
}

function computeLightDurationHours(onHour, onMinute, offHour, offMinute) {
  // Convert to fractional hours, compute forward duration (wraps midnight)
  const on = (Number(onHour) || 0) + ((Number(onMinute) || 0) / 60.0);
  const off = (Number(offHour) || 0) + ((Number(offMinute) || 0) / 60.0);
  let dur = off - on;
  if (dur <= 0) dur += 24.0;
  return dur;
}

/**
 * Validate thresholds payload.
 * Returns null when valid, or an object { message, details } describing the first validation error found.
 * This central validation mirrors the client-side checks to ensure operational safety before any RTDB write.
 */
function validateThresholdsPayload(payload) {
  // Normalize expected numeric fields
  const tFanLow = toNumber(payload.temp_fan_low);
  const tFanHigh = toNumber(payload.temp_fan_high);
  const tHeatOn = toNumber(payload.temp_heat_on);
  const rhHigh = toNumber(payload.rh_high);
  const nh3Warn = toNumber(payload.nh3_warn);
  const nh3Critical = toNumber(payload.nh3_critical);
  const co2High = toNumber(payload.co2_high);
  const waterOn = toNumber(payload.water_pump_on);
  const waterOff = toNumber(payload.water_pump_off);
  const lightOnHour = toNumber(payload.light_on_hour);
  const lightOnMinute = toNumber(payload.light_on_minute) ?? 0;
  const lightOffHour = toNumber(payload.light_off_hour);
  const lightOffMinute = toNumber(payload.light_off_minute) ?? 0;
  const feedLevel = toNumber(payload.feed_level);
  const lightIntensity = toNumber(payload.light_intensity);

  // Temperature checks
  if (tFanLow !== null && !inRange(tFanLow, RANGES.temperature.min, RANGES.temperature.max)) {
    return { message: `Temperature (fan low) must be between ${RANGES.temperature.min}°C and ${RANGES.temperature.max}°C.`, details: { field: 'temp_fan_low' } };
  }
  if (tFanHigh !== null && !inRange(tFanHigh, RANGES.temperature.min, RANGES.temperature.max)) {
    return { message: `Temperature (fan high) must be between ${RANGES.temperature.min}°C and ${RANGES.temperature.max}°C.`, details: { field: 'temp_fan_high' } };
  }
  if (tHeatOn !== null && !inRange(tHeatOn, RANGES.temperature.min, RANGES.temperature.max)) {
    return { message: `Temperature (heat ON) must be between ${RANGES.temperature.min}°C and ${RANGES.temperature.max}°C.`, details: { field: 'temp_heat_on' } };
  }
  if (tFanLow !== null && tFanHigh !== null && !(tFanLow < tFanHigh)) {
    return { message: 'Temperature: fan low must be less than fan high.', details: { fieldA: 'temp_fan_low', fieldB: 'temp_fan_high' } };
  }

  // Humidity
  if (rhHigh !== null && !inRange(rhHigh, RANGES.humidity.min, RANGES.humidity.max)) {
    return { message: `Humidity (high) must be between ${RANGES.humidity.min}% and ${RANGES.humidity.max}%.`, details: { field: 'rh_high' } };
  }

  // NH3
  if (nh3Warn !== null && !inRange(nh3Warn, RANGES.nh3.min, RANGES.nh3.max)) {
    return { message: `NH3 (warning) must be between ${RANGES.nh3.min} and ${RANGES.nh3.max} ppm.`, details: { field: 'nh3_warn' } };
  }
  if (nh3Critical !== null && !inRange(nh3Critical, RANGES.nh3.min, RANGES.nh3.max)) {
    return { message: `NH3 (critical) must be between ${RANGES.nh3.min} and ${RANGES.nh3.max} ppm.`, details: { field: 'nh3_critical' } };
  }
  if (nh3Warn !== null && nh3Critical !== null && !(nh3Warn < nh3Critical)) {
    return { message: 'NH3: warning level must be less than critical level.', details: { fieldA: 'nh3_warn', fieldB: 'nh3_critical' } };
  }

  // CO2
  if (co2High !== null && !inRange(co2High, RANGES.co2.min, RANGES.co2.max)) {
    return { message: `CO2 (high) must be between ${RANGES.co2.min} and ${RANGES.co2.max} ppm.`, details: { field: 'co2_high' } };
  }

  // Water level
  if (waterOn !== null && !inRange(waterOn, RANGES.waterLevel.min, RANGES.waterLevel.max)) {
    return { message: `Water pump ON threshold must be between ${RANGES.waterLevel.min}% and ${RANGES.waterLevel.max}%.`, details: { field: 'water_pump_on' } };
  }
  if (waterOff !== null && !inRange(waterOff, RANGES.waterLevel.min, RANGES.waterLevel.max)) {
    return { message: `Water pump OFF threshold must be between ${RANGES.waterLevel.min}% and ${RANGES.waterLevel.max}%.`, details: { field: 'water_pump_off' } };
  }
  if (waterOn !== null && waterOff !== null && !(waterOn < waterOff)) {
    return { message: 'Water levels: pump ON threshold must be less than OFF threshold.', details: { fieldA: 'water_pump_on', fieldB: 'water_pump_off' } };
  }

  // Feed level
  if (feedLevel !== null && !inRange(feedLevel, RANGES.feedLevel.min, RANGES.feedLevel.max)) {
    return { message: `Feed level must be between ${RANGES.feedLevel.min}% and ${RANGES.feedLevel.max}%.`, details: { field: 'feed_level' } };
  }

  // Light intensity
  if (lightIntensity !== null && !inRange(lightIntensity, RANGES.lightIntensity.min, RANGES.lightIntensity.max)) {
    return { message: `Light intensity must be between ${RANGES.lightIntensity.min} and ${RANGES.lightIntensity.max} lux.`, details: { field: 'light_intensity' } };
  }

  // Light duration (requires on/off hours)
  if (lightOnHour !== null && lightOffHour !== null) {
    const duration = computeLightDurationHours(lightOnHour, lightOnMinute, lightOffHour, lightOffMinute);
    if (!(duration >= RANGES.lightDuration.min && duration <= RANGES.lightDuration.max)) {
      return { message: `Light duration must be between ${RANGES.lightDuration.min} and ${RANGES.lightDuration.max} hours/day.`, details: { fieldA: 'light_on_hour', fieldB: 'light_off_hour', duration } };
    }
  }

  return null;
}

// --- End validation helpers ---

exports.deleteUserAccount = onCall({ region: 'us-central1' }, async (request) => {
  const callerUid = request.auth?.uid;
  const targetUid = typeof request.data?.targetUid === 'string' ? request.data.targetUid.trim() : '';

  if (!callerUid) {
    throw new HttpsError('unauthenticated', 'You must be signed in to delete a user.');
  }

  if (!targetUid) {
    throw new HttpsError('invalid-argument', 'targetUid is required.');
  }

  if (targetUid === callerUid) {
    throw new HttpsError('failed-precondition', 'You cannot delete your own account from this screen.');
  }

  const caller = await getCallerProfile(callerUid);
  const target = await getCallerProfile(targetUid);

  if (!caller.exists || caller.disabled || !['admin', 'super_admin'].includes(caller.role)) {
    throw new HttpsError('permission-denied', 'Only admins can delete users.');
  }

  if (caller.role !== 'super_admin') {
    const sameFarm = caller.farmId === target.farmId || (!caller.farmId && !target.farmId);
    if (!sameFarm) {
      throw new HttpsError('permission-denied', 'You can only delete users in your own farm.');
    }
  }

  if (target.role === 'super_admin' && caller.role !== 'super_admin') {
    throw new HttpsError('permission-denied', 'Super admins can only be deleted by super admins.');
  }

  const userRef = db.collection(usersCollection).doc(targetUid);
  const jobRef = db.collection(deletionJobsCollection).doc(targetUid);

  let previousDisabled = false;
  let userExists = false;
  let jobAlreadyCompleted = false;

  try {
    await db.runTransaction(async (transaction) => {
      const [userSnap, jobSnap] = [await transaction.get(userRef), await transaction.get(jobRef)];

      userExists = userSnap.exists;
      previousDisabled = userSnap.exists ? Boolean(userSnap.data()?.disabled) : false;

      if (jobSnap.exists && jobSnap.data()?.status === 'completed') {
        jobAlreadyCompleted = true;
        return;
      }

      // Mark the user as pending deletion before the Auth delete starts.
      // This prevents the UI from treating the account as active if cleanup is retried.
      if (userSnap.exists) {
        transaction.set(
          userRef,
          {
            disabled: true,
            deletionPending: true,
            deletionRequestedBy: callerUid,
            deletionRequestedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }

      transaction.set(
        jobRef,
        {
          targetUid,
          requestedBy: callerUid,
          requestedAt: admin.firestore.FieldValue.serverTimestamp(),
          status: 'in_progress',
          authDeleted: false,
          firestoreDeleted: !userSnap.exists,
          lastError: null,
        },
        { merge: true },
      );
    });

    if (jobAlreadyCompleted) {
      return {
        success: true,
        targetUid,
        status: 'already_deleted',
      };
    }

    try {
      await retry(async () => {
        try {
          await auth.deleteUser(targetUid);
        } catch (error) {
          if (error?.code === 'auth/user-not-found') {
            return;
          }
          throw error;
        }
      });
    } catch (error) {
      logger.error('Failed to delete Firebase Auth user.', {
        targetUid,
        callerUid,
        error: error?.message ?? String(error),
      });

      if (userExists) {
        await userRef.set(
          {
            disabled: previousDisabled,
            deletionPending: false,
            deletionRollbackReason: error?.message ?? String(error),
            deletionRollbackAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      }

      await jobRef.set(
        {
          status: 'failed',
          stage: 'auth_delete',
          lastError: error?.message ?? String(error),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      throw new HttpsError('internal', 'Failed to delete the Firebase Auth account.');
    }

    try {
      await retry(async () => {
        await userRef.delete();
      });
    } catch (error) {
      logger.error('Auth user deleted, but Firestore cleanup failed.', {
        targetUid,
        callerUid,
        error: error?.message ?? String(error),
      });

      await jobRef.set(
        {
          status: 'pending_firestore_cleanup',
          stage: 'firestore_delete',
          authDeleted: true,
          firestoreDeleted: false,
          lastError: error?.message ?? String(error),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      throw new HttpsError(
        'internal',
        'The Auth account was deleted, but Firestore cleanup failed. Retry the deletion to finish cleanup.',
      );
    }

    await jobRef.set(
      {
        status: 'completed',
        authDeleted: true,
        firestoreDeleted: true,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return {
      success: true,
      targetUid,
      status: 'deleted',
    };
  } catch (error) {
    logger.error('User deletion failed.', {
      targetUid,
      callerUid,
      error: error?.message ?? String(error),
    });

    throw error instanceof HttpsError
      ? error
      : new HttpsError('internal', 'Unexpected error while deleting the user.');
  }
});

/**
 * Scheduled job: archive daily RTDB totals into Firestore `daily_reports`
 * and reset RTDB counters at midnight local time (Africa/Addis_Ababa).
 *
 * NOTE: Deploying scheduled Cloud Functions requires the Firebase project
 * to be on the Blaze (pay-as-you-go) plan.
 */
exports.archiveDailyTotals = onSchedule(
  {
    schedule: '0 0 * * *', // run at 00:00 every day
    timeZone: 'Africa/Addis_Ababa',
  },
  async (context) => {
    logger.log('archiveDailyTotals: starting scheduled archival job');

    try {
      // Read RTDB paths
      const eggsSnap = await rtdb.ref('/live/eggs').once('value');
      const h1Snap = await rtdb.ref('/live/h1').once('value');
      const h2Snap = await rtdb.ref('/live/h2').once('value');

      const eggs = eggsSnap.exists() ? eggsSnap.val() : {};
      const h1 = h1Snap.exists() ? h1Snap.val() : {};
      const h2 = h2Snap.exists() ? h2Snap.val() : {};

      // Build daily report document according to required structure
      const now = new Date();
      // Use local date string (YYYY-MM-DD) in Africa/Addis_Ababa timezone semantics
      // Although JS Date doesn't support TZ conversion easily here, using ISO date
      // of current server time is acceptable; schedule already aligns with Addis_Ababa.
      const dateId = now.toISOString().split('T')[0];

      const report = {
        date: dateId,
        farm_id: (eggs && eggs.farm_id) ? eggs.farm_id : null,
        eggs_total: toNumber(eggs.total_today) ?? 0,
        laying_rate: toNumber(eggs.laying_rate) ?? 0,
        feed_h1_kg: toNumber(h1.feed_kg) ?? 0,
        feed_h2_kg: toNumber(h2.feed_kg) ?? 0,
        mortality: toNumber(eggs.mortality) ?? 0,
        recorded_at: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Write to Firestore: use date string as document ID
      await db.collection(dailyReportsCollection).doc(dateId).set(report, { merge: true });

      // Reset RTDB counters (but do NOT reset water_pct)
      const updates = {};
      updates['/live/eggs/total_today'] = 0;
      updates['/live/eggs/laying_rate'] = 0;
      updates['/live/h1/feed_kg'] = 0;
      updates['/live/h2/feed_kg'] = 0;

      await rtdb.ref('/').update(updates);

      logger.log('archiveDailyTotals: archival and reset completed', { date: dateId });
      return { success: true, date: dateId };
    } catch (error) {
      logger.error('archiveDailyTotals: failed', { error: error?.message ?? String(error) });
      throw error;
    }
  }
);

// Create a new user (farm-scoped). Farm admins can only create operators/viewers.
exports.createUserAccount = onCall({ region: 'us-central1' }, async (request) => {
  const callerUid = request.auth?.uid;
  if (!callerUid) throw new HttpsError('unauthenticated', 'You must be signed in.');

  const caller = await getCallerProfile(callerUid);
  if (!caller.exists || caller.disabled || !['admin', 'super_admin'].includes(caller.role)) {
    throw new HttpsError('permission-denied', 'Only admins can create users.');
  }

  const { email, role = 'viewer', farm_id } = request.data || {};
  const normalizedRole = normalizeRole(role);
  if (!email || !normalizedRole) throw new HttpsError('invalid-argument', 'email and role are required.');

  if (caller.role !== 'super_admin' && !caller.farmId) {
    throw new HttpsError('failed-precondition', 'This account is not assigned to a farm yet.');
  }

  if (caller.role !== 'super_admin' && normalizedRole !== 'operator' && normalizedRole !== 'viewer') {
    throw new HttpsError('permission-denied', 'Farm admins can only create operators or viewers.');
  }

  const targetFarmId = caller.role === 'super_admin' ? (farm_id?.toString().trim() || null) : caller.farmId;
  if (caller.role !== 'super_admin' && targetFarmId !== caller.farmId) {
    throw new HttpsError('permission-denied', 'You can only create users inside your own farm.');
  }

  try {
    const { uid, resetLink } = await createInvitedUser({
      email: String(email).toLowerCase(),
      role: normalizedRole,
      farmId: targetFarmId,
      createdBy: callerUid,
    });

    const farmDoc = targetFarmId ? await db.collection(farmsCollection).doc(targetFarmId).get() : null;
    const farmName = farmDoc?.exists ? farmDoc.data()?.name?.toString() ?? 'Farm' : 'Farm';

    try {
      await sendInvitationEmail({
        to: String(email).toLowerCase(),
        subject: `You're invited to ${farmName}`,
        text: `You have been invited to ${farmName}. Use this link to set your password: ${resetLink}`,
        html: `<p>You have been invited to <strong>${farmName}</strong>.</p><p><a href="${resetLink}">Set your password</a></p>`,
      });
    } catch (emailErr) {
      try { await auth.deleteUser(uid); } catch (_) {}
      try { await db.collection(usersCollection).doc(uid).delete(); } catch (_) {}
      logger.error('Invitation email failed for createUserAccount', { callerUid, uid, error: emailErr?.message ?? String(emailErr) });
      throw new HttpsError('internal', 'Invitation email could not be sent.');
    }

    await writeAdminAudit('createUser', callerUid, {
      targetUid: uid,
      farmId: targetFarmId,
      data: { role: normalizedRole },
    });

    return { success: true, uid, farmId: targetFarmId };
  } catch (err) {
    logger.error('createUserAccount failed', { callerUid, error: err?.message ?? String(err) });
    if (err?.code === 'auth/email-already-exists') {
      throw new HttpsError('already-exists', 'Email already in use.');
    }
    throw new HttpsError('internal', 'Failed to create user.');
  }
});

// Create a new farm and its first admin.
exports.createFarmAdmin = onCall({ region: 'us-central1' }, async (request) => {
  const callerUid = request.auth?.uid;
  if (!callerUid) throw new HttpsError('unauthenticated', 'You must be signed in.');

  const caller = await getCallerProfile(callerUid);
  if (!caller.exists || caller.disabled || caller.role !== 'super_admin') {
    throw new HttpsError('permission-denied', 'Only super admins can create farms.');
  }

  const farmName = typeof request.data?.farm_name === 'string' ? request.data.farm_name.trim() : '';
  const adminEmail = typeof request.data?.admin_email === 'string' ? request.data.admin_email.trim().toLowerCase() : '';
  const subscriptionPlan = typeof request.data?.subscription_plan === 'string' ? request.data.subscription_plan.trim() : 'starter';

  if (!farmName || !adminEmail) {
    throw new HttpsError('invalid-argument', 'farm_name and admin_email are required.');
  }

  const farmRef = db.collection(farmsCollection).doc();
  let adminUid = null;

  try {
    const userResult = await createInvitedUser({
      email: adminEmail,
      role: 'admin',
      farmId: farmRef.id,
      farmName,
      createdBy: callerUid,
    });
    adminUid = userResult.uid;

    await farmRef.set({
      name: farmName,
      owner_uid: adminUid,
      subscription_plan: subscriptionPlan,
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    });

    const resetLink = userResult.resetLink;
    try {
      await sendInvitationEmail({
        to: adminEmail,
        subject: `Your farm admin account for ${farmName}`,
        text: `Your farm has been created. Set your password here: ${resetLink}`,
        html: `<p>Your farm <strong>${farmName}</strong> is ready.</p><p><a href="${resetLink}">Set your password</a></p>`,
      });
    } catch (emailErr) {
      try { await auth.deleteUser(adminUid); } catch (_) {}
      try { await db.collection(usersCollection).doc(adminUid).delete(); } catch (_) {}
      try { await farmRef.delete(); } catch (_) {}
      logger.error('Invitation email failed for createFarmAdmin', { callerUid, farmId: farmRef.id, error: emailErr?.message ?? String(emailErr) });
      throw new HttpsError('internal', 'Invitation email could not be sent.');
    }

    await writeAdminAudit('createFarmAdmin', callerUid, {
      targetUid: adminUid,
      farmId: farmRef.id,
      data: { farmName, adminEmail, subscriptionPlan },
    });

    return { success: true, uid: adminUid, farmId: farmRef.id };
  } catch (err) {
    if (adminUid) {
      try { await auth.deleteUser(adminUid); } catch (_) {}
      try { await db.collection(usersCollection).doc(adminUid).delete(); } catch (_) {}
    }
    try { await farmRef.delete(); } catch (_) {}
    logger.error('createFarmAdmin failed', { callerUid, error: err?.message ?? String(err) });
    if (err?.code === 'auth/email-already-exists') {
      throw new HttpsError('already-exists', 'Admin email already exists.');
    }
    throw err instanceof HttpsError ? err : new HttpsError('internal', 'Failed to create farm admin.');
  }
});

// Change a user's role (admin-only).
exports.changeUserRole = onCall({ region: 'us-central1' }, async (request) => {
  const callerUid = request.auth?.uid;
  if (!callerUid) throw new HttpsError('unauthenticated', 'You must be signed in.');
  const caller = await getCallerProfile(callerUid);
  if (!caller.exists || caller.disabled || !['admin', 'super_admin'].includes(caller.role)) throw new HttpsError('permission-denied', 'Only admins can change roles.');

  const { targetUid, newRole } = request.data || {};
  const normalizedRole = normalizeRole(newRole);
  if (!targetUid || !normalizedRole) throw new HttpsError('invalid-argument', 'targetUid and newRole required.');

  try {
    await db.runTransaction(async (tx) => {
      const ref = db.collection(usersCollection).doc(targetUid);
      const snap = await tx.get(ref);
      if (!snap.exists) throw new HttpsError('not-found', 'Target user not found.');
      const target = snap.data() || {};
      const targetFarmId = target.farm_id?.toString() ?? null;

      if (caller.role !== 'super_admin') {
        const sameFarm = caller.farmId === targetFarmId || (!caller.farmId && !targetFarmId);
        if (!sameFarm) {
          throw new HttpsError('permission-denied', 'You can only change users in your own farm.');
        }
        if (normalizedRole !== 'operator' && normalizedRole !== 'viewer') {
          throw new HttpsError('permission-denied', 'Farm admins can only assign operator or viewer roles.');
        }
      }

      if (normalizedRole === 'super_admin' && caller.role !== 'super_admin') {
        throw new HttpsError('permission-denied', 'Only super admins can assign super admin role.');
      }

      tx.update(ref, { role: normalizedRole });
      tx.set(db.collection(adminAuditCollection).doc(), {
        action: 'changeRole',
        targetUid,
        performedBy: callerUid,
        newRole: normalizedRole,
        ts: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    return { success: true };
  } catch (err) {
    logger.error('changeUserRole failed', { callerUid, targetUid, error: err?.message ?? String(err) });
    if (err instanceof HttpsError) throw err;
    throw new HttpsError('internal', 'Failed to change role.');
  }
});

// Toggle disabled flag on user (admin-only)
exports.toggleUserDisabled = onCall({ region: 'us-central1' }, async (request) => {
  const callerUid = request.auth?.uid;
  if (!callerUid) throw new HttpsError('unauthenticated', 'You must be signed in.');
  const caller = await getCallerProfile(callerUid);
  if (!caller.exists || caller.disabled || !['admin', 'super_admin'].includes(caller.role)) throw new HttpsError('permission-denied', 'Only admins can disable users.');

  const { targetUid, disabled } = request.data || {};
  if (!targetUid || typeof disabled !== 'boolean') throw new HttpsError('invalid-argument', 'targetUid and disabled(boolean) required.');

  try {
    const target = await getCallerProfile(targetUid);
    if (caller.role !== 'super_admin') {
      const sameFarm = caller.farmId === target.farmId || (!caller.farmId && !target.farmId);
      if (!sameFarm) {
        throw new HttpsError('permission-denied', 'You can only disable users in your own farm.');
      }
    }
    await db.collection(usersCollection).doc(targetUid).update({ disabled });
    await db.collection(adminAuditCollection).add({
      action: 'toggleDisabled',
      targetUid,
      performedBy: callerUid,
      disabled,
      ts: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { success: true };
  } catch (err) {
    logger.error('toggleUserDisabled failed', { callerUid, targetUid, error: err?.message ?? String(err) });
    throw new HttpsError('internal', 'Failed to update user disabled flag.');
  }
});

// Update thresholds or other RTDB-based system config (admin-only)
exports.updateThresholds = onCall({ region: 'us-central1' }, async (request) => {
  const callerUid = request.auth?.uid;
  if (!callerUid) throw new HttpsError('unauthenticated', 'You must be signed in.');
  const caller = await getCallerProfile(callerUid);
  if (!caller.exists || caller.disabled || !['admin', 'super_admin'].includes(caller.role)) throw new HttpsError('permission-denied', 'Only admins can update thresholds.');

  const payload = request.data || {};
  if (!payload || typeof payload !== 'object') throw new HttpsError('invalid-argument', 'Invalid thresholds payload.');
  if (!payload.farm_id) {
    payload.farm_id = caller.farmId;
  }
  if (caller.role !== 'super_admin' && caller.farmId && payload.farm_id !== caller.farmId) {
    throw new HttpsError('permission-denied', 'You can only update thresholds for your own farm.');
  }
  // Server-side validation: mirror client rules and prevent unsafe writes
  const validation = validateThresholdsPayload(payload);
  if (validation !== null) {
    // Log rejected attempt for auditing
    try {
      await writeAdminAudit('updateThresholds_rejected', callerUid, {
        reason: validation.message,
        details: validation.details || null,
        farmId: payload.farm_id || null,
        payloadSummary: Object.keys(payload).reduce((acc, k) => ({ ...acc, [k]: payload[k] }), {}),
      });
    } catch (logErr) {
      logger.warn('Failed to write validation rejection audit log', { error: logErr?.message ?? String(logErr) });
    }

    // Return structured HttpsError to client with details
    throw new HttpsError('invalid-argument', validation.message, validation.details || null);
  }

  try {
    // All validation passed — perform the RTDB write and audit
    await rtdb.ref('/thresholds').set(payload);
    await writeAdminAudit('updateThresholds', callerUid, { farmId: payload.farm_id || null, data: payload });
    return { success: true };
  } catch (err) {
    logger.error('updateThresholds failed', { callerUid, error: err?.message ?? String(err) });
    throw new HttpsError('internal', 'Failed to update thresholds.');
  }
});

// Escalate an alert: record history and notify farm topic (admin/operator callable)
exports.escalateAlert = onCall({ region: 'us-central1' }, async (request) => {
  const callerUid = request.auth?.uid;
  if (!callerUid) throw new HttpsError('unauthenticated', 'You must be signed in.');

  // Operators and admins can escalate
  const caller = await getCallerProfile(callerUid);
  const role = caller.exists ? caller.role : null;
  if (!(role === 'admin' || role === 'operator' || role === 'super_admin')) throw new HttpsError('permission-denied', 'Operator or admin required.');

  const { alertId, reason } = request.data || {};
  if (!alertId) throw new HttpsError('invalid-argument', 'alertId required.');

  try {
    const alertRef = db.collection(alertsCollection).doc(alertId);
    const alertSnap = await alertRef.get();
    if (!alertSnap.exists) throw new HttpsError('not-found', 'Alert not found.');

    const alert = alertSnap.data() || {};
    const farmId = alert.farm_id || alert.farmId || caller.farmId || 'unknown';

    // Record escalation in history
    await db.collection(alertsHistoryCollection).add({
      alertId,
      escalatedBy: callerUid,
      reason: reason || null,
      original: alert,
      ts: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send an FCM notification to farm topic
    try {
      const topic = `farm-${farmId}-alerts`;
      await admin.messaging().send({
        topic,
        notification: { title: 'Alert Escalation', body: `Alert ${alertId} escalated` },
        data: { alertId: String(alertId) },
      });
    } catch (fcmErr) {
      logger.warn('Failed to send FCM for escalation', { alertId, error: fcmErr?.message ?? String(fcmErr) });
    }

    return { success: true };
  } catch (err) {
    logger.error('escalateAlert failed', { callerUid, alertId: request.data?.alertId, error: err?.message ?? String(err) });
    if (err instanceof HttpsError) throw err;
    throw new HttpsError('internal', 'Failed to escalate alert.');
  }
});

// Scheduled analytics aggregation (daily)
const { schedule } = require('firebase-functions/v2');
exports.aggregateAnalytics = schedule('every 24 hours').onRun(async (context) => {
  logger.log('Running scheduled aggregateAnalytics');
  const now = Date.now();
  const dayAgo = new Date(now - 24 * 60 * 60 * 1000);

  try {
    const q = await db.collection(sensorHistoryCollection).where('ts', '>=', admin.firestore.Timestamp.fromDate(dayAgo)).get();
    const buckets = {};
    q.docs.forEach((d) => {
      const data = d.data();
      const farmId = data.farm_id || 'unknown';
      if (!buckets[farmId]) buckets[farmId] = { count: 0, tempSum: 0 };
      buckets[farmId].count += 1;
      buckets[farmId].tempSum += Number(data.temperature || 0);
    });

    const writes = Object.entries(buckets).map(([farmId, stats]) => {
      const avgTemp = stats.tempSum / stats.count;
      return db.collection(dailyReportsCollection).add({ farm_id: farmId, avg_temperature: avgTemp, sample_count: stats.count, ts: admin.firestore.FieldValue.serverTimestamp() });
    });

    await Promise.all(writes);
    return { success: true, processedFarms: Object.keys(buckets).length };
  } catch (err) {
    logger.error('aggregateAnalytics failed', { error: err?.message ?? String(err) });
    return { success: false, error: err?.message ?? String(err) };
  }
});
