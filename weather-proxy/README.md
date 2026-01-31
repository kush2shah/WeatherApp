# Weather Proxy

Cloud Run proxy for Google Weather API with OAuth authentication and caching.

## Local Development

```bash
export PROXY_API_KEY=12e41cad6b1132308c75673905f0f17220623e481366f584f1f1d730ae1c6f78
export PORT=8080
go run .
```

## Deploy

```bash
gcloud run deploy weather-proxy \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --service-account weather-app@project-85dca6cf-ba5d-4efd-9df.iam.gserviceaccount.com \
  --set-env-vars PROXY_API_KEY=12e41cad6b1132308c75673905f0f17220623e481366f584f1f1d730ae1c6f78 \
  --memory 256Mi \
  --max-instances 10
```
