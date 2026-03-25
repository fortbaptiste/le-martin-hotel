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
-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  SEED — Chambres & Suites du Le Martin Boutique Hotel          ║
-- ╚══════════════════════════════════════════════════════════════════╝

INSERT INTO rooms (slug, name, category, public_category_fr, public_category_en, size_m2, bed_type, bed_twinable, extra_bed_price, child_supplement, view_fr, view_en, floor, terrace, capacity_adults, capacity_children, description_fr, description_en, design_style, amenities, accessibility, is_communicating, communicating_with, price_low_season, price_high_season, sort_order) VALUES

-- MARIUS
('marius', 'Suite Marius', 'deluxe',
 'Suite vue jardin avec grande terrasse (RDC)', 'Garden View Suite with large terrace (ground floor)',
 34, 'Queen (non séparable). Lit simple d''appoint possible (115 €/nuit)',
 FALSE, 115.00, 150.00,
 'Vue jardin', 'Garden view',
 'Rez-de-chaussée', 'Grande terrasse adjacente à la piscine',
 2, 1,
 'Suite au rez-de-chaussée avec accès privé, adjacente à la piscine. Design minimaliste aux tons terre, noyer, terrazzo et marbre. Ambiance de studio indépendant. Seule suite accessible PMR. Lit bébé disponible (0-2 ans), lit d''appoint simple possible (115 €/nuit). Les lits ne sont PAS séparables en twin.',
 'Ground-floor suite with private entrance, adjacent to the pool. Minimalist design with clean earth tones, walnut, terrazzo and marble. Feels like a self-contained studio. Only wheelchair-accessible suite. Cot available (0-2). Extra single bed possible (€115/night). Beds are NOT twinable.',
 'Minimaliste, tons terre, noyer, terrazzo, marbre',
 '["Climatisation", "Smart TV Apple TV + streaming", "WiFi gratuit", "Machine Nespresso", "Bouilloire SMEG", "Kit thé", "Minibar (sodas, eau, vin — pas un réfrigérateur pour nourriture personnelle)", "Coffre-fort", "Prises USB-C et USB-D", "Bureau + bloc-notes", "Penderie", "Douche pluie walk-in", "Produits Grown Alchemist", "Peignoirs nid d''abeille brodés", "Linge de maison premium", "Sacs de plage en paille + serviettes plage", "Insonorisation", "Service de blanchisserie"]',
 TRUE, FALSE, NULL,
 294.00, 470.00, 1),

-- PIERRE
('pierre', 'Chambre Pierre', 'prestige',
 'Chambre Privilège vue jardin (étage)', 'Privilege Room garden view (upper floor)',
 22, 'Queen (non séparable). Lit simple d''appoint possible (115 €/nuit)',
 FALSE, 115.00, 150.00,
 'Vue jardin tropical avec aperçu mer', 'Tropical garden view with ocean glimpses',
 'Étage supérieur', 'Petite terrasse couverte',
 2, 2,
 'Chambre intime et bucolique à l''étage. Décoration minimaliste originale en bois, pierre, marbre et feuillage. Ambiance feutrée avec des senteurs subtiles de mousse. Fauteuil confortable inclus. Communicante avec la Suite Marcelle pour former la Suite Familiale. Les lits ne sont PAS séparables en twin.',
 'Intimate, bucolic upper-level room. Original minimalist decoration in wood, stone, marble and foliage. Hushed atmosphere with subtle moss scents. Easy chair included. Connects with Marcelle Suite to form the Family Suite. Beds are NOT twinable.',
 'Original, feutré, bois, pierre, marbre, feuillage, bucolique',
 '["Climatisation", "Smart TV Apple TV + streaming", "WiFi gratuit", "Machine Nespresso", "Bouilloire SMEG", "Kit thé", "Minibar (sodas, eau, vin — pas un réfrigérateur pour nourriture personnelle)", "Coffre-fort", "Prises USB-C et USB-D", "Bureau + bloc-notes", "Penderie", "Douche pluie walk-in", "Produits Grown Alchemist", "Peignoirs nid d''abeille brodés", "Linge de maison premium", "Sacs de plage en paille + serviettes plage", "Insonorisation", "Fauteuil confortable"]',
 FALSE, TRUE, 'marcelle',
 294.00, 410.00, 2),

-- MARCELLE
('marcelle', 'Suite Marcelle', 'deluxe',
 'Suite Deluxe vue mer (étage)', 'Deluxe Sea View Suite (upper floor)',
 30, 'Queen (non séparable). Lit simple d''appoint possible (115 €/nuit)',
 FALSE, 115.00, 150.00,
 'Vue mer', 'Ocean view',
 'Étage supérieur', 'Grande terrasse vue jardin',
 2, 2,
 'Suite lumineuse à l''étage avec vue mer. Décoration minimaliste originale en bois, pierre, marbre et feuillage. "Une chambre au bord d''une clairière, réveillée par la douce chaleur d''un rayon de soleil." Communicante avec la Chambre Pierre pour former la Suite Familiale. Les lits ne sont PAS séparables en twin.',
 'Bright upper-level suite with ocean view. Original minimalist decoration in wood, stone, marble and foliage. "A room at the edge of a clearing, awakened by the gentle warmth of a sunbeam." Connects with Pierre Room to form the Family Suite. Beds are NOT twinable.',
 'Lumineux, minimaliste, bois, pierre, marbre, feuillage',
 '["Climatisation", "Smart TV Apple TV + streaming", "WiFi gratuit", "Machine Nespresso", "Bouilloire SMEG", "Kit thé", "Minibar (sodas, eau, vin — pas un réfrigérateur pour nourriture personnelle)", "Coffre-fort", "Prises USB-C et USB-D", "Bureau + bloc-notes", "Penderie", "Douche pluie walk-in", "Produits Grown Alchemist", "Peignoirs nid d''abeille brodés", "Linge de maison premium", "Sacs de plage en paille + serviettes plage", "Insonorisation"]',
 FALSE, TRUE, 'pierre',
 294.00, 470.00, 3),

-- RENÉ
('rene', 'Suite René', 'deluxe',
 'Suite Deluxe vue mer panoramique (étage)', 'Deluxe Panoramic Sea View Suite (upper floor)',
 41, 'Queen (non séparable)',
 FALSE, 115.00, 150.00,
 'Vue mer panoramique', 'Panoramic ocean view',
 'Étage supérieur', 'Grande terrasse avec salon, table, chaises, bains de soleil',
 2, 0,
 'La plus spacieuse de l''hôtel (41 m²). Vue mer panoramique. "L''ambiance calme et feutrée d''un atelier d''artiste" — peintures éparses, jeux d''ombre et de lumière. Une ode à la rêverie. Idéale pour les lunes de miel. La mer murmure à votre fenêtre au réveil. Les lits ne sont PAS séparables en twin.',
 'The most spacious suite in the hotel (41 m²). Panoramic ocean view. "The quiet, hushed ambience of an artist''s studio" — scattered paintings, interplay of shadow and light. An ode to reverie. Ideal for honeymoons. The sea whispers at your window as you greet the day. Beds are NOT twinable.',
 'Atelier d''artiste, peintures, jeux d''ombre et lumière, rêverie',
 '["Climatisation", "Smart TV Apple TV + streaming", "WiFi gratuit", "Machine Nespresso", "Bouilloire SMEG", "Kit thé", "Minibar (sodas, eau, vin — pas un réfrigérateur pour nourriture personnelle)", "Coffre-fort", "Prises USB-C et USB-D", "Bureau + bloc-notes", "Penderie", "Douche pluie walk-in", "Produits Grown Alchemist", "Peignoirs nid d''abeille brodés", "Linge de maison premium", "Sacs de plage en paille + serviettes plage", "Insonorisation", "Salon terrasse avec mobilier"]',
 FALSE, FALSE, NULL,
 329.00, 540.00, 4),

-- MARTHE
('marthe', 'Suite Marthe', 'deluxe',
 'Suite Deluxe vue mer (étage)', 'Deluxe Sea View Suite (upper floor)',
 28, 'Queen (non séparable). Lit simple d''appoint possible (115 €/nuit)',
 FALSE, 115.00, 150.00,
 'Vue mer', 'Ocean view',
 'Étage supérieur', 'Terrasse vue mer avec table, chaises, bains de soleil',
 2, 0,
 'Suite intime et chaleureuse avec vue mer. Décoration chic et décontractée de style parisien. Terrasse avec vue sur l''océan pour des moments de détente parfaits. Les lits ne sont PAS séparables en twin.',
 'Intimate and warm suite with ocean view. Chic, relaxed Parisian-style decor. Terrace with ocean views for perfect moments of relaxation. Beds are NOT twinable.',
 'Chic parisien, décontracté, intime, chaleureux',
 '["Climatisation", "Smart TV Apple TV + streaming", "WiFi gratuit", "Machine Nespresso", "Bouilloire SMEG", "Kit thé", "Minibar (sodas, eau, vin — pas un réfrigérateur pour nourriture personnelle)", "Coffre-fort", "Prises USB-C et USB-D", "Bureau + bloc-notes", "Penderie", "Douche pluie walk-in", "Produits Grown Alchemist", "Peignoirs nid d''abeille brodés", "Linge de maison premium", "Sacs de plage en paille + serviettes plage", "Insonorisation"]',
 FALSE, FALSE, NULL,
 294.00, 470.00, 5),

-- GEORGETTE
('georgette', 'Suite Georgette', 'deluxe',
 'Suite Deluxe vue mer (étage)', 'Deluxe Sea View Suite (upper floor)',
 28, 'Queen (non séparable). Lit simple d''appoint possible (115 €/nuit)',
 FALSE, 115.00, 150.00,
 'Vue mer', 'Ocean view',
 'Étage supérieur', 'Grande terrasse vue jardin',
 2, 0,
 'Suite élégante avec vue mer et grande terrasse sur le jardin. Décoration chic et décontractée de style parisien. Un havre de paix élégant baigné de lumière naturelle. Les lits ne sont PAS séparables en twin.',
 'Elegant suite with ocean view and large garden terrace. Chic, relaxed Parisian-style decor. An elegant haven of peace bathed in natural light. Beds are NOT twinable.',
 'Élégant, chic parisien, décontracté, lumineux',
 '["Climatisation", "Smart TV Apple TV + streaming", "WiFi gratuit", "Machine Nespresso", "Bouilloire SMEG", "Kit thé", "Minibar (sodas, eau, vin — pas un réfrigérateur pour nourriture personnelle)", "Coffre-fort", "Prises USB-C et USB-D", "Bureau + bloc-notes", "Penderie", "Douche pluie walk-in", "Produits Grown Alchemist", "Peignoirs nid d''abeille brodés", "Linge de maison premium", "Sacs de plage en paille + serviettes plage", "Insonorisation"]',
 FALSE, FALSE, NULL,
 294.00, 470.00, 6),

