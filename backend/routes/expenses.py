from fastapi import APIRouter, HTTPException
from database import execute_query
from pydantic import BaseModel
from typing import Optional
from datetime import date

router = APIRouter()

class ExpenseCreate(BaseModel):
    freelancer_id: int
    category_id: int
    amount: float
    expense_date: date
    description: Optional[str] = None
    receipt_reference: Optional[str] = None
    notes: Optional[str] = None

# Get all expenses for a freelancer
@router.get("/{freelancer_id}")
def get_expenses(freelancer_id: int):
    query = """
        SELECT e.expense_id, e.amount, e.expense_date,
               e.description, e.receipt_reference, e.notes,
               ec.category_name, ec.is_fbr_deductible
        FROM expenses e
        JOIN expense_categories ec ON ec.category_id = e.category_id
        WHERE e.freelancer_id = %s
        ORDER BY e.expense_date DESC
    """
    return execute_query(query, (freelancer_id,))

# Get deductible vs non deductible split
@router.get("/{freelancer_id}/deductible-split")
def get_deductible_split(freelancer_id: int):
    query = """
        SELECT ec.is_fbr_deductible,
               SUM(e.amount)  AS total_amount,
               COUNT(*)       AS expense_count
        FROM expenses e
        JOIN expense_categories ec ON ec.category_id = e.category_id
        WHERE e.freelancer_id = %s
        GROUP BY ec.is_fbr_deductible
    """
    return execute_query(query, (freelancer_id,))

# Get expenses grouped by category
@router.get("/{freelancer_id}/by-category")
def get_expenses_by_category(freelancer_id: int):
    query = """
        SELECT ec.category_name,
               SUM(e.amount) AS total,
               COUNT(*)      AS count,
               ec.is_fbr_deductible
        FROM expenses e
        JOIN expense_categories ec ON ec.category_id = e.category_id
        WHERE e.freelancer_id = %s
        GROUP BY ec.category_name, ec.is_fbr_deductible
        ORDER BY total DESC
    """
    return execute_query(query, (freelancer_id,))

# Get yearly deductible total
@router.get("/{freelancer_id}/yearly-deductible/{year}")
def get_yearly_deductible(freelancer_id: int, year: int):
    query = """
        SELECT SUM(e.amount) AS total_deductible
        FROM expenses e
        JOIN expense_categories ec ON ec.category_id = e.category_id
        WHERE e.freelancer_id = %s
          AND ec.is_fbr_deductible = TRUE
          AND EXTRACT(YEAR FROM e.expense_date) = %s
    """
    return execute_query(query, (freelancer_id, year))

# Add new expense
@router.post("/")
def create_expense(expense: ExpenseCreate):
    query = """
        INSERT INTO expenses
        (freelancer_id, category_id, amount, expense_date,
         description, receipt_reference, notes)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        RETURNING *
    """
    return execute_query(query, (
        expense.freelancer_id, expense.category_id,
        expense.amount, expense.expense_date,
        expense.description, expense.receipt_reference,
        expense.notes
    ))

# Delete expense
@router.delete("/{expense_id}")
def delete_expense(expense_id: int):
    query = "DELETE FROM expenses WHERE expense_id = %s"
    return execute_query(query, (expense_id,), fetch=False)