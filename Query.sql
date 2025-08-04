-- Create table: content
CREATE TABLE IF NOT EXISTS content (
    id UUID PRIMARY KEY,
    slug TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    content_type TEXT CHECK (content_type IN ('podcast', 'newsletter', 'video')),
    length_seconds INTEGER,
    publish_ts TIMESTAMPTZ NOT NULL
);

-- Sample content rows
INSERT INTO content (id, slug, title, content_type, length_seconds, publish_ts) VALUES
  ('11111111-1111-1111-1111-111111111111', 'ai-trends', 'AI Trends 2025', 'podcast', 1800, now() - interval '2 days'),
  ('22222222-2222-2222-2222-222222222222', 'climate-future', 'Climate Future', 'video', 1200, now() - interval '1 day'),
  ('33333333-3333-3333-3333-333333333333', 'daily-news', 'Daily Newsletter', 'newsletter', null, now());

-- Create table: engagement_events
CREATE TABLE IF NOT EXISTS engagement_events (
    id BIGSERIAL PRIMARY KEY,
    content_id UUID REFERENCES content(id),
    user_id UUID,
    event_type TEXT CHECK (event_type IN ('play', 'pause', 'finish', 'click')),
    event_ts TIMESTAMPTZ NOT NULL,
    duration_ms INTEGER,
    device TEXT,
    raw_payload JSONB
);

-- Sample engagement rows
INSERT INTO engagement_events (content_id, user_id, event_type, event_ts, duration_ms, device, raw_payload) VALUES
  ('11111111-1111-1111-1111-111111111111', 'aaaa1111-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'play', now(), 30000, 'ios', '{}'),
  ('11111111-1111-1111-1111-111111111111', 'aaaa1111-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'finish', now(), 1700000, 'ios', '{}'),
  ('22222222-2222-2222-2222-222222222222', 'bbbb2222-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'play', now(), 60000, 'web-chrome', '{}'),
  ('22222222-2222-2222-2222-222222222222', 'bbbb2222-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'pause', now(), 200000, 'web-chrome', '{}');
