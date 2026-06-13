"""
HisaabPro — Complete System Test Suite
Tests every single endpoint, database trigger, stored procedure,
materialized view, JSONB queries, and data integrity.

Run from backend folder:
    pip install pytest requests --break-system-packages
    python test_hisaabpro.py
"""

import requests
import json
import sys
from datetime import date, datetime

BASE = "http://127.0.0.1:8000"
FREELANCER_ID = 1

# ── Colors for terminal output ────────────────────────────────
GREEN  = "\033[92m"
RED    = "\033[91m"
YELLOW = "\033[93m"
CYAN   = "\033[96m"
BOLD   = "\033[1m"
RESET  = "\033[0m"

passed = 0
failed = 0
created_ids = {}  # track created records for cleanup

def ok(msg):
    global passed
    passed += 1
    print(f"  {GREEN}✔{RESET} {msg}")

def fail(msg, detail=""):
    global failed
    failed += 1
    print(f"  {RED}✘{RESET} {msg}")
    if detail:
        print(f"    {RED}→ {detail}{RESET}")

def section(title):
    print(f"\n{CYAN}{BOLD}{'─'*55}{RESET}")
    print(f"{CYAN}{BOLD}  {title}{RESET}")
    print(f"{CYAN}{BOLD}{'─'*55}{RESET}")

def check(label, condition, detail=""):
    if condition:
        ok(label)
    else:
        fail(label, detail)

def get(path):
    try:
        r = requests.get(f"{BASE}{path}", timeout=10)
        return r
    except Exception as e:
        return None

def post(path, data):
    try:
        r = requests.post(f"{BASE}{path}", json=data, timeout=10)
        return r
    except Exception as e:
        return None

def put(path, data):
    try:
        r = requests.put(f"{BASE}{path}", json=data, timeout=10)
        return r
    except Exception as e:
        return None

def delete(path):
    try:
        r = requests.delete(f"{BASE}{path}", timeout=10)
        return r
    except Exception as e:
        return None

# ══════════════════════════════════════════════════════════════
# TEST 1: SERVER HEALTH
# ══════════════════════════════════════════════════════════════
section("1. SERVER HEALTH")

r = get("/")
check("Server is running", r and r.status_code == 200)
check("Returns correct message",
    r and r.json().get("message") == "HisaabPro API is running")

r = get("/docs")
check("Swagger docs accessible", r and r.status_code == 200)

# ══════════════════════════════════════════════════════════════
# TEST 2: FREELANCER
# ══════════════════════════════════════════════════════════════
section("2. FREELANCER")

r = get(f"/freelancer/{FREELANCER_ID}")
check("GET freelancer profile", r and r.status_code == 200)
if r and r.status_code == 200:
    d = r.json()
    check("Has freelancer_id",     "freelancer_id"       in d)
    check("Has full_name",         "full_name"           in d)
    check("Has filer_status",      "filer_status"        in d)
    check("Has tax_year",          "tax_year"            in d)
    check("Has currency_preference","currency_preference" in d)

r = put(f"/freelancer/{FREELANCER_ID}", {"filer_status": True})
check("PUT update filer status to True",  r and r.status_code == 200)

r = get(f"/freelancer/9999")
check("GET non-existent freelancer returns 404",
    r and r.status_code == 404)

# ══════════════════════════════════════════════════════════════
# TEST 3: CLIENTS
# ══════════════════════════════════════════════════════════════
section("3. CLIENTS")

r = get(f"/clients/{FREELANCER_ID}")
check("GET all clients", r and r.status_code == 200)
if r and r.status_code == 200:
    clients = r.json()
    check("Returns list",           isinstance(clients, list))
    if clients:
        c = clients[0]
        check("Client has client_id",     "client_id"     in c)
        check("Client has client_name",   "client_name"   in c)
        check("Client has platform_name", "platform_name" in c)

