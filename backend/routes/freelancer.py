from fastapi import APIRouter, HTTPException
from database import execute_query
from pydantic import BaseModel
from typing import Optional

router = APIRouter()

class FreelancerUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    filer_status: Optional[bool] = None
    tax_year: Optional[int] = None
    currency_preference: Optional[str] = None

# Get freelancer profile
@router.get("/{freelancer_id}")
def get_freelancer(freelancer_id: int):
    query = """
        SELECT * FROM freelancer
        WHERE freelancer_id = %s
    """
    result = execute_query(query, (freelancer_id,))
    if not result:
        raise HTTPException(status_code=404, detail="Freelancer not found")
    return result[0]

# Update freelancer profile / filer status
@router.put("/{freelancer_id}")
def update_freelancer(freelancer_id: int, data: FreelancerUpdate):
    fields = []
    values = []
    if data.full_name is not None:
        fields.append("full_name = %s")
        values.append(data.full_name)
    if data.phone is not None:
        fields.append("phone = %s")
        values.append(data.phone)
    if data.filer_status is not None:
        fields.append("filer_status = %s")
        values.append(data.filer_status)
    if data.tax_year is not None:
        fields.append("tax_year = %s")
        values.append(data.tax_year)
    if data.currency_preference is not None:
        fields.append("currency_preference = %s")
        values.append(data.currency_preference)
    if not fields:
        raise HTTPException(status_code=400, detail="No fields to update")
    values.append(freelancer_id)
    query = f"UPDATE freelancer SET {', '.join(fields)} WHERE freelancer_id = %s"
    return execute_query(query, tuple(values), fetch=False)