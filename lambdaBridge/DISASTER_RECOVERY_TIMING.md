# Disaster Recovery Timing

Azure Function monitors AWS infrastructure health every 5 minutes with automated alerts.

## Configuration

- **Timer**: Every 5 minutes (`0 */5 * * * *`)
- **Timeout**: 30s per request
- **Retries**: 3 attempts with 30s delays

## Detection Times

| Scenario  | Time   | When                      |
| --------- | ------ | ------------------------- |
| **Best**  | 1m 31s | Failure just before timer |
| **Worst** | 5m 29s | Failure just after timer  |

## Retry Process

```
Timer → Attempt 1 (30s) → Wait 30s → Attempt 2 (30s) → Wait 30s → Attempt 3 (30s) → Alert
```

**Total retry time**: 1.5 minutes

## Alert Flow

1. Generate correlation ID (`DR-YYYYMMDD-HHMMSS`)
2. Select 4 random technicians
3. Send HTML email alert
4. Log results

## Optimization

**Faster detection**: Reduce timer to 2-3 minutes, add webhooks  
**Better reliability**: Exponential backoff, multiple endpoints
