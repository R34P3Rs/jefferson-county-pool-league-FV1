# Jefferson County Pool League — cloud deployment

This package uses a static web app, Supabase Auth, a shared JSONB league-state record, and Supabase Storage for public rulebook PDFs. It is designed to deploy to Cloudflare Pages and install on iPhone as a PWA.

## 1. Create the GitHub repository
1. Open https://github.com/new
2. Repository name: `jefferson-county-pool-league`
3. Choose **Public** (Cloudflare can also deploy private repos if connected) and **Add a README** is optional.
4. Create the repository.
5. Use **Add file > Upload files** and upload the contents of this folder (not the ZIP file itself): `index.html`, `manifest.json`, `sw.js`, `config.js`, `supabase-schema.sql`, `SETUP.md`, `README.md`, `.gitignore`.
6. Commit the files to the `main` branch.

## 2. Create Supabase project and configure the database
1. Open https://supabase.com/dashboard and create a project on the Free plan.
2. In **SQL Editor**, create a new query, paste all of `supabase-schema.sql`, and run it.
3. Open **Project Settings > API** (or **Connect**, depending on dashboard version). Copy the Project URL and the **publishable key** (or legacy anon/public key). Do NOT copy or expose the `service_role` or secret key.
4. Edit `config.js` in GitHub. Replace `https://YOUR_PROJECT_ID.supabase.co` with your project URL and `YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY` with the publishable/anon key. Commit the change. These two values are public browser config; database security is enforced by RLS.

## 3. Create the administrator account
1. In Supabase, open **Authentication > Users** and choose **Add user** / **Create new user**.
2. Enter the admin email and set a strong unique password. Confirm the user if the dashboard offers that option.
3. In **SQL Editor**, run this query after replacing the email:

```sql
insert into public.league_admins (user_id)
select id from auth.users
where lower(email) = lower('your-admin-email@example.com')
on conflict (user_id) do nothing;
```

4. Keep the admin email and password private. Do not add untrusted users to `league_admins`.

## 4. Deploy to Cloudflare Pages
1. Open https://dash.cloudflare.com/ and create/sign in to an account.
2. Go to **Workers & Pages** > **Create** > **Pages** > **Connect to Git** (the exact menu wording can change).
3. Connect GitHub and select `jefferson-county-pool-league`.
4. For a plain static site, leave the framework preset as **None**. Build command: leave blank. Build output directory: `/` or the repository root, depending on the Cloudflare UI. If the UI requires an output directory, use `.`.
5. Deploy. Cloudflare will provide an HTTPS `*.pages.dev` address.

## 5. Test before inviting the league
- Open the public site in a private/incognito browser: standings and schedule should load; admin changes must not be possible.
- Open Admin and sign in with the Supabase admin account. Add a harmless test change, refresh, and verify it remains.
- Open the same site on a second device and verify that the change appears.
- Upload a small test PDF and confirm it opens for a non-admin visitor.
- Remove test data before announcing the app.

## 6. Install on iPhone
1. Open the Cloudflare `pages.dev` URL in Safari.
2. Tap **Share** > **Add to Home Screen** > **Add**.

## Security and operational notes
- Never put Supabase `service_role`/secret keys in `config.js`, HTML, or GitHub.
- The public browser key is safe only because the SQL enables Row Level Security. Do not disable RLS.
- Only users in `public.league_admins` can update league state or upload PDFs.
- This initial implementation stores the current league dataset in one JSONB row. It is suitable as a starter for a small league, but concurrent edits can overwrite each other; use one admin at a time until the app is upgraded to normalized tables and conflict handling.
- Rule PDFs are public, up to 20 MB, because official league rules are intended to be public. Do not upload private or sensitive documents.
- Supabase Free projects may pause after inactivity and have quotas. Check current provider terms before relying on it for critical records.
- Cloud sync does not automatically import the previous local-only prototype's browser data. If you have important results in the old prototype, export a JSON backup and migrate them deliberately before launch.
