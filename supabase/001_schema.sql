-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  VisionIA × Le Martin Boutique Hotel                            ║
-- ║  Supabase Database Schema — v1.0                                ║
-- ║  À exécuter dans : Supabase > SQL Editor                       ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  EXTENSIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  ENUMS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TYPE conversation_status AS ENUM ('active', 'closed', 'escalated');
CREATE TYPE conversation_category AS ENUM ('availability', 'pricing', 'booking', 'booking_modification', 'cancellation', 'info_request', 'restaurant', 'activity', 'transfer', 'complaint', 'compliment', 'honeymoon', 'family', 'other');
CREATE TYPE message_direction AS ENUM ('inbound', 'outbound');
CREATE TYPE reservation_status AS ENUM ('pending', 'confirmed', 'cancelled', 'completed', 'no_show');
CREATE TYPE rate_type AS ENUM ('advance_purchase', 'flexible', 'honeymoon', 'non_refundable', 'other');
CREATE TYPE escalation_reason AS ENUM ('low_confidence', 'complaint', 'refund_request', 'booking_modification', 'group_request', 'privatization', 'payment_issue', 'out_of_scope', 'unknown_question', 'physical_action_required', 'other');
CREATE TYPE rule_type AS ENUM ('response', 'escalation', 'tone', 'availability', 'pricing', 'routing', 'greeting', 'signature');
CREATE TYPE app_mode AS ENUM ('draft', 'auto');
CREATE TYPE room_category AS ENUM ('prestige', 'deluxe', 'family_suite');
CREATE TYPE service_category AS ENUM ('wellness', 'transport', 'dining', 'activity', 'room_extra', 'concierge', 'event');
CREATE TYPE beach_side AS ENUM ('french', 'dutch');
CREATE TYPE activity_category AS ENUM ('water_sport', 'boat_trip', 'island_trip', 'land_activity', 'wellness', 'shopping', 'nightlife', 'cultural', 'family');
CREATE TYPE price_range AS ENUM ('€', '€€', '€€€', '€€€€');


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  1. CLIENTS — Profils des clients
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE clients (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email           TEXT UNIQUE NOT NULL,
    first_name      TEXT,
    last_name       TEXT,
    phone           TEXT,
    language        TEXT DEFAULT 'en',
    nationality     TEXT,
    vip_score       INT DEFAULT 0 CHECK (vip_score >= 0 AND vip_score <= 10),
    total_stays     INT DEFAULT 0,
    preferences     JSONB DEFAULT '{}',
    notes           TEXT,
    first_contact_at TIMESTAMPTZ DEFAULT NOW(),
    last_contact_at  TIMESTAMPTZ DEFAULT NOW(),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_clients_email ON clients(email);
CREATE INDEX idx_clients_language ON clients(language);
CREATE INDEX idx_clients_last_contact ON clients(last_contact_at DESC);
CREATE INDEX idx_clients_name ON clients USING gin ((first_name || ' ' || last_name) gin_trgm_ops);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  2. CONVERSATIONS — Fils de discussion email
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE conversations (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id           UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    outlook_thread_id   TEXT,
    outlook_conversation_id TEXT,
    subject             TEXT,
    status              conversation_status DEFAULT 'active',
    category            conversation_category DEFAULT 'other',
    assignee            TEXT DEFAULT 'bot',
    message_count       INT DEFAULT 0,
    last_message_at     TIMESTAMPTZ,
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_conversations_client ON conversations(client_id);
CREATE INDEX idx_conversations_status ON conversations(status);
CREATE INDEX idx_conversations_thread ON conversations(outlook_thread_id);
CREATE INDEX idx_conversations_last_msg ON conversations(last_message_at DESC);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  3. MESSAGES — Chaque email individuel
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE messages (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id     UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    outlook_message_id  TEXT,
    direction           message_direction NOT NULL,
    from_email          TEXT NOT NULL,
    to_email            TEXT NOT NULL,
    subject             TEXT,
    body_text           TEXT,
    body_html           TEXT,
    ai_draft            TEXT,
    final_text          TEXT,
    was_edited          BOOLEAN DEFAULT FALSE,
    confidence_score    DECIMAL(3,2) CHECK (confidence_score >= 0 AND confidence_score <= 1),
    tokens_input        INT DEFAULT 0,
    tokens_output       INT DEFAULT 0,
    cost_eur            DECIMAL(6,4) DEFAULT 0,
    response_time_ms    INT,
    detected_language   TEXT,
    category            conversation_category,
    sent_at             TIMESTAMPTZ,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_direction ON messages(direction);
CREATE INDEX idx_messages_outlook ON messages(outlook_message_id);
CREATE INDEX idx_messages_sent ON messages(sent_at DESC);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  4. RESERVATIONS — Sync Thais PMS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE reservations (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id               UUID REFERENCES clients(id) ON DELETE SET NULL,
    conversation_id         UUID REFERENCES conversations(id) ON DELETE SET NULL,
    thais_reservation_id    TEXT,
    room_slug               TEXT,
    checkin_date            DATE NOT NULL,
    checkout_date           DATE NOT NULL,
    nights                  INT GENERATED ALWAYS AS (checkout_date - checkin_date) STORED,
    guests_adults           INT DEFAULT 1,
    guests_children         INT DEFAULT 0,
    total_price             DECIMAL(10,2),
    currency                TEXT DEFAULT 'EUR',
    rate                    rate_type DEFAULT 'flexible',
    status                  reservation_status DEFAULT 'pending',
    special_requests        TEXT,
    created_at              TIMESTAMPTZ DEFAULT NOW(),
    updated_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_reservations_client ON reservations(client_id);
CREATE INDEX idx_reservations_dates ON reservations(checkin_date, checkout_date);
CREATE INDEX idx_reservations_status ON reservations(status);
CREATE INDEX idx_reservations_thais ON reservations(thais_reservation_id);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  5. ESCALATIONS — Transferts vers l'humain
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE escalations (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id     UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    message_id          UUID REFERENCES messages(id) ON DELETE SET NULL,
    reason              escalation_reason NOT NULL,
    confidence_score    DECIMAL(3,2),
    details             TEXT,
    handled_by          TEXT,
    resolved            BOOLEAN DEFAULT FALSE,
    resolved_at         TIMESTAMPTZ,
    resolution_notes    TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_escalations_conversation ON escalations(conversation_id);
CREATE INDEX idx_escalations_resolved ON escalations(resolved);
CREATE INDEX idx_escalations_created ON escalations(created_at DESC);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  6. AI_RULES — Règles métier de l'IA
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE ai_rules (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_name       TEXT NOT NULL,
    rule            rule_type NOT NULL,
    condition_text  TEXT NOT NULL,
    action_text     TEXT NOT NULL,
    priority        INT DEFAULT 50 CHECK (priority >= 0 AND priority <= 100),
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_rules_type ON ai_rules(rule);
CREATE INDEX idx_rules_active ON ai_rules(is_active) WHERE is_active = TRUE;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  8. DAILY_SUMMARIES — Rapports quotidiens
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE daily_summaries (
    id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date                    DATE UNIQUE NOT NULL,
    emails_received         INT DEFAULT 0,
    emails_replied          INT DEFAULT 0,
    emails_escalated        INT DEFAULT 0,
    avg_response_time_ms    INT,
    avg_confidence_score    DECIMAL(3,2),
    total_tokens_used       INT DEFAULT 0,
    total_cost_eur          DECIMAL(8,4) DEFAULT 0,
    summary_text            TEXT,
    sent_to_owner           BOOLEAN DEFAULT FALSE,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_summaries_date ON daily_summaries(date DESC);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  9. ROOMS — Chambres & Suites de l'hôtel
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE rooms (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug            TEXT UNIQUE NOT NULL,
    name            TEXT NOT NULL,
    category        room_category NOT NULL,
    public_category_fr TEXT,
    public_category_en TEXT,
    size_m2         INT NOT NULL,
    bed_type        TEXT DEFAULT 'Queen',
    bed_twinable    BOOLEAN DEFAULT FALSE,
    extra_bed_price DECIMAL(8,2) DEFAULT 115.00,
    child_supplement DECIMAL(8,2) DEFAULT 150.00,
    view_fr         TEXT,
    view_en         TEXT,
    floor           TEXT,
    terrace         TEXT,
    capacity_adults INT DEFAULT 2,
    capacity_children INT DEFAULT 0,
    description_fr  TEXT,
    description_en  TEXT,
    design_style    TEXT,
    amenities       JSONB DEFAULT '[]',
    accessibility   BOOLEAN DEFAULT FALSE,
    is_communicating BOOLEAN DEFAULT FALSE,
    communicating_with TEXT,
    price_low_season  DECIMAL(8,2),
    price_high_season DECIMAL(8,2),
    is_active       BOOLEAN DEFAULT TRUE,
    sort_order      INT DEFAULT 0
);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  10. HOTEL_SERVICES — Services avec tarifs
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE hotel_services (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug            TEXT UNIQUE NOT NULL,
    name_fr         TEXT NOT NULL,
    name_en         TEXT NOT NULL,
    category        service_category NOT NULL,
    description_fr  TEXT,
    description_en  TEXT,
    price_eur       DECIMAL(8,2),
    price_note      TEXT,
    is_complimentary BOOLEAN DEFAULT FALSE,
    is_active       BOOLEAN DEFAULT TRUE,
    sort_order      INT DEFAULT 0
);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  11. RESTAURANTS — Guide restaurants
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE restaurants (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name                TEXT NOT NULL,
    area                TEXT NOT NULL,
    cuisine             TEXT,
    price               price_range DEFAULT '€€',
    avg_price_eur       INT,
    phone               TEXT,
    website             TEXT,
    rating              DECIMAL(2,1),
    hours               TEXT,
    closed_day          TEXT,
    reservation_required BOOLEAN DEFAULT FALSE,
    dress_code          TEXT DEFAULT 'casual',
    specialties         TEXT,
    vegetarian_options  BOOLEAN DEFAULT TRUE,
    ambiance            TEXT,
    distance_km         DECIMAL(4,1),
    driving_time_min    INT,
    walkable            BOOLEAN DEFAULT FALSE,
    access_note_fr      TEXT,
    access_note_en      TEXT,
    best_for            TEXT[] DEFAULT '{}',
    description_fr      TEXT,
    description_en      TEXT,
    is_partner          BOOLEAN DEFAULT FALSE,
    sort_order          INT DEFAULT 0
);

CREATE INDEX idx_restaurants_area ON restaurants(area);
CREATE INDEX idx_restaurants_best_for ON restaurants USING gin(best_for);
CREATE INDEX idx_restaurants_partner ON restaurants(is_partner) WHERE is_partner = TRUE;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  12. BEACHES — Guide plages
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE beaches (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name            TEXT NOT NULL,
    side            beach_side NOT NULL,
    distance_km     DECIMAL(4,1),
    driving_time_min INT,
    walking_time_min INT,
    characteristics TEXT,
    facilities      TEXT,
    crowd_level     TEXT,
    best_for        TEXT[] DEFAULT '{}',
    description_fr  TEXT,
    description_en  TEXT,
    sort_order      INT DEFAULT 0
);

CREATE INDEX idx_beaches_side ON beaches(side);
CREATE INDEX idx_beaches_distance ON beaches(distance_km ASC);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  13. ACTIVITIES — Activités & excursions
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE activities (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_fr         TEXT NOT NULL,
    name_en         TEXT NOT NULL,
    category        activity_category NOT NULL,
    operator        TEXT,
    location        TEXT,
    distance_km     DECIMAL(4,1),
    price_from_eur  DECIMAL(8,2),
    price_to_eur    DECIMAL(8,2),
    duration        TEXT,
    phone           TEXT,
    website         TEXT,
    description_fr  TEXT,
    description_en  TEXT,
    best_for        TEXT[] DEFAULT '{}',
    booking_required BOOLEAN DEFAULT FALSE,
    sort_order      INT DEFAULT 0
);

CREATE INDEX idx_activities_category ON activities(category);
CREATE INDEX idx_activities_best_for ON activities USING gin(best_for);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  14. PRACTICAL_INFO — Infos pratiques
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE practical_info (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category        TEXT NOT NULL,
    name            TEXT NOT NULL,
    address         TEXT,
    phone           TEXT,
    distance_km     DECIMAL(4,1),
    driving_time_min INT,
    hours           TEXT,
    notes           TEXT,
    sort_order      INT DEFAULT 0
);

CREATE INDEX idx_practical_category ON practical_info(category);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  15. FAQ — Questions fréquentes
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE faq (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_fr     TEXT NOT NULL,
    question_en     TEXT NOT NULL,
    answer_fr       TEXT NOT NULL,
    answer_en       TEXT NOT NULL,
    category        TEXT,
    sort_order      INT DEFAULT 0
);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  FONCTIONS — Auto-update timestamps
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_clients_updated
    BEFORE UPDATE ON clients FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trigger_conversations_updated
    BEFORE UPDATE ON conversations FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trigger_reservations_updated
    BEFORE UPDATE ON reservations FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trigger_rules_updated
    BEFORE UPDATE ON ai_rules FOR EACH ROW EXECUTE FUNCTION update_updated_at();


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  FONCTION — Mise à jour automatique conversation
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE OR REPLACE FUNCTION update_conversation_on_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE conversations SET
        message_count = message_count + 1,
        last_message_at = NEW.created_at,
        updated_at = NOW()
    WHERE id = NEW.conversation_id;

    UPDATE clients SET
        last_contact_at = NOW(),
        updated_at = NOW()
    WHERE id = (SELECT client_id FROM conversations WHERE id = NEW.conversation_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_message_inserted
    AFTER INSERT ON messages FOR EACH ROW EXECUTE FUNCTION update_conversation_on_message();


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  RLS — Row Level Security
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE escalations ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE hotel_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE beaches ENABLE ROW LEVEL SECURITY;
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE practical_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE faq ENABLE ROW LEVEL SECURITY;

-- Politique : accès total via service_role key (backend Python)
CREATE POLICY "Service role full access" ON clients FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON conversations FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON messages FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON reservations FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON escalations FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON ai_rules FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON daily_summaries FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON rooms FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON hotel_services FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON restaurants FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON beaches FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON activities FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON practical_info FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON faq FOR ALL USING (true) WITH CHECK (true);
