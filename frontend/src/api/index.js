import axios from 'axios';

const API = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://127.0.0.1:8000',
  headers: { 'Content-Type': 'application/json' }
});

const FREELANCER_ID = 1;

// ── FREELANCER ──────────────────────────────────────────────
export const getFreelancer    = () =>
  API.get(`/freelancer/${FREELANCER_ID}`);
export const updateFreelancer = (data) =>
  API.put(`/freelancer/${FREELANCER_ID}`, data);

// ── CLIENTS ─────────────────────────────────────────────────
export const getClients       = () =>
  API.get(`/clients/${FREELANCER_ID}`);
export const getClient        = (id) =>
  API.get(`/clients/detail/${id}`);
export const searchClients    = (name) =>
  API.get(`/clients/search/${FREELANCER_ID}/${name}`);
export const createClient     = (data) =>
  API.post('/clients/', data);
export const updateClient     = (id, data) =>
  API.put(`/clients/${id}`, data);
export const deleteClient     = (id) =>
  API.delete(`/clients/${id}`);
export const searchMetadata   = (key, value) =>
  API.get(`/clients/${FREELANCER_ID}/search-metadata?key=${key}&value=${value}`);

// ── PROJECTS ────────────────────────────────────────────────
export const getProjects      = () =>
  API.get(`/projects/${FREELANCER_ID}`);
export const getProjectsByStatus = (status) =>
  API.get(`/projects/${FREELANCER_ID}/status/${status}`);
export const getProject       = (id) =>
  API.get(`/projects/detail/${id}`);
export const getMilestones    = (id) =>
  API.get(`/projects/milestones/${id}`);
export const createProject    = (data) =>
  API.post('/projects/', data);
export const updateProject    = (id, data) =>
  API.put(`/projects/${id}`, data);
export const deleteProject    = (id) =>
  API.delete(`/projects/${id}`);

// ── INVOICES ────────────────────────────────────────────────
export const getInvoices      = () =>
  API.get(`/invoices/${FREELANCER_ID}`);
export const getUnpaidInvoices= () =>
  API.get(`/invoices/${FREELANCER_ID}/unpaid`);
export const getInvoice       = (id) =>
  API.get(`/invoices/detail/${id}`);
export const getInvoicePayments=(id) =>
  API.get(`/invoices/payments/${id}`);
export const getMonthlySummary= () =>
  API.get(`/invoices/${FREELANCER_ID}/summary/monthly`);
export const getOutstanding   = () =>
  API.get(`/invoices/${FREELANCER_ID}/outstanding`);
export const createInvoice    = (data) =>
  API.post('/invoices/', data);
export const createInvoiceItem= (data) =>
  API.post('/invoices/items', data);
export const deleteInvoice    = (id) =>
  API.delete(`/invoices/${id}`);

// ── PAYMENTS ────────────────────────────────────────────────
export const getPayments      = () =>
  API.get(`/payments/${FREELANCER_ID}`);
export const getPaymentsByPlatform = () =>
  API.get(`/payments/${FREELANCER_ID}/by-platform`);
export const getMonthlyTrend  = () =>
  API.get(`/payments/${FREELANCER_ID}/monthly-trend`);
export const getSRO586Split   = () =>
  API.get(`/payments/${FREELANCER_ID}/sro586`);
export const getTopClients    = () =>
  API.get(`/payments/${FREELANCER_ID}/top-clients`);
export const getRecentPayments= () =>
  API.get(`/payments/${FREELANCER_ID}/recent`);
export const getPaymentsByCurrency = () =>
  API.get(`/payments/${FREELANCER_ID}/by-currency`);
export const createPayment    = (data) =>
  API.post('/payments/', data);
export const deletePayment    = (id) =>
  API.delete(`/payments/${id}`);

// ── EXPENSES ────────────────────────────────────────────────
export const getExpenses      = () =>
  API.get(`/expenses/${FREELANCER_ID}`);
export const getDeductibleSplit=() =>
  API.get(`/expenses/${FREELANCER_ID}/deductible-split`);
export const getExpensesByCategory=()=>
  API.get(`/expenses/${FREELANCER_ID}/by-category`);
export const getYearlyDeductible=(year)=>
  API.get(`/expenses/${FREELANCER_ID}/yearly-deductible/${year}`);
export const createExpense    = (data) =>
  API.post('/expenses/', data);
export const deleteExpense    = (id) =>
  API.delete(`/expenses/${id}`);

// ── TAX ─────────────────────────────────────────────────────
export const calculateTax     = (year) =>
  API.get(`/tax/calculate/${FREELANCER_ID}/${year}`);
export const saveTaxReport    = (data) =>
  API.post('/tax/save-report', data);
export const getTaxReports    = () =>
  API.get(`/tax/reports/${FREELANCER_ID}`);
export const getTaxSummary    = () =>
  API.get(`/tax/summary/${FREELANCER_ID}`);
export const refreshSummary   = () =>
  API.post('/tax/refresh-summary');
export const getDashboard     = () =>
  API.get(`/tax/dashboard/${FREELANCER_ID}`);
export const getNotifications = () =>
  API.get(`/tax/notifications/${FREELANCER_ID}`);
export const markNotificationRead=(id)=>
  API.put(`/tax/notifications/${id}/read`);

// ── EXCHANGE RATES ───────────────────────────────────────────
export const getLatestRate    = (currency) =>
  API.get(`/exchange-rates/${currency}`);
export const getRateHistory   = (currency) =>
  API.get(`/exchange-rates/${currency}/history`);
export const createExchangeRate=(data)=>
  API.post('/exchange-rates/', data);