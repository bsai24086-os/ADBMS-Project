from fastapi import APIRouter, HTTPException
from database import execute_query
from pydantic import BaseModel
from typing import Optional

router = APIRouter()

class ClientCreate(BaseModel):
    freelancer_id: int
    platform_id: int
    client_name: str
    country: Optional[str] = None
    currency: str = "USD"
    platform_metadata: Optional[dict] = None

class ClientUpdate(BaseModel):
    client_name: Optional[str] = None
    country: Optional[str] = None
    currency: Optional[str] = None

# Get all clients for a freelancer
@router.get("/{freelancer_id}")
def get_clients(freelancer_id: int):
    query = """
        SELECT c.client_id, c.client_name, c.country, c.currency,
               p.platform_name, p.fee_percentage, c.platform_metadata
        FROM clients c
        JOIN platforms p ON p.platform_id = c.platform_id
        WHERE c.freelancer_id = %s
        ORDER BY c.created_at DESC
    """
    return execute_query(query, (freelancer_id,))

# Get single client with contacts
@router.get("/detail/{client_id}")
def get_client(client_id: int):
    query = """
        SELECT c.*, cc.name AS contact_name, cc.email,
               cc.phone, cc.is_primary, p.platform_name
        FROM clients c
        LEFT JOIN client_contacts cc ON cc.client_id = c.client_id
        LEFT JOIN platforms p ON p.platform_id = c.platform_id
        WHERE c.client_id = %s
    """
    result = execute_query(query, (client_id,))
    if not result:
        raise HTTPException(status_code=404, detail="Client not found")
    return result

# Search clients by name
@router.get("/search/{freelancer_id}/{name}")
def search_clients(freelancer_id: int, name: str):
    query = """
        SELECT c.*, p.platform_name
        FROM clients c
        JOIN platforms p ON p.platform_id = c.platform_id
        WHERE c.freelancer_id = %s
          AND c.client_name ILIKE %s
    """
    return execute_query(query, (freelancer_id, f"%{name}%"))

# Add new client
@router.post("/")
def create_client(client: ClientCreate):
    import json
    query = """
        INSERT INTO clients
        (freelancer_id, platform_id, client_name, country, currency, platform_metadata)
        VALUES (%s, %s, %s, %s, %s, %s)
        RETURNING *
    """
    metadata = json.dumps(client.platform_metadata) if client.platform_metadata else None
    return execute_query(query, (
        client.freelancer_id, client.platform_id,
        client.client_name, client.country,
        client.currency, metadata
    ))

# Update client
@router.put("/{client_id}")
def update_client(client_id: int, client: ClientUpdate):
    fields = []
    values = []
    if client.client_name:
        fields.append("client_name = %s")
        values.append(client.client_name)
    if client.country:
        fields.append("country = %s")
        values.append(client.country)
    if client.currency:
        fields.append("currency = %s")
        values.append(client.currency)
    if not fields:
        raise HTTPException(status_code=400, detail="No fields to update")
    values.append(client_id)
    query = f"UPDATE clients SET {', '.join(fields)} WHERE client_id = %s"
    return execute_query(query, tuple(values), fetch=False)


# Search clients by platform metadata (uses GIN index)
@router.get("/{freelancer_id}/search-metadata")
def search_by_metadata(freelancer_id: int, key: str, value: str):
    import json
    query = """
        SELECT c.*, p.platform_name
        FROM clients c
        JOIN platforms p ON p.platform_id = c.platform_id
        WHERE c.platform_metadata @> %s::jsonb
          AND c.freelancer_id = %s
    """
    filter_json = json.dumps({key: value})
    return execute_query(query, (filter_json, freelancer_id))

# Extract specific JSONB field from all clients
@router.get("/{freelancer_id}/metadata-field/{field_name}")
def extract_metadata_field(freelancer_id: int, field_name: str):
    query = """
        SELECT c.client_name,
               c.platform_metadata->>%s AS field_value
        FROM clients c
        WHERE c.freelancer_id = %s
          AND c.platform_metadata ? %s
    """
    return execute_query(query, (field_name, freelancer_id, field_name))


# Delete client
@router.delete("/{client_id}")
def delete_client(client_id: int):
    query = "DELETE FROM clients WHERE client_id = %s"
    return execute_query(query, (client_id,), fetch=False)