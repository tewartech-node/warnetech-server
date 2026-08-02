# warnetech-server Backup System

**Status:** Ready to deploy  
**Backup Account:** warnet.dev01@gmail.com  
**Backup Location:** Separate Google Drive (isolated from personal account)

---

## 📁 Files in This Directory

| File | Purpose |
|------|---------|
| `google-drive-backup-config.json` | Complete backup configuration (policies, retention, schedules) |
| `GOOGLE_DRIVE_SETUP.md` | Step-by-step setup guide for Google Cloud + Google Drive |
| `backup-worker-code.ts` | TypeScript functions for Worker (backupDaily, backupWeekly, etc.) |
| `BACKUP_README.md` | This file |

---

## 🚀 Quick Start

### 1. Follow Setup Guide (30 min)
```bash
Read: GOOGLE_DRIVE_SETUP.md

# Complete steps:
# 1. Create Google Cloud project
# 2. Create service account
# 3. Create backup folder in warnet.dev01@gmail.com
# 4. Share folder with service account
# 5. Store credentials in Cloudflare KV
# 6. Deploy Worker code
# 7. Test backup
```

### 2. Deploy to Your Worker

Copy `backup-worker-code.ts` functions into your Cloudflare Worker:

```typescript
// src/backup.ts
import { backupDaily, backupWeekly, testBackup } from './backup';

// Add scheduled triggers to your worker
export default {
  async fetch(request, env) {
    if (request.url.endsWith('/backup/test')) {
      return Response.json(await testBackup(env));
    }
  },

  async scheduled(event, env) {
    // Run daily at 02:00 UTC
    if (event.cron === '0 2 * * *') {
      await backupDaily(env);
    }
    // Run weekly Sunday at 03:00 UTC
    if (event.cron === '0 3 ? * SUN') {
      await backupWeekly(env);
    }
  }
};
```

### 3. Test It Works

```bash
# Trigger test backup
curl https://testllm.warnetwork.cloud/backup/test

# Check Google Drive
# Log into warnet.dev01@gmail.com
# Open warnetech-server-backups folder
# You should see test file in daily/ subfolder
```

---

## 📊 Backup Schedule

Once deployed, backups run automatically:

```
Daily (02:00 UTC)
  ↓ Database snapshot → daily/ folder (30-day retention)

Weekly (Sunday 03:00 UTC)
  ↓ Full export → weekly/ folder (90-day retention)

Hourly
  ↓ Connector logs → logs/ folder (90-day retention)

Monthly (1st of month, 04:00 UTC)
  ↓ Archive weekly backups → monthly/ folder (1-year retention)
```

---

## 🔐 Security

- **Separate Account:** warnet.dev01@gmail.com (not personal)
- **Service Account:** Only automation has access
- **Encrypted:** Credentials stored in Cloudflare KV (encrypted by Worker)
- **Isolated:** Service account can only access shared folders
- **Audit Trail:** All uploads logged with timestamps

---

## 🆘 Troubleshooting

**Q: Backup failed with "Access denied"**  
A: Folder not shared with service account. See GOOGLE_DRIVE_SETUP.md Step 3.4

**Q: "Service account key invalid"**  
A: Re-create service account key in Google Cloud, upload to KV

**Q: Backups not appearing in Google Drive**  
A: Check Worker logs, verify folder ID, check service account permissions

**Q: How do I restore from backup?**  
A: See `schema/RESTORE.md` in the repo root

---

## 📋 Configuration Reference

See `google-drive-backup-config.json` for:
- Backup policies (what gets backed up, when, where)
- Retention settings (how long to keep backups)
- Failure handling (retry logic, alerts)
- Monitoring (health checks, metrics)

---

## 🔄 Manual Backup

To run a backup outside the schedule:

```bash
# Via Worker API
curl -X POST https://testllm.warnetwork.cloud/backup/daily \
  -H "Authorization: Bearer YOUR-SERVICE-TOKEN"

# Response:
{
  "status": "success",
  "fileId": "1abc2def3...",
  "filename": "warnetech-server-data-2026-08-02T12:00:00Z.json",
  "size": 524288,
  "timestamp": "2026-08-02T12:00:00Z",
  "duration_ms": 1234
}
```

---

## 📈 Monitoring

Monitor these metrics:
- Backup success rate (should be 100%)
- Backup duration (should be < 60 seconds)
- Backup size growth (should be steady)
- Restore test results (weekly)
- Quota usage (Google Drive quota)

---

## 🧪 Test Restore Weekly

```bash
# Set calendar reminder: Every Sunday
# Pick a recent backup file
# Download from warnetech-server-backups/daily or weekly
# Follow RESTORE.md to restore to test environment
# Verify data integrity
```

---

## 📞 Support

- **Setup questions:** See `GOOGLE_DRIVE_SETUP.md`
- **Configuration:** See `google-drive-backup-config.json`
- **Restore procedures:** See `schema/RESTORE.md`
- **Failures:** See `RUNBOOK.md` (look for "Predictable failures")

---

## ✅ Deployment Checklist

```
Before going live:
☐ Read GOOGLE_DRIVE_SETUP.md
☐ Complete all 7 setup steps
☐ Test backup succeeds
☐ Verify files in Google Drive
☐ Check Worker logs for errors
☐ Set up monitoring/alerts

After deployment:
☐ Monitor first 7 days of backups
☐ Weekly manual restore test
☐ Monthly quota usage review
☐ Document any issues in RUNBOOK.md
```

---

**Next:** Follow `GOOGLE_DRIVE_SETUP.md` to get started!
