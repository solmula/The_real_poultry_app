# Firebase Admin SDK Security Remediation Guide

## Summary

This project had **critical security issues** with exposed Firebase service account credentials. This guide documents:
1. What was exposed and why it's dangerous
2. Changes made to fix the issues
3. Steps to complete the remediation
4. Secure procedures going forward

---

## 🚨 Critical Issue: Exposed Service Account Key

### What Was Exposed
- **File:** `scripts/serviceAccount.json` (committed to git history)
- **Contents:** Complete Firebase Admin SDK service account with private key
- **Risk:** Anyone with access to git history can impersonate your Firebase project admin
- **Affected Systems:** All Firebase services (Firestore, RTDB, Auth, Storage)

### Why This Is Dangerous
A service account private key grants **full admin access** to your Firebase project, allowing:
- ✗ Read/write all Firestore data
- ✗ Read/write Realtime Database data
- ✗ Create/delete users
- ✗ Modify security rules
- ✗ Access Firebase Storage
- ✗ Issue new admin tokens
- ✗ Delete the entire project

---

## ✅ Changes Made

### 1. Updated `.gitignore` (Critical)
**File:** `.gitignore`

Added comprehensive patterns to prevent credential files from being committed:
```gitignore
# Firebase Admin SDK credentials
scripts/*.json
**/*serviceAccount*.json
**/*firebase-admin*.json
**/*gcp-key*.json
**/*google-*.json

# Environment files
.env
.env.local
.env.*.local
*.env

# API keys and secrets
.secrets
**/*.key
**/*.pem
**/*.p12
```

**Status:** ✅ Complete

---

### 2. Refactored `scripts/seed_data.js` (Node.js Seeder)
**File:** `scripts/seed_data.js`

**Before:**
```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccount.json');  // ✗ Hardcoded path

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),  // ✗ Hardcoded key
});
```

**After:**
```javascript
const admin = require('firebase-admin');
// Credentials loaded from environment only — never from committed files

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID || 'poultry-automation-93ae1';

if (!PROJECT_ID) {
  console.error('Set GOOGLE_APPLICATION_CREDENTIALS or run: gcloud auth application-default login');
  process.exit(1);
}

admin.initializeApp();  // Loads credentials from environment
```

**Key Changes:**
- ✅ Removed hardcoded `require('./serviceAccount.json')`
- ✅ Uses GOOGLE_APPLICATION_CREDENTIALS env var or gcloud ADC
- ✅ Added helpful error messages with setup instructions

**Status:** ✅ Complete

---

### 3. Refactored `scripts/seed_firestore.dart` (Dart Seeder)
**File:** `scripts/seed_firestore.dart`

**Changes:**
- ✅ Removed `--service-account` command-line flag (encourages hardcoding paths)
- ✅ Removed `serviceAccountPath` from `_SeedConfig` class
- ✅ Updated `_resolveCredential()` to:
  - Check GOOGLE_APPLICATION_CREDENTIALS env var first
  - Fall back to application default credentials (`gcloud auth application-default login`)
  - Provide clear error messages guiding users to secure setup
- ✅ Updated error messages to reference `.env.example` and `gcloud auth`

**Before:**
```dart
// ✗ Supported hardcoded paths
dart scripts/seed_firestore.dart --service-account ./serviceAccount.json
```

**After:**
```dart
// ✅ Environment-based only
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/sa-key.json"
dart scripts/seed_firestore.dart
```

**Status:** ✅ Complete

---

### 4. Created `.env.example` (Setup Guide)
**File:** `.env.example`

Comprehensive documentation for three credential methods:
1. **GOOGLE_APPLICATION_CREDENTIALS** (Recommended for CI/CD)
2. **Application Default Credentials** (Recommended for local development)
3. Legacy method (no longer supported)

Includes:
- ✅ Setup instructions for each method
- ✅ Platform-specific examples (Linux, macOS, Windows)
- ✅ CI/CD examples (GitHub Actions)
- ✅ Security checklist
- ✅ File permissions best practices

