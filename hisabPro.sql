-- ============================================================
-- HisaabPro Database Schema
-- Pakistani Freelancer Financial Intelligence System
-- Normalized to 3NF | PostgreSQL
-- ============================================================

-- ============================================================
-- STEP 1: LOOKUP / REFERENCE TABLES (no dependencies)
-- ============================================================

-- Platforms (Fiverr, Upwork, Direct)
CREATE TABLE platforms (
    platform_id     SERIAL PRIMARY KEY,
    platform_name   VARCHAR(50) NOT NULL UNIQUE,
    fee_percentage  NUMERIC(5,2) NOT NULL DEFAULT 0.00
);

-- Contract Types (Fixed, Hourly, Retainer)
CREATE TABLE contract_types (
    contract_type_id    SERIAL PRIMARY KEY,
    type_name           VARCHAR(50) NOT NULL UNIQUE,
    description         TEXT
);

-- Payment Channels (Bank, Payoneer, Wise etc.)
CREATE TABLE payment_channels (
    channel_id          SERIAL PRIMARY KEY,
    channel_name        VARCHAR(100) NOT NULL UNIQUE,
    is_fbr_compliant    BOOLEAN NOT NULL DEFAULT FALSE
);

-- Expense Categories (Internet, Home Office, Software etc.)
CREATE TABLE expense_categories (
    category_id         SERIAL PRIMARY KEY,
    category_name       VARCHAR(100) NOT NULL UNIQUE,
    is_fbr_deductible   BOOLEAN NOT NULL DEFAULT FALSE
);

-- FBR Tax Brackets (updatable every year without changing code)
CREATE TABLE tax_brackets (
    bracket_id      SERIAL PRIMARY KEY,
    min_income      NUMERIC(15,2) NOT NULL,
    max_income      NUMERIC(15,2),               -- NULL means no upper limit
    tax_rate        NUMERIC(5,2) NOT NULL,
    tax_year        INTEGER NOT NULL,
    UNIQUE (min_income, tax_year)
);

-- Withholding Tax Rates (filer vs non-filer)
CREATE TABLE withholding_tax_rates (
    rate_id             SERIAL PRIMARY KEY,
    filer_status        BOOLEAN NOT NULL,         -- TRUE = filer, FALSE = non-filer
    transaction_type    VARCHAR(100) NOT NULL,
    rate_percentage     NUMERIC(5,4) NOT NULL,
    effective_from      DATE NOT NULL,
    effective_to        DATE                      -- NULL means still active
);

-- Exchange Rates (historical log)
CREATE TABLE exchange_rates (
    rate_id         SERIAL PRIMARY KEY,
    from_currency   VARCHAR(10) NOT NULL,
    to_currency     VARCHAR(10) NOT NULL DEFAULT 'PKR',
    rate            NUMERIC(15,4) NOT NULL,
    rate_date       DATE NOT NULL,
    source          VARCHAR(100),
    UNIQUE (from_currency, to_currency, rate_date)
);

-- ============================================================
-- STEP 2: CORE TABLES
-- ============================================================

