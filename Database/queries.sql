-- 1. Get freelancer profile
SELECT * FROM freelancer WHERE freelancer_id = 1;

-- 2. Update filer status
UPDATE freelancer SET filer_status = TRUE WHERE freelancer_id = 1;



-- 3. Get all clients for a freelancer
SELECT c.client_id, c.client_name, c.country, c.currency,
       p.platform_name, p.fee_percentage
FROM clients c
JOIN platforms p ON p.platform_id = c.platform_id
WHERE c.freelancer_id = 1;

-- 4. Get single client with their contacts
SELECT c.*, cc.name, cc.email, cc.phone, cc.is_primary
FROM clients c
LEFT JOIN client_contacts cc ON cc.client_id = c.client_id
WHERE c.client_id = 1;

-- 5. Insert new client
INSERT INTO clients (freelancer_id, platform_id, client_name, country, currency, platform_metadata)
VALUES (1, 1, 'New Client', 'USA', 'USD', '{"order_id": "FO-999"}');

-- 6. Update client details
UPDATE clients SET country = 'Canada' WHERE client_id = 1;

-- 7. Delete client
DELETE FROM clients WHERE client_id = 1;

-- 8. Search clients by name
SELECT * FROM clients WHERE client_name ILIKE '%john%' AND freelancer_id = 1;

-- 9. Get all projects with client name and contract type
SELECT pr.project_id, pr.project_title, pr.agreed_amount,
       pr.currency, pr.status, pr.start_date, pr.end_date,
       c.client_name, ct.type_name AS contract_type
FROM projects pr
JOIN clients c       ON c.client_id = pr.client_id
JOIN contract_types ct ON ct.contract_type_id = pr.contract_type_id
WHERE c.freelancer_id = 1
ORDER BY pr.start_date DESC;

-- 10. Get projects by status
SELECT * FROM projects pr
JOIN clients c ON c.client_id = pr.client_id
WHERE pr.status = 'active' AND c.freelancer_id = 1;

-- 11. Get single project with full details
SELECT pr.*, c.client_name, ct.type_name, p.platform_name
FROM projects pr
JOIN clients c         ON c.client_id = pr.client_id
JOIN contract_types ct ON ct.contract_type_id = pr.contract_type_id
JOIN platforms p       ON p.platform_id = c.platform_id
WHERE pr.project_id = 1;

-- 12. Insert new project
INSERT INTO projects (client_id, contract_type_id, project_title, agreed_amount, currency, status, start_date)
VALUES (1, 1, 'New Website', 1500.00, 'USD', 'active', '2024-05-01');

-- 13. Update project status
UPDATE projects SET status = 'completed', end_date = CURRENT_DATE
WHERE project_id = 1;

-- 14. Get project milestones
SELECT * FROM milestones WHERE project_id = 1 ORDER BY due_date;

-- 15. Get total agreed amount vs total paid per project
SELECT pr.project_id, pr.project_title, pr.agreed_amount,
       COALESCE(SUM(pay.amount_paid), 0) AS total_paid,
       pr.agreed_amount - COALESCE(SUM(pay.amount_paid), 0) AS remaining
FROM projects pr
LEFT JOIN invoices i  ON i.project_id = pr.project_id
LEFT JOIN payments pay ON pay.invoice_id = i.invoice_id
WHERE pr.project_id = 1
GROUP BY pr.project_id, pr.project_title, pr.agreed_amount;


-- 16. Get all invoices with project and client info
SELECT i.invoice_id, i.invoice_number, i.amount_due,
       i.due_date, i.status, i.created_at,
       pr.project_title, c.client_name
FROM invoices i
JOIN projects pr ON pr.project_id = i.project_id 
JOIN clients c   ON c.client_id = pr.client_id
WHERE c.freelancer_id = 1
ORDER BY i.created_at DESC;

-- 17. Get all unpaid and overdue invoices (uses partial index)
SELECT i.invoice_number, i.amount_due, i.due_date,
       c.client_name, pr.project_title,
       CURRENT_DATE - i.due_date AS days_overdue