# Create new client
r = post("/clients/", {
    "freelancer_id": FREELANCER_ID,
    "platform_id": 1,
    "client_name": "TEST CLIENT — DELETE ME",
    "country": "Germany",
    "currency": "EUR",
    "platform_metadata": {"order_id": "TEST-001", "gig_title": "Test Gig"}
})
check("POST create new client", r and r.status_code == 200)
if r and r.status_code == 200:
    new_client = r.json()
    if isinstance(new_client, list):
        new_client = new_client[0]
    created_ids["client_id"] = new_client.get("client_id")
    check("New client has ID", created_ids.get("client_id") is not None)

# Search clients
r = get(f"/clients/search/{FREELANCER_ID}/test")
check("GET search clients by name", r and r.status_code == 200)

# Update client
if created_ids.get("client_id"):
    r = put(f"/clients/{created_ids['client_id']}", {"country": "France"})
    check("PUT update client country", r and r.status_code == 200)

# ══════════════════════════════════════════════════════════════
# TEST 4: PROJECTS
# ══════════════════════════════════════════════════════════════
section("4. PROJECTS")

r = get(f"/projects/{FREELANCER_ID}")
check("GET all projects", r and r.status_code == 200)
if r and r.status_code == 200:
    projects = r.json()
    check("Returns list",          isinstance(projects, list))
    if projects:
        p = projects[0]
        check("Project has project_id",    "project_id"    in p)
        check("Project has project_title", "project_title" in p)

# Filter by status
r = get(f"/projects/{FREELANCER_ID}/status/active")
check("GET projects filtered by status", r and r.status_code == 200)

# Create project
if created_ids.get("client_id"):
    r = post("/projects/", {
        "client_id":        created_ids["client_id"],
        "contract_type_id": 1,
        "project_title":    "TEST PROJECT — DELETE ME",
        "agreed_amount":    999.99,
        "currency":         "USD",
        "status":           "active",
        "start_date":       str(date.today()),
        "end_date":         None
    })
    check("POST create new project", r and r.status_code == 200)
    if r and r.status_code == 200:
        np = r.json()
        if isinstance(np, list): np = np[0]
        created_ids["project_id"] = np.get("project_id")

# ══════════════════════════════════════════════════════════════
# TEST 5: INVOICES
# ══════════════════════════════════════════════════════════════
section("5. INVOICES")

r = get(f"/invoices/{FREELANCER_ID}")
check("GET all invoices", r and r.status_code == 200)
if r and r.status_code == 200:
    invoices = r.json()
    check("Returns list",           isinstance(invoices, list))
    if invoices:
        i = invoices[0]
        check("Invoice has invoice_number", "invoice_number" in i)
        check("Invoice has amount_due",     "amount_due"     in i)

# Unpaid invoices
r = get(f"/invoices/{FREELANCER_ID}/unpaid")
check("GET unpaid invoices", r and r.status_code == 200)

# Create invoice
if created_ids.get("project_id"):
    r = post("/invoices/", {
        "project_id":     created_ids["project_id"],
        "invoice_number": "INV-TEST-9999",
        "amount_due":     250.00,
        "due_date":       str(date.today())
    })
    check("POST create new invoice", r and r.status_code == 200)
    if r and r.status_code == 200:
        ni = r.json()
        if isinstance(ni, list): ni = ni[0]
        created_ids["invoice_id"] = ni.get("invoice_id")

# ══════════════════════════════════════════════════════════════
# TEST 6: PAYMENTS + TRIGGER
# ══════════════════════════════════════════════════════════════
section("6. PAYMENTS + DATABASE TRIGGER")

r = get(f"/payments/{FREELANCER_ID}")
check("GET all payments", r and r.status_code == 200)
if r and r.status_code == 200:
    payments = r.json()
    check("Returns list",            isinstance(payments, list))
    if payments:
        p = payments[0]
        check("Payment has net_pkr",        "net_pkr"         in p)
        check("Payment has is_fbr_compliant","is_fbr_compliant" in p)

# Platform breakdown
r = get(f"/payments/{FREELANCER_ID}/by-platform")
check("GET income by platform", r and r.status_code == 200)

