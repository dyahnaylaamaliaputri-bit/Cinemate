-- ============================================================
-- Cinemate - Supabase Schema (PB-002)
-- Custom Authentication di atas tabel public.users
-- Referensi SRS: NFR-004, NFR-031
-- ============================================================

-- =====================
-- TABEL: users
-- =====================
CREATE TABLE public.users (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  email         TEXT        UNIQUE NOT NULL,
  password_hash TEXT        NOT NULL,  -- format: "salt:sha256hash"
  full_name     TEXT        NOT NULL,
  phone         TEXT,
  avatar_url    TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_email ON public.users(email);

-- =====================
-- TABEL: sessions
-- =====================
CREATE TABLE public.sessions (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  token_hash  TEXT        NOT NULL,  -- SHA-256 dari raw token
  expires_at  TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_sessions_token_hash ON public.sessions(token_hash);
CREATE INDEX idx_sessions_user_id    ON public.sessions(user_id);

-- =====================
-- TABEL: cinemas
-- =====================
CREATE TABLE public.cinemas (
  id        UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
  name      TEXT             NOT NULL,
  address   TEXT             NOT NULL,
  latitude  DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  city      TEXT             NOT NULL DEFAULT 'Jakarta',
  image_url TEXT
);

-- =====================
-- TABEL: movies (mapping TMDB ke jadwal)
-- =====================
CREATE TABLE public.movies (
  id            UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  tmdb_id       INTEGER UNIQUE NOT NULL,
  title         TEXT    NOT NULL,
  poster_path   TEXT,
  backdrop_path TEXT,
  overview      TEXT,
  release_date  DATE,
  vote_average  NUMERIC(3,1),
  genres        JSONB   DEFAULT '[]'
);

-- =====================
-- TABEL: showtimes
-- =====================
CREATE TABLE public.showtimes (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  cinema_id   UUID        NOT NULL REFERENCES public.cinemas(id) ON DELETE CASCADE,
  movie_id    UUID        NOT NULL REFERENCES public.movies(id)  ON DELETE CASCADE,
  show_date   DATE        NOT NULL,
  show_time   TIME        NOT NULL,
  hall_name   TEXT        NOT NULL DEFAULT 'Studio 1',
  price       INTEGER     NOT NULL DEFAULT 50000,
  total_seats INTEGER     NOT NULL DEFAULT 100,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- =====================
-- TABEL: seat_locks (PB-029)
-- =====================
CREATE TABLE public.seat_locks (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  showtime_id  UUID        NOT NULL REFERENCES public.showtimes(id) ON DELETE CASCADE,
  seat_label   TEXT        NOT NULL,
  user_id      UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  locked_until TIMESTAMPTZ NOT NULL,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (showtime_id, seat_label)
);

-- =====================
-- TABEL: bookings
-- =====================
CREATE TABLE public.bookings (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  showtime_id  UUID        NOT NULL REFERENCES public.showtimes(id),
  booking_code TEXT        UNIQUE NOT NULL,
  status       TEXT        NOT NULL DEFAULT 'pending'
               CHECK (status IN ('pending','paid','expired','cancelled')),
  total_price  INTEGER     NOT NULL,
  qr_data      TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.booking_seats (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  seat_label TEXT NOT NULL,
  UNIQUE (booking_id, seat_label)
);

-- =====================
-- TABEL: fnb_items
-- =====================
CREATE TABLE public.fnb_items (
  id           UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  name         TEXT    NOT NULL,
  description  TEXT,
  price        INTEGER NOT NULL,
  category     TEXT    NOT NULL,
  image_url    TEXT,
  is_available BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE public.fnb_orders (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  booking_id  UUID        REFERENCES public.bookings(id),
  cinema_id   UUID        NOT NULL REFERENCES public.cinemas(id),
  pickup_code TEXT        UNIQUE,
  status      TEXT        NOT NULL DEFAULT 'processing'
              CHECK (status IN ('processing','ready','completed')),
  total_price INTEGER     NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.fnb_order_items (
  id          UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id    UUID    NOT NULL REFERENCES public.fnb_orders(id) ON DELETE CASCADE,
  fnb_item_id UUID    NOT NULL REFERENCES public.fnb_items(id),
  quantity    INTEGER NOT NULL DEFAULT 1,
  note        TEXT,
  subtotal    INTEGER NOT NULL
);

-- =====================
-- ROW LEVEL SECURITY
-- =====================
ALTER TABLE public.users            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cinemas          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.movies           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.showtimes        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seat_locks       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_seats    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fnb_items        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fnb_orders       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fnb_order_items  ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read cinemas"   ON public.cinemas   FOR SELECT USING (true);
CREATE POLICY "Public read movies"    ON public.movies    FOR SELECT USING (true);
CREATE POLICY "Public read showtimes" ON public.showtimes FOR SELECT USING (true);
CREATE POLICY "Public read fnb_items" ON public.fnb_items FOR SELECT USING (true);
CREATE POLICY "Allow user insert"     ON public.users     FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow user select"     ON public.users     FOR SELECT USING (true);
CREATE POLICY "Allow user update"     ON public.users     FOR UPDATE USING (true);
CREATE POLICY "Allow session insert"  ON public.sessions  FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow session select"  ON public.sessions  FOR SELECT USING (true);
CREATE POLICY "Allow session delete"  ON public.sessions  FOR DELETE USING (true);
CREATE POLICY "Allow booking ops"       ON public.bookings       FOR ALL USING (true);
CREATE POLICY "Allow booking seat ops"  ON public.booking_seats  FOR ALL USING (true);
CREATE POLICY "Allow seat lock ops"     ON public.seat_locks     FOR ALL USING (true);
CREATE POLICY "Allow fnb order ops"     ON public.fnb_orders     FOR ALL USING (true);
CREATE POLICY "Allow fnb order item ops" ON public.fnb_order_items FOR ALL USING (true);

-- =====================
-- SEED DATA
-- =====================
INSERT INTO public.cinemas (name, address, latitude, longitude, city) VALUES
  ('Cinemate Plaza',         'Jl. Sudirman No. 1, Jakarta Pusat',      -6.2088, 106.8456, 'Jakarta'),
  ('Nusantara XXI Fiktif',   'Jl. Gatot Subroto No. 25, Jakarta Sel.', -6.2297, 106.8295, 'Jakarta'),
  ('Metro Cinema Senayan',   'Jl. Asia Afrika No. 8, Jakarta Selatan',  -6.2176, 106.8013, 'Jakarta'),
  ('Cinemate Kelapa Gading', 'Jl. Boulevard Raya, Jakarta Utara',      -6.1601, 106.9013, 'Jakarta'),
  ('Bintang Cinema Depok',   'Jl. Margonda Raya No. 50, Depok',        -6.3728, 106.8318, 'Depok');

INSERT INTO public.fnb_items (name, description, price, category) VALUES
  ('Popcorn Regular', 'Popcorn butter ukuran regular', 35000, 'snack'),
  ('Popcorn Large',   'Popcorn butter ukuran besar',   50000, 'snack'),
  ('Nachos',          'Nachos dengan saus keju',        45000, 'snack'),
  ('Coca-Cola Regular', 'Minuman soda 400ml',           25000, 'drink'),
  ('Coca-Cola Large',   'Minuman soda 600ml',           35000, 'drink'),
  ('Air Mineral',       'Air mineral 600ml',            15000, 'drink'),
  ('Combo 1', 'Popcorn Regular + Coca-Cola Regular',    55000, 'combo'),
  ('Combo 2', 'Popcorn Large + 2 Coca-Cola Regular',    95000, 'combo'),
  ('Hot Dog',  'Hot dog dengan saus mustard',            40000, 'food'),
  ('Pretzel',  'Pretzel asin dengan saus keju',          38000, 'food');
