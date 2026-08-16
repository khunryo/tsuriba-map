CREATE TABLE IF NOT EXISTS suspended_authors (
  author_id TEXT PRIMARY KEY NOT NULL,
  reason TEXT NOT NULL,
  created_at TEXT NOT NULL
);