-- FAMILY SUITE (Marcelle + Pierre)
('family-suite', 'Suite Familiale (Marcelle & Pierre)', 'family_suite',
 'Suite Familiale (chambres communicantes)', 'Family Suite (connecting rooms)',
 52, '2 Queen (non séparables). Jusqu''à 3 lits d''appoint possibles (115 €/nuit/lit, supplément enfant 150 €/nuit)',
 FALSE, 115.00, 150.00,
 'Vue mer + vue jardin', 'Ocean view + garden view',
 'Étage supérieur', '2 grandes terrasses couvertes et meublées',
 4, 2,
 'Combinaison des 2 chambres communicantes Marcelle (30 m²) et Pierre (22 m²) pour former une suite familiale de 52 m². 2 chambres, 2 salles de bain, 2 terrasses. Jusqu''à 3 lits d''appoint possibles (115 €/nuit/lit). Supplément enfant : 150 €/nuit. Idéale pour les familles. Les lits ne sont PAS séparables en twin.',
 'Combination of the connecting Marcelle (30 m²) and Pierre (22 m²) rooms forming a 52 m² family suite. 2 bedrooms, 2 bathrooms, 2 terraces. Up to 3 extra beds available (€115/night/bed). Child supplement: €150/night. Ideal for families. Beds are NOT twinable.',
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
 'Kayaks en libre-service. Petit dock à 1 minute à pied de l''hôtel. Idéal pour rejoindre l''Île Pinel (20-25 min de pagaie).',
 'Complimentary kayaks. Small dock 1 minute walk from hotel. Perfect for paddling to Pinel Island (20-25 min).',
 0, 'Inclus', TRUE, 3),

('paddle', 'Stand-up paddle (SUP)', 'Stand-up paddle (SUP)', 'activity',
 'Planches de paddle en libre-service au petit dock de l''hôtel (1 min à pied).',
 'Complimentary stand-up paddle boards at the hotel''s small dock (1 min walk).',
 0, 'Inclus', TRUE, 4),

('snorkeling', 'Équipement de snorkeling', 'Snorkeling gear', 'activity',
 'Masques, tubas et palmes disponibles gratuitement.',
 'Masks, snorkels and fins available free of charge.',
 0, 'Inclus', TRUE, 5),

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
 'Transfert privé depuis/vers l''aéroport Princess Juliana (SXM, environ 1h de route) ou l''aéroport Grand Case (SFG, 10 min) ou le port de Marigot.',
 'Private transfer to/from Princess Juliana Airport (SXM, approx. 1 hour drive) or Grand Case Airport (SFG, 10 min) or Marigot port.',
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
 896.00, 'À partir de, par nuit (Suite Deluxe vue mer panoramique)', FALSE, 35),

('pilates', 'Cours de Pilates', 'Pilates class', 'wellness',
 'Cours de Pilates disponibles à l''hôtel.',
 'Pilates classes available at the hotel.',
 0, 'Sur demande', FALSE, 36);
-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  SEED — Restaurants (vrais restaurants validés par Marion)    ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- Restaurants confirmés dans les vrais emails de Marion & Emmanuel.
-- IMPORTANT : Aucun restaurant n'est accessible à pied depuis l'hôtel.
-- Tous nécessitent une voiture (5-25 min).

INSERT INTO restaurants (name, area, cuisine, price, avg_price_eur, phone, reservation_required, specialties, ambiance, distance_km, driving_time_min, walkable, access_note_fr, access_note_en, best_for, description_fr, description_en, is_partner, sort_order) VALUES

-- Restaurants confirmés par Marion (email Linda Thornton, fév. 2026)
('Ristorante Del Arti', 'Orient Bay', 'italian', '€€€', 55,
 '+590 690 73 96 33', TRUE,
 'Cuisine italienne gastronomique',
 'Élégant, en plein air',
 3.5, 8, FALSE,
 'Environ 8 minutes en voiture depuis l''hôtel.',
 'About 8 minutes drive from the hotel.',
 ARRAY['romantic', 'anniversary', 'gourmet', 'outdoor'],
 'Restaurant italien recommandé par Marion pour les dîners spéciaux et anniversaires. Tables en extérieur disponibles.',
 'Italian restaurant recommended by Marion for special dinners and anniversaries. Outdoor tables available.',
 FALSE, 1),

('Le Tropicana', 'Orient Bay', 'french', '€€', 40,
 '+590 590 87 79 07', TRUE,
 'Cuisine française et créole',
 'Décontracté, convivial',
 3.5, 8, FALSE,
 'Environ 8 minutes en voiture depuis l''hôtel.',
 'About 8 minutes drive from the hotel.',
 ARRAY['lunch', 'casual', 'returning_guests'],
 'Restaurant apprécié des habitués. Recommandé par Marion pour le déjeuner. Salle intérieure et terrasse.',
 'A favorite among returning guests. Recommended by Marion for lunch. Indoor and terrace seating.',
 FALSE, 2),

('Le Terrasse Rooftop Restaurant', 'Marigot', 'french', '€€€', 60,
 '+590 690 66 99 99', TRUE,
 'Cuisine gastronomique, vue mer',
 'Rooftop, vue sur l''eau, élégant',
 9.0, 15, FALSE,
 'Environ 15 minutes en voiture depuis l''hôtel.',
 'About 15 minutes drive from the hotel.',
 ARRAY['romantic', 'sunset', 'waterside', 'anniversary', 'gourmet'],
 'Restaurant rooftop avec vue sur l''eau. Tables au bord de l''eau demandées. Idéal pour un dîner romantique.',
 'Rooftop restaurant with water view. Waterside tables available on request. Ideal for a romantic dinner.',
 FALSE, 3),

('Lulu''s Corner', 'Grand Case', 'french', '€€', 35,
 '+590 690 77 87 81', TRUE,
 'Cuisine française bistrot',
 'Chaleureux, climatisé',
 6.0, 10, FALSE,
 'Environ 10 minutes en voiture depuis l''hôtel.',
 'About 10 minutes drive from the hotel.',
 ARRAY['lunch', 'casual', 'family'],
 'Bistrot à Grand Case recommandé par Marion pour le déjeuner. Salle climatisée et tables ombragées disponibles.',
 'Grand Case bistro recommended by Marion for lunch. Air-conditioned and shaded tables available.',
 FALSE, 4),

('Bistrot Caraïbes', 'Grand Case', 'french', '€€€', 50,
 NULL, TRUE,
 'Gastronomie française caribéenne',
 'Élégant, boulevard de Grand Case',
 6.0, 10, FALSE,
 'Environ 10 minutes en voiture depuis l''hôtel.',
 'About 10 minutes drive from the hotel.',
 ARRAY['gourmet', 'romantic', 'anniversary'],
 'Restaurant gastronomique sur le boulevard de Grand Case. Recommandé par les clients et Marion.',
 'Gourmet restaurant on Grand Case boulevard. Recommended by guests and Marion.',
 FALSE, 5);
-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  SEED — Plages de Saint-Martin (20+)                           ║
-- ╚══════════════════════════════════════════════════════════════════╝

INSERT INTO beaches (name, side, distance_km, driving_time_min, walking_time_min, characteristics, facilities, crowd_level, best_for, description_fr, description_en, sort_order) VALUES

-- ═══ CÔTÉ FRANÇAIS ═══
('Cul de Sac Bay', 'french', 0, 0, 0,
 'Baie calme, dock de l''hôtel, départ kayak/paddle vers Pinel', 'Dock hôtel, kayaks gratuits, paddle gratuits', 'Calme',
 ARRAY['kayak', 'paddle', 'snorkeling', 'calm'],
 'La baie de l''hôtel. Petit dock à 1 minute à pied pour les kayaks et paddles. Le ferry vers Pinel part d''un autre dock (2-3 min en voiture ou 15 min à pied).',
 'The hotel''s own bay. Small dock 1 minute walk for kayaks and paddleboards. The ferry to Pinel departs from a different dock (2-3 min drive or 15 min walk).', 1),

('Orient Bay Beach', 'french', 1.9, 5, 18,
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
('airport', 'Aéroport Princess Juliana (SXM)', 'Simpson Bay, côté hollandais', NULL, 30.0, 60, '24/7', 'Aéroport international principal. 27+ compagnies aériennes. Vols directs USA, Europe, Caraïbes. Compter environ 1 heure de route depuis l''hôtel. Shuttle hôtel : 75€.', 20),
('airport', 'Aéroport Grand Case-Espérance (SFG)', 'Grand Case, côté français', NULL, 6.0, 10, 'Horaires de vol', 'Aéroport régional. Vols vers St-Barth (15 min), Guadeloupe. Pratique pour arrivées inter-îles.', 21),

-- Transport
('transport', 'Ferry Marigot → Anguilla', 'Port de Marigot', '+590 590 87 10 68', 9.0, 15, '8h30-18h, toutes les 30-45 min', '30$ aller + 7€ taxe. Passeport obligatoire. 20 min traversée.', 25),
('transport', 'Ferry Marigot → St-Barth (Voyager)', 'Port de Marigot', NULL, 9.0, 15, 'Jusqu''à 5 départs/jour', 'ECO 108€ A/R, SMART 131€, BUSINESS 162€. 1h traversée.', 26),
('transport', 'Taxis', 'Partout sur l''île', NULL, NULL, NULL, '24/7', 'Tarifs fixes par zone. Supplément 25% 22h-minuit, 50% minuit-6h. Pas de Uber/Lyft.', 27),
('transport', 'Location de voitures', 'Aéroports et hôtels', NULL, NULL, NULL, 'Variable', 'À partir de ~20$/jour. Conduite à droite. Permis français ou international.', 28),
('transport', 'Pas de Uber / VTC', NULL, NULL, NULL, NULL, NULL, 'Il n''y a pas de Uber ni de VTC sur l''île. Uniquement des taxis (tarifs fixes par zone) et des loueurs de voitures.', 29),

-- Commerce
('shopping', 'Supermarché Gocci', 'Route de Cul de Sac', NULL, 1.5, 2, 'Lun-Sam', 'Supermarché moderne le plus proche de l''hôtel.', 30),
('shopping', 'Super U', 'Près de Grand Case', NULL, 5.0, 8, 'Lun-Sam 8h-20h', 'Grand supermarché complet.', 31),
('shopping', 'Marché de Marigot', 'Waterfront, Marigot', NULL, 9.0, 15, 'Tous les jours sauf dim, 8h-13h', 'Meilleurs jours : mercredi et samedi.', 32),

-- Banques
('bank', 'Distributeur ATM le plus proche', 'Cul de Sac / Grand Case', NULL, 2.0, 4, '24/7', 'ATMs français : EUR. ATMs hollandais : USD. La plupart des commerces acceptent les deux.', 35),

-- Divers
-- Livraison repas
('dining', 'Delifood Island SXM', NULL, NULL, NULL, NULL, NULL, 'Service de livraison de repas, le UberEats de Saint-Martin. Possibilité de se faire livrer le soir à l''hôtel. Site : https://www.delifood-sxm.com', 50),

('info', 'Fuseau horaire', NULL, NULL, NULL, NULL, NULL, 'AST (Atlantic Standard Time) = UTC-4. Pas de changement d''heure.', 40),
('info', 'Monnaie', NULL, NULL, NULL, NULL, NULL, 'EUR côté français, USD/ANG côté hollandais. Les deux acceptés presque partout. Cartes Visa/Mastercard largement acceptées.', 41),
('info', 'Langues', NULL, NULL, NULL, NULL, NULL, 'Français (côté FR), anglais (côté NL), créole, espagnol. L''anglais est compris partout.', 42),
('info', 'Électricité', NULL, NULL, NULL, NULL, NULL, '220V côté français (prises EU), 110V côté hollandais (prises US). L''hôtel fournit prises USB-C et USB-D.', 43),
('info', 'Saison cyclonique', NULL, NULL, NULL, NULL, 'Juin - Novembre', 'Pic : août-octobre. L''hôtel ferme du 15 août au 30 septembre. Réouverture le 1er octobre.', 44),
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
 'Deux options ! Option 1 : Le petit ferry depuis le dock de Cul de Sac (2-3 min en voiture ou 15 min à pied depuis l''hôtel, 10€ A/R, toutes les 30 min, 5 min de traversée). Option 2 : Nos kayaks gratuits depuis le petit dock en face de l''hôtel (1 min à pied, 20-25 min de pagaie). On recommande d''y aller le matin pour le snorkeling avec les tortues.',
 'Two options! Option 1: The small ferry from the Cul de Sac dock (2-3 min drive or 15 min walk from the hotel, €10 round trip, every 30 min, 5-min crossing). Option 2: Our free kayaks from the small dock in front of the hotel (1 min walk, 20-25 min paddle). We recommend going in the morning for turtle snorkeling.',
 'activity', 5),

