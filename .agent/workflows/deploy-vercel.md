---
description: Deploy web version to Vercel
---

This workflow deploys the Flutter web app to Vercel with proper routing configuration.

## Steps

1. Build the Flutter web app for production
```bash
flutter build web --release
```

2. Copy the Vercel configuration to the build directory
```bash
cp vercel.json build/web/
```

3. Deploy to Vercel from the build/web directory
```bash
cd build/web && vercel --prod
```

## Notes

- The `vercel.json` file is required for proper SPA routing
- It ensures that all routes (including `/reset-password`) redirect to `index.html`
- This allows Flutter to handle routing internally