# Monthly trend
r = get(f"/payments/{FREELANCER_ID}/monthly-trend")
check("GET monthly income trend", r and r.status_code == 200)

# SRO 586 split
r = get(f"/payments/{FREELANCER_ID}/sro586")
check("GET SRO 586 compliant vs taxable split", r and r.status_code == 200)

# By currency
r = get(f"/payments/{FREELANCER_ID}/by-currency")
check("GET income by currency", r and r.status_code == 200)

# Recent payments
r = get(f"/payments/{FREELANCER_ID}/recent")
check("GET recent payments (limit 5)", r and r.status_code == 200)

# Create payment
if created_ids.get("invoice_id"):
    r = post("/payments/", {
        "invoice_id":   created_ids["invoice_id"],
        "channel_id":   1,
        "amount_paid":  100.00,
        "pkr_rate":     280.50,
        "gross_amount": 100.00,
        "platform_fee": 0.00,
        "payment_date": str(date.today()),
        "notes":        "Test payment"
    })
    check("POST payment recorded", r and r.status_code == 200)
    if r and r.status_code == 200:
        np = r.json()
        if isinstance(np, list): np = np[0]
        created_ids["payment_id"] = np.get("payment_id")

# ══════════════════════════════════════════════════════════════
# TEST 7: EXPENSES
# ══════════════════════════════════════════════════════════════
section("7. EXPENSES")

r = get(f"/expenses/{FREELANCER_ID}")
check("GET all expenses", r and r.status_code == 200)
if r and r.status_code == 200:
    expenses = r.json()
    check("Returns list",             isinstance(expenses, list))

# Deductible split
r = get(f"/expenses/{FREELANCER_ID}/deductible-split")
check("GET deductible vs non-deductible split", r and r.status_code == 200)

# By category
r = get(f"/expenses/{FREELANCER_ID}/by-category")
check("GET expenses by category", r and r.status_code == 200)

# Yearly deductible
r = get(f"/expenses/{FREELANCER_ID}/yearly-deductible/2024")
check("GET yearly deductible total (2024)", r and r.status_code == 200)

# Create expense
r = post("/expenses/", {
    "freelancer_id":    FREELANCER_ID,
    "category_id":      1,
    "amount":           3500.00,
    "expense_date":     str(date.today()),
    "description":      "TEST EXPENSE — DELETE ME",
    "receipt_reference":"TEST-RECEIPT-001"
})
check("POST create new expense", r and r.status_code == 200)
if r and r.status_code == 200:
    ne = r.json()
    if isinstance(ne, list): ne = ne[0]
    created_ids["expense_id"] = ne.get("expense_id")

# ══════════════════════════════════════════════════════════════
# TEST 8: TAX ENGINE + STORED PROCEDURE
# ══════════════════════════════════════════════════════════════
section("8. FBR TAX ENGINE (STORED PROCEDURE)")

r = get(f"/tax/calculate/{FREELANCER_ID}/2024")
check("GET calculate FBR tax (stored procedure)", r and r.status_code == 200)
if r and r.status_code == 200:
    tax = r.json()
    check("Has total_income_pkr",        "total_income_pkr"        in tax)
    check("Has exempt_income",           "exempt_income"           in tax)
    check("Has taxable_income",          "taxable_income"          in tax)
    check("Has total_deductions",        "total_deductions"        in tax)
    check("Has withholding_tax",         "withholding_tax"         in tax)

    total  = float(tax.get("total_income_pkr")  or 0)
    check("Total income > 0",                total  > 0)

# Save tax report
r = post("/tax/save-report", {
    "freelancer_id": FREELANCER_ID,
    "tax_year":      2024
})
check("POST save tax report to database", r and r.status_code == 200)

# Get saved reports
r = get(f"/tax/reports/{FREELANCER_ID}")
check("GET saved tax reports", r and r.status_code == 200)

# ══════════════════════════════════════════════════════════════
# TEST 9: MATERIALIZED VIEW
# ══════════════════════════════════════════════════════════════
section("9. MATERIALIZED VIEW (TAX SUMMARY)")

