# FoodHub (Flutter Web + Supabase + Google Maps)

FoodHub is a role-based food ecommerce prototype with 4 account types:
- **User (Buyer)**: view/buy/rate (1–5 stars) + message seller
- **Seller**: post products, apply discounts, confirm/decline orders, dashboard analytics
- **Rider**: dashboard + deliveries + real-time location on Google Maps + messaging
- **Admin**: system overview, approvals (user/seller/rider), analytics, commission totals

In the database, the “account type” is stored in the `accounts.role` column.

## Run (quick)

If you run without Supabase keys, the app uses in-memory demo data.

- Web: `flutter run -d chrome`

## Auth (prototype)

- Login supports `Username or Email` + `Password`.
- Registration is multi-step per role (User/Seller/Rider) and creates a **pending** account that must be approved by Admin.
- Email verification + password reset codes are **prototype-only**: the app generates a code and shows it in a SnackBar (no real email is sent).

### Demo credentials (no Supabase keys)

- Admin: `admin` / `Admin123!`
- User: `alice` / `User123!`
- Seller: `freshmart` / `Seller123!`
- Rider: `ramon` / `Rider123!`

## Supabase setup

1) Create a Supabase project.

2) In Supabase **SQL Editor**, run the schema file:
- [supabase/schema.sql](supabase/schema.sql)

If you already ran an older version of this schema, re-run it to apply the latest `ALTER TABLE` changes.

3) (Prototype only) If you’re not ready for Row Level Security yet, you can disable RLS while building.

4) Enable **Realtime** (optional but recommended for multi-session updates):
- Supabase Dashboard → Database → Replication → enable for `accounts`, `products`, `orders`, `messages`

5) Copy your project values:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Run with:

`flutter run -d chrome --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_KEY`

This app also accepts the newer key name:

`flutter run -d chrome --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_KEY`

## Supabase Auth (Email/Password)

This app uses **Supabase Auth** for registration and sign-in.

1) Supabase Dashboard → **Authentication** → **Providers**
- Enable **Email**.

2) Supabase Dashboard → **Authentication** → **URL Configuration**
- Set **Site URL** to your web app URL (or your local dev URL while testing).
- Add any needed **Redirect URLs** (used for password reset links).

3) Admin approval

New registrations create an auth user plus a row in the `accounts` table with `status = pending`.

- To approve users, update the `accounts.status` field to `approved` in Supabase Table Editor.
- To bootstrap an Admin account (Username: `Admin`, Password: `Admin123`), run:
	- Supabase Dashboard → Authentication → Users → Add user
		- Email: `admin@foodhub.local`
		- Password: `Admin123`
	- Then run [supabase/bootstrap_admin.sql](supabase/bootstrap_admin.sql) in the Supabase SQL Editor.

## Google Maps setup

You need a Google Maps API key with Maps enabled.

### Web

Edit [web/index.html](web/index.html) and replace:
- `YOUR_GOOGLE_MAPS_API_KEY`

### Android

Edit [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) and replace:
- `YOUR_GOOGLE_MAPS_API_KEY`

### iOS

Edit [ios/Runner/AppDelegate.swift](ios/Runner/AppDelegate.swift) and replace:
- `YOUR_GOOGLE_MAPS_API_KEY`