FROM invoices i
JOIN projects pr ON pr.project_id = i.project_id
JOIN clients c   ON c.client_id = pr.client_id
WHERE i.status IN ('unpaid', 'partially_paid')
  AND c.freelancer_id = 1
ORDER BY i.due_date ASC;

-- 18. Get single invoice with all line items
SELECT i.invoice_number, i.amount_due, i.status,
       ii.description, ii.quantity, ii.unit_price,
       (ii.quantity * ii.unit_price) AS line_total
FROM invoices i
JOIN invoice_items ii ON ii.invoice_id = i.invoice_id
WHERE i.invoice_id = 1;

-- 19. Get invoice payment history
SELECT i.invoice_number, i.amount_due,
       COALESCE(SUM(p.amount_paid), 0) AS total_paid,
       i.amount_due - COALESCE(SUM(p.amount_paid), 0) AS balance_remaining,
       i.status
FROM invoices i
LEFT JOIN payments p ON p.invoice_id = i.invoice_id
WHERE i.invoice_id = 1
GROUP BY i.invoice_id, i.invoice_number, i.amount_due, i.status;

-- 20. Insert new invoice
INSERT INTO invoices (project_id, invoice_number, amount_due, due_date)
VALUES (1, 'INV-2024-015', 500.00, '2024-06-01');

-- 21. Insert invoice line items
INSERT INTO invoice_items (invoice_id, description, quantity, unit_price)
VALUES (15, 'Frontend Development', 1, 500.00);

-- 22. Get monthly invoice summary
SELECT DATE_TRUNC('month', created_at) AS month,
       COUNT(*) AS total_invoices,
       SUM(amount_due) AS total_billed,
       COUNT(CASE WHEN status = 'paid' THEN 1 END) AS paid_count,
       COUNT(CASE WHEN status = 'unpaid' THEN 1 END) AS unpaid_count
FROM invoices i
JOIN projects pr ON pr.project_id = i.project_id
JOIN clients c   ON c.client_id = pr.client_id
WHERE c.freelancer_id = 1
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month DESC;

-- 23. Get total outstanding amount
SELECT SUM(i.amount_due - COALESCE(paid.total_paid, 0)) AS total_outstanding
FROM invoices i
LEFT JOIN (
    SELECT invoice_id, SUM(amount_paid) AS total_paid
    FROM payments GROUP BY invoice_id
) paid ON paid.invoice_id = i.invoice_id
JOIN projects pr ON pr.project_id = i.project_id
JOIN clients c   ON c.client_id = pr.client_id
WHERE i.status IN ('unpaid', 'partially_paid')
  AND c.freelancer_id = 1;



-- 24. Insert new payment (trigger fires automatically after this)
INSERT INTO payments (invoice_id, channel_id, amount_paid, pkr_rate, gross_amount, platform_fee, payment_date)
VALUES (1, 2, 400.00, 278.50, 500.00, 100.00, CURRENT_DATE);

-- 25. Get all payments with full details
SELECT pay.payment_id, pay.amount_paid, pay.pkr_rate,
       pay.gross_amount, pay.platform_fee,
       (pay.gross_amount - pay.platform_fee) AS net_amount,
       (pay.gross_amount - pay.platform_fee) * pay.pkr_rate AS net_pkr,
       pay.payment_date, pc.channel_name, pc.is_fbr_compliant,
       i.invoice_number, c.client_name
FROM payments pay
JOIN payment_channels pc ON pc.channel_id = pay.channel_id
JOIN invoices i          ON i.invoice_id = pay.invoice_id
JOIN projects pr         ON pr.project_id = i.project_id
JOIN clients c           ON c.client_id = pr.client_id
WHERE c.freelancer_id = 1
ORDER BY pay.payment_date DESC;

-- 26. Get total income by platform
SELECT p.platform_name,
       COUNT(pay.payment_id) AS total_payments,
       SUM(pay.gross_amount) AS total_gross,
       SUM(pay.platform_fee) AS total_fees,
       SUM(pay.gross_amount - pay.platform_fee) AS total_net,
       SUM((pay.gross_amount - pay.platform_fee) * pay.pkr_rate) AS total_net_pkr