-- Freelancer (main user)
CREATE TABLE freelancer (
    freelancer_id           SERIAL PRIMARY KEY,
    full_name               VARCHAR(150) NOT NULL,
    email                   VARCHAR(150) NOT NULL UNIQUE,
    phone                   VARCHAR(20),
    filer_status            BOOLEAN NOT NULL DEFAULT FALSE,  -- TRUE = filer
    tax_year                INTEGER NOT NULL DEFAULT 2024,
    currency_preference     VARCHAR(10) NOT NULL DEFAULT 'USD',
    created_at              TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Clients
CREATE TABLE clients (
    client_id       SERIAL PRIMARY KEY,
    freelancer_id   INTEGER NOT NULL REFERENCES freelancer(freelancer_id) ON DELETE CASCADE,
    platform_id     INTEGER NOT NULL REFERENCES platforms(platform_id),
    client_name     VARCHAR(150) NOT NULL,
    country         VARCHAR(100),
    currency        VARCHAR(10) NOT NULL DEFAULT 'USD',
    platform_metadata JSONB,                     -- Fiverr order IDs, Upwork contract IDs etc.
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Client Contacts
CREATE TABLE client_contacts (
    contact_id      SERIAL PRIMARY KEY,
    client_id       INTEGER NOT NULL REFERENCES clients(client_id) ON DELETE CASCADE,
    name            VARCHAR(150) NOT NULL,
    email           VARCHAR(150),
    phone           VARCHAR(20),
    is_primary      BOOLEAN NOT NULL DEFAULT FALSE
);

-- Projects
CREATE TABLE projects (
    project_id          SERIAL PRIMARY KEY,
    client_id           INTEGER NOT NULL REFERENCES clients(client_id) ON DELETE CASCADE,
    contract_type_id    INTEGER NOT NULL REFERENCES contract_types(contract_type_id),
    project_title       VARCHAR(200) NOT NULL,
    agreed_amount       NUMERIC(15,2) NOT NULL,
    currency            VARCHAR(10) NOT NULL DEFAULT 'USD',
    status              VARCHAR(20) NOT NULL DEFAULT 'active'
                            CHECK (status IN ('active', 'completed', 'paused', 'cancelled')),
    start_date          DATE NOT NULL,
    end_date            DATE,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Milestones
CREATE TABLE milestones (
    milestone_id    SERIAL PRIMARY KEY,
    project_id      INTEGER NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    title           VARCHAR(200) NOT NULL,
    amount          NUMERIC(15,2) NOT NULL,
    due_date        DATE,
    status          VARCHAR(20) NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending', 'completed', 'paid'))
);

-- Invoices
CREATE TABLE invoices (
    invoice_id      SERIAL PRIMARY KEY,
    project_id      INTEGER NOT NULL REFERENCES projects(project_id) ON DELETE CASCADE,
    invoice_number  VARCHAR(50) NOT NULL UNIQUE,
    amount_due      NUMERIC(15,2) NOT NULL,
    due_date        DATE,
    status          VARCHAR(20) NOT NULL DEFAULT 'unpaid'
                        CHECK (status IN ('unpaid', 'partially_paid', 'paid')),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Invoice Items (line items per invoice)
CREATE TABLE invoice_items (
    item_id         SERIAL PRIMARY KEY,
    invoice_id      INTEGER NOT NULL REFERENCES invoices(invoice_id) ON DELETE CASCADE,
    description     VARCHAR(255) NOT NULL,
    quantity        NUMERIC(10,2) NOT NULL DEFAULT 1,
    unit_price      NUMERIC(15,2) NOT NULL
    -- amount intentionally excluded: calculated as quantity * unit_price (3NF)
);

-- Payments
CREATE TABLE payments (
    payment_id          SERIAL PRIMARY KEY,
    invoice_id          INTEGER NOT NULL REFERENCES invoices(invoice_id) ON DELETE CASCADE,
    channel_id          INTEGER NOT NULL REFERENCES payment_channels(channel_id),
    amount_paid         NUMERIC(15,2) NOT NULL,    -- in foreign currency
    pkr_rate            NUMERIC(15,4) NOT NULL,    -- locked at transaction time, never changes
    gross_amount        NUMERIC(15,2) NOT NULL,    -- before platform fee
    platform_fee        NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    -- net_amount intentionally excluded: calculated as gross_amount - platform_fee (3NF)
    payment_date        DATE NOT NULL DEFAULT CURRENT_DATE,
    notes               TEXT
);

-- Expenses
CREATE TABLE expenses (
    expense_id          SERIAL PRIMARY KEY,
    freelancer_id       INTEGER NOT NULL REFERENCES freelancer(freelancer_id) ON DELETE CASCADE,
    category_id         INTEGER NOT NULL REFERENCES expense_categories(category_id),
    amount              NUMERIC(15,2) NOT NULL,
    expense_date        DATE NOT NULL,
    description         VARCHAR(255),
    receipt_reference   VARCHAR(100),
    notes               TEXT
);

-- Tax Reports (intentional archival snapshot - documented 3NF exception)
CREATE TABLE tax_reports (
    report_id               SERIAL PRIMARY KEY,
    freelancer_id           INTEGER NOT NULL REFERENCES freelancer(freelancer_id) ON DELETE CASCADE,
    tax_year                INTEGER NOT NULL,
    total_income_pkr        NUMERIC(15,2) NOT NULL,
    exempt_income           NUMERIC(15,2) NOT NULL DEFAULT 0.00,   -- SRO 586 exempt
    taxable_income          NUMERIC(15,2) NOT NULL,                -- stored as archival snapshot
    total_deductions        NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    withholding_tax         NUMERIC(15,2) NOT NULL DEFAULT 0.00,
    net_tax_liability       NUMERIC(15,2) NOT NULL,                -- stored as archival snapshot
    generated_at            TIMESTAMP NOT NULL DEFAULT NOW(),
    iris_export_data        JSONB                                   -- mapped to FBR Iris portal fields
);

-- Notifications
CREATE TABLE notifications (
    notification_id     SERIAL PRIMARY KEY,
    freelancer_id       INTEGER NOT NULL REFERENCES freelancer(freelancer_id) ON DELETE CASCADE,
    type                VARCHAR(50) NOT NULL,     -- 'overdue_invoice', 'tax_due', 'payment_received'
    message             TEXT NOT NULL,
    reference_id        INTEGER,                  -- ID of the related record (invoice_id etc.)
    is_read             BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ============================================================
-- STEP 3: INDEXES
-- ============================================================

-- Partial index: only unpaid/partially paid invoices (query performance)
CREATE INDEX idx_invoices_unpaid
    ON invoices(due_date)
    WHERE status IN ('unpaid', 'partially_paid');

-- GIN index on JSONB platform metadata
CREATE INDEX idx_clients_platform_metadata
    ON clients USING GIN (platform_metadata);

-- Index on payments for fast income lookups
CREATE INDEX idx_payments_date
    ON payments(payment_date);

-- Index on expenses for fast deduction lookups
CREATE INDEX idx_expenses_date
    ON expenses(expense_date);

-- ============================================================
-- STEP 4: TRIGGER — Auto update invoice status on payment
-- ============================================================

CREATE OR REPLACE FUNCTION update_invoice_status()
RETURNS TRIGGER AS $$
DECLARE
    v_total_paid    NUMERIC(15,2);
    v_amount_due    NUMERIC(15,2);
BEGIN
    -- Sum all payments for this invoice
    SELECT COALESCE(SUM(amount_paid), 0)
    INTO v_total_paid
    FROM payments
    WHERE invoice_id = NEW.invoice_id;

    -- Get invoice amount due
    SELECT amount_due
    INTO v_amount_due
    FROM invoices
    WHERE invoice_id = NEW.invoice_id;

    -- Update status based on payment total
    IF v_total_paid >= v_amount_due THEN
        UPDATE invoices SET status = 'paid'
        WHERE invoice_id = NEW.invoice_id;
    ELSIF v_total_paid > 0 THEN
        UPDATE invoices SET status = 'partially_paid'
        WHERE invoice_id = NEW.invoice_id;
    ELSE
        UPDATE invoices SET status = 'unpaid'
        WHERE invoice_id = NEW.invoice_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_invoice_status
AFTER INSERT OR UPDATE ON payments
FOR EACH ROW
EXECUTE FUNCTION update_invoice_status();

-- ============================================================
-- STEP 5: MATERIALIZED VIEW — Tax summary dashboard
-- ============================================================

CREATE MATERIALIZED VIEW tax_summary AS
SELECT
    f.freelancer_id,
    f.full_name,
    f.filer_status,
    EXTRACT(YEAR FROM p.payment_date)               AS tax_year,
    SUM(p.gross_amount * p.pkr_rate)                AS total_gross_pkr,
    SUM(p.platform_fee * p.pkr_rate)                AS total_fees_pkr,
    SUM((p.gross_amount - p.platform_fee) * p.pkr_rate) AS total_net_pkr,
    SUM(CASE WHEN pc.is_fbr_compliant = TRUE
        THEN (p.gross_amount - p.platform_fee) * p.pkr_rate
        ELSE 0 END)                                 AS exempt_income_pkr,
    SUM(CASE WHEN pc.is_fbr_compliant = FALSE
        THEN (p.gross_amount - p.platform_fee) * p.pkr_rate
        ELSE 0 END)                                 AS taxable_income_pkr,
    COUNT(DISTINCT p.payment_id)                    AS total_payments,
    COUNT(DISTINCT i.invoice_id)                    AS total_invoices
FROM freelancer f
JOIN clients cl      ON cl.freelancer_id = f.freelancer_id
JOIN projects pr     ON pr.client_id = cl.client_id
JOIN invoices i      ON i.project_id = pr.project_id
JOIN payments p      ON p.invoice_id = i.invoice_id
JOIN payment_channels pc ON pc.channel_id = p.channel_id
GROUP BY f.freelancer_id, f.full_name, f.filer_status, EXTRACT(YEAR FROM p.payment_date);

-- ============================================================
-- STEP 6: STORED PROCEDURE — FBR Tax Engine
-- ============================================================

CREATE OR REPLACE FUNCTION calculate_fbr_tax(
    p_freelancer_id INTEGER,
    p_tax_year      INTEGER
)
RETURNS TABLE (
    total_income_pkr        NUMERIC,
    exempt_income           NUMERIC,
    taxable_income          NUMERIC,
    total_deductions        NUMERIC,
    income_after_deductions NUMERIC,
    withholding_tax         NUMERIC,
    bracket_tax             NUMERIC,
    net_tax_liability       NUMERIC
) AS $$
DECLARE
    v_filer_status      BOOLEAN;
    v_total_income      NUMERIC := 0;
    v_exempt_income     NUMERIC := 0;
    v_deductions        NUMERIC := 0;
    v_withholding_rate  NUMERIC := 0;
    v_bracket_tax       NUMERIC := 0;
BEGIN
    -- Get filer status
    SELECT filer_status INTO v_filer_status
    FROM freelancer WHERE freelancer_id = p_freelancer_id;

    -- Get total net income in PKR for the year
    SELECT COALESCE(SUM((p.gross_amount - p.platform_fee) * p.pkr_rate), 0)
    INTO v_total_income
    FROM payments p
    JOIN invoices i   ON i.invoice_id = p.invoice_id
    JOIN projects pr  ON pr.project_id = i.project_id
    JOIN clients cl   ON cl.client_id = pr.client_id
    WHERE cl.freelancer_id = p_freelancer_id
      AND EXTRACT(YEAR FROM p.payment_date) = p_tax_year;

    -- SRO 586: Get exempt income (payments via FBR compliant channels)
    SELECT COALESCE(SUM((p.gross_amount - p.platform_fee) * p.pkr_rate), 0)
    INTO v_exempt_income
    FROM payments p
    JOIN payment_channels pc ON pc.channel_id = p.channel_id
    JOIN invoices i   ON i.invoice_id = p.invoice_id
    JOIN projects pr  ON pr.project_id = i.project_id
    JOIN clients cl   ON cl.client_id = pr.client_id
    WHERE cl.freelancer_id = p_freelancer_id
      AND EXTRACT(YEAR FROM p.payment_date) = p_tax_year
      AND pc.is_fbr_compliant = TRUE;

    -- Get total FBR deductible expenses
    SELECT COALESCE(SUM(e.amount), 0)
    INTO v_deductions
    FROM expenses e
    JOIN expense_categories ec ON ec.category_id = e.category_id
    WHERE e.freelancer_id = p_freelancer_id
      AND EXTRACT(YEAR FROM e.expense_date) = p_tax_year
      AND ec.is_fbr_deductible = TRUE;

    -- Get withholding tax rate based on filer status
    SELECT rate_percentage INTO v_withholding_rate
    FROM withholding_tax_rates
    WHERE filer_status = v_filer_status
      AND transaction_type = 'banking'
      AND effective_from <= CURRENT_DATE
      AND (effective_to IS NULL OR effective_to >= CURRENT_DATE)
    LIMIT 1;

    -- Calculate bracket tax on non-exempt income
    SELECT COALESCE(SUM(
        CASE
            WHEN (v_total_income - v_exempt_income - v_deductions) > tb.min_income
            THEN LEAST(
                (v_total_income - v_exempt_income - v_deductions) - tb.min_income,
                COALESCE(tb.max_income, v_total_income) - tb.min_income
            ) * (tb.tax_rate / 100)
            ELSE 0
        END
    ), 0)
    INTO v_bracket_tax
    FROM tax_brackets tb
    WHERE tb.tax_year = p_tax_year;

    -- Return all values
    RETURN QUERY SELECT
        v_total_income,
        v_exempt_income,
        v_total_income - v_exempt_income,
        v_deductions,
        v_total_income - v_exempt_income - v_deductions,
        v_total_income * v_withholding_rate,
        v_bracket_tax,
        (v_total_income * v_withholding_rate) + v_bracket_tax;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- STEP 7: SEED DATA — Lookups
-- ============================================================

INSERT INTO platforms (platform_name, fee_percentage) VALUES
    ('Fiverr', 20.00),
    ('Upwork', 10.00),
    ('Direct', 0.00);

INSERT INTO contract_types (type_name, description) VALUES
    ('Fixed',    'One-time fixed price project'),
    ('Hourly',   'Billed by the hour'),
    ('Retainer', 'Monthly recurring contract');

INSERT INTO payment_channels (channel_name, is_fbr_compliant) VALUES
    ('Bank Transfer', TRUE),
    ('Payoneer',      TRUE),
    ('Wise',          TRUE),
    ('Cash',          FALSE),
    ('Crypto',        FALSE);

INSERT INTO expense_categories (category_name, is_fbr_deductible) VALUES
    ('Internet',        TRUE),
    ('Home Office',     TRUE),
    ('Software',        TRUE),
    ('Equipment',       TRUE),
    ('Marketing',       TRUE),
    ('Entertainment',   FALSE),
    ('Personal',        FALSE);

-- FBR Tax Brackets 2024 (PKR)
INSERT INTO tax_brackets (min_income, max_income, tax_rate, tax_year) VALUES
    (0,         600000,     0.00,   2024),
    (600001,    1200000,    5.00,   2024),
    (1200001,   2400000,    10.00,  2024),
    (2400001,   3600000,    15.00,  2024),
    (3600001,   6000000,    20.00,  2024),
    (6000001,   NULL,       25.00,  2024);

-- Withholding Tax Rates
INSERT INTO withholding_tax_rates (filer_status, transaction_type, rate_percentage, effective_from) VALUES
    (TRUE,  'banking', 0.0015, '2024-01-01'),   -- filer: 0.15%
    (FALSE, 'banking', 0.0030, '2024-01-01');   -- non-filer: 0.30%




-- ============================================================
-- HisaabPro Dummy Data
-- Realistic Pakistani Freelancer Scenario
-- ============================================================

-- ============================================================
-- FREELANCER
-- ============================================================

INSERT INTO freelancer (full_name, email, phone, filer_status, tax_year, currency_preference) VALUES
('Ahmed Raza', 'ahmed.raza@gmail.com', '0312-4567890', TRUE, 2024, 'USD');

-- ============================================================
-- CLIENTS
-- ============================================================

INSERT INTO clients (freelancer_id, platform_id, client_name, country, currency, platform_metadata) VALUES
-- Fiverr client from USA
(1, 1, 'John Mitchell', 'United States', 'USD', 
    '{"order_id": "FO-20240101", "gig_title": "Full Stack Web Development", "delivery_days": 7}'),

-- Upwork client from UK
(1, 2, 'Sarah Thompson', 'United Kingdom', 'GBP', 
    '{"contract_id": "UW-48291", "contract_type": "hourly", "weekly_limit_hours": 20}'),

-- Direct client from UAE
(1, 3, 'Ali Hassan Trading LLC', 'United Arab Emirates', 'USD', 
    '{"reference": "DIRECT-2024-001", "payment_terms": "net30"}'),

-- Upwork client from Canada
(1, 2, 'David Chen', 'Canada', 'USD', 
    '{"contract_id": "UW-59302", "contract_type": "fixed", "weekly_limit_hours": null}'),

-- Fiverr client from Australia
(1, 1, 'Emma Wilson', 'Australia', 'USD', 
    '{"order_id": "FO-20240215", "gig_title": "React Dashboard Development", "delivery_days": 14}');

-- ============================================================
-- CLIENT CONTACTS
-- ============================================================

INSERT INTO client_contacts (client_id, name, email, phone, is_primary) VALUES
(1, 'John Mitchell',   'john.mitchell@techcorp.com',   '+1-555-0101', TRUE),
(2, 'Sarah Thompson',  'sarah.t@digitalagency.co.uk',  '+44-20-7946', TRUE),
(2, 'Mike Roberts',    'mike.r@digitalagency.co.uk',   '+44-20-7947', FALSE),
(3, 'Ali Hassan',      'ali@alihassantrading.ae',       '+971-50-123', TRUE),
(3, 'Fatima Malik',    'fatima@alihassantrading.ae',    '+971-50-124', FALSE),
(4, 'David Chen',      'david.chen@startupco.ca',      '+1-416-555',  TRUE),
(5, 'Emma Wilson',     'emma.w@designstudio.com.au',   '+61-2-9876',  TRUE);

-- ============================================================
-- PROJECTS
-- ============================================================

INSERT INTO projects (client_id, contract_type_id, project_title, agreed_amount, currency, status, start_date, end_date) VALUES
-- John Mitchell - Fixed project
(1, 1, 'E-Commerce Website Development',        1200.00, 'USD', 'completed', '2024-01-05', '2024-02-05'),

-- Sarah Thompson - Hourly project
(2, 2, 'Digital Marketing Dashboard',           800.00,  'GBP', 'completed', '2024-02-01', '2024-03-15'),

-- Ali Hassan - Retainer
(3, 3, 'Monthly IT Support & Maintenance',      500.00,  'USD', 'active',    '2024-01-01', NULL),

-- David Chen - Fixed project
(4, 1, 'Mobile App Backend API',                2500.00, 'USD', 'completed', '2024-03-01', '2024-05-01'),

-- Emma Wilson - Fixed project
(5, 1, 'React Analytics Dashboard',             950.00,  'USD', 'active',    '2024-04-01', NULL),

-- John Mitchell - second project
(1, 2, 'Website Maintenance Hourly',            300.00,  'USD', 'active',    '2024-03-01', NULL);

-- ============================================================
-- MILESTONES
-- ============================================================

INSERT INTO milestones (project_id, title, amount, due_date, status) VALUES
-- E-Commerce Website milestones
(1, 'UI Design & Wireframes',       300.00, '2024-01-15', 'paid'),
(1, 'Frontend Development',         500.00, '2024-01-25', 'paid'),
(1, 'Backend & Database',           400.00, '2024-02-05', 'paid'),

-- Mobile App Backend milestones
(4, 'API Architecture & Setup',     500.00, '2024-03-15', 'paid'),
(4, 'Core API Development',         1000.00,'2024-04-01', 'paid'),
(4, 'Testing & Deployment',         1000.00,'2024-05-01', 'paid'),

-- React Dashboard milestones
(5, 'Design Mockups',               250.00, '2024-04-15', 'completed'),
(5, 'Dashboard Development',        700.00, '2024-05-15', 'pending');

-- ============================================================
-- INVOICES
-- ============================================================

INSERT INTO invoices (project_id, invoice_number, amount_due, due_date, status) VALUES
-- E-Commerce project invoices
(1, 'INV-2024-001', 300.00, '2024-01-15', 'paid'),
(1, 'INV-2024-002', 500.00, '2024-01-25', 'paid'),
(1, 'INV-2024-003', 400.00, '2024-02-05', 'paid'),

-- Marketing Dashboard
(2, 'INV-2024-004', 800.00, '2024-03-15', 'paid'),

-- Monthly retainer (Jan, Feb, Mar, Apr)
(3, 'INV-2024-005', 500.00, '2024-01-31', 'paid'),
(3, 'INV-2024-006', 500.00, '2024-02-29', 'paid'),
(3, 'INV-2024-007', 500.00, '2024-03-31', 'paid'),
(3, 'INV-2024-008', 500.00, '2024-04-30', 'unpaid'),

-- Mobile App Backend
(4, 'INV-2024-009', 500.00,  '2024-03-15', 'paid'),
(4, 'INV-2024-010', 1000.00, '2024-04-01', 'paid'),
(4, 'INV-2024-011', 1000.00, '2024-05-01', 'paid'),

-- React Dashboard
(5, 'INV-2024-012', 250.00, '2024-04-15', 'partially_paid'),

-- Website Maintenance
(6, 'INV-2024-013', 150.00, '2024-03-31', 'paid'),
(6, 'INV-2024-014', 150.00, '2024-04-30', 'unpaid');

-- ============================================================
-- INVOICE ITEMS
-- ============================================================

INSERT INTO invoice_items (invoice_id, description, quantity, unit_price) VALUES
(1,  'UI Design & Wireframes',              1,    300.00),
(2,  'Frontend Development',                1,    500.00),
(3,  'Backend & Database Setup',            1,    400.00),
(4,  'Marketing Dashboard - Full Project',  1,    800.00),
(5,  'IT Support - January',                1,    500.00),
(6,  'IT Support - February',               1,    500.00),
(7,  'IT Support - March',                  1,    500.00),
(8,  'IT Support - April',                  1,    500.00),
(9,  'API Architecture & Setup',            1,    500.00),
(10, 'Core API Development',                1,   1000.00),
(11, 'Testing & Deployment',                1,   1000.00),
(12, 'Design Mockups',                      1,    250.00),
(13, 'Website Maintenance - March',         3,     50.00),
(14, 'Website Maintenance - April',         3,     50.00);

-- ============================================================
-- EXCHANGE RATES (historical PKR rates)
-- ============================================================

INSERT INTO exchange_rates (from_currency, to_currency, rate, rate_date, source) VALUES
('USD', 'PKR', 278.50, '2024-01-15', 'SBP'),
('USD', 'PKR', 279.20, '2024-01-25', 'SBP'),
('USD', 'PKR', 279.80, '2024-02-05', 'SBP'),
('GBP', 'PKR', 354.60, '2024-03-15', 'SBP'),
('USD', 'PKR', 278.00, '2024-01-31', 'SBP'),
('USD', 'PKR', 280.10, '2024-02-29', 'SBP'),
('USD', 'PKR', 278.90, '2024-03-31', 'SBP'),
('USD', 'PKR', 281.50, '2024-03-15', 'SBP'),
('USD', 'PKR', 282.00, '2024-04-01', 'SBP'),
('USD', 'PKR', 283.50, '2024-05-01', 'SBP'),
('USD', 'PKR', 279.00, '2024-03-30', 'SBP'),
('USD', 'PKR', 280.50, '2024-04-15', 'SBP');

-- ============================================================
-- PAYMENTS
-- (trigger will auto-update invoice status)
-- ============================================================

INSERT INTO payments (invoice_id, channel_id, amount_paid, pkr_rate, gross_amount, platform_fee, payment_date, notes) VALUES
-- INV-2024-001: $300 Fiverr (20% fee) via Payoneer
(1,  2, 240.00, 278.50, 300.00, 60.00,  '2024-01-15', 'Fiverr order payment - 20% fee deducted'),

-- INV-2024-002: $500 Fiverr via Payoneer
(2,  2, 400.00, 279.20, 500.00, 100.00, '2024-01-25', 'Fiverr milestone payment'),

-- INV-2024-003: $400 Fiverr via Payoneer
(3,  2, 320.00, 279.80, 400.00, 80.00,  '2024-02-05', 'Fiverr final milestone'),

-- INV-2024-004: £800 Upwork (10% fee) via Bank Transfer
(4,  1, 720.00, 354.60, 800.00, 80.00,  '2024-03-15', 'Upwork monthly billing'),

-- INV-2024-005: $500 Direct via Bank Transfer
(5,  1, 500.00, 278.00, 500.00, 0.00,   '2024-01-31', 'Monthly retainer January'),

-- INV-2024-006: $500 Direct via Wise
(6,  3, 500.00, 280.10, 500.00, 0.00,   '2024-02-29', 'Monthly retainer February'),

-- INV-2024-007: $500 Direct via Bank Transfer
(7,  1, 500.00, 278.90, 500.00, 0.00,   '2024-03-31', 'Monthly retainer March'),

-- INV-2024-009: $500 Upwork via Bank Transfer
(9,  1, 450.00, 281.50, 500.00, 50.00,  '2024-03-15', 'Upwork first milestone'),

-- INV-2024-010: $1000 Upwork via Bank Transfer
(10, 1, 900.00, 282.00, 1000.00, 100.00,'2024-04-01', 'Upwork core development milestone'),

-- INV-2024-011: $1000 Upwork via Bank Transfer
(11, 1, 900.00, 283.50, 1000.00, 100.00,'2024-05-01', 'Upwork final milestone'),

-- INV-2024-012: Partial payment $100 of $250 via Payoneer
(12, 2, 100.00, 280.50, 100.00, 0.00,   '2024-04-15', 'Partial payment received'),

-- INV-2024-013: $150 via Bank Transfer
(13, 1, 150.00, 279.00, 150.00, 0.00,   '2024-03-31', 'Maintenance hours March');

-- ============================================================
-- EXPENSES
-- ============================================================

INSERT INTO expenses (freelancer_id, category_id, amount, expense_date, description, receipt_reference, notes) VALUES
(1, 1, 3500.00,  '2024-01-05', 'Monthly fiber internet - PTCL',        'PTCL-JAN-2024',  'Home office internet'),
(1, 1, 3500.00,  '2024-02-05', 'Monthly fiber internet - PTCL',        'PTCL-FEB-2024',  'Home office internet'),
(1, 1, 3500.00,  '2024-03-05', 'Monthly fiber internet - PTCL',        'PTCL-MAR-2024',  'Home office internet'),
(1, 1, 3500.00,  '2024-04-05', 'Monthly fiber internet - PTCL',        'PTCL-APR-2024',  'Home office internet'),
(1, 3, 12000.00, '2024-01-10', 'Adobe Creative Cloud annual',          'ADOBE-2024',     'Design software'),
(1, 3, 8500.00,  '2024-01-15', 'GitHub Pro + Vercel Pro subscription', 'GH-VER-2024',    'Dev tools'),
(1, 3, 4200.00,  '2024-02-20', 'Postman API Tool annual license',      'POSTMAN-2024',   'API testing tool'),
(1, 4, 45000.00, '2024-02-01', 'Mechanical keyboard - Keychron K2',    'KK2-LAHORE',     'Work equipment'),
(1, 4, 8500.00,  '2024-03-10', 'Webcam for client meetings',           'WC-DARAZ-2024',  'Work equipment'),
(1, 2, 5000.00,  '2024-01-01', 'Home office desk setup',               'DESK-2024',      'Dedicated work area'),
(1, 5, 3000.00,  '2024-02-15', 'LinkedIn Premium - 3 months',          'LI-Q1-2024',     'Client acquisition'),
(1, 6, 2500.00,  '2024-03-20', 'Team lunch with local collaborator',   'LUNCH-MAR-2024', 'Not deductible'),
(1, 7, 1500.00,  '2024-04-10', 'Personal mobile bill',                 'JAZZ-APR-2024',  'Not deductible');

-- ============================================================
-- NOTIFICATIONS
-- ============================================================

INSERT INTO notifications (freelancer_id, type, message, reference_id, is_read) VALUES
(1, 'overdue_invoice',    'Invoice INV-2024-008 for Ali Hassan Trading is due today',        8,    FALSE),
(1, 'overdue_invoice',    'Invoice INV-2024-014 for John Mitchell maintenance is overdue',   14,   FALSE),
(1, 'payment_received',   'Payment received for INV-2024-011 - Mobile App final milestone',  11,   TRUE),
(1, 'tax_due',            'Your Q1 2024 tax summary is ready. Review your FBR liability',    NULL, FALSE),
(1, 'payment_received',   'Partial payment received for INV-2024-012 from Emma Wilson',      12,   TRUE);

-- ============================================================
-- VERIFY DATA
-- ============================================================

SELECT 'freelancer'         AS table_name, COUNT(*) AS rows FROM freelancer         UNION ALL
SELECT 'clients',                          COUNT(*)          FROM clients            UNION ALL
SELECT 'client_contacts',                  COUNT(*)          FROM client_contacts    UNION ALL
SELECT 'projects',                         COUNT(*)          FROM projects           UNION ALL
SELECT 'milestones',                       COUNT(*)          FROM milestones         UNION ALL
SELECT 'invoices',                         COUNT(*)          FROM invoices           UNION ALL
SELECT 'invoice_items',                    COUNT(*)          FROM invoice_items      UNION ALL
SELECT 'payments',                         COUNT(*)          FROM payments           UNION ALL
SELECT 'expenses',                         COUNT(*)          FROM expenses           UNION ALL
SELECT 'notifications',                    COUNT(*)          FROM notifications      UNION ALL
SELECT 'exchange_rates',                   COUNT(*)          FROM exchange_rates;