('Quelle est la politique d''annulation ?', 'What is the cancellation policy?',
 'Plus de 30 jours avant : annulation gratuite, remboursement intégral. 16-29 jours : 50% de l''acompte retenu. 15 jours ou moins : 100% de l''acompte retenu. No-show : totalité du séjour facturée.',
 '30+ days before: free cancellation, full refund. 16-29 days: 50% of deposit retained. 15 days or fewer: 100% of deposit retained. No-show: full stay amount charged.',
 'policy', 6),

('Proposez-vous un transfert aéroport ?', 'Do you offer airport transfers?',
 'Oui, nous organisons des transferts privés depuis/vers l''aéroport Princess Juliana (SXM) pour 75€ par trajet. Il faut compter environ 1 heure de route. Depuis l''aéroport régional de Grand Case (SFG), c''est seulement 10 minutes.',
 'Yes, we arrange private transfers to/from Princess Juliana Airport (SXM) for €75 per trip. The journey takes approximately 1 hour. From Grand Case regional airport (SFG), it''s only 10 minutes.',
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
 'Oui, et gratuitement ! Kayaks, stand-up paddles et équipement de snorkeling sont à disposition. Le petit dock est à 1 minute à pied de l''hôtel. Vous pouvez pagayer jusqu''à l''île Pinel en 20-25 minutes ! Vous pouvez aussi rejoindre Orient Bay à pied le long de la côte en 15-20 minutes.',
 'Yes, and they''re free! Kayaks, stand-up paddle boards and snorkeling gear are available. The small dock is a 1-minute walk from the hotel. You can paddle to Pinel Island in 20-25 minutes! You can also walk to Orient Bay along the coast in 15-20 minutes.',
 'activity', 10),

('L''hôtel est-il adapté aux familles ?', 'Is the hotel family-friendly?',
 'Absolument ! Notre Suite Familiale (52 m²) combine 2 chambres communicantes avec 2 salles de bain — parfaite pour les familles. Lits bébé et lits d''appoint disponibles (supplément 150€/nuit par enfant). Les enfants de tous âges sont les bienvenus.',
 'Absolutely! Our Family Suite (52 m²) combines 2 connecting rooms with 2 bathrooms — perfect for families. Cots and extra beds available (€150/night per child supplement). Children of all ages are welcome.',
 'general', 11),

('Avez-vous un restaurant ?', 'Do you have a restaurant?',
 'Nous n''avons pas de restaurant à proprement parler, mais notre Honesty Bar propose boissons (G&T, bières, vins) et planches (fromages, charcuterie) en libre-service. Le chef organise 1-2 dîners à thème par semaine (BBQ, fruits de mer) qui ressemblent à des soirées privées. Et nous sommes à 5-10 minutes des meilleurs restaurants de l''île !',
 'We don''t have a formal restaurant, but our Honesty Bar offers drinks (G&T, beers, wines) and boards (cheese, charcuterie) self-service. The chef organizes 1-2 themed dinners per week (BBQ, seafood) that feel like private parties. And we''re 5-10 minutes from the island''s best restaurants!',
 'dining', 12),

('Quand l''hôtel est-il fermé ?', 'When is the hotel closed?',
 'L''hôtel ferme chaque année du 15 août au 30 septembre (saison cyclonique). Nous rouvrons le 1er octobre.',
 'The hotel closes annually from August 15 to September 30 (hurricane season). We reopen on October 1st.',
 'general', 13),

('Peut-on privatiser l''hôtel ?', 'Can we book the entire hotel?',
 'Oui ! L''hôtel peut être réservé en exclusivité pour des réunions familiales, anniversaires, groupes d''amis ou séminaires intimes. Personnel dédié et partenaires locaux mobilisés. Contactez-nous pour un devis personnalisé.',
 'Yes! The hotel can be booked exclusively for family reunions, birthdays, friend groups or intimate seminars. Dedicated staff and local partners mobilized. Contact us for a custom quote.',
 'general', 14),

