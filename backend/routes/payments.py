from fastapi import APIRouter, HTTPException
from database import execute_query
from pydantic import BaseModel
from typing import Optional
from datetime import date

router = APIRouter()

class PaymentCreate(BaseModel):
    invoice_id: int
    channel_id: int
    amount_paid: float
    pkr_rate: float
    gross_amount: float
    platform_fee: float = 0.00
    payment_date: date
    notes: Optional[str] = None

# Get all payments for a freelancer
@router.get("/{freelancer_id}")
def get_payments(freelancer_id: int):
    query = """
        SELECT pay.payment_id, pay.amount_paid, pay.pkr_rate,
               pay.gross_amount, pay.platform_fee,
               (pay.gross_amount - pay.platform_fee) AS net_amount,
               (pay.gross_amount - pay.platform_fee) * pay.pkr_rate AS net_pkr,
               pay.payment_date, pay.notes,
               pc.channel_name, pc.is_fbr_compliant,
               i.invoice_number, c.client_name
        FROM payments pay
        JOIN payment_channels pc ON pc.channel_id = pay.channel_id
        JOIN invoices i          ON i.invoice_id = pay.invoice_id
        JOIN projects pr         ON pr.project_id = i.project_id
        JOIN clients c           ON c.client_id = pr.client_id
        WHERE c.freelancer_id = %s
        ORDER BY pay.payment_date DESC
    """
    return execute_query(query, (freelancer_id,))

# Get income by platform
@router.get("/{freelancer_id}/by-platform")
def get_income_by_platform(freelancer_id: int):
    query = """
        SELECT p.platform_name,
               COUNT(pay.payment_id)                              AS total_payments,
               SUM(pay.gross_amount)                              AS total_gross,
               SUM(pay.platform_fee)                              AS total_fees,
               SUM(pay.gross_amount - pay.platform_fee)           AS total_net,
               SUM((pay.gross_amount - pay.platform_fee) * pay.pkr_rate) AS total_net_pkr
        FROM payments pay
        JOIN invoices i    ON i.invoice_id = pay.invoice_id
        JOIN projects pr   ON pr.project_id = i.project_id
        JOIN clients c     ON c.client_id = pr.client_id
        JOIN platforms p   ON p.platform_id = c.platform_id
        WHERE c.freelancer_id = %s
        GROUP BY p.platform_name
    """
    return execute_query(query, (freelancer_id,))

# Get monthly income trend
@router.get("/{freelancer_id}/monthly-trend")
def get_monthly_trend(freelancer_id: int):
    query = """
        SELECT DATE_TRUNC('month', pay.payment_date)              AS month,
               SUM(pay.gross_amount - pay.platform_fee)           AS net_income,
               SUM((pay.gross_amount - pay.platform_fee) * pay.pkr_rate) AS net_income_pkr
        FROM payments pay
        JOIN invoices i  ON i.invoice_id = pay.invoice_id
        JOIN projects pr ON pr.project_id = i.project_id
        JOIN clients c   ON c.client_id = pr.client_id
        WHERE c.freelancer_id = %s
        GROUP BY DATE_TRUNC('month', pay.payment_date)
        ORDER BY month
    """
    return execute_query(query, (freelancer_id,))

# Get SRO 586 compliant vs non compliant split
@router.get("/{freelancer_id}/sro586")
def get_sro586_split(freelancer_id: int):
    query = """
        SELECT pc.is_fbr_compliant,
               SUM((pay.gross_amount - pay.platform_fee) * pay.pkr_rate) AS total_pkr,
               COUNT(*) AS payment_count
        FROM payments pay
        JOIN payment_channels pc ON pc.channel_id = pay.channel_id
        JOIN invoices i          ON i.invoice_id = pay.invoice_id
        JOIN projects pr         ON pr.project_id = i.project_id
        JOIN clients c           ON c.client_id = pr.client_id
        WHERE c.freelancer_id = %s
        GROUP BY pc.is_fbr_compliant
    """
    return execute_query(query, (freelancer_id,))

# Get top earning clients
@router.get("/{freelancer_id}/top-clients")
def get_top_clients(freelancer_id: int):
    query = """
        SELECT c.client_name, p.platform_name,
               SUM((pay.gross_amount - pay.platform_fee) * pay.pkr_rate) AS total_earned_pkr
        FROM payments pay
        JOIN invoices i  ON i.invoice_id = pay.invoice_id
        JOIN projects pr ON pr.project_id = i.project_id
        JOIN clients c   ON c.client_id = pr.client_id
        JOIN platforms p ON p.platform_id = c.platform_id
        WHERE c.freelancer_id = %s
        GROUP BY c.client_name, p.platform_name
        ORDER BY total_earned_pkr DESC
    """
    return execute_query(query, (freelancer_id,))

# Get recent payments for activity feed
@router.get("/{freelancer_id}/recent")
def get_recent_payments(freelancer_id: int):
    query = """
        SELECT pay.payment_date, pay.amount_paid,
               (pay.gross_amount - pay.platform_fee) * pay.pkr_rate AS net_pkr,
               c.client_name, i.invoice_number, pc.channel_name
        FROM payments pay
        JOIN invoices i          ON i.invoice_id = pay.invoice_id
        JOIN projects pr         ON pr.project_id = i.project_id
        JOIN clients c           ON c.client_id = pr.client_id
        JOIN payment_channels pc ON pc.channel_id = pay.channel_id
        WHERE c.freelancer_id = %s
        ORDER BY pay.payment_date DESC
        LIMIT 5
    """
    return execute_query(query, (freelancer_id,))

# Record new payment (trigger fires automatically after this)
@router.post("/")
def create_payment(payment: PaymentCreate):
    query = """
        INSERT INTO payments
        (invoice_id, channel_id, amount_paid, pkr_rate,
         gross_amount, platform_fee, payment_date, notes)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        RETURNING *
    """
    return execute_query(query, (
        payment.invoice_id, payment.channel_id,
        payment.amount_paid, payment.pkr_rate,
        payment.gross_amount, payment.platform_fee,
        payment.payment_date, payment.notes
    ))

# Get income by currency
@router.get("/{freelancer_id}/by-currency")
def get_income_by_currency(freelancer_id: int):
    query = """
        SELECT
            pr.currency,
            SUM(pay.gross_amount - pay.platform_fee)           AS total_net_foreign,
            SUM((pay.gross_amount - pay.platform_fee) * pay.pkr_rate) AS total_net_pkr
        FROM payments pay
        JOIN invoices i  ON i.invoice_id = pay.invoice_id
        JOIN projects pr ON pr.project_id = i.project_id
        JOIN clients c   ON c.client_id = pr.client_id
        WHERE c.freelancer_id = %s
        GROUP BY pr.currency
        ORDER BY total_net_pkr DESC
    """
    return execute_query(query, (freelancer_id,))



# Delete payment
@router.delete("/{payment_id}")
def delete_payment(payment_id: int):
    query = "DELETE FROM payments WHERE payment_id = %s"
    return execute_query(query, (payment_id,), fetch=False)