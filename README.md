# Jefferson County Pool League

Responsive 8-ball league web app/PWA for standings, season schedule, player and team stats, results entry, and rulebook PDFs.

## Cloud-ready package
Follow [SETUP.md](SETUP.md) to connect Supabase Auth/database/storage, deploy to Cloudflare Pages, and install on iPhone. Run `supabase-schema.sql` in Supabase SQL Editor and configure the public project URL/key in `config.js` before deployment.

## Included
- Home dashboard, standings, schedule, player/team stats, rules library, admin area
- 2026–27 regular Wednesday schedule seeded in the app
- Supabase email/password sign-in; database permissions are enforced by Row Level Security and the `league_admins` table
- Shared league data stored in Supabase; public rules PDFs stored in Supabase Storage
- JSON backup export/import
- iPhone-friendly PWA manifest and service worker

## Important
This is a deployment package, not a live website. It becomes cloud-connected only after you configure Supabase, run the SQL, grant an admin user, and deploy. Never publish a Supabase service-role key. The public publishable/anon key belongs in `config.js` and must be paired with the included RLS policies.