**Status:** ✅ Complete — File is tracked in git (it's an example, not a secret)

---

## 🔴 REQUIRED: Remove Leaked Key from Git History

### Immediate Actions (Do These Now)

#### Step 1: Rotate the exposed key
1. Go to [Google Cloud Console](https://console.cloud.google.com/iam-admin/serviceaccounts)
2. Find: `firebase-adminsdk-fbsvc@poultry-automation-93ae1.iam.gserviceaccount.com`
3. Click the service account → **Keys** tab
4. Delete the key with ID: `9b1f7b10b20800b0aeb45974a743c138ee8efe23`
5. **Create a new key** (you'll use this for setup in Step 3)

#### Step 2: Purge the secret from git history
The file `scripts/serviceAccount.json` is still in git history and must be removed.

**Option A: Using BFG Repo-Cleaner (Easier)**
```powershell
# Download BFG (https://rtyley.github.io/bfg-repo-cleaner/)
# Place bfg.jar in your project directory

java -jar bfg.jar --delete-files scripts/serviceAccount.json

# Verify and clean
git reflog expire --expire=now --all && git gc --prune=now --aggressive

# Force push to update remote (if you have origin)
git push origin --force-all
```

**Option B: Using git filter-branch (More control)**
```powershell
# Remove file from all commits
git filter-branch --tree-filter 'rm -f scripts/serviceAccount.json' -- --all

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push to update remote
git push origin --force-all
```

**⚠️ WARNING:** Force-pushing rewrites history. Only do this if you:
- Are the sole developer, OR
- Coordinate with your team to re-clone the repository

#### Step 3: Verify the key is gone
```powershell
# This should return nothing if successful
git log -p --all -- scripts/serviceAccount.json | head -50
```

---

## 📋 Verification Checklist

### Files to Delete (Already in .gitignore)
- ✅ `scripts/serviceAccount.json` — DO NOT commit this file ever again
- ✅ Any `.env` files (local development only)
- ✅ Any service account JSON files in git history

### Files Modified
- ✅ `.gitignore` — Enhanced with comprehensive credential patterns
- ✅ `scripts/seed_data.js` — Uses env-based credentials only
- ✅ `scripts/seed_firestore.dart` — Uses env-based credentials only
- ✅ `.env.example` — Created (tracked in git, shows example env vars)

### Client Code Audit
- ✅ **Verified:** No mobile/client code uses Firebase Admin SDK
  - `lib/**/*.dart` contains only client SDK (`firebase_auth`, `firebase_database`, `cloud_firestore`)
  - Admin SDK (`firebase_admin_sdk`, `google_cloud_firestore`) only in `scripts/` directory
  - This is correct and secure

---

## 🔧 Setup Instructions for Team

### For Local Development

**Method 1: Application Default Credentials (Easiest)**
```powershell
# One-time setup
gcloud auth application-default login

# Then run seeding (no env vars needed)
npm run seed
# or
dart scripts/seed_firestore.dart
```

**Method 2: GOOGLE_APPLICATION_CREDENTIALS**
```powershell
# Get service account key from Google Cloud Console (see above)
# Save as: C:\secure\path\service-account-key.json

# Set environment variable
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\secure\path\service-account-key.json"

# Run seeding
npm run seed
dart scripts/seed_firestore.dart
```

### For GitHub Actions or CI/CD

```yaml
# .github/workflows/seed.yml
name: Seed Firebase

on:
  workflow_dispatch:

jobs:
  seed:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: npm install
      
      - name: Write service account key
        env:
          FIREBASE_SERVICE_ACCOUNT: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
        run: echo "$FIREBASE_SERVICE_ACCOUNT" > /tmp/sa-key.json
      
      - name: Seed Firebase
        env:
          GOOGLE_APPLICATION_CREDENTIALS: /tmp/sa-key.json
          FIREBASE_PROJECT_ID: poultry-automation-93ae1
        run: npm run seed
```

---

## 🛡️ Security Best Practices

### Going Forward

1. **Never commit secrets**
   - ✅ Use `.env.example` to show examples only
   - ✅ Always add credential files to `.gitignore`
   - ✅ Use environment variables for all sensitive data

2. **Rotate service account keys regularly**
   - Generate new keys quarterly
   - Delete old keys after verification
   - Document rotation dates

3. **Use least privilege**
   - Service accounts should have minimal permissions
   - Don't use the default service account in production
   - Create separate service accounts for different services (seeding, cloud functions, etc.)

4. **Monitor credential usage**
   - Enable Cloud Audit Logs
   - Set up alerts for suspicious activity
   - Review access logs regularly

5. **Secure CI/CD pipelines**
   - Use GitHub secrets (not environment files)
   - Use CI/CD provider's native credential management
   - Never echo secrets in logs

6. **Clean up git history**
   - Regularly audit git history for leaked secrets
   - Use pre-commit hooks to prevent secrets from being committed
   - Consider using tools like `detect-secrets` or `truffleHog`

---

## 📚 Related Files

| File | Status | Action |
|------|--------|--------|
| `.gitignore` | ✅ Updated | Review and commit |
| `.env.example` | ✅ Created | Commit to git (it's an example) |
| `scripts/seed_data.js` | ✅ Refactored | Commit changes |
| `scripts/seed_firestore.dart` | ✅ Refactored | Commit changes |
| `scripts/serviceAccount.json` | 🔴 DELETE | Remove from git history (see Step 2 above) |
| `.env` (local) | ❌ Don't track | Add to `.gitignore` ✅ |
| Any JSON keys | ❌ Don't track | Add to `.gitignore` ✅ |

---

## 🚀 Next Steps

1. **Immediately:**
   - [ ] Rotate the exposed service account key (Step 1)
   - [ ] Purge from git history (Step 2)
   - [ ] Verify removal (Step 3)

2. **This week:**
   - [ ] Commit the refactored scripts
   - [ ] Commit `.gitignore` and `.env.example`
   - [ ] Test seeding with new credentials

3. **This month:**
   - [ ] Audit all other projects for similar issues
   - [ ] Implement pre-commit hooks to catch secrets
   - [ ] Set up GitHub Actions to seed Firebase

4. **Ongoing:**
   - [ ] Rotate service account keys quarterly
   - [ ] Monitor Cloud Audit Logs
   - [ ] Keep dependencies updated

---

## 📞 Questions?

Refer to:
- `.env.example` for setup instructions
- Google Cloud [Service Account documentation](https://cloud.google.com/docs/authentication/application-default-credentials)
- Firebase [Admin SDK documentation](https://firebase.google.com/docs/database/admin/start)
- GitHub [Managing secrets in GitHub Actions](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)

