-- Audio capture, transcription, meetings and speakers were removed from the
-- recorder. Children are dropped before parents so foreign keys never dangle.

DROP TRIGGER IF EXISTS audio_transcriptions_ai;
DROP TRIGGER IF EXISTS audio_transcriptions_delete;
DROP TRIGGER IF EXISTS audio_transcriptions_update;

DROP TABLE IF EXISTS audio_transcriptions_fts;
DROP TABLE IF EXISTS audio_tags;
DROP TABLE IF EXISTS meeting_transcript_segments;
DROP TABLE IF EXISTS meetings;
DROP TABLE IF EXISTS speaker_identity_evidence;
DROP TABLE IF EXISTS diarization_segments;
DROP TABLE IF EXISTS diarization_runs;
DROP TABLE IF EXISTS audio_transcriptions;
DROP TABLE IF EXISTS speaker_embeddings;
DROP TABLE IF EXISTS speakers;
DROP TABLE IF EXISTS audio_chunks;
