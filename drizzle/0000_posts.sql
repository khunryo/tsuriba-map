CREATE TABLE IF NOT EXISTS posts (
  id TEXT PRIMARY KEY NOT NULL,
  spot TEXT NOT NULL,
  species TEXT NOT NULL,
  catch_count INTEGER NOT NULL DEFAULT 0,
  max_size_cm REAL,
  method TEXT,
  memo TEXT,
  fishing_date TEXT NOT NULL,
  fishing_time TEXT,
  weather TEXT,
  wave_m REAL,
  depth_m REAL,
  photo_key TEXT,
  photo_type TEXT,
  created_at TEXT NOT NULL
);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at DESC);
