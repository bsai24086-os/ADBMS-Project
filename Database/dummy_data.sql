
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
