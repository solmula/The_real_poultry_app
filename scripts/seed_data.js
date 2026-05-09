const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccount.json');

const PROJECT_ID = serviceAccount.project_id || process.env.FIREBASE_PROJECT_ID || 'poultry-automation-93ae1';

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

function pad(value) {
  return String(value).padStart(2, '0');
}

function formatDate(date) {
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function round(value, digits = 1) {
  const factor = 10 ** digits;
  return Math.round(value * factor) / factor;
}

function dailyReportForDay(offsetDays) {
  const today = new Date();
  const date = new Date(today.getFullYear(), today.getMonth(), today.getDate() - offsetDays);
  const progress = offsetDays / 6;
  const totalEggs = Math.round(1160 + progress * 60 + Math.sin(offsetDays) * 12);
  const layingRatePct = round(clamp(79.5 + progress * 4.8 + Math.cos(offsetDays * 1.4) * 1.1, 74, 90), 1);
  const feedConsumedKg = round(clamp(totalEggs * 0.059 + Math.sin(offsetDays * 0.8) * 1.7, 64, 82), 1);
  const fcr = round(feedConsumedKg / (totalEggs * 0.06), 2);
  const avgTemp = round(clamp(25.1 + Math.cos(offsetDays * 0.7) * 0.8, 23, 28), 1);
  const maxNh3 = round(clamp(11 + Math.sin(offsetDays * 0.9) * 4.5, 6, 24), 1);
  const lightHours = round(clamp(13.7 + Math.cos(offsetDays * 0.5) * 0.3, 13, 14.8), 1);

  return {
    id: formatDate(date),
    data: {
      date: formatDate(date),
      total_eggs: totalEggs,
      laying_rate_pct: layingRatePct,
      feed_consumed_kg: feedConsumedKg,
      fcr,
      avg_temp: avgTemp,
      max_nh3: maxNh3,
      light_hours: lightHours,
      alerts_count: Math.max(0, Math.round(1 + Math.sin(offsetDays * 1.2))),
    },
  };
}

function sensorSampleForIndex(index, timestamp) {
  const phase = (index / 48) * Math.PI * 2;
  const daytime = timestamp.getHours() >= 6 && timestamp.getHours() <= 18;
  const dayLift = daytime ? 1 : -0.7;

  const tempAvg = round(clamp(25 + Math.sin(phase) * 1.2 + dayLift, 22.8, 28.2), 1);
  const tempMin = round(tempAvg - (0.7 + (index % 3) * 0.1), 1);
  const tempMax = round(tempAvg + (0.8 + (index % 4) * 0.1), 1);
  const rhAvg = round(clamp(66 + Math.cos(phase) * 4.2, 58, 78), 1);
  const nh3Max = round(clamp(9 + Math.max(0, Math.sin(phase - Math.PI / 4)) * 5.5, 5, 22), 1);
  const co2Avg = Math.round(clamp(2200 + (daytime ? 350 : 120) + Math.cos(phase) * 160, 1700, 3400));
  const lightAvg = daytime
    ? Math.round(clamp(3800 + Math.sin(phase) * 900, 2500, 6200))
    : Math.round(clamp(35, 0, 80));
  const h1FeedKg = round(clamp(34 + (index / 48) * 6 + Math.sin(phase + 0.4) * 0.8, 32, 42), 1);
  const h2FeedKg = round(clamp(34 + (index / 48) * 6 + Math.sin(phase + 1.0) * 0.9, 31.5, 41.5), 1);
  const h1WaterPct = round(clamp(71 - index * 0.18, 42, 74), 1);
  const h2WaterPct = round(clamp(69 - index * 0.17, 40, 72), 1);
  const eggsTotal = 1120 + index * 2 + (daytime ? 12 : 0);
  const layingRate = round(clamp(77.8 + (daytime ? 4.2 : 1.1) + Math.sin(phase - 0.6) * 1.8, 72, 89), 1);

  return {
    id: String(timestamp.getTime()),
    data: {
      timestamp: admin.firestore.Timestamp.fromDate(timestamp),
      temp_avg: tempAvg,
      temp_min: tempMin,
      temp_max: tempMax,
      rh_avg: rhAvg,
      nh3_max: nh3Max,
      co2_avg: co2Avg,
      light_avg: lightAvg,
      h1_feed_kg: h1FeedKg,
      h2_feed_kg: h2FeedKg,
      h1_water_pct: h1WaterPct,
      h2_water_pct: h2WaterPct,
      eggs_total: eggsTotal,
      laying_rate: layingRate,
    },
  };
}

async function seedDailyReports() {
  const batch = db.batch();

  for (let offsetDays = 6; offsetDays >= 0; offsetDays -= 1) {
    const report = dailyReportForDay(offsetDays);
    batch.set(db.collection('daily_reports').doc(report.id), report.data);
  }

  await batch.commit();
}

async function seedSensorHistory() {
  const batch = db.batch();
  const start = new Date(Date.now() - 24 * 60 * 60 * 1000);

  for (let index = 0; index < 48; index += 1) {
    const timestamp = new Date(start.getTime() + index * 30 * 60 * 1000);
    const sample = sensorSampleForIndex(index, timestamp);
    batch.set(db.collection('sensor_history').doc(sample.id), sample.data);
  }

  await batch.commit();
}

async function main() {
  try {
    await seedDailyReports();
    await seedSensorHistory();
    console.log(`Seeded daily_reports (7 docs) and sensor_history (48 docs) for ${PROJECT_ID}.`);
  } catch (error) {
    console.error('Failed to seed Firestore:', error.message || error);
    console.error('Ensure application default credentials are available or set GOOGLE_APPLICATION_CREDENTIALS.');
    process.exitCode = 1;
  }
}

main();