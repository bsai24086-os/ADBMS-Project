import { useState, useEffect } from 'react';
import { Plus, Trash2, AlertCircle } from 'lucide-react';
import {
  getInvoices, getOutstanding, createInvoice,
  createInvoiceItem, deleteInvoice
} from '../api';
import './Invoices.css';

const fmt = n => new Intl.NumberFormat('en-PK').format(Math.round(n || 0));

export default function Invoices() {
  const [invoices,    setInvoices]    = useState([]);
  const [outstanding, setOutstanding] = useState(0);
  const [loading,     setLoading]     = useState(true);
  const [filter,      setFilter]      = useState('all');
  const [showModal,   setModal]       = useState(false);
  const [form,        setForm]        = useState({
    project_id: '', invoice_number: '',
    amount_due: '', due_date: ''
  });

  const load = () => {
    setLoading(true);
    Promise.all([getInvoices(), getOutstanding()])
      .then(([inv, out]) => {
        setInvoices(inv.data);
        setOutstanding(out.data[0]?.total_outstanding || 0);
      }).finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  const filtered = filter === 'all'
    ? invoices
    : invoices.filter(i => i.status === filter);

  const handleCreate = () => {
    createInvoice({
      project_id: parseInt(form.project_id),
      invoice_number: form.invoice_number,
      amount_due: parseFloat(form.amount_due),
      due_date: form.due_date || null
    }).then(() => { load(); setModal(false); }).catch(() => {});
  };

  const handleDelete = (id) => {
    if (window.confirm('Delete this invoice?')) {
      deleteInvoice(id).then(load).catch(() => {});
    }
  };

  const statusColor = (s) => ({
    paid: 'paid', unpaid: 'unpaid',
    partially_paid: 'partial'
  }[s] || 'unpaid');

  return (
    <div className="page-container">
      <div className="page-title">Invoices</div>
      <div className="page-subtitle">Track and manage all your invoices</div>

      {/* Outstanding Banner */}
      {outstanding > 0 && (
        <div className="outstanding-banner">
          <AlertCircle size={16} />
          <span>Total Outstanding:</span>
          <strong>$ {fmt(outstanding)}</strong>
        </div>
      )}

      <div className="toolbar">
        <div className="filter-tabs">
          {['all', 'unpaid', 'partially_paid', 'paid'].map(f => (
            <button
              key={f}
              className={`filter-tab ${filter === f ? 'filter-tab-active' : ''}`}
              onClick={() => setFilter(f)}
            >
              {f === 'partially_paid' ? 'Partial' :
               f.charAt(0).toUpperCase() + f.slice(1)}
              <span className="filter-count">
                {f === 'all' ? invoices.length
                  : invoices.filter(i => i.status === f).length}
              </span>
            </button>
          ))}
        </div>
        <button className="btn-primary" onClick={() => setModal(true)}>
          <Plus size={16} /> New Invoice
        </button>
      </div>

      {loading
        ? <div className="loading"><div className="spinner"/>Loading invoices...</div>
        : <div className="card">
            <table>
              <thead>
                <tr>
                  <th>Invoice #</th>
                  <th>Client</th>
                  <th>Project</th>
                  <th>Amount</th>
                  <th>Due Date</th>
                  <th>Status</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {filtered.length === 0
                  ? <tr><td colSpan={7} style={{ textAlign:'center', color:'var(--gray-2)', padding: 40 }}>
                      No invoices found
                    </td></tr>
                  : filtered.map(inv => (
                    <tr key={inv.invoice_id}
                      className={inv.status === 'unpaid' &&
                        new Date(inv.due_date) < new Date()
                          ? 'row-overdue' : ''}>
                      <td className="inv-number">{inv.invoice_number}</td>
                      <td>{inv.client_name}</td>
                      <td className="text-gray">{inv.project_title}</td>
                      <td className="inv-amount">
                        $ {fmt(inv.amount_due)}
                      </td>
                      <td className="text-gray">
                        {inv.due_date
                          ? new Date(inv.due_date).toLocaleDateString()
                          : '—'}
                      </td>
                      <td>
                        <span className={`badge badge-${statusColor(inv.status)}`}>
                          {inv.status === 'partially_paid' ? 'Partial' : inv.status}
                        </span>
                      </td>
                      <td>
                        <button
                          className="delete-btn"
                          onClick={() => handleDelete(inv.invoice_id)}
                        >
                          <Trash2 size={14} />
                        </button>
                      </td>
                    </tr>
                  ))
                }
              </tbody>
            </table>
          </div>
      }

      {showModal && (
        <div className="modal-overlay" onClick={() => setModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h3>New Invoice</h3>
            <div className="form-group">
              <label>Invoice Number</label>
              <input
                value={form.invoice_number}
                onChange={e => setForm({...form, invoice_number: e.target.value})}
                placeholder="INV-2024-015"
              />
            </div>
            <div className="form-group">
              <label>Project ID</label>
              <input
                type="number"
                value={form.project_id}
                onChange={e => setForm({...form, project_id: e.target.value})}
                placeholder="1"
              />
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Amount Due ($)</label>
                <input
                  type="number"
                  value={form.amount_due}
                  onChange={e => setForm({...form, amount_due: e.target.value})}
                  placeholder="500"
                />
              </div>
              <div className="form-group">
                <label>Due Date</label>
                <input
                  type="date"
                  value={form.due_date}
                  onChange={e => setForm({...form, due_date: e.target.value})}
                />
              </div>
            </div>
            <div className="modal-actions">
              <button className="btn-secondary" onClick={() => setModal(false)}>
                Cancel
              </button>
              <button className="btn-primary" onClick={handleCreate}>
                <Plus size={16} /> Create Invoice
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}