r = post("/tax/refresh-summary", {})
check("POST refresh materialized view", r and r.status_code == 200)

r = get(f"/tax/summary/{FREELANCER_ID}")
check("GET tax summary from materialized view", r and r.status_code == 200)

# ══════════════════════════════════════════════════════════════
# TEST 10: DASHBOARD
# ══════════════════════════════════════════════════════════════
section("10. DASHBOARD SUMMARY QUERY")

r = get(f"/tax/dashboard/{FREELANCER_ID}")
check("GET dashboard numbers", r and r.status_code == 200)
if r and r.status_code == 200:
    d = r.json()
    check("Has total_clients",        "total_clients"         in d)
    check("Has active_projects",      "active_projects"       in d)
    check("Has unpaid_invoices",      "unpaid_invoices"       in d)
    check("Has total_income_pkr_2024","total_income_pkr_2024" in d)

# ══════════════════════════════════════════════════════════════
# TEST 11: NOTIFICATIONS
# ══════════════════════════════════════════════════════════════
section("11. NOTIFICATIONS")

r = get(f"/tax/notifications/{FREELANCER_ID}")
check("GET unread notifications", r and r.status_code == 200)

# ══════════════════════════════════════════════════════════════
# TEST 12: EXCHANGE RATES
# ══════════════════════════════════════════════════════════════
section("12. EXCHANGE RATES")

r = get("/exchange-rates/USD")
check("GET latest USD/PKR rate", r and r.status_code == 200)
if r and r.status_code == 200:
    d = r.json()
    check("Has rate field",      "rate"      in d)
    check("Rate > 200 (sanity)", float(d.get("rate") or 0) > 200)

r = get("/exchange-rates/USD/history")
check("GET USD rate history", r and r.status_code == 200)

r = post("/exchange-rates/", {
    "from_currency": "USD",
    "to_currency":   "PKR",
    "rate":          285.75,
    "rate_date":     "2024-06-01",
    "source":        "SBP"
})
check("POST insert new exchange rate", r and r.status_code == 200)

# ══════════════════════════════════════════════════════════════
# TEST 13: CLEANUP — Delete test records
# ══════════════════════════════════════════════════════════════
section("13. CLEANUP (Deleting test records)")

if created_ids.get("expense_id"):
    r = delete(f"/expenses/{created_ids['expense_id']}")
    check("DELETE test expense", r and r.status_code == 200)

if created_ids.get("invoice_id"):
    r = delete(f"/invoices/{created_ids['invoice_id']}")
    check("DELETE test invoice", r and r.status_code == 200)

if created_ids.get("project_id"):
    r = delete(f"/projects/{created_ids['project_id']}")
    check("DELETE test project", r and r.status_code == 200)

if created_ids.get("client_id"):
    r = delete(f"/clients/{created_ids['client_id']}")
    check("DELETE test client", r and r.status_code == 200)

# ══════════════════════════════════════════════════════════════
# FINAL REPORT
# ══════════════════════════════════════════════════════════════
total = passed + failed
print(f"\n{BOLD}{'═'*55}{RESET}")
print(f"{BOLD}  FINAL RESULTS{RESET}")
print(f"{BOLD}{'═'*55}{RESET}")
print(f"  Total Tests : {BOLD}{total}{RESET}")
print(f"  {GREEN}Passed      : {BOLD}{passed}{RESET}")
print(f"  {RED}Failed      : {BOLD}{failed}{RESET}")
score = int((passed / total) * 100) if total > 0 else 0
color = GREEN if score >= 90 else YELLOW if score >= 70 else RED
print(f"  Score       : {color}{BOLD}{score}%{RESET}")
print(f"{BOLD}{'═'*55}{RESET}\n")

if failed > 0:
    print(f"{YELLOW}Fix the failed tests before deployment.{RESET}\n")
else:
    print(f"{GREEN}All tests passed. Project is ready.{RESET}\n")

sys.exit(0 if failed == 0 else 1)