FROM payments pay
JOIN invoices i    ON i.invoice_id = pay.invoice_id
JOIN projects pr   ON pr.project_id = i.project_id
JOIN clients c     ON c.client_id = pr.client_id
JOIN platforms p   ON p.platform_id = c.platform_id
WHERE c.freelancer_id = 1
GROUP BY p.platform_name;

-- 27. Get monthly income trend
SELECT DATE_TRUNC('month', pay.payment_date) AS month,
       SUM(pay.gross_amount - pay.platform_fee) AS net_income,
       SUM((pay.gross_amount - pay.platform_fee) * pay.pkr_rate) AS net_income_pkr
FROM payments pay
JOIN invoices i  ON i.invoice_id = pay.invoice_id
JOIN projects pr ON pr.project_id = i.project_id
JOIN clients c   ON c.client_id = pr.client_id
WHERE c.freelancer_id = 1
GROUP BY DATE_TRUNC('month', pay.payment_date)
ORDER BY month;

-- 28. Get income by currency
SELECT i.currency,
       SUM(pay.gross_amount - pay.platform_fee) AS total_net_foreign,
       SUM((pay.gross_amount - pay.platform_fee) * pay.pkr_rate) AS total_net_pkr
FROM payments pay
JOIN invoices i  ON i.invoice_id = pay.invoice_id
JOIN projects pr ON pr.project_id = i.project_id
JOIN clients c   ON c.client_id = pr.client_id
WHERE c.freelancer_id = 1
GROUP BY i.currency;

-- 29. Get SRO 586 compliant vs non-compliant income split
SELECT pc.is_fbr_compliant,
       SUM((pay.gross_amount - pay.platform_fee) * pay.pkr_rate) AS total_pkr,
       COUNT(*) AS payment_count
FROM payments pay
JOIN payment_channels pc ON pc.channel_id = pay.channel_id
JOIN invoices i          ON i.invoice_id = pay.invoice_id
JOIN projects pr         ON pr.project_id = i.project_id
JOIN clients c           ON c.client_id = pr.client_id
WHERE c.freelancer_id = 1
GROUP BY pc.is_fbr_compliant;

-- 30. Get top earning clients
SELECT c.client_name, p.platform_name,
       SUM((pay.gross_amount - pay.platform_fee) * pay.pkr_rate) AS total_earned_pkr
FROM payments pay
JOIN invoices i  ON i.invoice_id = pay.invoice_id
JOIN projects pr ON pr.project_id = i.project_id
JOIN clients c   ON c.client_id = pr.client_id
JOIN platforms p ON p.platform_id = c.platform_id
WHERE c.freelancer_id = 1
GROUP BY c.client_name, p.platform_name
ORDER BY total_earned_pkr DESC;



-- 31. Get all expenses with category and deductibility
SELECT e.expense_id, e.amount, e.expense_date,
       e.description, e.receipt_reference,
       ec.category_name, ec.is_fbr_deductible
FROM expenses e
JOIN expense_categories ec ON ec.category_id = e.category_id
WHERE e.freelancer_id = 1
ORDER BY e.expense_date DESC;

-- 32. Get total deductible vs non-deductible expenses
SELECT ec.is_fbr_deductible,
       SUM(e.amount) AS total_amount,
       COUNT(*) AS expense_count
FROM expenses e
JOIN expense_categories ec ON ec.category_id = e.category_id
WHERE e.freelancer_id = 1
GROUP BY ec.is_fbr_deductible;

-- 33. Get expenses by category
SELECT ec.category_name, SUM(e.amount) AS total,
       COUNT(*) AS count
FROM expenses e
JOIN expense_categories ec ON ec.category_id = e.category_id
WHERE e.freelancer_id = 1
GROUP BY ec.category_name
ORDER BY total DESC;

-- 34. Insert new expense
INSERT INTO expenses (freelancer_id, category_id, amount, expense_date, description, receipt_reference)
VALUES (1, 1, 3500.00, CURRENT_DATE, 'Monthly internet - PTCL', 'PTCL-MAY-2024');