('Quels restaurants recommandez-vous ?', 'Which restaurants do you recommend?',
 'Cela dépend de vos envies ! L''île regorge d''excellents restaurants dans plusieurs quartiers : Grand Case (la « capitale gastronomique »), Orient Bay, Marigot et d''autres. Marion & Emmanuel seront ravis de vous faire des recommandations personnalisées selon vos goûts et de réserver pour vous !',
 'It depends on what you''re in the mood for! The island is full of excellent restaurants in several areas: Grand Case (the "gourmet capital"), Orient Bay, Marigot and more. Marion & Emmanuel will be happy to give personalized recommendations based on your preferences and book for you!',
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
('Incohérence réservation', 'escalation', 'Les données Thais (dates, chambre, nb personnes) ne correspondent pas à ce que le client affirme (ex: le client dit avoir ajouté des enfants mais Thais montre 2 adultes)', 'Ne PAS proposer de solutions ni corriger. Répondre que l''on vérifie sa réservation et qu''on revient très vite vers lui. Escalader à l''équipe pour vérification manuelle.', 95, TRUE),
('Action physique requise', 'escalation', 'Le client demande une réservation restaurant, transfert, ou arrangement nécessitant une action physique', 'Confirmer au client que c''est noté, puis notifier l''équipe (equipe@lemartinhotel.com) pour exécution.', 75, TRUE),

-- Response rules
('Famille détectée', 'response', 'Le client mentionne enfants, famille, bébé, ou 3-4 personnes', 'Suggérer automatiquement la Suite Familiale (52 m², 2 chambres communicantes). Supplément enfant : 150€/nuit.', 70, TRUE),
('Lune de miel détectée', 'response', 'Le client mentionne lune de miel, honeymoon, mariage, anniversaire de mariage', 'Proposer le forfait Lune de Miel (Suite Deluxe vue mer panoramique, champagne, fleurs) et mentionner les expériences romantiques.', 70, TRUE),
('PMR détectée', 'response', 'Le client mentionne mobilité réduite, fauteuil roulant, handicap, accessibility', 'Recommander la Suite vue jardin avec grande terrasse au RDC (accès PMR, douche adaptée, entrée privée).', 80, TRUE),
('Demande de disponibilité', 'response', 'Le client demande la disponibilité pour des dates spécifiques', 'Consulter l''API Thais pour les disponibilités et tarifs exacts du jour. Ne JAMAIS inventer un prix.', 90, TRUE),
('Dates flexibles', 'response', 'Le client ne donne pas de dates précises mais demande des infos générales', 'Donner les fourchettes de prix (à partir de 294€/nuit) et inviter à préciser les dates pour un tarif exact.', 60, TRUE),
('Restaurant demandé', 'response', 'Le client demande une recommandation de restaurant', 'Utiliser la table restaurants pour recommander selon le profil (romantique, famille, budget, cuisine). Proposer de réserver.', 65, TRUE),
('Activité demandée', 'response', 'Le client demande des idées d''activités ou excursions', 'Utiliser la table activities pour recommander selon le profil. Mentionner les activités gratuites de l''hôtel en premier.', 65, TRUE),

-- Tone rules
('Ton général', 'tone', 'Toutes les réponses', 'Ton chaleureux, professionnel mais pas guindé. Comme Marion : personnalisé, attentionné, jamais robotique. Tutoiement interdit. Vouvoiement systématique en français.', 100, TRUE),
('Ton anglais', 'tone', 'Email en anglais détecté', 'Répondre en anglais. Ton warm, professional, personalized. Mention guest by first name.', 100, TRUE),
('Ton français', 'tone', 'Email en français détecté', 'Répondre en français. Vouvoiement. Ton chaleureux et professionnel. Mentionner le prénom du client.', 100, TRUE),

-- Signature rules
('Signature email', 'signature', 'Toutes les réponses sortantes', 'Signer : Marion & Emmanuel / Le Martin Boutique Hotel / Cul de Sac, Saint-Martin', 100, TRUE),

-- Availability rules
('Fermeture annuelle', 'availability', 'Demande pour des dates entre le 15 août et le 30 septembre', 'Informer poliment que l''hôtel est fermé du 15 août au 30 septembre (saison cyclonique) et que nous rouvrons le 1er octobre. Proposer les dates les plus proches disponibles.', 95, TRUE),
('Vérification prix Thais', 'pricing', 'Toute demande de prix', 'TOUJOURS consulter l''API Thais pour le tarif exact. Ne JAMAIS inventer, estimer ou arrondir un prix.', 100, TRUE);
-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  SCHEMA — Système email IA                                     ║
-- ║  Templates, partenaires, transports, exemples de conversation  ║
-- ╚══════════════════════════════════════════════════════════════════╝


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TABLE — email_templates
--  Templates email réutilisables (FR/EN, email/whatsapp)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE email_templates (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category            TEXT NOT NULL,
    name                TEXT NOT NULL,
    language            TEXT NOT NULL DEFAULT 'fr',
    channel             TEXT NOT NULL DEFAULT 'email',
    subject_line        TEXT,
    body                TEXT NOT NULL,
    variables           TEXT[] DEFAULT '{}',
    notes               TEXT,
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_email_templates_category ON email_templates(category);
CREATE INDEX idx_email_templates_lang ON email_templates(language, channel);

COMMENT ON TABLE email_templates IS 'Templates email pré-rédigés par Marion, réutilisables par l''IA';
COMMENT ON COLUMN email_templates.category IS 'restaurant_reco, car_rental, cancellation, welcome_board, birthday, pre_arrival, post_stay';
COMMENT ON COLUMN email_templates.channel IS 'email ou whatsapp';
COMMENT ON COLUMN email_templates.variables IS 'Placeholders dynamiques : {guest_name}, {arrival_date}, etc.';


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TABLE — partners
--  Partenaires de confiance de l'hôtel
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE partners (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name                TEXT NOT NULL,
    service_type        TEXT NOT NULL,
    contact_name        TEXT,
    contact_email       TEXT,
    contact_phone       TEXT,
    website             TEXT,
    description_fr      TEXT,
    description_en      TEXT,
    forward_template_fr TEXT,
    forward_template_en TEXT,
    pricing_info        TEXT,
    notes               TEXT,
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_partners_type ON partners(service_type);

COMMENT ON TABLE partners IS 'Partenaires de confiance du Martin Boutique Hotel';
COMMENT ON COLUMN partners.service_type IS 'car_rental, snorkeling, gym, boat_tour, taxi, excursion, ferry';
COMMENT ON COLUMN partners.forward_template_fr IS 'Template de mail à envoyer au partenaire (FR)';


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TABLE — transport_schedules
--  Horaires ferry et navettes inter-îles
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE transport_schedules (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    route               TEXT NOT NULL,
    operator            TEXT NOT NULL,
    departure_time      TIME NOT NULL,
    arrival_time        TIME,
    day_of_week         TEXT DEFAULT 'daily',
    duration_minutes    INT,
    price_amount        DECIMAL(10,2),
    price_currency      TEXT DEFAULT 'EUR',
    notes               TEXT,
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_transport_route ON transport_schedules(route);
CREATE INDEX idx_transport_operator ON transport_schedules(operator);

COMMENT ON TABLE transport_schedules IS 'Horaires des ferries et navettes inter-îles';
COMMENT ON COLUMN transport_schedules.route IS 'marigot_to_anguilla, anguilla_to_marigot, sxm_to_sbh, sbh_to_sxm';
COMMENT ON COLUMN transport_schedules.day_of_week IS 'daily, mon-sat, monday, tuesday, etc.';


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  TABLE — email_examples
--  Exemples de conversations réelles (few-shot pour l'IA)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CREATE TABLE email_examples (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category            TEXT NOT NULL,
    title               TEXT NOT NULL,
    client_message      TEXT NOT NULL,
    marion_response     TEXT NOT NULL,
    context             TEXT,
    learnings           TEXT[] DEFAULT '{}',
    language            TEXT DEFAULT 'en',
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_email_examples_category ON email_examples(category);

COMMENT ON TABLE email_examples IS 'Exemples de conversations réelles Marion/clients pour guider l''IA';
COMMENT ON COLUMN email_examples.category IS 'reservation_inquiry, concierge_restaurant, concierge_activity, concierge_transport, special_occasion, car_rental, modification, pre_arrival, post_stay';
COMMENT ON COLUMN email_examples.learnings IS 'Leçons que l''IA doit retenir de cet exemple';


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  RLS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ALTER TABLE email_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE transport_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_examples ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role full access" ON email_templates FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON partners FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON transport_schedules FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Service role full access" ON email_examples FOR ALL USING (true) WITH CHECK (true);
-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  SEED — Système email IA complet                               ║
-- ║  Templates · Partenaires · Transports · Exemples · Règles IA   ║
-- ╚══════════════════════════════════════════════════════════════════╝


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  1. EMAIL TEMPLATES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT INTO email_templates (category, name, language, channel, subject_line, body, variables, notes) VALUES

-- ── Restaurant Reco EN (email) ──
('restaurant_reco', 'Recommandations restaurants — Email EN', 'en', 'email',
 'Our curated restaurant & experience recommendations',
 'Dear {guest_name},

We are delighted to share with you a selection of carefully chosen restaurants and experiences, perfectly aligned with the spirit of the Martin Boutique Hotel.

These are places we genuinely love, that we frequent ourselves, and that we are happy to introduce to you during your stay with us. Of course, these suggestions are just a starting point: as you know, we also enjoy guiding you day by day, according to your mood and desires, and whispering along the way a few of our best-kept secrets.

This selection blends French gastronomy, intimate addresses, unexpected spots, and authentic local experiences.
At Saint-Martin, each day has its own ambiance… and every table tells a story.

For Lunch

Karibuni – Ilet Pinel
An unmissable experience. If you set off directly from the hotel by kayak, nothing compares to watching turtles and fish before arriving at the beach. A joyful, relaxed atmosphere, feet in the sand — simple, lively luxury.

Coco Beach – Orient Bay
A chic classic by the sea, perfect for a sunny and elegant lunch, with refined cuisine and a gentle, summery ambiance.

Aloha – Orient Bay
A friendly, modern, and relaxed spot, ideal for a lunch by the sea in a light and pleasant atmosphere.

Anse Marcel Beach Restaurant – Anse Marcel
A splendid, peaceful, and elegant natural setting for a timeless lunch, between the turquoise bay and refined cuisine.

For Dinner

Calmos Cafe – Grand Case
By the water, with a casual and relaxed atmosphere, impeccable service, and one of the island''s most beautiful sunsets. Not to be missed.

Le Java – Grand Case
In the same spirit, a warm and welcoming atmosphere, perfect for a dinner by the sea at dusk.

Maison Mere – Orient Bay
A contemporary, elegant, and creative table, where the cuisine is generous and inspired.

L''Atelier – Orient Bay
Refined cuisine in an elegant and intimate setting, perfect for a gentle, memorable dinner.

Le Cottage – Grand Case
An iconic gastronomic address, offering a timeless and sophisticated French dining experience.

Les Galets – Grand Case
Our absolute favorite. A very intimate, sincere place, perfectly aligned with our hotel''s spirit: sensitive cuisine, a cozy atmosphere, and truly moving moments at the table.

L''Astrolabe – Grand Case
Famous for its lobster nights, an elegant and warm institution for lovers of fine dining.

Les Lolos – Grand Case
Typical Creole cuisine, BBQ, local ambiance, and authentic flavors: a true immersion into the soul of Saint-Martin.

We remain, of course, at your full disposal to make reservations, refine these suggestions, or guide you according to your desires in the moment.

We look forward to sharing these wonderful addresses with you,
and to continuing to craft together an experience that truly reflects you.

Warm regards,
Marion / Idalia
The Martin Boutique Hotel',
 ARRAY['guest_name'],
 'Template principal envoyé à tous les clients avant ou pendant le séjour. Utilisé systématiquement dans les threads Richard, Jon, Rosenberg.'),


-- ── Restaurant Reco FR (email) ──
('restaurant_reco', 'Recommandations restaurants — Email FR', 'fr', 'email',
 'Nos recommandations gourmandes & expériences locales',
 'Chers {guest_name},

Nous sommes ravis de vous proposer une sélection de restaurants et d''expériences soigneusement choisis, en parfaite harmonie avec l''ADN du Martin Boutique Hotel.

Il s''agit de lieux que nous aimons sincèrement, que nous fréquentons, et que nous sommes heureux de vous faire découvrir au fil de votre séjour parmi nous. Bien entendu, ces suggestions ne sont qu''un point de départ : comme vous le savez, nous aimons aussi vous accompagner jour après jour, selon vos envies, votre humeur, et vous chuchoter, au fil de votre séjour, quelques-uns de nos secrets les mieux gardés.

Cette sélection mêle gastronomie française, adresses intimistes, lieux surprenants et expériences plus locales.
A Saint-Martin, chaque jour a son ambiance… et chaque table raconte une histoire.

Pour le déjeuner

Karibuni – Ilet Pinel
Une expérience incontournable. Si vous partez directement de l''hôtel en kayak, rien de plus magique que d''observer tortues et poissons avant de rejoindre la plage. Une ambiance joyeuse, décontractée, les pieds dans le sable : le luxe simple et vivant.

Coco Beach – Orient Bay
Un classique chic en bord de mer, idéal pour un déjeuner élégant, ensoleillé, avec une cuisine raffinée et une atmosphère douce et estivale.

Aloha – Orient Bay
Une adresse conviviale, moderne et décontractée, parfaite pour un lunch face à la mer dans une ambiance légère et agréable.

Anse Marcel Beach Restaurant – Anse Marcel
Un cadre naturel splendide, paisible et élégant, pour un déjeuner hors du temps, entre baie turquoise et cuisine soignée.

Pour le dîner

Calmos Cafe – Grand Case
Au bord de l''eau, une ambiance casual et décontractée, un service impeccable et l''un des plus beaux couchers de soleil de l''île. A ne pas manquer.

Le Java – Grand Case
Dans le même esprit, une atmosphère chaleureuse et conviviale, idéale pour profiter d''un dîner face à la mer au crépuscule.

Maison Mere – Orient Bay
Une table contemporaine, élégante et créative, où la cuisine se veut généreuse et inspirée.

L''Atelier – Orient Bay
Une cuisine fine et maîtrisée, dans un cadre élégant et intimiste, parfait pour un dîner tout en douceur.

Le Cottage – Grand Case
Une adresse gastronomique emblématique, pour une expérience française raffinée et intemporelle.

Les Galets – Grand Case
Notre coup de coeur absolu. Un lieu très intimiste, sincère, profondément aligné avec notre ADN : une cuisine sensible, une atmosphère feutrée, et une vraie émotion à table.

L''Astrolabe – Grand Case
Réputé pour ses soirées langoustes, une institution élégante et chaleureuse pour les amateurs de belles tables.

Les Lolos – Grand Case
Cuisine créole typique, BBQ, ambiance locale et authentique : une immersion gourmande au coeur de l''âme de Saint-Martin.

Nous restons bien entendu à votre entière disposition pour effectuer les réservations, affiner ces suggestions ou vous guider selon vos envies du moment.

Au plaisir de partager avec vous ces belles adresses,
et de continuer à façonner ensemble une expérience qui vous ressemble.

Chaleureusement,
Marion / Idalia
Le Martin Boutique Hotel',
 ARRAY['guest_name'],
 'Version française du template restaurant.'),


-- ── Restaurant Reco EN (WhatsApp) ──
('restaurant_reco', 'Recommandations restaurants — WhatsApp EN', 'en', 'whatsapp',
 NULL,
 'Hello {guest_name},

We''re delighted to share a few restaurants and experiences that we love and think you''ll enjoy during your stay at the Martin Boutique Hotel.

For lunch:
- Karibuni – Ilet Pinel: Kayak trip from the hotel, watch turtles & fish before the beach, joyful and relaxed.
- Coco Beach – Orient Bay: Chic, sunny, feet in the sand.
- Aloha – Orient Bay: Friendly, modern, casual.
- Anse Marcel Beach Restaurant: Peaceful, elegant, with a turquoise bay.

For dinner:
- Calmos Cafe – Grand Case: Casual, impeccable service, one of the most beautiful sunsets.
- Le Java – Grand Case: Warm, relaxed, perfect for a sunset dinner by the sea.
- Maison Mere – Orient Bay: Contemporary, elegant & creative.
- L''Atelier – Orient Bay: Refined cuisine in an intimate setting.
- Le Cottage – Grand Case: Iconic French gastronomy.
- Les Galets – Grand Case: Intimate, sincere, our favorite.
- L''Astrolabe – Grand Case: Famous for lobster nights, elegant & warm.
- Les Lolos – Grand Case: Authentic Creole BBQ, lively local atmosphere.

Of course, we''re happy to help with reservations or guide you day by day according to your mood and desires.

Warm regards,
Marion / Idalia',
 ARRAY['guest_name'],
 'Version courte WhatsApp pour envoi mobile.'),


-- ── Restaurant Reco FR (WhatsApp) ──
('restaurant_reco', 'Recommandations restaurants — WhatsApp FR', 'fr', 'whatsapp',
 NULL,
 'Bonjour {guest_name},

Nous sommes ravis de partager avec vous quelques adresses de restaurants et expériences que nous aimons et qui feront briller votre séjour au Martin Boutique Hotel.

Pour le déjeuner :
- Karibuni – Ilet Pinel : Départ en kayak depuis l''hôtel, tortues et poissons avant la plage, ambiance joyeuse et détendue.
- Coco Beach – Orient Bay : Chic, ensoleillé, pieds dans le sable.
- Aloha – Orient Bay : Convivial, moderne et décontracté.
- Anse Marcel Beach Restaurant : Cadre paisible et élégant, avec la baie turquoise.

Pour le dîner :
- Calmos Cafe – Grand Case : Casual, service impeccable, coucher de soleil magnifique.
- Le Java – Grand Case : Chaleureux et décontracté, idéal pour le soir.
- Maison Mere – Orient Bay : Contemporain, élégant et créatif.
- L''Atelier – Orient Bay : Cuisine raffinée dans un cadre intimiste.
- Le Cottage – Grand Case : Gastronomie française emblématique.
- Les Galets – Grand Case : Intime et sincère, notre coup de coeur.
- L''Astrolabe – Grand Case : Réputé pour ses soirées langoustes, élégant et chaleureux.
- Les Lolos – Grand Case : Cuisine créole authentique, BBQ et ambiance locale.

Nous sommes à votre disposition pour réserver vos tables ou vous guider au fil du séjour selon vos envies.

Chaleureusement,
Marion / Idalia',
 ARRAY['guest_name'],
 'Version courte WhatsApp FR.'),


-- ── Location voiture EN ──
('car_rental', 'Forward location voiture — Email EN', 'en', 'email',
 'Car rental request — Le Martin Boutique Hotel guest',
 'Dear Sébastien & Eve,

I hope this message finds you well.

Please find below the contact details of our valued guest, {guest_name} (in copy) who will be staying with us at Le Martin Boutique Hotel from {arrival_date} to {departure_date}.

Could you kindly prepare and send them a quote covering the full duration of their stay?

{special_requests}

Thank you very much for your kind assistance.

Warm regards,
Marion / Idalia
Le Martin Boutique Hotel',
 ARRAY['guest_name', 'arrival_date', 'departure_date', 'special_requests'],
 'Email envoyé à Escale Car Rental (Sébastien & Eve) avec le client en copie. Le loueur livre la voiture à l''aéroport. special_requests = ex: siège auto enfant.'),


-- ── Location voiture FR ──
('car_rental', 'Forward location voiture — Email FR', 'fr', 'email',
 'Demande de location — Client Le Martin Boutique Hotel',
 'Cher Sébastien, chère Eve,

J''espère que vous allez bien.

Vous trouverez ci-dessous les coordonnées de notre client, {guest_name} (en copie), qui séjournera au Martin Boutique Hotel du {arrival_date} au {departure_date}.

Pourriez-vous, s''il vous plaît, lui préparer et lui adresser un devis couvrant l''intégralité de son séjour ?

{special_requests}

Je vous remercie sincèrement pour votre précieuse assistance.

Bien chaleureusement,
Marion / Idalia
Le Martin Boutique Hotel',
 ARRAY['guest_name', 'arrival_date', 'departure_date', 'special_requests'],
 'Version FR du forward Escale Car Rental.'),


-- ── Annulation EN ──
('cancellation', 'Modèle annulation — Email EN', 'en', 'email',
 'Re: Your reservation at Le Martin Boutique Hotel',
 'Dear {guest_name},

We are truly sorry to hear that you will not be able to join us in Saint Martin for your stay.

In accordance with our cancellation policy and the terms of your reservation:

1) Advance Purchase Reservation
This booking is non-cancellable, non-modifiable, and non-refundable.

2) Flexible Reservation
- Cancellation more than 30 days prior to arrival: 100% refund.
- Cancellation between 30 and 16 days prior to arrival: 50% refund.
- Cancellation between 15 days and the day of arrival, or in case of no-show: the reservation is non-refundable.

However, we will do our utmost to rebook your room and refund any nights successfully reallocated as quickly as possible.

We hope to have the pleasure of welcoming you to Le Martin Boutique Hotel on a future occasion, and remain at your disposal for any questions or assistance.

Warm regards,
Le Martin Boutique Hotel',
 ARRAY['guest_name'],
 'IMPORTANT: Ce template est envoyé UNIQUEMENT après validation humaine. L''IA ne doit JAMAIS confirmer une annulation/remboursement de manière autonome. Toujours escalader.'),


-- ── Annulation FR ──
('cancellation', 'Modèle annulation — Email FR', 'fr', 'email',
 'Re: Votre réservation au Le Martin Boutique Hotel',
 'Cher(e) {guest_name},

Nous sommes sincèrement désolés d''apprendre que vous ne pourrez pas vous rendre à Saint-Martin et profiter de votre séjour parmi nous.

Conformément à notre politique d''annulation et aux conditions tarifaires de votre réservation :

1) Réservation « Advance Purchase »
Cette réservation est non annulable, non modifiable et non remboursable.

2) Réservation « Flexible »
- Annulation plus de 30 jours avant votre arrivée : remboursement intégral de votre séjour.
- Annulation entre 30 et 16 jours avant votre arrivée : remboursement de 50 % de votre séjour.
- Annulation entre 15 jours avant et le jour de votre arrivée, ou en cas de non-présentation : la réservation n''est pas remboursable.

Cependant, nous mettrons tout en oeuvre pour relouer votre chambre et vous rembourser les nuitées concernées dans les meilleurs délais.

Nous espérons avoir le plaisir de vous accueillir une prochaine fois au Martin Boutique Hotel, et restons à votre disposition pour toute question ou assistance.

Avec nos meilleures salutations,
Le Martin Boutique Hotel',
 ARRAY['guest_name'],
 'IMPORTANT: Toujours escalader les annulations. Ce template sert de base après décision humaine.'),


-- ── Welcome Board EN ──
('welcome_board', 'Pré-arrivée Welcome Board — Email EN', 'en', 'email',
 'Getting ready for your stay at Le Martin Boutique Hotel',
 'Dear {guest_name},

Thank you very much for sharing your flight/boat schedule with us.

Please find attached all the instructions to reach the hotel smoothly.

We wish you a wonderful trip and look forward to welcoming you at Le Martin for a truly lovely stay.

Warm regards,
Marion & Emmanuel
Le Martin Boutique Hotel',
 ARRAY['guest_name'],
 'Envoyé avec le PDF/guide d''accès à l''hôtel (code portail, itinéraire). Déclenché quand le client communique ses horaires de vol.'),


-- ── Welcome Board FR ──
('welcome_board', 'Pré-arrivée Welcome Board — Email FR', 'fr', 'email',
 'Préparez votre arrivée au Le Martin Boutique Hotel',
 'Cher(e) {guest_name},

Nous vous remercions sincèrement de nous avoir communiqué vos horaires de vol/bateau.

Veuillez trouver en pièce jointe toutes les instructions pour rejoindre l''hôtel.

Nous vous souhaitons un excellent voyage et avons hâte de vous accueillir au Martin pour un séjour des plus agréables.

Cordialement,
Marion & Emmanuel
Le Martin Boutique Hotel',
 ARRAY['guest_name'],
 'Version FR du welcome board.'),


-- ── Décoration anniversaire EN ──
('birthday', 'Proposition décoration anniversaire — Email EN', 'en', 'email',
 'Re: Birthday Decoration',
 'Dear {guest_name},

Thank you for your lovely message!

We would be happy to organize a small birthday decoration for {birthday_person}. We usually prepare a setup with balloons to which we attach little notes — we place about ten balloons and you can send us 10 short messages you would like us to write for them.

We can also arrange a bouquet of flowers for the room.

Here are the rates:
- Birthday decoration (balloons + notes): 75 EUR
- Flower bouquet: 60 EUR
- In-room massage (1 hour): 165 EUR

Let me know what you would like us to prepare, and I will take care of everything for you.

Warm regards,
Marion',
 ARRAY['guest_name', 'birthday_person'],
 'Proposé quand un client mentionne un anniversaire, lune de miel, ou occasion spéciale. Adapter pour honeymoon/anniversary.'),


-- ── Décoration anniversaire FR ──
('birthday', 'Proposition décoration anniversaire — Email FR', 'fr', 'email',
 'Re: Décoration anniversaire',
 'Cher(e) {guest_name},

Merci pour votre adorable message !

Nous serions ravis d''organiser une petite décoration d''anniversaire pour {birthday_person}. Nous préparons habituellement un décor avec des ballons auxquels nous attachons de petites notes — nous plaçons environ dix ballons et vous pouvez nous envoyer 10 courts messages que vous souhaitez que nous écrivions.

Nous pouvons également préparer un bouquet de fleurs pour la chambre.

Voici nos tarifs :
- Décoration anniversaire (ballons + notes) : 75 EUR
- Bouquet de fleurs : 60 EUR
- Massage en chambre (1 heure) : 165 EUR

Dites-nous ce que vous souhaitez et nous nous occupons de tout.

Chaleureusement,
Marion',
 ARRAY['guest_name', 'birthday_person'],
 'Version FR. Adapter pour anniversaire de mariage / lune de miel.');


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  2. PARTENAIRES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT INTO partners (name, service_type, contact_name, contact_email, contact_phone, website, description_fr, description_en, pricing_info, notes) VALUES

('Escale Car Rental', 'car_rental',
 'Sébastien & Eve', NULL, NULL, NULL,
 'Société de location de voiture partenaire. Amis de Marion et Emmanuel. Super service, trouvent toujours des solutions pour les clients. Livraison possible à l''aéroport.',
 'Trusted car rental partner. Friends of Marion and Emmanuel. Excellent service, always find solutions for guests. Airport delivery available.',
 'Devis sur demande selon durée du séjour. Siège auto enfant disponible sur demande.',
 'Utiliser le template email "car_rental" pour mettre en relation client et Escale Car Rental. Toujours mettre le client en copie.'),

('Bubble Shop', 'snorkeling',
 NULL, NULL, NULL, NULL,
 'Excursion snorkeling de 3 heures au Rocher Créole. Exploration de la vie marine autour des récifs.',
 'Three-hour snorkeling excursion to Rocher Créole. Explore the beautiful marine life around the reefs.',
 'Tarif sur demande.',
 'Recommandé pour les amateurs de snorkeling. Excursion populaire.'),

('Hopfit Hope Estate', 'gym',
 NULL, NULL, NULL, NULL,
 'Salle de sport bien équipée à seulement 5 minutes en voiture de l''hôtel.',
 'Well-equipped gym just 5 minutes from the hotel.',
 'Accès à la séance.',
 'Recommander aux clients qui demandent des activités fitness.'),

('Scoobi Too', 'boat_tour',
 NULL, NULL, NULL, NULL,
 'Sorties bateau privées ou charter. Excursions vers les îles voisines.',
 'Private or charter boat trips. Excursions to neighboring islands.',
 'Tarif sur demande selon durée et destination.',
 'Pour les sorties bateau privées. Mentionné dans la FAQ.'),

('Lottery Farm', 'excursion',
 NULL, NULL, NULL, NULL,
 'Randonnée jusqu''au Pic Paradis, point culminant de l''île. Vue panoramique 180° sur la mer. Parcours zipline disponible.',
 'Hike to Pic Paradis, the island''s highest point. Breathtaking 180-degree sea views. Zipline course available.',
 'Tarif randonnée + zipline sur demande.',
 'Recommandé spécialement pour les ados (zipline) et les amateurs de nature. Combinable avec randonnée Pic Paradis.'),

('Great Bay Express', 'ferry',
 NULL, NULL, '+1-721-520-5015', 'https://www.greatbayexpress.com',
 'Ferry rapide entre Sint Maarten (côté hollandais) et Saint-Barthélemy. 3 rotations par jour, 7j/7.',
 'Fast ferry between Sint Maarten (Dutch side) and Saint-Barthélemy. 3 daily rotations, 7 days a week.',
 'Voir horaires dans transport_schedules. Réservation sur le site web ou par WhatsApp.',
 'Passeport obligatoire. Check-in 15 min avant départ. Départ depuis le côté hollandais (Simpson Bay).'),

('Ferry Marigot-Anguilla', 'ferry',
 NULL, NULL, NULL, NULL,
 'Ferry public Marigot (St-Martin) vers Blowing Point (Anguilla). 10 départs par jour. Traversée 20 minutes. Billetterie sur place uniquement.',
 'Public ferry from Marigot (St. Martin) to Blowing Point (Anguilla). 10 daily departures. 20-minute crossing. Tickets on-site only.',
 'Aller simple : $30/30 EUR ($15 enfants 2-11 ans) + 7 EUR redevance passagère (dès 4 ans). Taxe Anguilla : $11 (journée) ou $28 (séjour > 12h). Espèces à bord, carte pour la redevance uniquement.',
 'Passeport obligatoire. Gare maritime ouverte 7j/7 de 8h30 à 18h sauf intempéries. Billetterie sur place uniquement, pas de réservation en ligne.');


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  3. HORAIRES TRANSPORT
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Ferry Marigot → Anguilla (Blowing Point)
INSERT INTO transport_schedules (route, operator, departure_time, arrival_time, day_of_week, duration_minutes, price_amount, price_currency, notes) VALUES
('marigot_to_anguilla', 'Ferry public Marigot', '08:30', '08:50', 'daily', 20, 30.00, 'EUR', 'Aller simple. +7 EUR redevance passagère. Enfants 2-11: 15 EUR.'),
('marigot_to_anguilla', 'Ferry public Marigot', '09:30', '09:50', 'daily', 20, 30.00, 'EUR', NULL),
('marigot_to_anguilla', 'Ferry public Marigot', '10:30', '10:50', 'daily', 20, 30.00, 'EUR', NULL),
('marigot_to_anguilla', 'Ferry public Marigot', '11:30', '11:50', 'daily', 20, 30.00, 'EUR', NULL),
('marigot_to_anguilla', 'Ferry public Marigot', '12:30', '12:50', 'daily', 20, 30.00, 'EUR', NULL),
('marigot_to_anguilla', 'Ferry public Marigot', '13:30', '13:50', 'daily', 20, 30.00, 'EUR', NULL),
('marigot_to_anguilla', 'Ferry public Marigot', '15:00', '15:20', 'daily', 20, 30.00, 'EUR', NULL),
('marigot_to_anguilla', 'Ferry public Marigot', '16:30', '16:50', 'daily', 20, 30.00, 'EUR', NULL),
('marigot_to_anguilla', 'Ferry public Marigot', '17:15', '17:35', 'daily', 20, 30.00, 'EUR', NULL),
('marigot_to_anguilla', 'Ferry public Marigot', '18:00', '18:20', 'daily', 20, 30.00, 'EUR', NULL);

-- Ferry Anguilla (Blowing Point) → Marigot
INSERT INTO transport_schedules (route, operator, departure_time, arrival_time, day_of_week, duration_minutes, price_amount, price_currency, notes) VALUES
('anguilla_to_marigot', 'Ferry public Anguilla', '07:30', '07:50', 'daily', 20, 30.00, 'USD', 'Taxe Anguilla en sus: $11 (journée) ou $28 (séjour > 12h).'),
('anguilla_to_marigot', 'Ferry public Anguilla', '08:30', '08:50', 'daily', 20, 30.00, 'USD', NULL),
('anguilla_to_marigot', 'Ferry public Anguilla', '09:30', '09:50', 'daily', 20, 30.00, 'USD', NULL),
('anguilla_to_marigot', 'Ferry public Anguilla', '10:30', '10:50', 'daily', 20, 30.00, 'USD', NULL),
('anguilla_to_marigot', 'Ferry public Anguilla', '11:30', '11:50', 'daily', 20, 30.00, 'USD', NULL),
('anguilla_to_marigot', 'Ferry public Anguilla', '12:30', '12:50', 'daily', 20, 30.00, 'USD', NULL),
('anguilla_to_marigot', 'Ferry public Anguilla', '14:00', '14:20', 'daily', 20, 30.00, 'USD', NULL),
('anguilla_to_marigot', 'Ferry public Anguilla', '15:30', '15:50', 'daily', 20, 30.00, 'USD', NULL),
('anguilla_to_marigot', 'Ferry public Anguilla', '16:30', '16:50', 'daily', 20, 30.00, 'USD', NULL),
('anguilla_to_marigot', 'Ferry public Anguilla', '17:15', '17:35', 'daily', 20, 30.00, 'USD', NULL);

-- Great Bay Express SXM → SBH (Tableau 1 — matin tôt)
INSERT INTO transport_schedules (route, operator, departure_time, arrival_time, day_of_week, duration_minutes, price_amount, price_currency, notes) VALUES
('sxm_to_sbh', 'Great Bay Express', '07:15', '08:00', 'monday',    45, NULL, 'USD', 'Passeport obligatoire. Check-in 15 min avant. Réservation: greatbayexpress.com'),
('sxm_to_sbh', 'Great Bay Express', '07:15', '08:00', 'tuesday',   45, NULL, 'USD', NULL),
('sxm_to_sbh', 'Great Bay Express', '07:15', '08:00', 'wednesday', 45, NULL, 'USD', NULL),
('sxm_to_sbh', 'Great Bay Express', '07:15', '08:00', 'thursday',  45, NULL, 'USD', NULL),
('sxm_to_sbh', 'Great Bay Express', '07:15', '08:00', 'friday',    45, NULL, 'USD', NULL),
('sxm_to_sbh', 'Great Bay Express', '07:15', '08:00', 'saturday',  45, NULL, 'USD', NULL);

-- Great Bay Express SBH → SXM (Tableau 1 — matin tôt retour)
INSERT INTO transport_schedules (route, operator, departure_time, arrival_time, day_of_week, duration_minutes, price_amount, price_currency, notes) VALUES
('sbh_to_sxm', 'Great Bay Express', '08:30', '09:15', 'monday',    45, NULL, 'USD', NULL),
('sbh_to_sxm', 'Great Bay Express', '08:30', '09:15', 'tuesday',   45, NULL, 'USD', NULL),
('sbh_to_sxm', 'Great Bay Express', '08:30', '09:15', 'wednesday', 45, NULL, 'USD', NULL),
('sbh_to_sxm', 'Great Bay Express', '08:30', '09:15', 'thursday',  45, NULL, 'USD', NULL),
('sbh_to_sxm', 'Great Bay Express', '08:30', '09:15', 'friday',    45, NULL, 'USD', NULL),
('sbh_to_sxm', 'Great Bay Express', '08:30', '09:15', 'saturday',  45, NULL, 'USD', NULL);

-- Great Bay Express SXM → SBH (Tableau 2 — milieu de journée, 7j/7)
INSERT INTO transport_schedules (route, operator, departure_time, arrival_time, day_of_week, duration_minutes, price_amount, price_currency, notes) VALUES
('sxm_to_sbh', 'Great Bay Express', '09:45', '10:30', 'daily', 45, NULL, 'USD', NULL);

-- Great Bay Express SBH → SXM (Tableau 2 — milieu de journée retour, 7j/7)
INSERT INTO transport_schedules (route, operator, departure_time, arrival_time, day_of_week, duration_minutes, price_amount, price_currency, notes) VALUES
('sbh_to_sxm', 'Great Bay Express', '11:00', '11:45', 'daily', 45, NULL, 'USD', NULL);

-- Great Bay Express SXM → SBH (Tableau 3 — soir, 7j/7)
INSERT INTO transport_schedules (route, operator, departure_time, arrival_time, day_of_week, duration_minutes, price_amount, price_currency, notes) VALUES
('sxm_to_sbh', 'Great Bay Express', '17:30', '18:15', 'daily', 45, NULL, 'USD', NULL);

-- Great Bay Express SBH → SXM (Tableau 3 — soir retour, 7j/7)
INSERT INTO transport_schedules (route, operator, departure_time, arrival_time, day_of_week, duration_minutes, price_amount, price_currency, notes) VALUES
('sbh_to_sxm', 'Great Bay Express', '18:45', '19:30', 'daily', 45, NULL, 'USD', NULL);

-- Ferry côté français SXM → SBH (navette)
INSERT INTO transport_schedules (route, operator, departure_time, arrival_time, day_of_week, duration_minutes, price_amount, price_currency, notes) VALUES
('sxm_to_sbh', 'Navette côté français', '00:00', NULL, 'daily', 50, NULL, 'EUR', 'Passeport ou carte d''identité obligatoire. 2 à 3 navettes par jour. Horaires et billetterie: 05 90 87 10 68 ou sur place. Moins intéressant que Great Bay Express selon Emmanuel.');


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  4. SERVICES ADDITIONNELS (ajout à hotel_services existant)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT INTO hotel_services (slug, name_fr, name_en, category, description_fr, description_en, price_eur, price_note, is_complimentary, is_active, sort_order) VALUES

('transfert-aeroport-hotel', 'Transfert aéroport (organisé par l''hôtel)', 'Airport transfer (arranged by the hotel)', 'concierge',
 'L''hôtel organise le transfert avec un chauffeur partenaire. Le client paie le chauffeur directement à l''arrivée. Trajet environ 1 heure.',
 'The hotel arranges the transfer with a trusted driver partner. The guest pays the driver directly upon arrival. Approximately 1 hour drive.',
 90.00, 'Option recommandée. Demander: ville de départ, compagnie, vol, heure arrivée. Taxi direct ~50 EUR.', FALSE, TRUE, 100),

('transfert-aeroport-enligne', 'Transfert aéroport (réservation en ligne)', 'Airport transfer (online booking)', 'concierge',
 'Réservation du transfert via le site web de l''hôtel.',
 'Transfer booking via the hotel website.',
 115.00, '115 EUR depuis aéroport → hôtel. 75 EUR depuis hôtel → aéroport. Proposer l''option à 90 EUR en priorité.', FALSE, TRUE, 101),

('kayak-double-pinel', 'Location kayak double (Pinel)', 'Double kayak rental (Pinel Island)', 'activity',
 'Location de kayak double pour rejoindre l''Ilet Pinel depuis le ponton de l''hôtel. Observation des tortues marines en chemin.',
 'Double kayak rental to paddle to Pinel Island from the hotel dock. Watch sea turtles along the way.',
 40.00, 'Par kayak double. Distinguer de la mise à dispo gratuite des kayaks/paddles pour loisir.', FALSE, TRUE, 102),

('decoration-anniversaire', 'Décoration chambre anniversaire', 'Birthday room decoration', 'event',
 'Décoration de la chambre avec ballons et petits messages personnalisés. Environ 10 ballons avec notes attachées.',
 'Room decoration with balloons and personalized notes. About 10 balloons with attached messages.',
 75.00, 'Demander 10 messages courts. Adaptable pour mariage/lune de miel. Hélium non garanti (île).', FALSE, TRUE, 103),

('bouquet-fleurs', 'Bouquet de fleurs en chambre', 'Flower bouquet in room', 'event',
 'Bouquet de fleurs frais disposé dans la chambre pour une occasion spéciale.',
 'Fresh flower bouquet placed in the room for a special occasion.',
 60.00, 'Complément idéal à la décoration anniversaire. Commander 48h avant.', FALSE, TRUE, 104),

('massage-chambre', 'Massage en chambre', 'In-room massage', 'wellness',
 'Massage bien-être réalisé dans l''intimité de votre chambre par un(e) praticien(ne) professionnel(le). 1 heure.',
 'Wellness massage in the privacy of your room by a professional therapist. 1 hour.',
 165.00, 'Prix actualisé 2026. Réservation 24h à l''avance. Proposer après anniversaire ou occasion spéciale.', FALSE, TRUE, 105);


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  5. EXEMPLES DE CONVERSATIONS (few-shot pour l'IA)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT INTO email_examples (category, title, client_message, marion_response, context, learnings, language) VALUES

-- Exemple 1 : Activité + logistique timing
('concierge_activity', 'Kayak vers Pinel + contrainte horaire avion',
 'Our group has 2 rooms booked for 1 night, Sunday May 17th. Does the hotel offer 2 person Kayaks for us to padel over to Pinel island. Our Winair flight leaves St Barts at 1, so I am not sure what time we will arrive at the hotel. We are considering visiting Pinel island, but I think the shuttle boats might not give us enough time.',
 'Dear Scott,

Thank you for your message.

We would be delighted to rent you double kayaks to paddle over to Pinel Island (the rate is 40 EUR per kayak). It''s a lovely experience and a beautiful way to reach the island.

However, if your Winair flight to St. Barths departs at 1:00 PM (from Princess Juliana Airport, I presume), you would need to be at the airport approximately 1 hour and 30 minutes before departure. The drive from the hotel to the airport takes about 1 hour, which means you would need to leave the hotel around 10:30 AM.

While it is technically possible to go to Pinel Island in the morning, I do feel it may be a bit tight in terms of timing and could feel rushed.

Please let me know how you would like to plan your morning. I''m happy to help you organize it in the most relaxed way possible.

Warm regards,
Marion',
 'Client avec contrainte horaire serrée (vol à 13h, trajet 1h vers aéroport, check-in 1h30 avant).',
 ARRAY[
   'Toujours calculer le timing réel quand un client a un vol',
   'Trajet hôtel → aéroport Princess Juliana = environ 1 heure',
   'Check-in aéroport = 1h30 avant le vol',
   'Ne jamais hésiter à prévenir que le timing est serré plutôt que de laisser le client stressé',
   'Proposer d''organiser la matinée de manière détendue'
 ], 'en'),


-- Exemple 2 : Demande de réservation (client qui revient)
('reservation_inquiry', 'Client fidèle demande extension de séjour',
 'We are looking to add another night (7th night) on to our existing reservation (February 6) is that possible to do without moving rooms? Let me know.',
 'Hi,

Thank you for your message — I''m happy to share some good news.

Yes, it is absolutely possible to add an additional night on February 6th to your existing reservation without changing rooms. I do have one room remaining, which allows me to extend your stay seamlessly.

That said, I wanted to let you know that I have had to adjust our planning to make this possible, and reservations are currently very active. Availability can change quickly, and it is possible that this room may no longer be available if not confirmed soon.

Please let me know if you would like me to go ahead and secure this extra night for you, and I will take care of the rest.

Warm regards,
Marion',
 'Client fidèle (Richard) qui revient pour la 2e année. Réservation existante dans la chambre Marcelle.',
 ARRAY[
   'Créer un sentiment d''urgence subtil sans être pushy',
   'Mentionner que des ajustements ont été faits = valorise l''effort',
   'Proposer de tout gérer pour le client',
   'Pour les clients fidèles, ton plus chaleureux et familier'
 ], 'en'),


-- Exemple 3 : Recommandation restaurant personnalisée
('concierge_restaurant', 'Client demande conseil restaurant spécifique',
 'We were hoping you could help us with a beach club reservation this coming Sunday. We really enjoyed Coco Beach last year but understand they are under new ownership. Would you still recommend? We want more of a French vibe than an American vibe. Do they still have French DJs on Sunday? Also, how is the new place, Babacool in Simpson Bay?',
 'Dear Richard,

We are looking forward to seeing you soon!

Coco Beach is still a wonderful spot — the change in ownership has been very positive, and the atmosphere remains fantastic. The French DJ on Sunday evenings is still there, so you''ll get the same French vibe you enjoyed last year.

Your reservation is confirmed for Sunday!

Regarding Babacool in Simpson Bay, I haven''t personally been, and the feedback I''ve heard hasn''t been very strong. If you''re looking for a better experience, I would recommend Kalatua instead — it''s more reliable and enjoyable.

[... suivi du template restaurant complet ...]

Warm regards,
Marion',
 'Client fidèle qui connaît déjà l''île. Demande conseil sur un lieu spécifique + comparaison.',
 ARRAY[
   'Répondre d''abord à la question spécifique AVANT d''envoyer le template',
   'Être honnête sur les endroits non recommandés (Babacool: feedback pas très fort)',
   'Proposer une alternative concrète (Kalatua au lieu de Babacool)',
   'Confirmer la réservation directement quand c''est possible',
   'Ajouter le template restaurant complet après la réponse personnalisée'
 ], 'en'),


-- Exemple 4 : Booking multi-chambres
('reservation_inquiry', 'Pas de chambre unique dispo — proposition alternative',
 'We would love to book one room for Feb 19-26 for 2 people (for my wife''s birthday). It seems that there is no one room available for that whole time but we would be happy to move rooms during the holiday. Would you be able to accommodate us?',
 'Bonsoir Jon,

Thank you very much for your message and for your interest in the Martin Boutique Hotel. We would be truly delighted to welcome you and your wife to celebrate her birthday with us.

Indeed, we no longer have availability for the entire stay in the same room. However, we would be very happy to offer you the following alternative, which will allow you to fully enjoy your time with us:

From February 19th to 23rd: the Deluxe Suite – Garden View, also known as La Chambre de Marius.
From February 23rd to 26th: the Privilege Room – La Chambre de Pierre.

I will send you, in a separate email, a detailed quotation including our Advance Purchase rate, which offers a 10% discount. Please note that this rate is non-refundable, non-changeable, and non-cancellable.

Please feel free to let me know if this arrangement suits you or if you have any questions at all.

Warm regards,
Marion',
 'Client souhaite 1 chambre sur 7 nuits mais aucune chambre n''est dispo sur toute la période.',
 ARRAY[
   'Quand pas de dispo en 1 chambre, proposer 2 chambres consécutives',
   'Nommer les chambres par leur nom (Marius, Pierre) + lien site web',
   'Mentionner le tarif Advance Purchase (-10%) dès le début',
   'Préciser les conditions (non remboursable, non modifiable)',
   'Envoyer le devis dans un email séparé',
   'Reconnaître l''occasion spéciale (anniversaire)'
 ], 'en'),


-- Exemple 5 : Pré-arrivée concierge complet
('pre_arrival', 'Questions pré-arrivée multiples (voiture, fitness, activités, dîners)',
 'We arrive on Feb 19 on DL1887 at 12.13pm. Just some thoughts / questions: Should we hire a car or is it easy to get around? Would you be able to arrange some evening dinners for us? We also would love to do some fitness activities - what do you recommend? What other activities do you recommend? (We like rum :-)) If we do not hire a car, can you arrange transfers from the airport?',
 'Dear Jon & Cass,

We are so excited to welcome you on Thursday!

Thank you for sharing your arrival details. We have noted that you land on February 19 at 12:13 pm on DL1887.

Car rental: I can put you in contact with our trusted car rental partner who can deliver your vehicle directly at the airport on the day of your arrival.

Fitness: There is a very nice gym just 5 minutes from the hotel: Hopfit Hope Estate.

Nature & outdoor: We highly recommend a kayak outing directly from the hotel to Ilet Pinel. For snorkeling, we can organize a 3-hour excursion with Bubble Shop to Rocher Créole. For hiking, I recommend Lottery Farm up to Pic Paradis with breathtaking 180-degree views.

Rum: We have a lovely selection of infused rums at the hotel which you can enjoy by the pool. We can also recommend tastings around the island.

[... suivi du template restaurant complet ...]

Warmest regards,
Marion & Idalia',
 'Client arrivant bientôt, multiple questions pratiques d''un coup.',
 ARRAY[
   'Toujours noter le numéro de vol et l''heure d''arrivée',
   'Structurer la réponse par thème (voiture, fitness, activités, restaurants)',
   'Pour la voiture: proposer le partenaire Escale Car Rental avec livraison aéroport',
   'Pour le fitness: recommander Hopfit Hope Estate (5 min)',
   'Pour les activités: kayak Pinel, snorkeling Bubble Shop, rando Lottery Farm',
   'Finir par le template restaurant complet',
   'Adapter le ton quand le client montre de l''humour (le rum :-) )'
 ], 'en'),


-- Exemple 6 : Modification réservation non remboursable
('modification', 'Raccourcir un séjour Advance Purchase',
 'Thank you for confirming the reservation, I am looking forward to our stay at your beautiful property. I am in need of a change to the reservation please…we will need to leave on Saturday February 14. Is a change possible?',
 'Dear Mary Beth,

Thank you very much for your message, and we are delighted to know that you are looking forward to your stay with us.

Regarding your request to shorten your stay and depart on Saturday, February 14th, your reservation was made under our Advance Purchase Offer – Breakfast Included, which offers a 10% discount on the room rate. As indicated in the rate conditions, this offer is non-refundable and non-modifiable, with a 100% deposit taken at the time of booking.

That said, I completely understand your situation and will do my best to assist you. I can exceptionally open availability for the two nights in question, and should these nights be rebooked by other guests, I will be happy to refund you the corresponding amount.

Please let me know if you wish to proceed in this way, and I will take care of everything.

Warm regards,
Marion Dufaur
Le Martin Boutique Hotel',
 'Réservation Advance Purchase (non remboursable). Client veut raccourcir de 2 nuits.',
 ARRAY[
   'TOUJOURS ESCALADER les demandes de modification/annulation/remboursement',
   'Rappeler les conditions du tarif (Advance Purchase = non remboursable)',
   'Montrer de l''empathie et proposer une solution: rembourser si les nuits sont rebookées',
   'Ne jamais promettre un remboursement direct — conditionner au rebooking',
   'Utiliser le nom complet avec titre (Marion Dufaur) pour les sujets importants'
 ], 'en'),


-- Exemple 7 : Décoration anniversaire + transfert
('special_occasion', 'Organisation anniversaire + transfert aéroport',
 'We have a reservation under the name Erica Shepperd-Debnam for February 26-28th. We are celebrating Erica''s birthday and I wanted to inquire about decorating the room for her birthday. Is this something that the hotel is able to help facilitate?',
 'Dear Nneka,

Thank you for your lovely message!

We would be happy to organize a small birthday decoration for Erica. We usually prepare a setup with balloons to which we attach little notes — we place about ten balloons and you can send us 10 short messages you would like us to write for her.

We can also arrange a bouquet of flowers for the room.

Please note that I cannot fully guarantee the balloon floating effect, as it requires a helium tank and, on a small island, it can sometimes be challenging to source certain supplies… but I will absolutely do my best to make it beautiful.

Here are the rates:
- Birthday decoration: 75 EUR
- Flower bouquet: 60 EUR
- Massage (1 hour): 165 EUR

Let me know what you would like us to prepare, and I will take care of everything for you.

Warm regards,
Marion',
 'Réservation au nom d''une personne, mais c''est son amie qui organise la surprise.',
 ARRAY[
   'Répondre avec enthousiasme aux occasions spéciales',
   'Détailler le process (10 ballons, 10 messages)',
   'Être transparente sur les limitations (hélium sur une petite île)',
   'Proposer des extras (fleurs, massage) en upsell naturel',
   'Tarifs transfert: 90 EUR (hôtel organise), 115 EUR (via site), ~50 EUR (taxi direct)',
   'Pour le transfert: demander ville de départ, compagnie, numéro de vol, heure d''arrivée'
 ], 'en'),


-- Exemple 8 : Planning restaurant complet sur séjour long
('concierge_restaurant', 'Organisation complète lunch + dîner sur 10 jours',
 'Thank you for sharing your preferred restaurants for dinner. [Client a envoyé sa liste de restaurants souhaités pour chaque jour de son séjour de 10 nuits]',
 'Dear Joseph and Phil,

We are delighted to welcome you back and look forward to having you with us again.

Please note that dinner seatings are typically available at 6:00 or 6:30 p.m., and 8:00 or 8:30 p.m. However, we were able to secure one of your reservations for 7:30 p.m.

We are pleased to confirm that all of your lunch & dinner reservations have been secured as follows:

Friday, February 27
Lunch: Coco Beach – Beach chairs and lunch confirmed for 12:30 p.m.
Dinner: Maison Mere – Confirmed for 8:00 p.m.

Saturday, February 28
Lunch: Joa Beach – Beach chairs and lunch confirmed for 12:30 p.m.
Dinner: Le Pressoir – Confirmed for 8:00 p.m.

[... suite du planning jour par jour ...]

Please do not hesitate to let us know if there is anything further we may assist you with.

Kind regards,
Idalia',
 'Clients fidèles (3e séjour). Planning lunch + dîner sur 10 jours avec beach chairs.',
 ARRAY[
   'Pour les séjours longs (>7 nuits), proposer d''organiser tous les repas',
   'Mentionner les créneaux disponibles (18h/18h30 et 20h/20h30)',
   'Inclure les beach chairs pour les déjeuners en bord de mer',
   'Format: jour par jour, Lunch + Dinner, nom du restaurant, heure confirmée',
   'Si un restaurant nécessite une carte bancaire (ex: Rainbow Cafe), le préciser',
   'Idalia signe ce type de mail opérationnel (pas Marion)'
 ], 'en'),


-- Exemple 9 : Message post-séjour chaleureux
('post_stay', 'Message d''attention post-séjour',
 'I am most grateful, Marion! We are currently enduring a blizzard and I so wish we were still there! I look forward to returning to your beautiful island and of course staying at your peaceful oasis!',
 'Dear Mary Beth,

Oh my goodness… a blizzard! I can only imagine how cold it must be. I wish I could send you a little box of Caribbean sunshine right now.

We miss you already and would absolutely love to welcome you back to our peaceful oasis whenever you are ready to escape the snow. St. Martin will be here, warm and glowing, waiting for you.

Until then, stay cozy and safe — and keep dreaming of turquoise waters and gentle island breezes.

With warmest thoughts,
Marion',
 'Client post-séjour qui mentionne la météo chez elle (blizzard). Marion répond avec chaleur et poésie.',
 ARRAY[
   'Les messages post-séjour sont très personnels — l''IA doit ESCALADER ou générer un brouillon supervisé',
   'Rebondir sur ce que dit le client (météo, souvenirs)',
   'Utiliser des images poétiques (box of Caribbean sunshine, turquoise waters)',
   'Toujours laisser la porte ouverte pour un retour',
   'Ce type d''échange construit la fidélité — ne jamais répondre de manière générique'
 ], 'en');


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  6. NOUVELLES RÈGLES IA
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT INTO ai_rules (rule_name, rule, condition_text, action_text, priority, is_active) VALUES

-- Classification des emails
('Classification email — restaurant', 'response',
 'Le client demande des recommandations de restaurants, des suggestions pour déjeuner ou dîner, ou mentionne qu''il cherche où manger.',
 'Utiliser le template email_templates.category = "restaurant_reco" dans la langue du client. Personnaliser l''introduction avant le template. Répondre d''abord aux questions spécifiques si le client mentionne un restaurant précis.',
 30, TRUE),

('Classification email — location voiture', 'response',
 'Le client demande comment se déplacer, s''il faut louer une voiture, ou demande un transfert depuis l''aéroport.',
 'Recommander la location de voiture avec le partenaire Escale Car Rental (Sébastien & Eve). Utiliser le template email_templates.category = "car_rental". Mettre le client en copie du mail au partenaire.',
 31, TRUE),

('Classification email — occasion spéciale', 'response',
 'Le client mentionne un anniversaire, une lune de miel, un anniversaire de mariage ou toute occasion spéciale.',
 'Proposer la décoration chambre (75 EUR), le bouquet de fleurs (60 EUR) et le massage (165 EUR/h). Utiliser le template email_templates.category = "birthday". Adapter le message selon l''occasion.',
 32, TRUE),

('Classification email — activités', 'response',
 'Le client demande des activités, des choses à faire, ou des expériences sur l''île.',
 'Répondre avec les données de la table activities + partners. Recommander en priorité : kayak vers Pinel (40 EUR/kayak double), snorkeling avec Bubble Shop (Rocher Créole, 3h), randonnée Lottery Farm/Pic Paradis. Pour les ados : insister sur kayak, jet ski Orient Bay, zipline Lottery Farm.',
 33, TRUE),

('Classification email — transport inter-îles', 'response',
 'Le client demande comment aller à Anguilla ou Saint-Barthélemy.',
 'Consulter la table transport_schedules. Pour Anguilla: ferry depuis Marigot, 20 min, 30 EUR. Pour St. Barth: recommander Great Bay Express (côté hollandais, 45 min, 3 rotations/jour). Toujours mentionner le passeport obligatoire.',
 34, TRUE),

('Classification email — transfert aéroport', 'response',
 'Le client demande un transfert aéroport ou comment se rendre à l''hôtel depuis l''aéroport.',
 'Proposer 3 options. Recommandée: hôtel organise (90 EUR). Alternative: en ligne (115 EUR aéroport, 75 EUR hôtel). Taxi direct: ~50 EUR. Trajet Princess Juliana → hôtel = 1h. Demander: ville départ, compagnie, vol, heure arrivée.',
 35, TRUE),

('Classification email — pré-arrivée', 'response',
 'Le client communique ses horaires de vol ou demande comment rejoindre l''hôtel.',
 'Envoyer le template welcome_board avec instructions d''accès et code portail. Noter le numéro de vol et l''heure d''arrivée. Si arrivée après 19h, demander au client de prévenir à l''avance.',
 36, TRUE),

-- Escalades supplémentaires
('Escalade — réservation restaurant', 'escalation',
 'Le client demande de réserver une table dans un restaurant spécifique.',
 'L''IA peut recommander des restaurants mais ne doit JAMAIS confirmer une réservation. Les réservations nécessitent un appel téléphonique par l''équipe. Formuler : "I will take care of the reservation and confirm the details shortly."',
 82, TRUE),

('Escalade — mise en relation partenaire', 'escalation',
 'L''email nécessite un contact avec un partenaire externe (Escale Car Rental, Bubble Shop, etc.).',
 'L''IA peut rédiger un brouillon de mail vers un partenaire mais ne doit JAMAIS l''envoyer directement. Toujours passer en mode brouillon supervisé pour les mails vers des partenaires externes.',
 83, TRUE),

('Escalade — post-séjour et fidélisation', 'escalation',
 'Le client envoie un message de remerciement post-séjour ou exprime le souhait de revenir.',
 'Générer un brouillon supervisé. Ne JAMAIS envoyer automatiquement un message post-séjour. Marion y met une touche très personnelle et poétique. Ces échanges construisent la fidélité.',
 84, TRUE),

-- Règles de ton
('Ton — anticipation proactive', 'tone',
 'Le client mentionne un timing serré (vol, ferry, activité) ou une logistique complexe.',
 'Toujours anticiper les problèmes logistiques (timing kayak+vol, trajet aéroport, horaires ferry). Prévenir le client plutôt que de le laisser découvrir seul. Formuler comme un conseil bienveillant, pas comme un refus.',
 42, TRUE),

('Ton — upsell naturel', 'tone',
 'L''occasion se présente pour proposer des services additionnels (anniversaire, lune de miel, long séjour).',
 'Proposer naturellement décoration, fleurs, massage, restaurants sans être commercial. Le ton doit être "nous serions ravis de..." et non "nous proposons aussi...". L''upsell doit sembler un cadeau, pas une vente.',
 43, TRUE),

('Ton — honnêteté recommandations', 'tone',
 'Le client demande un avis sur un lieu ou restaurant spécifique.',
 'Toujours être honnête. Si un lieu n''est pas recommandé, formuler diplomatiquement: "the feedback I''ve heard hasn''t been very strong" et proposer une alternative. Les Galets = favori absolu. Kalatua = recommandé. Babacool = pas recommandé.',
 44, TRUE);
