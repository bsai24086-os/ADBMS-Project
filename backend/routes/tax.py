from fastapi import APIRouter, HTTPException
from database import execute_query
from pydantic import BaseModel
from typing import Optional

router = APIRouter()

class TaxReportSave(BaseModel):
    freelancer_id: int
    tax_year: int
    iris_export_data: Optional[dict] = None

# Run FBR Tax Engine stored procedure
@router.get("/calculate/{freelancer_id}/{tax_year}")
def calculate_tax(freelancer_id: int, tax_year: int):
    query = """
        SELECT * FROM calculate_fbr_tax(%s, %s)
    """
    result = execute_query(query, (freelancer_id, tax_year))
    if not result:
        raise HTTPException(status_code=404, detail="No data found for this freelancer and year")
    return result[0]

# Save tax report to database
@router.post("/save-report")
def save_tax_report(report: TaxReportSave):
    import json

    # First calculate the tax
    calc_query = """
        SELECT * FROM calculate_fbr_tax(%s, %s)
    """
    result = execute_query(calc_query, (report.freelancer_id, report.tax_year))
    if not result:
        raise HTTPException(status_code=404, detail="No tax data found")

    tax = result[0]

    # Save it as archival snapshot
    save_query = """
        INSERT INTO tax_reports (
            freelancer_id, tax_year, total_income_pkr,
            exempt_income, taxable_income, total_deductions,
            withholding_tax, net_tax_liability, iris_export_data
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        RETURNING *
    """
    iris_data = json.dumps(report.iris_export_data) if report.iris_export_data else json.dumps({
        "total_income":      str(tax["total_income_pkr"]),
        "exempt_income":     str(tax["exempt_income"]),
        "taxable_income":    str(tax["taxable_income"]),
        "deductions":        str(tax["total_deductions"]),
        "withholding_tax":   str(tax["withholding_tax"]),
        "bracket_tax":       str(tax["bracket_tax"]),
        "net_tax_liability": str(tax["net_tax_liability"])
    })

    return execute_query(save_query, (
        report.freelancer_id,
        report.tax_year,
        tax["total_income_pkr"],
        tax["exempt_income"],
        tax["taxable_income"],
        tax["total_deductions"],
        tax["withholding_tax"],
        tax["net_tax_liability"],
        iris_data
    ))

# Get all saved tax reports for a freelancer
@router.get("/reports/{freelancer_id}")
def get_tax_reports(freelancer_id: int):
    query = """
        SELECT * FROM tax_reports
        WHERE freelancer_id = %s
        ORDER BY generated_at DESC
    """
    return execute_query(query, (freelancer_id,))

# Get tax summary from materialized view
@router.get("/summary/{freelancer_id}")
def get_tax_summary(freelancer_id: int):
    query = """
        SELECT * FROM tax_summary
        WHERE freelancer_id = %s
    """
    return execute_query(query, (freelancer_id,))

# Refresh materialized view
@router.post("/refresh-summary")
def refresh_summary():
    query = "REFRESH MATERIALIZED VIEW tax_summary"
    execute_query(query, fetch=False)
    return {"message": "Tax summary refreshed successfully"}

# Get dashboard numbers
@router.get("/dashboard/{freelancer_id}")
def get_dashboard(freelancer_id: int):
    query = """
        SELECT
            (SELECT COUNT(*)
             FROM clients
             WHERE freelancer_id = %s)                                AS total_clients,

            (SELECT COUNT(*)
             FROM projects pr
             JOIN clients c ON c.client_id = pr.client_id
             WHERE c.freelancer_id = %s
               AND pr.status = 'active')                             AS active_projects,

            (SELECT COUNT(*)
             FROM invoices i
             JOIN projects pr ON pr.project_id = i.project_id
             JOIN clients c   ON c.client_id = pr.client_id
             WHERE c.freelancer_id = %s
               AND i.status = 'unpaid')                              AS unpaid_invoices,

            (SELECT COALESCE(SUM(
                (pay.gross_amount - pay.platform_fee) * pay.pkr_rate), 0)
             FROM payments pay
             JOIN invoices i  ON i.invoice_id = pay.invoice_id
             JOIN projects pr ON pr.project_id = i.project_id
             JOIN clients c   ON c.client_id = pr.client_id
             WHERE c.freelancer_id = %s
               AND EXTRACT(YEAR FROM pay.payment_date) = 2024)       AS total_income_pkr_2024
    """
    result = execute_query(query, (
        freelancer_id, freelancer_id,
        freelancer_id, freelancer_id
    ))
    return result[0]

# Get unread notifications
@router.get("/notifications/{freelancer_id}")
def get_notifications(freelancer_id: int):
    query = """
        SELECT * FROM notifications
        WHERE freelancer_id = %s
          AND is_read = FALSE
        ORDER BY created_at DESC
    """
    return execute_query(query, (freelancer_id,))

# Mark notification as read
@router.put("/notifications/{notification_id}/read")
def mark_notification_read(notification_id: int):
    query = """
        UPDATE notifications
        SET is_read = TRUE
        WHERE notification_id = %s
    """
    return execute_query(query, (notification_id,), fetch=False)