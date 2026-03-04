-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  SCHEMA — Avis clients (Google + Tripadvisor)                  ║
-- ║  Le Martin Boutique Hotel — 5.0 ★ (219 avis Google)            ║
-- ╚══════════════════════════════════════════════════════════════════╝


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  ENUMS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TYPE review_source AS ENUM ('google', 'tripadvisor');
CREATE TYPE review_travel_group AS ENUM ('couple', 'famille', 'solo', 'amis');
CREATE TYPE review_visit_type AS ENUM ('vacances', 'affaires');


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TABLE — reviews
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE reviews (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source              review_source NOT NULL DEFAULT 'google',
    author_name         TEXT NOT NULL,
    rating              INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text         TEXT,
    original_language   TEXT DEFAULT 'fr',
    is_translated       BOOLEAN DEFAULT FALSE,
    visit_type          review_visit_type,
    travel_group        review_travel_group,
    visited_date        TEXT,
    sub_rating_rooms    DECIMAL(2,1) CHECK (sub_rating_rooms >= 0 AND sub_rating_rooms <= 5),
    sub_rating_service  DECIMAL(2,1) CHECK (sub_rating_service >= 0 AND sub_rating_service <= 5),
    sub_rating_location DECIMAL(2,1) CHECK (sub_rating_location >= 0 AND sub_rating_location <= 5),
    highlights          TEXT[] DEFAULT '{}',
    owner_response      TEXT,
    photo_count         INT DEFAULT 0,
    posted_at           DATE,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_reviews_source ON reviews(source);
CREATE INDEX idx_reviews_rating ON reviews(rating);
CREATE INDEX idx_reviews_posted ON reviews(posted_at DESC);
CREATE INDEX idx_reviews_language ON reviews(original_language);
CREATE INDEX idx_reviews_travel ON reviews(travel_group);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TABLE — review_stats (agrégats par plateforme)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE review_stats (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    platform            TEXT UNIQUE NOT NULL,
    total_reviews       INT DEFAULT 0,
    average_rating      DECIMAL(2,1),
    rating_5_count      INT DEFAULT 0,
    rating_4_count      INT DEFAULT 0,
    rating_3_count      INT DEFAULT 0,
    rating_2_count      INT DEFAULT 0,
    rating_1_count      INT DEFAULT 0,
    last_updated        DATE DEFAULT CURRENT_DATE
);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  RLS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE review_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role full access" ON reviews FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON review_stats FOR ALL USING (true) WITH CHECK (true);
