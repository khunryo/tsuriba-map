ALTER TABLE posts ADD COLUMN author_id TEXT;
--> statement-breakpoint
ALTER TABLE posts ADD COLUMN owner_token_hash TEXT;
--> statement-breakpoint
ALTER TABLE posts ADD COLUMN hidden INTEGER NOT NULL DEFAULT 0;
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS post_reports (
  id TEXT PRIMARY KEY NOT NULL,
  post_id TEXT NOT NULL,
  reason TEXT NOT NULL,
  created_at TEXT NOT NULL
);
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS idx_post_reports_post_id ON post_reports(post_id);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS support_requests (
  id TEXT PRIMARY KEY NOT NULL,
  kind TEXT NOT NULL,
  reply TEXT,
  message TEXT NOT NULL,
  created_at TEXT NOT NULL
);
