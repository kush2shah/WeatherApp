# Cloud Run Weather Proxy Deployment

## Overview

The weather proxy service handles OAuth authentication and caching for Google Weather API calls from the iOS app.

## Architecture

- **Service:** `weather-proxy` on Cloud Run
- **Region:** us-central1
- **Service Account:** `weather-app@project-85dca6cf-ba5d-4efd-9df.iam.gserviceaccount.com`
- **URL:** https://weather-proxy-777152718569.us-central1.run.app

## Authentication

### iOS App → Proxy
- Header: `X-API-Key`
- Value: Stored in `Info.plist` as `CLOUD_RUN_PROXY_API_KEY`

### Proxy → Google Weather API
- OAuth 2.0 via Application Default Credentials (ADC)
- Service account token automatically managed by Google SDK

## Caching

| Endpoint | TTL | Purpose |
|----------|-----|---------|
| Current conditions | 10 min | Frequently changing |
| Hourly forecast | 30 min | Moderate refresh |
| Daily forecast | 60 min | Slow changing |

## Deployment

### Update Proxy Code

```bash
cd weather-proxy
gcloud run deploy weather-proxy --source .
```

### Update API Key

```bash
gcloud run services update weather-proxy \
  --region us-central1 \
  --update-env-vars PROXY_API_KEY=<new-key>
```

### View Logs

```bash
gcloud run logs read weather-proxy \
  --region us-central1 \
  --limit 100
```

### View Metrics

Visit [Cloud Run Console](https://console.cloud.google.com/run/detail/us-central1/weather-proxy/metrics)

## Monitoring

Key metrics to watch:
- Request count (should scale with app usage)
- Cache hit ratio (target >60%)
- Error rate (target <1%)
- Response latency (target <1s for cache misses)

## Troubleshooting

### iOS app shows "unauthorized" error
- Check proxy API key matches in both Info.plist and Cloud Run env vars
- Verify proxy URL is correct in Info.plist

### Proxy returns 401 when calling Google API
- Check service account has Google Weather API enabled
- Verify service account is attached to Cloud Run service

### High costs
- Check cache hit ratio in logs
- Verify TTL values are appropriate
- Consider increasing TTL for daily forecasts

## Security

- API key is embedded in iOS app binary (acceptable for personal app)
- Service account credentials never leave Cloud Run
- No service account keys stored anywhere
- API key can be rotated by updating both iOS config and Cloud Run env var
