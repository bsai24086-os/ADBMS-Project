from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes import clients, projects, invoices, payments, expenses, tax, freelancer, exchange_rates

app = FastAPI(title="HisaabPro API", version="1.0.0")

# Allow React frontend to talk to this backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register all routes
app.include_router(clients.router,   prefix="/clients",   tags=["Clients"])
app.include_router(projects.router,  prefix="/projects",  tags=["Projects"])
app.include_router(invoices.router,  prefix="/invoices",  tags=["Invoices"])
app.include_router(payments.router,  prefix="/payments",  tags=["Payments"])
app.include_router(expenses.router,  prefix="/expenses",  tags=["Expenses"])
app.include_router(tax.router,       prefix="/tax",       tags=["Tax"])
app.include_router(freelancer.router,      prefix="/freelancer",      tags=["Freelancer"])
app.include_router(exchange_rates.router,  prefix="/exchange-rates",  tags=["Exchange Rates"])
@app.get("/")
def root():
    return {"message": "HisaabPro API is running"}