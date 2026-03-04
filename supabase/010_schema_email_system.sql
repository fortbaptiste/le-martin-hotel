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
