from fastapi import APIRouter, HTTPException
from database import execute_query
from pydantic import BaseModel
from datetime import date

router = APIRouter()

class ExchangeRateCreate(BaseModel):
    from_currency: str
    to_currency: str = "PKR"
    rate: float
    rate_date: date
    source: str = "SBP"

# Get latest rate for a currency
@router.get("/{from_currency}")
def get_latest_rate(from_currency: str):
    query = """
        SELECT rate, rate_date, source
        FROM exchange_rates
        WHERE from_currency = %s
          AND to_currency = 'PKR'
        ORDER BY rate_date DESC
        LIMIT 1
    """
    result = execute_query(query, (from_currency.upper(),))
    if not result:
        raise HTTPException(status_code=404, detail="No rate found for this currency")
    return result[0]

# Get rate history for a currency
@router.get("/{from_currency}/history")
def get_rate_history(from_currency: str):
    query = """
        SELECT rate, rate_date, source
        FROM exchange_rates
        WHERE from_currency = %s
          AND to_currency = 'PKR'
        ORDER BY rate_date DESC
    """
    return execute_query(query, (from_currency.upper(),))

# Insert new exchange rate
@router.post("/")
def create_exchange_rate(rate: ExchangeRateCreate):
    query = """
        INSERT INTO exchange_rates
        (from_currency, to_currency, rate, rate_date, source)
        VALUES (%s, %s, %s, %s, %s)
        RETURNING *
    """
    return execute_query(query, (
        rate.from_currency.upper(),
        rate.to_currency.upper(),
        rate.rate,
        rate.rate_date,
        rate.source
    ))


    