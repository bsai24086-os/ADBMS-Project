from fastapi import APIRouter, HTTPException
from database import execute_query
from pydantic import BaseModel
from typing import Optional
from datetime import date

router = APIRouter()

class InvoiceCreate(BaseModel):
    project_id: int
    invoice_number: str
    amount_due: float
    due_date: Optional[date] = None

class InvoiceItemCreate(BaseModel):
    invoice_id: int
    description: str
    quantity: float = 1
    unit_price: float

# Get all invoices for a freelancer
@router.get("/{freelancer_id}")
def get_invoices(freelancer_id: int):
    query = """
        SELECT i.invoice_id, i.invoice_number, i.amount_due,
               i.due_date, i.status, i.created_at,
               pr.project_title, c.client_name
        FROM invoices i
        JOIN projects pr ON pr.project_id = i.project_id
        JOIN clients c   ON c.client_id = pr.client_id
        WHERE c.freelancer_id = %s
        ORDER BY i.created_at DESC
    """
    return execute_query(query, (freelancer_id,))

# Get all unpaid and overdue invoices
@router.get("/{freelancer_id}/unpaid")
def get_unpaid_invoices(freelancer_id: int):
    query = """
        SELECT i.invoice_number, i.amount_due, i.due_date,
               c.client_name, pr.project_title,
               CURRENT_DATE - i.due_date AS days_overdue
        FROM invoices i
        JOIN projects pr ON pr.project_id = i.project_id
        JOIN clients c   ON c.client_id = pr.client_id
        WHERE i.status IN ('unpaid', 'partially_paid')
          AND c.freelancer_id = %s
        ORDER BY i.due_date ASC
    """
    return execute_query(query, (freelancer_id,))

# Get single invoice with line items
@router.get("/detail/{invoice_id}")
def get_invoice(invoice_id: int):
    query = """
        SELECT i.invoice_number, i.amount_due, i.status,
               i.due_date, i.created_at,
               ii.description, ii.quantity, ii.unit_price,
               (ii.quantity * ii.unit_price) AS line_total
        FROM invoices i
        JOIN invoice_items ii ON ii.invoice_id = i.invoice_id
        WHERE i.invoice_id = %s
    """
    result = execute_query(query, (invoice_id,))
    if not result:
        raise HTTPException(status_code=404, detail="Invoice not found")
    return result

# Get invoice payment history
@router.get("/payments/{invoice_id}")
def get_invoice_payments(invoice_id: int):
    query = """
        SELECT i.invoice_number, i.amount_due,
               COALESCE(SUM(p.amount_paid), 0) AS total_paid,
               i.amount_due - COALESCE(SUM(p.amount_paid), 0) AS balance_remaining,
               i.status
        FROM invoices i
        LEFT JOIN payments p ON p.invoice_id = i.invoice_id
        WHERE i.invoice_id = %s
        GROUP BY i.invoice_id, i.invoice_number,
                 i.amount_due, i.status
    """
    result = execute_query(query, (invoice_id,))
    if not result:
        raise HTTPException(status_code=404, detail="Invoice not found")
    return result[0]

# Get monthly invoice summary
@router.get("/{freelancer_id}/summary/monthly")
def get_monthly_summary(freelancer_id: int):
    query = """
        SELECT DATE_TRUNC('month', i.created_at) AS month,
               COUNT(*) AS total_invoices,
               SUM(i.amount_due) AS total_billed,
               COUNT(CASE WHEN i.status = 'paid' THEN 1 END) AS paid_count,
               COUNT(CASE WHEN i.status = 'unpaid' THEN 1 END) AS unpaid_count
        FROM invoices i
        JOIN projects pr ON pr.project_id = i.project_id
        JOIN clients c   ON c.client_id = pr.client_id
        WHERE c.freelancer_id = %s
        GROUP BY DATE_TRUNC('month', i.created_at)
        ORDER BY month DESC
    """
    return execute_query(query, (freelancer_id,))

# Get total outstanding amount
@router.get("/{freelancer_id}/outstanding")
def get_outstanding(freelancer_id: int):
    query = """
        SELECT SUM(i.amount_due - COALESCE(paid.total_paid, 0)) AS total_outstanding
        FROM invoices i
        LEFT JOIN (
            SELECT invoice_id, SUM(amount_paid) AS total_paid
            FROM payments GROUP BY invoice_id
        ) paid ON paid.invoice_id = i.invoice_id
        JOIN projects pr ON pr.project_id = i.project_id
        JOIN clients c   ON c.client_id = pr.client_id
        WHERE i.status IN ('unpaid', 'partially_paid')
          AND c.freelancer_id = %s
    """
    return execute_query(query, (freelancer_id,))

# Create new invoice
@router.post("/")
def create_invoice(invoice: InvoiceCreate):
    query = """
        INSERT INTO invoices (project_id, invoice_number, amount_due, due_date)
        VALUES (%s, %s, %s, %s)
        RETURNING *
    """
    return execute_query(query, (
        invoice.project_id, invoice.invoice_number,
        invoice.amount_due, invoice.due_date
    ))

# Add invoice line item
@router.post("/items")
def create_invoice_item(item: InvoiceItemCreate):
    query = """
        INSERT INTO invoice_items (invoice_id, description, quantity, unit_price)
        VALUES (%s, %s, %s, %s)
        RETURNING *
    """
    return execute_query(query, (
        item.invoice_id, item.description,
        item.quantity, item.unit_price
    ))

# Delete invoice
@router.delete("/{invoice_id}")
def delete_invoice(invoice_id: int):
    query = "DELETE FROM invoices WHERE invoice_id = %s"
    return execute_query(query, (invoice_id,), fetch=False)