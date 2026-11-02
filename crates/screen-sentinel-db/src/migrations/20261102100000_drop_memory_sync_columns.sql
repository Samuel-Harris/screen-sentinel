-- Cross-device memory sync was removed. SQLite refuses to drop an indexed
-- column, so the uuid index goes first.

DROP INDEX IF EXISTS idx_memories_sync_uuid;
ALTER TABLE memories DROP COLUMN sync_uuid;
ALTER TABLE memories DROP COLUMN sync_modified_by;
