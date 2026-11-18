# Firebase Hosting — Waznah Deep Links

Deploy from this folder after installing Firebase CLI:

```bash
cd hosting
firebase login
firebase deploy --only hosting
```

Your links will work at:

- `https://waznah-60781.web.app/open` — open app / App Store
- `https://waznah-60781.web.app/r/{recipeId}` — open community recipe
- `https://waznah-60781.web.app/r/{recipeId}/brew` — open recipe and start brew

Universal Links require this hosting to be deployed and Associated Domains enabled in Xcode.
