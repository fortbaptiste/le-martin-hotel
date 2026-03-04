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
CREATE TYPE correction_type AS ENUM ('tone', 'factual', 'missing_info', 'wrong_info', 'grammar', 'policy', 'other');
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
--  6. AI_CORRECTIONS — Apprentissage continu
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE ai_corrections (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id          UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    original_draft      TEXT NOT NULL,
    corrected_text      TEXT NOT NULL,
    correction          correction_type DEFAULT 'other',
    correction_note     TEXT,
    corrected_by        TEXT DEFAULT 'Marion',
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_corrections_message ON ai_corrections(message_id);
CREATE INDEX idx_corrections_type ON ai_corrections(correction);
CREATE INDEX idx_corrections_created ON ai_corrections(created_at DESC);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  7. AI_RULES — Règles métier de l'IA
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
    size_m2         INT NOT NULL,
    bed_type        TEXT DEFAULT 'Queen',
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
ALTER TABLE ai_corrections ENABLE ROW LEVEL SECURITY;
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
CREATE POLICY "Service role full access" ON ai_corrections FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON ai_rules FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON daily_summaries FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON rooms FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON hotel_services FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON restaurants FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON beaches FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON activities FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON practical_info FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON faq FOR ALL USING (true) WITH CHECK (true);
-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  SEED — Chambres & Suites du Le Martin Boutique Hotel          ║
-- ╚══════════════════════════════════════════════════════════════════╝

INSERT INTO rooms (slug, name, category, size_m2, bed_type, view_fr, view_en, floor, terrace, capacity_adults, capacity_children, description_fr, description_en, design_style, amenities, accessibility, is_communicating, communicating_with, price_low_season, price_high_season, sort_order) VALUES

-- MARIUS
('marius', 'Suite Marius', 'deluxe', 34, 'Queen (ou 2 lits simples)',
 'Vue jardin', 'Garden view',
 'Rez-de-chaussée', 'Grande terrasse adjacente à la piscine',
 2, 1,
 'Suite au rez-de-chaussée avec accès privé, adjacente à la piscine. Design minimaliste aux tons terre, noyer, terrazzo et marbre. Ambiance de studio indépendant. Seule suite accessible PMR. Lit bébé disponible (0-2 ans), lit d''appoint possible (2-17 ans).',
 'Ground-floor suite with private entrance, adjacent to the pool. Minimalist design with clean earth tones, walnut, terrazzo and marble. Feels like a self-contained studio. Only wheelchair-accessible suite. Cot available (0-2), extra bed possible (2-17).',
 'Minimaliste, tons terre, noyer, terrazzo, marbre',
 '["Climatisation", "Smart TV Apple TV + streaming", "WiFi gratuit", "Machine Nespresso", "Bouilloire SMEG", "Kit thé", "Minibar (sodas, eau, vin)", "Coffre-fort", "Prises USB-C et USB-D", "Bureau + bloc-notes", "Penderie", "Douche pluie walk-in", "Produits Grown Alchemist", "Peignoirs nid d''abeille brodés", "Linge de maison premium", "Sacs de plage en paille + serviettes plage", "Insonorisation", "Service de blanchisserie"]',
 TRUE, FALSE, NULL,
 294.00, 470.00, 1),

-- PIERRE
('pierre', 'Chambre Pierre', 'prestige', 22, 'Queen',
 'Vue jardin tropical avec aperçu mer', 'Tropical garden view with ocean glimpses',
 'Étage supérieur', 'Petite terrasse couverte',
 2, 2,
 'Chambre intime et bucolique à l''étage. Décoration minimaliste originale en bois, pierre, marbre et feuillage. Ambiance feutrée avec des senteurs subtiles de mousse. Fauteuil confortable inclus. Communicante avec la Suite Marcelle pour former la Suite Familiale.',
 'Intimate, bucolic upper-level room. Original minimalist decoration in wood, stone, marble and foliage. Hushed atmosphere with subtle moss scents. Easy chair included. Connects with Marcelle Suite to form the Family Suite.',
 'Original, feutré, bois, pierre, marbre, feuillage, bucolique',
 '["Climatisation", "Smart TV Apple TV + streaming", "WiFi gratuit", "Machine Nespresso", "Bouilloire SMEG", "Kit thé", "Minibar (sodas, eau, vin)", "Coffre-fort", "Prises USB-C et USB-D", "Bureau + bloc-notes", "Penderie", "Douche pluie walk-in", "Produits Grown Alchemist", "Peignoirs nid d''abeille brodés", "Linge de maison premium", "Sacs de plage en paille + serviettes plage", "Insonorisation", "Fauteuil confortable"]',
 FALSE, TRUE, 'marcelle',
 294.00, 410.00, 2),

-- MARCELLE
('marcelle', 'Suite Marcelle', 'deluxe', 30, 'Queen',
 'Vue mer', 'Ocean view',
 'Étage supérieur', 'Grande terrasse vue jardin',
 2, 2,
 'Suite lumineuse à l''étage avec vue mer. Décoration minimaliste originale en bois, pierre, marbre et feuillage. "Une chambre au bord d''une clairière, réveillée par la douce chaleur d''un rayon de soleil." Communicante avec la Chambre Pierre pour former la Suite Familiale.',
 'Bright upper-level suite with ocean view. Original minimalist decoration in wood, stone, marble and foliage. "A room at the edge of a clearing, awakened by the gentle warmth of a sunbeam." Connects with Pierre Room to form the Family Suite.',
 'Lumineux, minimaliste, bois, pierre, marbre, feuillage',
 '["Climatisation", "Smart TV Apple TV + streaming", "WiFi gratuit", "Machine Nespresso", "Bouilloire SMEG", "Kit thé", "Minibar (sodas, eau, vin)", "Coffre-fort", "Prises USB-C et USB-D", "Bureau + bloc-notes", "Penderie", "Douche pluie walk-in", "Produits Grown Alchemist", "Peignoirs nid d''abeille brodés", "Linge de maison premium", "Sacs de plage en paille + serviettes plage", "Insonorisation"]',
 FALSE, TRUE, 'pierre',
 294.00, 470.00, 3),

-- RENÉ
('rene', 'Suite René', 'deluxe', 41, 'Queen',
 'Vue mer panoramique', 'Panoramic ocean view',
 'Étage supérieur', 'Grande terrasse avec salon, table, chaises, bains de soleil',
 2, 0,
 'La plus spacieuse de l''hôtel (41 m²). Vue mer panoramique. "L''ambiance calme et feutrée d''un atelier d''artiste" — peintures éparses, jeux d''ombre et de lumière. Une ode à la rêverie. Idéale pour les lunes de miel. La mer murmure à votre fenêtre au réveil.',
 'The most spacious suite in the hotel (41 m²). Panoramic ocean view. "The quiet, hushed ambience of an artist''s studio" — scattered paintings, interplay of shadow and light. An ode to reverie. Ideal for honeymoons. The sea whispers at your window as you greet the day.',
 'Atelier d''artiste, peintures, jeux d''ombre et lumière, rêverie',
 '["Climatisation", "Smart TV Apple TV + streaming", "WiFi gratuit", "Machine Nespresso", "Bouilloire SMEG", "Kit thé", "Minibar (sodas, eau, vin)", "Coffre-fort", "Prises USB-C et USB-D", "Bureau + bloc-notes", "Penderie", "Douche pluie walk-in", "Produits Grown Alchemist", "Peignoirs nid d''abeille brodés", "Linge de maison premium", "Sacs de plage en paille + serviettes plage", "Insonorisation", "Salon terrasse avec mobilier"]',
 FALSE, FALSE, NULL,
 329.00, 540.00, 4),

-- MARTHE
('marthe', 'Suite Marthe', 'deluxe', 28, 'Queen',
 'Vue mer', 'Ocean view',
 'Étage supérieur', 'Terrasse vue mer avec table, chaises, bains de soleil',
 2, 0,
 'Suite intime et chaleureuse avec vue mer. Décoration chic et décontractée de style parisien. Terrasse avec vue sur l''océan pour des moments de détente parfaits.',
 'Intimate and warm suite with ocean view. Chic, relaxed Parisian-style decor. Terrace with ocean views for perfect moments of relaxation.',
 'Chic parisien, décontracté, intime, chaleureux',
 '["Climatisation", "Smart TV Apple TV + streaming", "WiFi gratuit", "Machine Nespresso", "Bouilloire SMEG", "Kit thé", "Minibar (sodas, eau, vin)", "Coffre-fort", "Prises USB-C et USB-D", "Bureau + bloc-notes", "Penderie", "Douche pluie walk-in", "Produits Grown Alchemist", "Peignoirs nid d''abeille brodés", "Linge de maison premium", "Sacs de plage en paille + serviettes plage", "Insonorisation"]',
 FALSE, FALSE, NULL,
 294.00, 470.00, 5),

-- GEORGETTE
('georgette', 'Suite Georgette', 'deluxe', 28, 'Queen',
 'Vue mer', 'Ocean view',
 'Étage supérieur', 'Grande terrasse vue jardin',
 2, 0,
 'Suite élégante avec vue mer et grande terrasse sur le jardin. Décoration chic et décontractée de style parisien. Un havre de paix élégant baigné de lumière naturelle.',
 'Elegant suite with ocean view and large garden terrace. Chic, relaxed Parisian-style decor. An elegant haven of peace bathed in natural light.',
 'Élégant, chic parisien, décontracté, lumineux',
 '["Climatisation", "Smart TV Apple TV + streaming", "WiFi gratuit", "Machine Nespresso", "Bouilloire SMEG", "Kit thé", "Minibar (sodas, eau, vin)", "Coffre-fort", "Prises USB-C et USB-D", "Bureau + bloc-notes", "Penderie", "Douche pluie walk-in", "Produits Grown Alchemist", "Peignoirs nid d''abeille brodés", "Linge de maison premium", "Sacs de plage en paille + serviettes plage", "Insonorisation"]',
 FALSE, FALSE, NULL,
 294.00, 470.00, 6),

-- FAMILY SUITE (Marcelle + Pierre)
('family-suite', 'Suite Familiale (Marcelle & Pierre)', 'family_suite', 52, '2 Queen',
 'Vue mer + vue jardin', 'Ocean view + garden view',
 'Étage supérieur', '2 grandes terrasses couvertes et meublées',
 4, 2,
 'Combinaison des 2 chambres communicantes Marcelle (30 m²) et Pierre (22 m²) pour former une suite familiale de 52 m². 2 chambres, 2 salles de bain, 2 terrasses. Jusqu''à 3 lits d''appoint possibles. Idéale pour les familles.',
 'Combination of the connecting Marcelle (30 m²) and Pierre (22 m²) rooms forming a 52 m² family suite. 2 bedrooms, 2 bathrooms, 2 terraces. Up to 3 extra beds available. Ideal for families.',
 'Familial, spacieux, double espace, 2 ambiances',
 '["Tout Marcelle + tout Pierre", "2 salles de bain", "2 terrasses", "Jusqu''à 3 lits d''appoint"]',
 FALSE, FALSE, NULL,
 382.00, 750.00, 7);
-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  SEED — Services du Le Martin Boutique Hotel                   ║
-- ╚══════════════════════════════════════════════════════════════════╝

INSERT INTO hotel_services (slug, name_fr, name_en, category, description_fr, description_en, price_eur, price_note, is_complimentary, sort_order) VALUES

-- INCLUS (gratuit)
('breakfast', 'Petit-déjeuner fait maison', 'Homemade breakfast', 'dining',
 'Servi au bord de la piscine, 8h-10h. Buffet froid (viennoiseries, pains artisanaux, confitures maison mangue/passion, pâte chocolat-noisette maison) + carte chaude (Martin''s Bagel, avocado toast, gaufres butternut au saumon, toasts healthy). Jus frais pressés, cappuccinos.',
 'Served poolside, 8am-10am. Cold buffet (French pastries, artisanal breads, homemade mango/passion fruit jams, homemade chocolate-hazelnut spread) + hot menu (Martin''s Bagel, avocado toast, butternut waffles with salmon, healthy toasts). Fresh-squeezed juices, cappuccinos.',
 0, 'Inclus dans le tarif', TRUE, 1),

('pool', 'Piscine chauffée eau de mer', 'Heated saltwater pool', 'activity',
 'Piscine chauffée à l''eau de mer avec entrée par marches, palmier central. Accès 24h/24. Parasols, bains de soleil, bouées.',
 'Heated saltwater pool with step entry, central palm tree. 24/7 access. Parasols, sunloungers, pool rings.',
 0, 'Inclus', TRUE, 2),

('kayaks', 'Kayaks', 'Kayaks', 'activity',
 'Kayaks en libre-service. Dock à 20 secondes à pied de l''hôtel. Idéal pour rejoindre l''Île Pinel (20-25 min de pagaie).',
 'Complimentary kayaks. Dock 20 seconds walk from hotel. Perfect for paddling to Pinel Island (20-25 min).',
 0, 'Inclus', TRUE, 3),

('paddle', 'Stand-up paddle (SUP)', 'Stand-up paddle (SUP)', 'activity',
 'Planches de paddle en libre-service au dock de l''hôtel.',
 'Complimentary stand-up paddle boards at hotel dock.',
 0, 'Inclus', TRUE, 4),

('snorkeling', 'Équipement de snorkeling', 'Snorkeling gear', 'activity',
 'Masques, tubas et palmes disponibles gratuitement.',
 'Masks, snorkels and fins available free of charge.',
 0, 'Inclus', TRUE, 5),

('bikes', 'Vélos', 'Bikes', 'activity',
 'Vélos en prêt gratuit pour explorer les environs.',
 'Complimentary bikes to explore the surroundings.',
 0, 'Inclus', TRUE, 6),

('wifi', 'WiFi haut débit', 'High-speed WiFi', 'room_extra',
 'WiFi gratuit dans toutes les chambres et espaces communs.',
 'Free WiFi in all rooms and common areas.',
 0, 'Inclus', TRUE, 7),

('parking', 'Parking privé', 'Private parking', 'transport',
 'Parking privé gratuit sur place.',
 'Free private on-site parking.',
 0, 'Inclus', TRUE, 8),

('honesty-bar', 'Honesty Bar', 'Honesty Bar', 'dining',
 'Bar en libre-service toute la journée et en soirée. G&T, bière, vin, digestifs, planches de fromages et charcuterie. Les consommations sont ajoutées à la note de chambre.',
 'Self-service bar throughout the day and evening. G&T, beer, wine, nightcaps, cheese and charcuterie boards. Extras charged to room.',
 0, 'Self-service, facturé à la chambre', FALSE, 9),

('concierge', 'Service conciergerie', 'Concierge service', 'concierge',
 'Marion et Emmanuel organisent personnellement vos restaurants, activités, excursions et transferts. Recommandations sur mesure.',
 'Marion and Emmanuel personally arrange your restaurants, activities, excursions and transfers. Bespoke recommendations.',
 0, 'Inclus', TRUE, 10),

('tea-coffee', 'Thé et café en libre-service', 'Self-service tea and coffee', 'dining',
 'Thé et café disponibles en libre-service toute la journée dans les espaces communs.',
 'Tea and coffee available self-service throughout the day in common areas.',
 0, 'Inclus', TRUE, 11),

('beach-bags', 'Sacs de plage et serviettes', 'Beach bags and towels', 'room_extra',
 'Sacs de plage en paille et serviettes de plage fournis dans chaque chambre.',
 'Straw beach bags and beach towels provided in each room.',
 0, 'Inclus', TRUE, 12),

('boutique', 'Boutique Le Martin', 'Le Martin Shop', 'concierge',
 'Petite boutique sur place avec articles Le Martin, crème solaire, accessoires.',
 'On-site designer store with Le Martin branded items, sunscreen, accessories.',
 0, 'Prix selon articles', FALSE, 13),

-- PAYANTS
('shuttle', 'Navette aéroport / port', 'Airport / port shuttle', 'transport',
 'Transfert privé depuis/vers l''aéroport Princess Juliana (SXM) ou le port de Marigot.',
 'Private transfer to/from Princess Juliana Airport (SXM) or Marigot port.',
 75.00, 'Par trajet', FALSE, 20),

('massage-solo', 'Massage individuel (1h)', 'Individual massage (1h)', 'wellness',
 'Massage d''une heure en chambre ou en extérieur. Différentes techniques disponibles.',
 'One-hour massage in-room or outdoors. Various techniques available.',
 120.00, 'Par séance', FALSE, 21),

('massage-couple', 'Massage en duo (1h)', 'Couples massage (1h)', 'wellness',
 'Massage en duo d''une heure, en chambre ou en extérieur.',
 'One-hour couples massage, in-room or outdoors.',
 240.00, 'Par séance', FALSE, 22),

('yoga', 'Cours de yoga privé (1h)', 'Private yoga class (1h)', 'wellness',
 'Cours de yoga privé d''une heure — au jardin, sur paddle ou au bord de la piscine.',
 'One-hour private yoga class — in the garden, on paddle board or poolside.',
 104.00, 'Par séance', FALSE, 23),

('facial', 'Soin visage Carita', 'Carita facial treatment', 'wellness',
 'Soin du visage professionnel par Carita.',
 'Professional Carita facial treatment.',
 180.00, 'Par séance', FALSE, 24),

('coaching', 'Coaching sportif privé (1h)', 'Private coaching session (1h)', 'wellness',
 'Séance de coaching sportif privée d''une heure — à l''hôtel ou en découverte de l''île.',
 'One-hour private coaching session — at the hotel or discovering the island.',
 80.00, 'Par séance', FALSE, 25),

('champagne', 'Champagne en chambre', 'Champagne in room', 'room_extra',
 'Bouteille de champagne déposée en chambre.',
 'Bottle of champagne placed in room.',
 70.00, 'Par bouteille', FALSE, 26),

('flowers', 'Bouquet de fleurs en chambre', 'Flower bouquet in room', 'room_extra',
 'Bouquet de fleurs fraîches déposé en chambre.',
 'Fresh flower bouquet placed in room.',
 48.00, 'Par bouquet', FALSE, 27),

('breakfast-room', 'Petit-déjeuner en chambre', 'In-room breakfast', 'dining',
 'Petit-déjeuner servi directement en chambre ou sur votre terrasse privée.',
 'Breakfast served directly in your room or on your private terrace.',
 15.00, 'Supplément par personne', FALSE, 28),

('cooking-class', 'Cours de cuisine privé', 'Private cooking class', 'activity',
 'Le chef vous initie à la cuisine saint-martinoise avec des produits locaux.',
 'The chef introduces you to Saint-Martin cuisine with locally sourced ingredients.',
 0, 'Sur devis', FALSE, 29),

('themed-dinner', 'Dîner à thème', 'Themed dinner', 'dining',
 'Dîners organisés 1 à 2 fois par semaine par le chef — barbecues, fruits de mer. Ambiance de soirée privée.',
 'Dinners organized 1-2 times per week by the chef — barbecues, seafood cook-ups. Feels like a private party.',
 0, 'Inclus selon le programme', FALSE, 30),

('private-chef', 'Chef privé', 'Private chef', 'dining',
 'Dîner privé préparé par un chef à l''hôtel, sur votre terrasse ou au bord de la piscine.',
 'Private dinner prepared by a chef at the hotel, on your terrace or poolside.',
 0, 'Sur devis', FALSE, 31),

('car-rental', 'Location de voiture', 'Car rental', 'transport',
 'Arrangement de location de voiture via la conciergerie.',
 'Car rental arrangement through concierge.',
 0, 'Via conciergerie, prix selon modèle', FALSE, 32),

('laundry', 'Blanchisserie', 'Laundry service', 'room_extra',
 'Service de blanchisserie et pressing.',
 'Laundry and dry cleaning service.',
 0, 'Prix selon articles', FALSE, 33),

('privatization', 'Privatisation de l''hôtel', 'Full hotel privatization', 'event',
 'Réservation exclusive de l''hôtel entier pour réunions familiales, anniversaires, séminaires intimes. Personnel dédié, partenaires locaux mobilisés.',
 'Exclusive booking of the entire hotel for family reunions, birthdays, intimate seminars. Dedicated staff, local partners mobilized.',
 0, 'Sur devis personnalisé', FALSE, 34),

('honeymoon', 'Forfait Lune de Miel', 'Honeymoon package', 'event',
 'Package personnalisé avec champagne, douceurs sucrées, bouquet de fleurs. Conçu sur mesure avec les mariés.',
 'Customized package with champagne, sweet treats, flower bouquet. Designed with you, for you.',
 896.00, 'À partir de, par nuit (Suite René)', FALSE, 35),

('pilates', 'Cours de Pilates', 'Pilates class', 'wellness',
 'Cours de Pilates disponibles à l''hôtel.',
 'Pilates classes available at the hotel.',
 0, 'Sur demande', FALSE, 36);
-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  SEED — Restaurants (66 restaurants)                            ║
-- ╚══════════════════════════════════════════════════════════════════╝

INSERT INTO restaurants (name, area, cuisine, price, avg_price_eur, phone, website, rating, hours, closed_day, reservation_required, dress_code, specialties, vegetarian_options, ambiance, distance_km, driving_time_min, best_for, is_partner, sort_order) VALUES

-- ═══ CUL DE SAC / MONT VERNON (1-5 min) ═══
('La Villa Hibiscus', 'Cul de Sac', 'Gastronomique française', '€€€€', 90, NULL, NULL, 4.9, 'Mar-Sam dîner', 'Dimanche, Lundi', TRUE, 'smart casual', 'Menus dégustation du Chef Bastian Schenk (formé chez Joël Robuchon, Anne-Sophie Pic)', TRUE, 'Intime, gastronomique, jardin tropical', 1.5, 3, ARRAY['romantic', 'honeymoon', 'french', 'special_occasion'], TRUE, 1),
('Sol e Luna', 'Cul de Sac', 'Gastronomique française / Créole', '€€€', 70, '+590 590 29 08 29', NULL, 4.8, 'Dîner', NULL, TRUE, 'smart casual', 'Cuisine française revisitée, produits locaux', TRUE, 'Élégant, vue mer', 1.5, 3, ARRAY['romantic', 'french', 'seafood'], TRUE, 2),
('Le Taitu', 'Cul de Sac', 'Français-Créole', '€€', 35, '+590 590 87 43 23', NULL, 4.7, 'Lun-Sam 11h45-14h15 & 18h30-21h30', 'Dimanche', FALSE, 'casual', 'Cuisine locale fraîche, ambiance décontractée', TRUE, 'Décontracté, local', 1.0, 2, ARRAY['casual', 'local', 'budget'], FALSE, 3),
('Chez Hercule', 'Cul de Sac', 'Créole / BBQ', '€', 15, NULL, NULL, 4.5, 'Déjeuner et dîner', NULL, FALSE, 'casual', 'Grillades créoles, poisson frais', FALSE, 'Local, simple, authentique', 1.0, 2, ARRAY['budget', 'local', 'family'], FALSE, 4),
('Lulu''s Corner', 'Mont Vernon', 'Café / Brunch', '€', 12, NULL, NULL, 4.6, 'Petit-déjeuner et déjeuner', NULL, FALSE, 'casual', 'Brunch, smoothies, bowls', TRUE, 'Cozy, healthy', 2.0, 4, ARRAY['budget', 'family', 'brunch'], FALSE, 5),
('SAO Asian Factory', 'Mont Vernon', 'Asiatique fusion', '€€', 30, NULL, NULL, 4.3, 'Déjeuner et dîner', NULL, FALSE, 'casual', 'Sushi, wok, noodles', TRUE, 'Moderne, asiatique', 2.0, 4, ARRAY['casual', 'family'], FALSE, 6),
('Papadan Pizza', 'Mont Vernon', 'Pizza / Italien', '€', 15, NULL, NULL, 4.4, 'Déjeuner et dîner', NULL, FALSE, 'casual', 'Pizzas artisanales', TRUE, 'Familial, décontracté', 2.0, 4, ARRAY['budget', 'family'], FALSE, 7),

-- ═══ ORIENT BAY (5 min) ═══
('L''Atelier', 'Orient Bay', 'Steakhouse français', '€€€', 60, '+590 690 22 10 22', 'latelier-sxm.com', 4.7, 'Tous les jours 17h30-22h30', NULL, TRUE, 'smart casual', 'Viandes maturées, côte de boeuf, tartares', FALSE, 'Chic, terrasse extérieure', 2.5, 5, ARRAY['romantic', 'meat', 'special_occasion'], FALSE, 10),
('Maison Mère', 'Orient Bay', 'Bistrot français', '€€', 40, '+590 690 38 11 39', 'maisonmere.restaurant', 4.6, 'Mer-Lun 18h-22h30', 'Mardi', TRUE, 'smart casual', 'Cuisine française bistrot, cocktails primés, ambiance coloniale', TRUE, 'Colonial, cocktails, élégant', 2.5, 5, ARRAY['romantic', 'french', 'cocktails'], TRUE, 11),
('Kontiki Beach', 'Orient Bay', 'Franco-asiatique fusion', '€€', 40, '+590 690 66 24 25', 'kontiki.restaurant', 4.3, 'Tous les jours 9h-18h', NULL, FALSE, 'casual beach', 'Fusion, beach club, DJ le dimanche', TRUE, 'Beach club, pieds dans le sable', 2.0, 5, ARRAY['beach', 'family', 'sunset'], FALSE, 12),
('KKO Beach', 'Orient Bay', 'Fusion / Nikkei', '€€', 40, '+590 690 75 41 39', NULL, 4.4, 'Tous les jours', NULL, FALSE, 'casual beach', 'Cuisine fusion, DJ sessions le dimanche', TRUE, 'Beach club tendance, DJ', 2.0, 5, ARRAY['beach', 'nightlife', 'sunset'], FALSE, 13),
('Coco Beach', 'Orient Bay', 'Gourmet beach', '€€', 40, NULL, 'cocobeach.restaurant', 4.4, 'Lun, Jeu-Dim 9h30-17h, Ven dîner 19h-21h30', 'Mardi, Mercredi', FALSE, 'casual beach', 'Cuisine beach gourmet, brunch', TRUE, 'Beach chic, pieds dans le sable', 2.0, 5, ARRAY['beach', 'brunch', 'family'], FALSE, 14),
('Bikini Beach', 'Orient Bay', 'Beach casual', '€€', 30, NULL, NULL, 4.2, 'Tous les jours 9h-21h30', NULL, FALSE, 'casual beach', 'Burgers, salades, poisson grillé', TRUE, 'Décontracté, vue mer', 2.0, 5, ARRAY['beach', 'family', 'casual', 'budget'], FALSE, 15),
('Wai Beach', 'Orient Bay', 'Beach dining haut de gamme', '€€€', 60, NULL, NULL, 4.5, 'Tous les jours', NULL, TRUE, 'smart casual', 'Gastronomie beach, musique live vendredi', FALSE, 'Haut de gamme, live music', 2.0, 5, ARRAY['romantic', 'beach', 'sunset', 'nightlife'], FALSE, 16),
('Joa Beach', 'Orient Bay', 'Beach club', '€€', 35, NULL, NULL, 4.3, 'Tous les jours', NULL, FALSE, 'casual beach', 'Beach club avec transats', TRUE, 'Tendance, musique', 2.0, 5, ARRAY['beach', 'nightlife'], FALSE, 17),
('Orange Fever', 'Orient Bay', 'Beach bar', '€', 20, NULL, NULL, 4.2, 'Tous les jours', NULL, FALSE, 'casual beach', 'Cocktails, snacks, ambiance', TRUE, 'Décontracté, fun', 2.0, 5, ARRAY['beach', 'budget', 'nightlife'], FALSE, 18),
('Le Piment', 'Orient Bay', 'Créole', '€€', 30, NULL, NULL, 4.5, 'Déjeuner et dîner', NULL, FALSE, 'casual', 'Cuisine créole authentique', TRUE, 'Local, chaleureux', 2.5, 5, ARRAY['local', 'casual'], FALSE, 19),

-- ═══ GRAND CASE — Fine Dining (10 min) ═══
('Le Pressoir', 'Grand Case', 'Gastronomique française', '€€€€', 100, '+590 690 52 75 95', 'lepressoirsxm.com', 4.6, 'Lun-Sam dîner, 1er service 17h, dernier 22h', 'Dimanche', TRUE, 'smart casual', '"Caribbean Restaurant of the Year" 4 ans de suite. Cuisine française gastronomique dans une maison créole historique.', TRUE, 'Maison créole historique, romantique, élégant', 6.0, 10, ARRAY['romantic', 'honeymoon', 'french', 'special_occasion', 'seafood'], TRUE, 20),
('Le Cottage', 'Grand Case', 'Bistrot chic français', '€€€', 65, '+590 690 56 32 69', 'lecottagesxm.com', 4.7, 'Lun-Sam 18h-22h', 'Dimanche', TRUE, 'smart casual', 'Cuisine française bistrot chic, produits frais', TRUE, 'Chic, intime, terrasse', 6.0, 10, ARRAY['romantic', 'french'], FALSE, 21),
('Le Tastevin', 'Grand Case', 'Gastronomique française', '€€€', 70, NULL, NULL, 4.6, 'Dîner', NULL, TRUE, 'smart casual', 'Haute cuisine française, cave à vins', TRUE, 'Gastronomique, raffiné', 6.0, 10, ARRAY['romantic', 'french', 'special_occasion'], FALSE, 22),
('L''Auberge Gourmande', 'Grand Case', 'Gastronomique française', '€€€', 65, NULL, NULL, 4.5, 'Dîner', NULL, TRUE, 'smart casual', 'Classiques français revisités', TRUE, 'Traditionnel, élégant', 6.0, 10, ARRAY['romantic', 'french'], FALSE, 23),
('Spiga', 'Grand Case', 'Italien créatif', '€€€', 65, '+590 590 52 47 83', 'spigasxm.com', 4.7, 'Lun-Sam 18h-22h', 'Dimanche', TRUE, 'smart casual', 'Pâtes fraîches maison, cuisine italienne créative', TRUE, 'Cour intérieure, romantique, italien raffiné', 6.0, 10, ARRAY['romantic', 'italian', 'special_occasion'], FALSE, 24),
('Ocean 82', 'Grand Case', 'Seafood français', '€€€', 70, NULL, 'ocean82.fr', 4.6, 'Dîner', NULL, TRUE, 'smart casual', 'Fruits de mer, poissons, vue mer', TRUE, 'Vue mer, terrasse, élégant', 6.0, 10, ARRAY['romantic', 'seafood', 'sunset'], FALSE, 25),
('Bistrot Caraïbes', 'Grand Case', 'Français-Caribéen', '€€€', 60, '+590 590 29 08 29', 'bistrot-caraibes.com', 4.7, 'Lun-Dim 18h-22h', NULL, TRUE, 'smart casual', 'Fusion franco-caribéenne, produits locaux', TRUE, 'Terrasse, vue mer, chaleureux', 6.0, 10, ARRAY['romantic', 'french', 'seafood', 'sunset'], TRUE, 26),
('La Villa', 'Grand Case', 'Français-Caribéen élevé', '€€€', 65, '+590 690 50 12 04', 'lavillasxm.com', 4.7, 'Dîner à partir de 17h', 'Mercredi', TRUE, 'smart casual', 'Cuisine française élevée, ambiance raffinée', TRUE, 'Raffiné, vue mer', 6.0, 10, ARRAY['romantic', 'french', 'special_occasion'], FALSE, 27),
('L''Effet Mer', 'Grand Case', 'Seafood français', '€€€', 55, NULL, NULL, 4.5, 'Dîner', NULL, TRUE, 'smart casual', 'Fruits de mer frais, ambiance maritime', TRUE, 'Maritime, front de mer', 6.0, 10, ARRAY['seafood', 'romantic'], FALSE, 28),

-- ═══ GRAND CASE — Casual & Bars ═══
('Calmos Café', 'Grand Case', 'Beach bar & grill', '€€', 30, NULL, NULL, 4.8, 'Toute la journée', NULL, FALSE, 'casual beach', 'Cocktails, grillades, coucher de soleil légendaire', TRUE, 'Pieds dans le sable, sunset, décontracté', 6.0, 10, ARRAY['sunset', 'beach', 'casual', 'cocktails'], FALSE, 30),
('Rainbow Café', 'Grand Case', 'Bar restaurant', '€€', 25, NULL, NULL, 4.4, 'Toute la journée', NULL, FALSE, 'casual', 'Cocktails, ambiance festive', TRUE, 'Festif, coloré', 6.0, 10, ARRAY['nightlife', 'casual'], FALSE, 31),
('Nice SXM', 'Grand Case', 'Français', '€€', 30, NULL, NULL, 4.3, 'Déjeuner et dîner', NULL, FALSE, 'casual', 'Cuisine française simple et bonne', TRUE, 'Décontracté', 6.0, 10, ARRAY['casual', 'french', 'budget'], FALSE, 32),
('Blue Martini', 'Grand Case', 'Bar cocktails', '€€', 25, NULL, NULL, 4.4, 'Soirée', NULL, FALSE, 'casual', 'Cocktails, musique', FALSE, 'Bar ambiance, soirée', 6.0, 10, ARRAY['nightlife', 'cocktails'], FALSE, 33),

-- ═══ GRAND CASE — Lolos (BBQ créole, €8-14/assiette) ═══
('Sky''s the Limit', 'Grand Case', 'BBQ Créole (Lolo)', '€', 12, NULL, NULL, 4.7, 'Soirée', NULL, FALSE, 'casual', 'Ribs, poulet grillé, langouste, sides créoles. Le plus célèbre des lolos.', FALSE, 'Extérieur, tables en bois, musique, authentique', 6.0, 10, ARRAY['budget', 'local', 'family', 'must_try'], FALSE, 35),
('Talk of the Town', 'Grand Case', 'BBQ Créole (Lolo)', '€', 12, NULL, NULL, 4.6, 'Soirée', NULL, FALSE, 'casual', 'BBQ ribs, poulet, poisson grillé, lobster', FALSE, 'Local, convivial, file d''attente le soir', 6.0, 10, ARRAY['budget', 'local', 'family'], FALSE, 36),
('Rib Shack', 'Grand Case', 'BBQ Créole (Lolo)', '€', 12, NULL, NULL, 4.5, 'Soirée', NULL, FALSE, 'casual', 'Ribs fumées, BBQ', FALSE, 'Authentique, fumoir', 6.0, 10, ARRAY['budget', 'local', 'meat'], FALSE, 37),
('Au Coin des Amis', 'Grand Case', 'BBQ Créole (Lolo)', '€', 12, NULL, NULL, 4.4, 'Soirée', NULL, FALSE, 'casual', 'Grillades créoles', FALSE, 'Local, simple', 6.0, 10, ARRAY['budget', 'local'], FALSE, 38),
('Scooby''s', 'Grand Case', 'BBQ Créole (Lolo)', '€', 10, NULL, NULL, 4.3, 'Soirée', NULL, FALSE, 'casual', 'BBQ pas cher, ambiance locale', FALSE, 'Très local, prix mini', 6.0, 10, ARRAY['budget', 'local'], FALSE, 39),
('Le Ti Coin Créole', 'Grand Case', 'Créole traditionnel', '€', 15, NULL, NULL, 4.5, 'Déjeuner et dîner', NULL, FALSE, 'casual', 'Plats créoles traditionnels', TRUE, 'Authentique, familial', 6.0, 10, ARRAY['budget', 'local', 'family'], FALSE, 40),

-- ═══ MARIGOT (15 min) ═══
('Le Tropicana', 'Marigot', 'Français élégant', '€€€', 45, '+590 590 87 79 07', NULL, 4.6, 'Mar-Sam 12h-14h30 & 18h-21h30', 'Dimanche, Lundi', TRUE, 'smart casual', '#3 de Marigot sur TripAdvisor. Restaurant préféré de Linda Thornton (cliente régulière).', TRUE, 'Élégant, front de mer', 9.0, 15, ARRAY['romantic', 'french', 'seafood'], TRUE, 41),
('Le Bistro de la Mer', 'Marigot', 'Français-Créole / Pizzas', '€€', 25, '+590 590 29 30 03', NULL, 3.8, 'Tous les jours 9h-22h', NULL, FALSE, 'casual', 'Cuisine franco-créole, pizzas, front de mer Marigot', TRUE, 'Front de mer, décontracté', 9.0, 15, ARRAY['casual', 'family', 'seafood', 'budget'], TRUE, 42),
('Enoch''s Place', 'Marigot', 'Créole local', '€', 12, NULL, NULL, 4.7, 'Petit-déjeuner et déjeuner uniquement', NULL, FALSE, 'casual', 'Marché de Marigot. Incontournable local. Poisson grillé, lambi.', FALSE, 'Marché, local, authentique', 9.0, 15, ARRAY['budget', 'local', 'must_try', 'brunch'], FALSE, 43),
('La Belle Époque', 'Marigot', 'Français classique', '€€€', 50, NULL, NULL, 4.4, 'Déjeuner et dîner', NULL, TRUE, 'smart casual', 'Cuisine française classique en bord de mer', TRUE, 'Classique, front de mer', 9.0, 15, ARRAY['romantic', 'french'], FALSE, 44),
('Le Marocain', 'Marigot', 'Marocain', '€€', 30, NULL, NULL, 4.3, 'Dîner', NULL, TRUE, 'casual', 'Tajines, couscous, pastilla', TRUE, 'Décor marocain, dépaysant', 9.0, 15, ARRAY['casual', 'exotic'], FALSE, 45),
('Rosemary''s', 'Marigot', 'Créole / International', '€€', 25, NULL, NULL, 4.5, 'Déjeuner et dîner', NULL, FALSE, 'casual', 'Cuisine créole et internationale', TRUE, 'Local, chaleureux', 9.0, 15, ARRAY['casual', 'local', 'family'], FALSE, 46),

-- ═══ ANSE MARCEL (10 min) ═══
('Le Bistro du Port', 'Anse Marcel', 'Français / Marina', '€€', 35, NULL, NULL, 4.3, 'Déjeuner et dîner', NULL, FALSE, 'casual', 'Cuisine française face à la marina', TRUE, 'Marina, bateaux, calme', 5.0, 10, ARRAY['casual', 'family', 'seafood'], FALSE, 50),

-- ═══ FRIAR''S BAY (12 min) ═══
('Kali''s Beach Bar', 'Friar''s Bay', 'BBQ / Créole', '€', 15, NULL, NULL, 4.6, 'Toute la journée', NULL, FALSE, 'casual beach', 'Légendaire. Bush Rum maison. Full Moon Party mensuelle (feu de camp, reggae).', FALSE, 'Légendaire, pieds dans le sable, bohème', 10.0, 15, ARRAY['beach', 'nightlife', 'local', 'must_try', 'sunset'], FALSE, 55),
('978 Beach Lounge', 'Friar''s Bay', 'Caribéen fusion', '€€', 30, NULL, NULL, 4.4, 'Toute la journée', NULL, FALSE, 'casual beach', 'Cuisine caribéenne fusion, cocktails', TRUE, 'Tendance, beach, moderne', 10.0, 15, ARRAY['beach', 'casual', 'cocktails'], FALSE, 56),
('Friar''s Bay Beach Café', 'Friar''s Bay', 'Français', '€€', 30, NULL, NULL, 4.3, 'Déjeuner', NULL, FALSE, 'casual beach', 'Classique français sur le sable', TRUE, 'Pieds dans le sable, classique', 10.0, 15, ARRAY['beach', 'french', 'casual'], FALSE, 57),

-- ═══ TERRES BASSES / BAIE LONGUE (25 min) ═══
('La Samanna - L''Oursin', 'Baie Longue', 'Gastronomique méditerranéen', '€€€€', 120, NULL, NULL, 4.5, 'Dîner', NULL, TRUE, 'smart casual', 'Restaurant gastronomique du Belmond La Samanna. Vue mer spectaculaire.', TRUE, 'Luxe absolu, vue mer, Belmond', 17.0, 25, ARRAY['romantic', 'honeymoon', 'special_occasion', 'french', 'sunset'], TRUE, 60),
('La Samanna - Laplaj', 'Baie Longue', 'Beach fusion', '€€€', 60, NULL, NULL, 4.4, 'Déjeuner', NULL, TRUE, 'casual beach', 'Déjeuner pieds dans le sable au Belmond La Samanna', TRUE, 'Luxe, plage, Belmond', 17.0, 25, ARRAY['beach', 'romantic', 'special_occasion'], TRUE, 61),

-- ═══ SIMPSON BAY / MAHO (25 min) ═══
('SkipJack''s', 'Simpson Bay', 'Seafood / Grill', '€€', 35, NULL, NULL, 4.5, 'Déjeuner et dîner', NULL, FALSE, 'casual', 'Poisson frais du jour, ambiance marina', TRUE, 'Marina, décontracté', 17.0, 25, ARRAY['seafood', 'casual', 'family'], FALSE, 65),
('IZI Ristorante', 'Maho', 'Italien', '€€€', 50, NULL, NULL, 4.4, 'Dîner', NULL, TRUE, 'smart casual', 'Cuisine italienne haut de gamme', TRUE, 'Élégant, italien', 20.0, 28, ARRAY['italian', 'romantic'], FALSE, 66),
('Sunset Bar & Grill', 'Maho', 'Grill / Bar', '€€', 25, NULL, NULL, 4.3, 'Toute la journée', NULL, FALSE, 'casual', 'Le bar emblématique de Maho Beach pour voir les avions atterrir', TRUE, 'Avions, iconique, fun', 20.0, 28, ARRAY['must_try', 'family', 'casual', 'nightlife'], FALSE, 67),
('Bamboo House', 'Maho', 'Asiatique', '€€', 30, NULL, NULL, 4.2, 'Dîner', NULL, FALSE, 'casual', 'Cuisine asiatique, sushis', TRUE, 'Moderne, asiatique', 20.0, 28, ARRAY['casual', 'exotic'], FALSE, 68),

-- ═══ PHILIPSBURG (20 min) ═══
('Ocean Lounge', 'Philipsburg', 'International', '€€€', 50, NULL, NULL, 4.4, 'Déjeuner et dîner', NULL, TRUE, 'smart casual', 'Vue sur Great Bay, boardwalk', TRUE, 'Vue mer, boardwalk, élégant', 15.0, 22, ARRAY['romantic', 'seafood', 'sunset'], FALSE, 70),
('Lazy Lizard', 'Philipsburg', 'Beach bar', '€', 15, NULL, NULL, 4.5, 'Toute la journée', NULL, FALSE, 'casual beach', 'Beach bar iconique du boardwalk', TRUE, 'Boardwalk, décontracté, fun', 15.0, 22, ARRAY['beach', 'budget', 'casual'], FALSE, 71),

-- ═══ PINEL ISLAND (5 min bateau) ═══
('Le Karibuni', 'Île Pinel', 'Créole / Seafood', '€€', 30, NULL, NULL, 4.5, '10h-16h', NULL, FALSE, 'casual beach', 'Restaurant sur l''île Pinel. Langouste grillée, pieds dans le sable, vue Anguilla.', FALSE, 'Île déserte, pieds dans le sable, paradisiaque', 1.7, NULL, ARRAY['beach', 'seafood', 'must_try', 'romantic'], FALSE, 75),
('Yellow Beach', 'Île Pinel', 'Créole / Beach', '€€', 25, NULL, NULL, 4.4, '10h-16h', NULL, FALSE, 'casual beach', 'Second restaurant de l''île Pinel. Vue sur St-Barth.', FALSE, 'Île, plage, vue St-Barth', 1.7, NULL, ARRAY['beach', 'budget', 'family'], FALSE, 76);
-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  SEED — Plages de Saint-Martin (20+)                           ║
-- ╚══════════════════════════════════════════════════════════════════╝

INSERT INTO beaches (name, side, distance_km, driving_time_min, walking_time_min, characteristics, facilities, crowd_level, best_for, description_fr, description_en, sort_order) VALUES

-- ═══ CÔTÉ FRANÇAIS ═══
('Cul de Sac Bay', 'french', 0, 0, 0,
 'Baie calme, dock de l''hôtel, départ kayak/paddle vers Pinel', 'Dock hôtel, kayaks gratuits, paddle gratuits', 'Calme',
 ARRAY['kayak', 'paddle', 'snorkeling', 'calm'],
 'La baie de l''hôtel. Dock à 20 secondes à pied pour les kayaks et paddles. Départ vers l''île Pinel.',
 'The hotel''s own bay. Dock 20 seconds walk for kayaks and paddleboards. Departure point for Pinel Island.', 1),

('Orient Bay Beach', 'french', 1.9, 5, 10,
 'La plus célèbre de l''île. 2 km de sable blanc, beach clubs, sports nautiques', 'Beach clubs, transats, restaurants, jet ski, kitesurf, parasailing, toilettes, douches', 'Animé',
 ARRAY['beach_clubs', 'water_sports', 'nightlife', 'family', 'snorkeling'],
 'Le "Saint-Tropez des Caraïbes". Plage la plus animée de l''île avec beach clubs (Kontiki, KKO, Bikini Beach, Wai Beach), restaurants, sports nautiques. Section naturiste au sud.',
 'The "Saint-Tropez of the Caribbean". Liveliest beach with beach clubs (Kontiki, KKO, Bikini Beach, Wai Beach), restaurants, water sports. Naturist section at south end.', 2),

('Île Pinel', 'french', 1.7, 0, 0,
 'Îlot paradisiaque en face de Cul de Sac. Snorkeling exceptionnel, tortues', 'Restaurants (Karibuni, Yellow Beach), snorkeling, pas de transats', 'Modéré',
 ARRAY['snorkeling', 'romantic', 'must_visit', 'kayak', 'family'],
 'Petit îlot accessible en ferry (10€ A/R, 5 min) ou kayak gratuit hôtel (20-25 min). Sentier de snorkeling balisé, tortues, raies. 2 restaurants pieds dans le sable. Vue sur Anguilla et St-Barth depuis le sommet.',
 'Small island accessible by ferry (€10 round trip, 5 min) or free hotel kayak (20-25 min). Marked snorkeling trail, turtles, rays. 2 feet-in-the-sand restaurants. Views of Anguilla and St Barth from hilltop.', 3),

('Galion Beach (Le Galion)', 'french', 7.0, 10, 0,
 'Protégée par récif, eau peu profonde, vent constant', 'Windsurf, kitesurf, toilettes', 'Calme',
 ARRAY['family', 'windsurf', 'kitesurf', 'calm', 'children'],
 'Plage familiale protégée par un récif. Eau calme et peu profonde, idéale pour les enfants. Spot de windsurf et kitesurf grâce au vent constant.',
 'Family-friendly reef-protected beach. Calm, shallow water ideal for children. Windsurf and kitesurf spot thanks to constant wind.', 4),

('Grand Case Beach', 'french', 6.0, 10, 0,
 'Sable blanc, eau calme, adjacente à la capitale gastronomique', 'Restaurants à 50m, transats, calme', 'Modéré',
 ARRAY['calm', 'romantic', 'sunset', 'snorkeling'],
 'Belle plage calme de sable blanc. Idéale avant ou après un dîner dans les restaurants de Grand Case. Snorkeling à Creole Rock accessible en bateau.',
 'Beautiful calm white sand beach. Ideal before or after dinner at Grand Case restaurants. Snorkeling at Creole Rock accessible by boat.', 5),

('Anse Marcel', 'french', 5.0, 10, 0,
 'Crique protégée très calme, marina, eau turquoise', 'Marina, restaurants, jet ski, plongée', 'Calme',
 ARRAY['calm', 'family', 'snorkeling', 'romantic'],
 'Crique protégée et très calme. Marina avec restaurants. Eau turquoise limpide. Idéale pour les familles et le snorkeling.',
 'Protected, very calm cove. Marina with restaurants. Crystal-clear turquoise water. Ideal for families and snorkeling.', 6),

('Happy Bay', 'french', 4.4, 10, 15,
 'Plage secrète accessible uniquement à pied depuis Friar''s Bay (15 min de marche)', 'Aucune installation', 'Très calme',
 ARRAY['secluded', 'romantic', 'hiking', 'quiet'],
 'Plage secrète et isolée. Accessible uniquement par un sentier de 15 min depuis Friar''s Bay. Aucune installation — apporter eau et nourriture. Vue sur Anguilla.',
 'Secret, secluded beach. Only accessible via 15-min trail from Friar''s Bay. No facilities — bring water and food. Views of Anguilla.', 7),

('Friar''s Bay (Baie des Pères)', 'french', 10.0, 15, 0,
 'Plage bohème avec bars de plage légendaires, Full Moon Party', 'Kali''s Beach Bar, 978 Beach Lounge, restaurants, transats', 'Modéré',
 ARRAY['nightlife', 'local', 'sunset', 'bohemian'],
 'Plage bohème et emblématique. Kali''s Beach Bar et son Bush Rum maison sont légendaires. Full Moon Party mensuelle avec feu de camp et reggae.',
 'Bohemian, iconic beach. Kali''s Beach Bar and its homemade Bush Rum are legendary. Monthly Full Moon Party with bonfire and reggae.', 8),

('Baie Rouge', 'french', 15.0, 20, 0,
 'Sable rosé, grotte pour snorkeling, romantique', 'Quelques transats, bar de plage saisonnier', 'Calme',
 ARRAY['romantic', 'snorkeling', 'quiet', 'secluded'],
 'Plage au sable rosé-rouge. Grotte accessible à la nage menant à une plage cachée. Excellent snorkeling. Très romantique.',
 'Pink-red sand beach. Swim-through cave leading to hidden beach. Excellent snorkeling. Very romantic.', 9),

('Baie Longue (Long Bay)', 'french', 17.0, 25, 0,
 'Plage préservée, Belmond La Samanna, très calme', 'La Samanna resort', 'Très calme',
 ARRAY['quiet', 'romantic', 'luxury', 'secluded'],
 'Longue plage préservée bordée par le Belmond La Samanna. Très calme, presque déserte. Idéale pour une marche romantique.',
 'Long, pristine beach bordered by Belmond La Samanna. Very quiet, almost deserted. Ideal for a romantic walk.', 10),

('Baie Nettle', 'french', 12.0, 18, 0,
 'Côté lagune, hôtels, kitesurf', 'Hôtels, restaurants, kitesurf', 'Animé',
 ARRAY['kitesurf', 'hotels'],
 'Plage côté lagune, bordée d''hôtels. Spot de kitesurf.',
 'Lagoon-side beach, lined with hotels. Kitesurfing spot.', 11),

('Tintamarre Island', 'french', 8.0, 0, 0,
 'Île inhabitée, réserve naturelle, tortues marines, piste d''atterrissage abandonnée', 'Aucune — apporter tout', 'Désert',
 ARRAY['snorkeling', 'nature', 'secluded', 'adventure'],
 'Île totalement inhabitée à 25 min en bateau. Réserve naturelle : tortues marines, raies, récif préservé. Ancienne piste d''atterrissage. Tintamarre Express depuis Cul de Sac : 25€ A/R.',
 'Totally uninhabited island 25 min by boat. Nature reserve: sea turtles, rays, pristine reef. Abandoned airstrip. Tintamarre Express from Cul de Sac: €25 round trip.', 12),

-- ═══ CÔTÉ HOLLANDAIS ═══
('Maho Beach', 'dutch', 20.0, 28, 0,
 'Célèbre pour les avions qui atterrissent à quelques mètres au-dessus de la plage', 'Sunset Bar & Grill, boutiques, casinos à proximité', 'Très animé',
 ARRAY['must_visit', 'family', 'nightlife', 'unique'],
 'La plage la plus célèbre au monde pour les avions. Les jets atterrissent à 10-20 mètres au-dessus de la plage (aéroport Princess Juliana). Sunset Bar & Grill pour regarder le spectacle.',
 'The world''s most famous plane-spotting beach. Jets land 10-20 meters above the beach (Princess Juliana Airport). Sunset Bar & Grill to watch the show.', 15),

('Mullet Bay Beach', 'dutch', 19.0, 25, 0,
 'Sable blanc fin, vagues douces, coucher de soleil', 'Limité — apporter provisions', 'Modéré',
 ARRAY['quiet', 'sunset', 'swimming'],
 'Belle plage de sable blanc fin. Vagues douces. Magnifique coucher de soleil. Peu d''installations — apporter eau et nourriture.',
 'Beautiful fine white sand beach. Gentle waves. Magnificent sunset. Few facilities — bring water and food.', 16),

('Cupecoy Beach', 'dutch', 18.0, 25, 0,
 'Falaises de grès spectaculaires, grottes, isolé', 'Aucune', 'Calme',
 ARRAY['secluded', 'romantic', 'photography', 'unique'],
 'Plage dramatique avec falaises de grès et grottes naturelles. Section isolée. Paysage unique sur l''île.',
 'Dramatic beach with sandstone cliffs and natural caves. Secluded sections. Unique landscape on the island.', 17),

('Simpson Bay Beach', 'dutch', 17.0, 22, 0,
 'Longue plage calme, proche aéroport', 'Bars, restaurants à proximité', 'Calme',
 ARRAY['calm', 'quiet', 'swimming'],
 'Longue plage calme près de l''aéroport. Idéale pour une dernière baignade avant le vol.',
 'Long, quiet beach near the airport. Ideal for a last swim before your flight.', 18),

('Great Bay Beach', 'dutch', 15.0, 22, 0,
 'Boardwalk de Philipsburg, shopping, bateaux de croisière', 'Boardwalk, restaurants, shopping duty-free, toilettes', 'Très animé',
 ARRAY['shopping', 'family', 'casual'],
 'Plage du boardwalk de Philipsburg. Shopping duty-free à 50m. Très animé les jours de croisière.',
 'Philipsburg boardwalk beach. Duty-free shopping 50m away. Very busy on cruise ship days.', 19),

('Dawn Beach', 'dutch', 8.0, 12, 0,
 'Côte est, lever de soleil, vagues', 'Hôtel Westin, restaurant', 'Calme',
 ARRAY['sunrise', 'surfing', 'quiet'],
 'Plage de la côte est, parfaite pour le lever de soleil. Quelques vagues. Près d''Oyster Bay.',
 'East coast beach, perfect for sunrise. Some waves. Near Oyster Bay.', 20),

('Little Bay Beach', 'dutch', 14.0, 20, 0,
 'Parc de sculptures sous-marines, Sea Trek', 'Sea Trek diving, snorkeling', 'Modéré',
 ARRAY['snorkeling', 'diving', 'unique', 'family'],
 'Parc de sculptures sous-marines unique. Activité Sea Trek (marche sous l''eau avec casque). Excellent snorkeling.',
 'Unique underwater sculpture park. Sea Trek activity (underwater walking with helmet). Excellent snorkeling.', 21),

('Kim Sha Beach', 'dutch', 17.0, 22, 0,
 'Plage calme protégée par récif, proche vie nocturne', 'Bars, restaurants', 'Modéré',
 ARRAY['calm', 'nightlife', 'family'],
 'Plage calme protégée par un récif. Proche des bars et de la vie nocturne de Simpson Bay.',
 'Calm reef-protected beach. Close to Simpson Bay bars and nightlife.', 22);
-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  SEED — Activités & Excursions                                 ║
-- ╚══════════════════════════════════════════════════════════════════╝

INSERT INTO activities (name_fr, name_en, category, operator, location, distance_km, price_from_eur, price_to_eur, duration, phone, website, description_fr, description_en, best_for, booking_required, sort_order) VALUES

-- ═══ SPORTS NAUTIQUES ═══
('Jet ski', 'Jet ski', 'water_sport', 'Bikini Watersports', 'Orient Bay', 2.0, 70, 110, '30-60 min', NULL, 'bikini-watersports.com',
 'Location de jet ski sur Orient Bay. 70€/30min, 110€/1h.', 'Jet ski rental on Orient Bay. €70/30min, €110/1h.',
 ARRAY['adventure', 'couples'], FALSE, 1),

('Kitesurf — cours', 'Kitesurfing — lessons', 'water_sport', 'SXM Kiteschool', 'Cul de Sac (Pinel Jetty)', 0.5, 150, 417, '2-6h', NULL, 'sxmkiteschool.com',
 'École de kitesurf à 500m de l''hôtel ! Cours 2h : 162$, 4h : 293$, initiation 6h : 417$. Location : 103$/jour.',
 'Kitesurfing school 500m from hotel! 2h lesson: $162, 4h: $293, 6h initiation: $417. Rental: $103/day.',
 ARRAY['adventure', 'sport'], TRUE, 2),

('Kitesurf & Windsurf', 'Kitesurf & Windsurf', 'water_sport', 'Wind Adventures', 'Orient Bay', 2.0, 55, 350, '1h-1 semaine', NULL, 'wind-adventures.com',
 'Cours kitesurf, windsurf et location. Windsurf : 60$/2h cours, 86$/jour location. Kite cruises disponibles.',
 'Kitesurf, windsurf lessons and rental. Windsurf: $60/2h lesson, $86/day rental. Kite cruises available.',
 ARRAY['adventure', 'sport'], TRUE, 3),

('Parasailing', 'Parasailing', 'water_sport', 'Bikini Watersports', 'Orient Bay', 2.0, 50, 100, '12-15 min', NULL, 'bikini-watersports.com',
 'Vol en parasailing au-dessus d''Orient Bay. 50-100€/pers, 12-15 min de vol.',
 'Parasailing flight above Orient Bay. €50-100/person, 12-15 min flight.',
 ARRAY['adventure', 'family', 'couples'], FALSE, 4),

('Flyboard', 'Flyboard', 'water_sport', 'Bikini Watersports', 'Orient Bay', 2.0, 100, 100, '20 min', NULL, 'bikini-watersports.com',
 'Flyboard sur Orient Bay. 100€/20 min.',
 'Flyboard on Orient Bay. €100/20 min.',
 ARRAY['adventure'], TRUE, 5),

('Plongée sous-marine', 'Scuba diving', 'water_sport', 'Bubble Shop', 'Hope Estate (route Orient Bay)', 3.0, 55, 470, '1-4h', NULL, 'bubbleshopsxm.com',
 'Centre PADI & CMAS. Sites : Creole Rock, Tintamarre. Baptême ~60€, exploration ~55€, PADI Open Water ~470$. Mar-Sam 9h-13h.',
 'PADI & CMAS center. Sites: Creole Rock, Tintamarre. Discovery dive ~€60, exploration ~€55, PADI Open Water ~$470. Tue-Sat 9am-1pm.',
 ARRAY['adventure', 'nature', 'couples'], TRUE, 6),

('Snorkeling guidé', 'Guided snorkeling', 'water_sport', 'Caribbean Paddling', 'Cul de Sac', 0.5, 85, 85, '2-3h', NULL, 'caribbeanpaddling.com',
 'Kayak + snorkeling guidé vers Pinel Island. 85$/pers. Départ Cul de Sac.',
 'Guided kayak + snorkeling to Pinel Island. $85/person. Departure from Cul de Sac.',
 ARRAY['nature', 'family', 'couples'], TRUE, 7),

('Massage à la plage', 'Beach massage', 'wellness', 'Colibri Massage SXM', 'Orient Bay (KKO Beach & Coco Beach)', 2.0, 60, 120, '30-60 min', NULL, 'colibri-massage-sxm.com',
 '#1 activité Orient Bay (TripAdvisor). Techniques californiennes, thaï, reiki. 20 ans d''expérience.',
 '#1 activity in Orient Bay (TripAdvisor). Californian, Thai, Reiki techniques. 20 years experience.',
 ARRAY['wellness', 'couples', 'romantic'], TRUE, 8),

-- ═══ EXCURSIONS EN BATEAU ═══
('Ferry vers Île Pinel', 'Ferry to Pinel Island', 'island_trip', 'Ferry Cul de Sac', 'Dock Cul de Sac', 0.5, 10, 10, '5 min traversée, demi-journée sur place', NULL, NULL,
 'Ferry toutes les 30 min, 10h-16h. 10€ A/R. Cash uniquement. Dernier retour 16h30. Snorkeling, 2 restaurants, rando colline.',
 'Ferry every 30 min, 10am-4pm. €10 round trip. Cash only. Last return 4:30pm. Snorkeling, 2 restaurants, hilltop hike.',
 ARRAY['must_do', 'family', 'snorkeling', 'nature', 'couples'], FALSE, 10),

('Tintamarre Express', 'Tintamarre Express', 'island_trip', 'Tintamarre Express', 'Dock Cul de Sac', 0.5, 25, 25, 'Journée (9h30-15h30)', '0690 15 57 40', 'tintamarreexpress.com',
 'Excursion vers l''île inhabitée de Tintamarre. 25€ A/R. Départ 9h30, retour 15h30. Tortues, raies, récif préservé. Réservation obligatoire. APPORTER eau et nourriture.',
 'Trip to uninhabited Tintamarre Island. €25 round trip. Departs 9:30am, returns 3:30pm. Turtles, rays, pristine reef. Booking required. BRING water and food.',
 ARRAY['nature', 'snorkeling', 'adventure'], TRUE, 11),

('Ferry vers Anguilla', 'Ferry to Anguilla', 'island_trip', 'Marigot Ferry Terminal', 'Marigot', 9.0, 60, 70, 'Journée (20 min traversée)', '+590 590 87 10 68', 'anguillaferrytimes.com',
 'Ferry toutes les 30-45 min, 8h30-18h. 30$ aller + 7€ taxe départ. Passeport OBLIGATOIRE. 20 min traversée. Anguilla : Rendezvous Bay, Shoal Bay, restaurants world-class.',
 'Ferry every 30-45 min, 8:30am-6pm. $30 one-way + €7 departure tax. Passport REQUIRED. 20 min crossing. Anguilla: Rendezvous Bay, Shoal Bay, world-class restaurants.',
 ARRAY['must_do', 'beach', 'romantic', 'adventure'], FALSE, 12),

('Ferry vers Saint-Barth', 'Ferry to St. Barths', 'island_trip', 'Voyager / Great Bay Express', 'Marigot ou Philipsburg', 9.0, 90, 162, 'Journée (45-60 min traversée)', NULL, 'voy12.com',
 'Voyager depuis Marigot : ECO 108€ A/R, SMART 131€ A/R, BUSINESS 162€ A/R (1h). Great Bay Express depuis Philipsburg : 90$ journée (45min). Avion depuis Grand Case : 15 min, 100-150$ aller. Passeport obligatoire.',
 'Voyager from Marigot: ECO €108 RT, SMART €131 RT, BUSINESS €162 RT (1h). Great Bay Express from Philipsburg: $90 day trip (45min). Plane from Grand Case: 15 min, $100-150 one-way. Passport required.',
 ARRAY['luxury', 'shopping', 'romantic', 'must_do'], TRUE, 13),

('Catamaran partagé', 'Shared catamaran cruise', 'boat_trip', 'Divers opérateurs', 'Simpson Bay Marina', 17.0, 95, 195, '4-8h', NULL, NULL,
 'Croisières catamaran partagées. 95-195$/pers. Snorkeling, open bar, déjeuner inclus selon formule.',
 'Shared catamaran cruises. $95-195/person. Snorkeling, open bar, lunch included depending on package.',
 ARRAY['family', 'couples', 'snorkeling'], TRUE, 14),

('Croisière coucher de soleil', 'Sunset cruise', 'boat_trip', 'Divers opérateurs', 'Simpson Bay / Marigot', 9.0, 45, 150, '2-3h', NULL, NULL,
 'Croisières coucher de soleil. 45-150$/pers. Cocktails, canapés, musique.',
 'Sunset cruises. $45-150/person. Cocktails, canapés, music.',
 ARRAY['romantic', 'honeymoon', 'sunset'], TRUE, 15),

('Bateau privé charter', 'Private boat charter', 'boat_trip', 'Divers opérateurs', 'Simpson Bay / Marigot', 9.0, 600, 2500, '4-8h', NULL, NULL,
 'Location bateau privé avec skipper. Demi-journée : 600-900€, journée : 1000-2500€. Destinations : Pinel, Tintamarre, Anguilla, St-Barth.',
 'Private boat hire with skipper. Half-day: €600-900, full day: €1000-2500. Destinations: Pinel, Tintamarre, Anguilla, St Barth.',
 ARRAY['luxury', 'romantic', 'honeymoon', 'adventure'], TRUE, 16),

('Pêche au gros', 'Deep sea fishing', 'boat_trip', 'St Maarten Fishing Charters', 'Simpson Bay Marina', 17.0, 110, 1400, '4-12h', NULL, NULL,
 'Pêche sportive. Partagé : dès 110$/pers. Privé : 400-1400$ le bateau.',
 'Sport fishing. Shared: from $110/person. Private: $400-1400 per boat.',
 ARRAY['adventure', 'sport'], TRUE, 17),

-- ═══ ACTIVITÉS TERRESTRES ═══
('Randonnée Pic Paradis', 'Pic Paradis hike', 'land_activity', NULL, 'Loterie Farm', 8.0, 10, 10, '2-2h30', NULL, 'loteriefarm.com',
 'Point culminant de l''île (424m). Entrée Loterie Farm : 10€. Difficulté modérée. Vue panoramique 360° sur l''île et les îles voisines.',
 'Highest point on the island (424m). Loterie Farm entry: €10. Moderate difficulty. 360° panoramic view of the island and neighbors.',
 ARRAY['hiking', 'nature', 'adventure', 'photography'], FALSE, 20),

('Loterie Farm — Zipline', 'Loterie Farm — Zipline', 'land_activity', 'Loterie Farm', 'Pic Paradis', 8.0, 55, 85, '1-2h', NULL, 'loteriefarm.com',
 'Tyrolienne dans la canopée tropicale. Fly Zone : 55-65€, Extreme : 85€. Cabana pool : 190€, Cabanita : 40€.',
 'Zipline through tropical canopy. Fly Zone: €55-65, Extreme: €85. Cabana pool: €190, Cabanita: €40.',
 ARRAY['adventure', 'family', 'nature'], TRUE, 21),

('Rainforest Adventures — Zipline', 'Rainforest Adventures — Zipline', 'land_activity', 'Rockland Estate', 'Côté hollandais', 15.0, 52, 139, '2-3h', NULL, 'rainforestadventure.com',
 'All Rides Pass : 139$. Flying Dutchman (tyrolienne géante) : 99$. Sky Explorer (téléphérique) : 52$.',
 'All Rides Pass: $139. Flying Dutchman (giant zipline): $99. Sky Explorer (chairlift): $52.',
 ARRAY['adventure', 'family'], TRUE, 22),

('Butterfly Farm', 'Butterfly Farm', 'cultural', 'Butterfly Farm', 'Route d''Orient Bay', 2.5, 15, 15, '45 min', NULL, NULL,
 'Ferme aux papillons tropicaux. ~15$/pers. Retour illimité avec le même billet. 9h-15h30.',
 'Tropical butterfly farm. ~$15/person. Unlimited returns with same ticket. 9am-3:30pm.',
 ARRAY['family', 'children', 'nature'], FALSE, 23),

('Fort Louis', 'Fort Louis', 'cultural', NULL, 'Marigot', 9.0, 0, 0, '45 min-1h', NULL, NULL,
 'Fort historique surplombant Marigot et la baie. Entrée gratuite. Vue panoramique. 15 min de montée.',
 'Historic fort overlooking Marigot and the bay. Free entry. Panoramic view. 15 min climb.',
 ARRAY['cultural', 'photography', 'family', 'free'], FALSE, 24),

('Dégustation de rhum — Topper''s', 'Rum tasting — Topper''s', 'cultural', 'Topper''s Rhum', 'Côté hollandais', 15.0, 24, 33, '90 min', NULL, 'toppers.sx',
 'Dégustation illimitée de 20+ rhums. 24-33$/pers. 90 min. Histoire du rhum caribéen.',
 'Unlimited tasting of 20+ rums. $24-33/person. 90 min. History of Caribbean rum.',
 ARRAY['cultural', 'couples', 'must_try'], TRUE, 25),

('Cours de cuisine créole', 'Creole cooking class', 'cultural', 'Creole Culinary Classroom', 'Saint-Martin', 8.0, 109, 139, '3-4h', NULL, 'creoleculinaryclassroom.com',
 'Apprenez à cuisiner créole avec des ingrédients locaux. 109-139$/pers.',
 'Learn Creole cooking with local ingredients. $109-139/person.',
 ARRAY['cultural', 'couples', 'family', 'foodie'], TRUE, 26),

('Tour en quad / ATV', 'ATV / Quad tour', 'land_activity', 'Divers opérateurs', 'Saint-Martin', 10.0, 70, 95, '2-3h', NULL, NULL,
 'Tour de l''île en quad. 70-95$/pers.',
 'Island tour by ATV/quad. $70-95/person.',
 ARRAY['adventure'], TRUE, 27),

('Équitation sur la plage', 'Horseback riding on the beach', 'land_activity', NULL, 'Côté hollandais', 15.0, 75, 75, '1-2h', NULL, NULL,
 'Balade à cheval sur la plage. ~75$/pers.',
 'Horseback riding on the beach. ~$75/person.',
 ARRAY['romantic', 'nature', 'couples'], TRUE, 28),

('Tour en hélicoptère', 'Helicopter tour', 'land_activity', 'Corail Hélicoptères', 'Aéroport', 15.0, 115, 300, '15-30 min', NULL, 'corailhelico-mu.com',
 'Survol de l''île en hélicoptère. À partir de 115$/pers.',
 'Helicopter flight over the island. From $115/person.',
 ARRAY['luxury', 'romantic', 'honeymoon', 'photography'], TRUE, 29),

-- ═══ WELLNESS ═══
('Yoga privé à l''hôtel', 'Private yoga at hotel', 'wellness', 'Le Martin Hotel', 'Hôtel', 0, 104, 104, '1h', NULL, NULL,
 'Cours privé au jardin, sur paddle ou au bord de la piscine. 104€/séance.',
 'Private class in garden, on paddleboard or poolside. €104/session.',
 ARRAY['wellness', 'couples'], TRUE, 30),

('Spa Gaia', 'Gaia Spa', 'wellness', 'Gaia Spa', 'Cul de Sac', 1.5, 80, 200, '1-2h', NULL, NULL,
 'Spa à proximité de l''hôtel. Massages, soins du visage, soins corporels.',
 'Spa near the hotel. Massages, facials, body treatments.',
 ARRAY['wellness', 'couples', 'romantic'], TRUE, 31),

-- ═══ SHOPPING ═══
('Marché de Marigot', 'Marigot Market', 'shopping', NULL, 'Marigot', 9.0, 0, 0, '1-2h', NULL, NULL,
 'Marché ouvert tous les jours sauf dimanche, 8h-13h. Meilleurs jours : mercredi et samedi (marché complet avec poisson, fruits, fermiers). Épices, rhum arrangé, artisanat.',
 'Open market daily except Sunday, 8am-1pm. Best days: Wednesday and Saturday (full market with fish, produce, farmers). Spices, rum, crafts.',
 ARRAY['cultural', 'family', 'shopping', 'free'], FALSE, 35),

('Shopping duty-free Philipsburg', 'Duty-free shopping Philipsburg', 'shopping', NULL, 'Philipsburg', 15.0, 0, 0, '2-4h', NULL, NULL,
 'Front Street : 1,5 km de boutiques duty-free. Bijoux (Cartier, Rolex, Dior), parfums, électronique, mode. Guavaberry Emporium pour la liqueur locale.',
 'Front Street: 1.5 km of duty-free shops. Jewelry (Cartier, Rolex, Dior), perfumes, electronics, fashion. Guavaberry Emporium for local liqueur.',
 ARRAY['shopping', 'luxury'], FALSE, 36),

-- ═══ VIE NOCTURNE ═══
('Casino Royale', 'Casino Royale', 'nightlife', 'Casino Royale', 'Maho Village', 20.0, 0, 0, 'Soirée', NULL, NULL,
 'Plus grand casino de l''île : 2000 m², 400+ machines, 21 tables. Côté hollandais.',
 'Largest casino on the island: 21,000 sq ft, 400+ slots, 21 tables. Dutch side.',
 ARRAY['nightlife'], FALSE, 40),

('Full Moon Party — Kali''s', 'Full Moon Party — Kali''s', 'nightlife', 'Kali''s Beach Bar', 'Friar''s Bay', 10.0, 0, 0, 'Soirée mensuelle', NULL, NULL,
 'Fête de la pleine lune mensuelle à Kali''s Beach Bar. Feu de camp, reggae, Bush Rum. Gratuit.',
 'Monthly full moon party at Kali''s Beach Bar. Bonfire, reggae, Bush Rum. Free.',
 ARRAY['nightlife', 'local', 'must_try', 'free'], FALSE, 41);
-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  SEED — Infos pratiques, FAQ & Règles IA                       ║
-- ╚══════════════════════════════════════════════════════════════════╝


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  INFOS PRATIQUES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT INTO practical_info (category, name, address, phone, distance_km, driving_time_min, hours, notes, sort_order) VALUES

-- Urgences
('emergency', 'Police (côté français)', NULL, '17', NULL, NULL, '24/7', 'Gendarmerie nationale', 1),
('emergency', 'SAMU / Ambulance', NULL, '15', NULL, NULL, '24/7', 'Urgences médicales', 2),
('emergency', 'Pompiers', NULL, '18', NULL, NULL, '24/7', NULL, 3),
('emergency', 'Numéro européen d''urgence', NULL, '112', NULL, NULL, '24/7', 'Fonctionne partout', 4),
('emergency', 'Police (côté hollandais)', NULL, '911', NULL, NULL, '24/7', 'Sint Maarten police', 5),

-- Santé
('health', 'Hôpital Louis Constant Fleming', 'Concordia, est de Marigot', '+590 590 52 25 25', 8.0, 12, '24/7 urgences', 'Hôpital principal côté français', 10),
('health', 'Pharmacie Cul de Sac', 'Route de Cul de Sac', NULL, 1.5, 2, 'Lun-Sam 8h-19h', 'Pharmacie la plus proche de l''hôtel', 11),

-- Aéroports
('airport', 'Aéroport Princess Juliana (SXM)', 'Simpson Bay, côté hollandais', NULL, 15.0, 25, '24/7', 'Aéroport international principal. 27+ compagnies aériennes. Vols directs USA, Europe, Caraïbes. Shuttle hôtel : 75€.', 20),
('airport', 'Aéroport Grand Case-Espérance (SFG)', 'Grand Case, côté français', NULL, 6.0, 10, 'Horaires de vol', 'Aéroport régional. Vols vers St-Barth (15 min), Guadeloupe. Pratique pour arrivées inter-îles.', 21),

-- Transport
('transport', 'Ferry Marigot → Anguilla', 'Port de Marigot', '+590 590 87 10 68', 9.0, 15, '8h30-18h, toutes les 30-45 min', '30$ aller + 7€ taxe. Passeport obligatoire. 20 min traversée.', 25),
('transport', 'Ferry Marigot → St-Barth (Voyager)', 'Port de Marigot', NULL, 9.0, 15, 'Jusqu''à 5 départs/jour', 'ECO 108€ A/R, SMART 131€, BUSINESS 162€. 1h traversée.', 26),
('transport', 'Taxis', 'Partout sur l''île', NULL, NULL, NULL, '24/7', 'Tarifs fixes par zone. Supplément 25% 22h-minuit, 50% minuit-6h. Pas de Uber/Lyft.', 27),
('transport', 'Location de voitures', 'Aéroports et hôtels', NULL, NULL, NULL, 'Variable', 'À partir de ~20$/jour. Conduite à droite. Permis français ou international.', 28),

-- Commerce
('shopping', 'Supermarché Gocci', 'Route de Cul de Sac', NULL, 1.5, 2, 'Lun-Sam', 'Supermarché moderne le plus proche de l''hôtel.', 30),
('shopping', 'Super U', 'Près de Grand Case', NULL, 5.0, 8, 'Lun-Sam 8h-20h', 'Grand supermarché complet.', 31),
('shopping', 'Marché de Marigot', 'Waterfront, Marigot', NULL, 9.0, 15, 'Tous les jours sauf dim, 8h-13h', 'Meilleurs jours : mercredi et samedi.', 32),

-- Banques
('bank', 'Distributeur ATM le plus proche', 'Cul de Sac / Grand Case', NULL, 2.0, 4, '24/7', 'ATMs français : EUR. ATMs hollandais : USD. La plupart des commerces acceptent les deux.', 35),

-- Divers
('info', 'Fuseau horaire', NULL, NULL, NULL, NULL, NULL, 'AST (Atlantic Standard Time) = UTC-4. Pas de changement d''heure.', 40),
('info', 'Monnaie', NULL, NULL, NULL, NULL, NULL, 'EUR côté français, USD/ANG côté hollandais. Les deux acceptés presque partout. Cartes Visa/Mastercard largement acceptées.', 41),
('info', 'Langues', NULL, NULL, NULL, NULL, NULL, 'Français (côté FR), anglais (côté NL), créole, espagnol. L''anglais est compris partout.', 42),
('info', 'Électricité', NULL, NULL, NULL, NULL, NULL, '220V côté français (prises EU), 110V côté hollandais (prises US). L''hôtel fournit prises USB-C et USB-D.', 43),
('info', 'Saison cyclonique', NULL, NULL, NULL, NULL, 'Juin - Novembre', 'Pic : août-octobre. L''hôtel ferme mi-août à octobre.', 44),
('info', 'Meilleure période', NULL, NULL, NULL, NULL, 'Décembre - Avril', 'Haute saison. Temps sec, 27-30°C. Février-mars idéal.', 45),
('info', 'Pourboires', NULL, NULL, NULL, NULL, NULL, 'Côté FR : service compris (15%), pourboire supplémentaire apprécié. Côté NL : style américain, 15-20% attendu.', 46);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  FAQ
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT INTO faq (question_fr, question_en, answer_fr, answer_en, category, sort_order) VALUES

('Quels sont les horaires de check-in et check-out ?', 'What are the check-in and check-out times?',
 'Check-in : 15h00 - 18h00. Check-out : 11h00. En cas d''arrivée anticipée ou de départ tardif, nous proposons un espace de stockage des bagages et un accès au salon.',
 'Check-in: 3:00 PM - 6:00 PM. Check-out: 11:00 AM. For early arrivals or late departures, we offer luggage storage and lounge access.',
 'general', 1),

('Le petit-déjeuner est-il inclus ?', 'Is breakfast included?',
 'Oui ! Le petit-déjeuner fait maison est inclus dans tous nos tarifs. Servi au bord de la piscine de 8h à 10h : buffet froid (viennoiseries, pains artisanaux, confitures maison) + carte chaude (bagel, avocado toast, gaufres). Jus frais pressés et cappuccinos.',
 'Yes! Homemade breakfast is included in all our rates. Served poolside from 8am to 10am: cold buffet (pastries, artisanal breads, homemade jams) + hot menu (bagel, avocado toast, waffles). Fresh-squeezed juices and cappuccinos.',
 'dining', 2),

('Acceptez-vous les animaux ?', 'Do you accept pets?',
 'Non, malheureusement les animaux ne sont pas acceptés à l''hôtel.',
 'No, unfortunately pets are not accepted at the hotel.',
 'policy', 3),

('L''hôtel est-il fumeur ?', 'Is smoking allowed?',
 'L''hôtel est entièrement non-fumeur. Des frais de nettoyage de 70€ seront facturés en cas de non-respect.',
 'The hotel is entirely non-smoking. A €70 cleaning fee will be charged for any violation.',
 'policy', 4),

('Comment rejoindre l''île Pinel ?', 'How do I get to Pinel Island?',
 'Depuis l''hôtel, c''est très simple ! Le dock est à 20 secondes à pied. Option 1 : Ferry (10€ A/R, toutes les 30 min, 5 min de traversée). Option 2 : Nos kayaks gratuits (20-25 min de pagaie). On recommande d''y aller le matin pour le snorkeling avec les tortues.',
 'From the hotel, it''s very easy! The dock is a 20-second walk. Option 1: Ferry (€10 round trip, every 30 min, 5-min crossing). Option 2: Our free kayaks (20-25 min paddle). We recommend going in the morning for turtle snorkeling.',
 'activity', 5),

('Quelle est la politique d''annulation ?', 'What is the cancellation policy?',
 'Plus de 30 jours avant : annulation gratuite, remboursement intégral. 16-29 jours : 50% de l''acompte retenu. 15 jours ou moins : 100% de l''acompte retenu. No-show : totalité du séjour facturée.',
 '30+ days before: free cancellation, full refund. 16-29 days: 50% of deposit retained. 15 days or fewer: 100% of deposit retained. No-show: full stay amount charged.',
 'policy', 6),

('Proposez-vous un transfert aéroport ?', 'Do you offer airport transfers?',
 'Oui, nous organisons des transferts privés depuis/vers l''aéroport Princess Juliana (SXM) pour 75€ par trajet. Le trajet dure environ 20-30 minutes.',
 'Yes, we arrange private transfers to/from Princess Juliana Airport (SXM) for €75 per trip. The journey takes approximately 20-30 minutes.',
 'transport', 7),

('Avez-vous une piscine ?', 'Do you have a pool?',
 'Oui ! Notre piscine chauffée à l''eau de mer est accessible 24h/24. Parasols, bains de soleil et bouées sont à votre disposition.',
 'Yes! Our heated saltwater pool is accessible 24/7. Parasols, sunloungers and pool rings are available.',
 'amenities', 8),

('Quels moyens de paiement acceptez-vous ?', 'What payment methods do you accept?',
 'Nous acceptons Visa, Mastercard et espèces. Les chèques ne sont pas acceptés.',
 'We accept Visa, Mastercard and cash. Checks are not accepted.',
 'policy', 9),

('Proposez-vous des activités nautiques ?', 'Do you offer water activities?',
 'Oui, et gratuitement ! Kayaks, stand-up paddles et équipement de snorkeling sont à disposition. Le dock est à 20 secondes de l''hôtel. Vous pouvez pagayer jusqu''à l''île Pinel en 20 minutes !',
 'Yes, and they''re free! Kayaks, stand-up paddle boards and snorkeling gear are available. The dock is 20 seconds from the hotel. You can paddle to Pinel Island in 20 minutes!',
 'activity', 10),

('L''hôtel est-il adapté aux familles ?', 'Is the hotel family-friendly?',
 'Absolument ! Notre Suite Familiale (Marcelle & Pierre, 52 m²) combine 2 chambres communicantes avec 2 salles de bain — parfaite pour les familles. Lits bébé et lits d''appoint disponibles. Les enfants de tous âges sont les bienvenus.',
 'Absolutely! Our Family Suite (Marcelle & Pierre, 52 m²) combines 2 connecting rooms with 2 bathrooms — perfect for families. Cots and extra beds available. Children of all ages are welcome.',
 'general', 11),

('Avez-vous un restaurant ?', 'Do you have a restaurant?',
 'Nous n''avons pas de restaurant à proprement parler, mais notre Honesty Bar propose boissons (G&T, bières, vins) et planches (fromages, charcuterie) en libre-service. Le chef organise 1-2 dîners à thème par semaine (BBQ, fruits de mer) qui ressemblent à des soirées privées. Et nous sommes à 5-10 minutes des meilleurs restaurants de l''île !',
 'We don''t have a formal restaurant, but our Honesty Bar offers drinks (G&T, beers, wines) and boards (cheese, charcuterie) self-service. The chef organizes 1-2 themed dinners per week (BBQ, seafood) that feel like private parties. And we''re 5-10 minutes from the island''s best restaurants!',
 'dining', 12),

('Quand l''hôtel est-il fermé ?', 'When is the hotel closed?',
 'L''hôtel ferme chaque année de mi-août à octobre (saison cyclonique). Nous rouvrons en novembre.',
 'The hotel closes annually from mid-August to October (hurricane season). We reopen in November.',
 'general', 13),

('Peut-on privatiser l''hôtel ?', 'Can we book the entire hotel?',
 'Oui ! L''hôtel peut être réservé en exclusivité pour des réunions familiales, anniversaires, groupes d''amis ou séminaires intimes. Personnel dédié et partenaires locaux mobilisés. Contactez-nous pour un devis personnalisé.',
 'Yes! The hotel can be booked exclusively for family reunions, birthdays, friend groups or intimate seminars. Dedicated staff and local partners mobilized. Contact us for a custom quote.',
 'general', 14),

('Quels restaurants recommandez-vous ?', 'Which restaurants do you recommend?',
 'Cela dépend de vos envies ! Pour une soirée gastronomique : Le Pressoir ou La Villa Hibiscus. Pour une ambiance beach : Kontiki ou Calmos Café. Pour découvrir la cuisine locale : les lolos de Grand Case (Sky''s the Limit). Pour un dîner romantique : Spiga ou Ocean 82. Marion sera ravie de vous faire des recommandations personnalisées et de réserver pour vous !',
 'It depends on what you''re in the mood for! Gourmet evening: Le Pressoir or La Villa Hibiscus. Beach vibe: Kontiki or Calmos Café. Local cuisine: Grand Case lolos (Sky''s the Limit). Romantic dinner: Spiga or Ocean 82. Marion will be happy to give personalized recommendations and book for you!',
 'dining', 15);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  RÈGLES IA
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT INTO ai_rules (rule_name, rule, condition_text, action_text, priority, is_active) VALUES

-- Escalation rules
('Plainte / Litige', 'escalation', 'Le client exprime une plainte, un mécontentement, ou demande un remboursement', 'Escalader immédiatement à Emmanuel. Ne PAS tenter de résoudre. Répondre avec empathie et indiquer qu''Emmanuel reviendra personnellement.', 100, TRUE),
('Modification réservation', 'escalation', 'Le client demande une modification ou annulation de réservation existante', 'Vérifier la disponibilité sur Thais, puis escalader à l''équipe pour validation dans Thais. L''IA ne modifie PAS les réservations.', 95, TRUE),
('Groupe 4+ personnes', 'escalation', 'Le client mentionne un groupe de plus de 4 personnes', 'Escalader à Emmanuel pour devis personnalisé (privatisation possible).', 90, TRUE),
('Demande privatisation', 'escalation', 'Le client veut réserver l''hôtel entier / privatisation / événement', 'Escalader à Emmanuel pour devis personnalisé.', 90, TRUE),
('Problème de paiement', 'escalation', 'Le client mentionne un problème de paiement, lien cassé, montant incorrect', 'Escalader immédiatement. L''IA ne gère PAS les paiements.', 95, TRUE),
('Hors périmètre', 'escalation', 'Le sujet n''est pas lié à l''hôtel ou au séjour (partenariat, presse, emploi)', 'Escalader à Emmanuel.', 80, TRUE),
('Doute IA', 'escalation', 'Le score de confiance de l''IA est inférieur à 0.7', 'Escalader plutôt que de risquer une réponse incorrecte.', 85, TRUE),
('Action physique requise', 'escalation', 'Le client demande une réservation restaurant, transfert, ou arrangement nécessitant une action physique', 'Confirmer au client que c''est noté, puis notifier l''équipe (equipe@lemartinhotel.com) pour exécution.', 75, TRUE),

-- Response rules
('Famille détectée', 'response', 'Le client mentionne enfants, famille, bébé, ou 3-4 personnes', 'Suggérer automatiquement la Suite Familiale (Marcelle & Pierre, 52 m², 2 chambres communicantes).', 70, TRUE),
('Lune de miel détectée', 'response', 'Le client mentionne lune de miel, honeymoon, mariage, anniversaire de mariage', 'Proposer le forfait Lune de Miel (Suite René, champagne, fleurs) et mentionner les expériences romantiques.', 70, TRUE),
('PMR détectée', 'response', 'Le client mentionne mobilité réduite, fauteuil roulant, handicap, accessibility', 'Recommander la Suite Marius (RDC, accès PMR, douche adaptée, entrée privée).', 80, TRUE),
('Demande de disponibilité', 'response', 'Le client demande la disponibilité pour des dates spécifiques', 'Consulter l''API Thais pour les disponibilités et tarifs exacts du jour. Ne JAMAIS inventer un prix.', 90, TRUE),
('Dates flexibles', 'response', 'Le client ne donne pas de dates précises mais demande des infos générales', 'Donner les fourchettes de prix (à partir de 294€/nuit) et inviter à préciser les dates pour un tarif exact.', 60, TRUE),
('Restaurant demandé', 'response', 'Le client demande une recommandation de restaurant', 'Utiliser la table restaurants pour recommander selon le profil (romantique, famille, budget, cuisine). Proposer de réserver.', 65, TRUE),
('Activité demandée', 'response', 'Le client demande des idées d''activités ou excursions', 'Utiliser la table activities pour recommander selon le profil. Mentionner les activités gratuites de l''hôtel en premier.', 65, TRUE),

-- Tone rules
('Ton général', 'tone', 'Toutes les réponses', 'Ton chaleureux, professionnel mais pas guindé. Comme Marion : personnalisé, attentionné, jamais robotique. Tutoiement interdit. Vouvoiement systématique en français.', 100, TRUE),
('Ton anglais', 'tone', 'Email en anglais détecté', 'Répondre en anglais. Ton warm, professional, personalized. Mention guest by first name.', 100, TRUE),
('Ton français', 'tone', 'Email en français détecté', 'Répondre en français. Vouvoiement. Ton chaleureux et professionnel. Mentionner le prénom du client.', 100, TRUE),

-- Signature rules
('Signature email', 'signature', 'Toutes les réponses sortantes', 'Signer : Marion / Le Martin Boutique Hotel / Cul de Sac, Saint-Martin', 100, TRUE),

-- Availability rules
('Fermeture annuelle', 'availability', 'Demande pour des dates entre mi-août et octobre', 'Informer poliment que l''hôtel est fermé pendant cette période (saison cyclonique) et proposer les dates les plus proches disponibles.', 95, TRUE),
('Vérification prix Thais', 'pricing', 'Toute demande de prix', 'TOUJOURS consulter l''API Thais pour le tarif exact. Ne JAMAIS inventer, estimer ou arrondir un prix.', 100, TRUE);
