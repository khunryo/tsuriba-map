import { index, integer, real, sqliteTable, text } from "drizzle-orm/sqlite-core";

export const posts = sqliteTable("posts", {
  id: text("id").primaryKey(),
  spot: text("spot").notNull(),
  species: text("species").notNull(),
  catchCount: integer("catch_count").notNull().default(0),
  maxSizeCm: real("max_size_cm"),
  method: text("method"),
  memo: text("memo"),
  fishingDate: text("fishing_date").notNull(),
  fishingTime: text("fishing_time"),
  weather: text("weather"),
  waveM: real("wave_m"),
  depthM: real("depth_m"),
  photoKey: text("photo_key"),
  photoType: text("photo_type"),
  authorId: text("author_id"),
  ownerTokenHash: text("owner_token_hash"),
  hidden: integer("hidden").notNull().default(0),
  createdAt: text("created_at").notNull(),
}, (table) => [index("idx_posts_created_at").on(table.createdAt)]);

export const postReports = sqliteTable("post_reports", {
  id: text("id").primaryKey(),
  postId: text("post_id").notNull(),
  reason: text("reason").notNull(),
  createdAt: text("created_at").notNull(),
}, (table) => [index("idx_post_reports_post_id").on(table.postId)]);

export const suspendedAuthors = sqliteTable("suspended_authors", {
  authorId: text("author_id").primaryKey(),
  reason: text("reason").notNull(),
  createdAt: text("created_at").notNull(),
});

export const supportRequests = sqliteTable("support_requests", {
  id: text("id").primaryKey(),
  kind: text("kind").notNull(),
  reply: text("reply"),
  message: text("message").notNull(),
  createdAt: text("created_at").notNull(),
});
