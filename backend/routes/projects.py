from fastapi import APIRouter, HTTPException
from database import execute_query
from pydantic import BaseModel
from typing import Optional
from datetime import date

router = APIRouter()

class ProjectCreate(BaseModel):
    client_id: int
    contract_type_id: int
    project_title: str
    agreed_amount: float
    currency: str = "USD"
    status: str = "active"
    start_date: date
    end_date: Optional[date] = None

class ProjectUpdate(BaseModel):
    project_title: Optional[str] = None
    agreed_amount: Optional[float] = None
    status: Optional[str] = None
    end_date: Optional[date] = None

# Get all projects for a freelancer
@router.get("/{freelancer_id}")
def get_projects(freelancer_id: int):
    query = """
        SELECT pr.project_id, pr.project_title, pr.agreed_amount,
               pr.currency, pr.status, pr.start_date, pr.end_date,
               c.client_name, ct.type_name AS contract_type,
               p.platform_name
        FROM projects pr
        JOIN clients c         ON c.client_id = pr.client_id
        JOIN contract_types ct ON ct.contract_type_id = pr.contract_type_id
        JOIN platforms p       ON p.platform_id = c.platform_id
        WHERE c.freelancer_id = %s
        ORDER BY pr.start_date DESC
    """
    return execute_query(query, (freelancer_id,))

# Get projects by status
@router.get("/{freelancer_id}/status/{status}")
def get_projects_by_status(freelancer_id: int, status: str):
    query = """
        SELECT pr.*, c.client_name, ct.type_name AS contract_type
        FROM projects pr
        JOIN clients c         ON c.client_id = pr.client_id
        JOIN contract_types ct ON ct.contract_type_id = pr.contract_type_id
        WHERE c.freelancer_id = %s AND pr.status = %s
    """
    return execute_query(query, (freelancer_id, status))

# Get single project with full details
@router.get("/detail/{project_id}")
def get_project(project_id: int):
    query = """
        SELECT pr.*, c.client_name, ct.type_name,
               p.platform_name,
               pr.agreed_amount - COALESCE(SUM(pay.amount_paid), 0) AS remaining
        FROM projects pr
        JOIN clients c         ON c.client_id = pr.client_id
        JOIN contract_types ct ON ct.contract_type_id = pr.contract_type_id
        JOIN platforms p       ON p.platform_id = c.platform_id
        LEFT JOIN invoices i   ON i.project_id = pr.project_id
        LEFT JOIN payments pay ON pay.invoice_id = i.invoice_id
        WHERE pr.project_id = %s
        GROUP BY pr.project_id, c.client_name,
                 ct.type_name, p.platform_name
    """
    result = execute_query(query, (project_id,))
    if not result:
        raise HTTPException(status_code=404, detail="Project not found")
    return result[0]

# Get project milestones
@router.get("/milestones/{project_id}")
def get_milestones(project_id: int):
    query = """
        SELECT * FROM milestones
        WHERE project_id = %s
        ORDER BY due_date
    """
    return execute_query(query, (project_id,))

# Create new project
@router.post("/")
def create_project(project: ProjectCreate):
    query = """
        INSERT INTO projects
        (client_id, contract_type_id, project_title,
         agreed_amount, currency, status, start_date, end_date)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        RETURNING *
    """
    return execute_query(query, (
        project.client_id, project.contract_type_id,
        project.project_title, project.agreed_amount,
        project.currency, project.status,
        project.start_date, project.end_date
    ))

# Update project
@router.put("/{project_id}")
def update_project(project_id: int, project: ProjectUpdate):
    fields = []
    values = []
    if project.project_title:
        fields.append("project_title = %s")
        values.append(project.project_title)
    if project.agreed_amount:
        fields.append("agreed_amount = %s")
        values.append(project.agreed_amount)
    if project.status:
        fields.append("status = %s")
        values.append(project.status)
    if project.end_date:
        fields.append("end_date = %s")
        values.append(project.end_date)
    if not fields:
        raise HTTPException(status_code=400, detail="No fields to update")
    values.append(project_id)
    query = f"UPDATE projects SET {', '.join(fields)} WHERE project_id = %s"
    return execute_query(query, tuple(values), fetch=False)

# Delete project
@router.delete("/{project_id}")
def delete_project(project_id: int):
    query = "DELETE FROM projects WHERE project_id = %s"
    return execute_query(query, (project_id,), fetch=False)