-- 35. Get yearly deductible expenses total
SELECT SUM(e.amount) AS total_deductible
FROM expenses e
JOIN expense_categories ec ON ec.category_id = e.category_id
WHERE e.freelancer_id = 1
  AND ec.is_fbr_deductible = TRUE
  AND EXTRACT(YEAR FROM e.expense_date) = 2024;




-- 36. Call FBR Tax Engine stored procedure
SELECT * FROM calculate_fbr_tax(1, 2024);

-- 37. Save tax report after calculation
INSERT INTO tax_reports (
    freelancer_id, tax_year, total_income_pkr, exempt_income,
    taxable_income, total_deductions, withholding_tax,
    net_tax_liability, iris_export_data
)
SELECT 1, 2024,
       total_income_pkr, exempt_income, taxable_income,
       total_deductions, withholding_tax, net_tax_liability,
       '{"field_1": "income", "field_2": "exemption"}'::JSONB
FROM calculate_fbr_tax(1, 2024);

-- 38. Get saved tax reports
SELECT * FROM tax_reports
WHERE freelancer_id = 1
ORDER BY generated_at DESC;

-- 39. Refresh materialized view (call this after new payments)
REFRESH MATERIALIZED VIEW tax_summary;

-- 40. Read from materialized view for dashboard
SELECT * FROM tax_summary WHERE freelancer_id = 1;




-- 41. Main dashboard numbers
SELECT
    (SELECT COUNT(*) FROM clients WHERE freelancer_id = 1) AS total_clients,
    (SELECT COUNT(*) FROM projects pr JOIN clients c ON c.client_id = pr.client_id
     WHERE c.freelancer_id = 1 AND pr.status = 'active') AS active_projects,
    (SELECT COUNT(*) FROM invoices i JOIN projects pr ON pr.project_id = i.project_id
     JOIN clients c ON c.client_id = pr.client_id
     WHERE c.freelancer_id = 1 AND i.status = 'unpaid') AS unpaid_invoices,
    (SELECT COALESCE(SUM((pay.gross_amount - pay.platform_fee) * pay.pkr_rate), 0)
     FROM payments pay
     JOIN invoices i ON i.invoice_id = pay.invoice_id
     JOIN projects pr ON pr.project_id = i.project_id
     JOIN clients c ON c.client_id = pr.client_id
     WHERE c.freelancer_id = 1
       AND EXTRACT(YEAR FROM pay.payment_date) = 2024) AS total_income_pkr_2024;

-- 42. Recent payments for activity feed
SELECT pay.payment_date, pay.amount_paid,
       (pay.gross_amount - pay.platform_fee) * pay.pkr_rate AS net_pkr,
       c.client_name, i.invoice_number, pc.channel_name
FROM payments pay
JOIN invoices i          ON i.invoice_id = pay.invoice_id
JOIN projects pr         ON pr.project_id = i.project_id
JOIN clients c           ON c.client_id = pr.client_id
JOIN payment_channels pc ON pc.channel_id = pay.channel_id
WHERE c.freelancer_id = 1
ORDER BY pay.payment_date DESC
LIMIT 5;

-- 43. Notifications — unread only
SELECT * FROM notifications
WHERE freelancer_id = 1 AND is_read = FALSE
ORDER BY created_at DESC;

-- 44. Mark notification as read
UPDATE notifications SET is_read = TRUE
WHERE notification_id = 1;


-- 45. Get latest rate for a currency
SELECT rate FROM exchange_rates
WHERE from_currency = 'USD' AND to_currency = 'PKR'
ORDER BY rate_date DESC
LIMIT 1;

-- 46. Insert new rate
INSERT INTO exchange_rates (from_currency, to_currency, rate, rate_date, source)
VALUES ('USD', 'PKR', 282.50, CURRENT_DATE, 'SBP');



-- 47. Search inside platform metadata using GIN index
SELECT * FROM clients
WHERE platform_metadata @> '{"contract_type": "hourly"}'::jsonb
  AND freelancer_id = 1;

-- 48. Extract specific field from JSONB
SELECT client_name,
       platform_metadata->>'order_id' AS fiverr_order_id
FROM clients
WHERE platform_id = 1 AND freelancer_id = 1;


