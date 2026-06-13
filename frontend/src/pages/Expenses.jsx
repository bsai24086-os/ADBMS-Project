import { useState, useEffect } from 'react';
import { Plus, Trash2 } from 'lucide-react';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer
} from 'recharts';
import {
  getExpenses, getExpensesByCategory,
  getDeductibleSplit, createExpense, deleteExpense,
  getYearlyDeductible
} from '../api';
import './Expenses.css';

const fmt = n => new Intl.NumberFormat('en-PK').format(Math.round(n || 0));

export default function Expenses() {
  const [expenses,    setExpenses]    = useState([]);
  const [byCategory,  setByCategory]  = useState([]);
  const [deductSplit, setDeductSplit] = useState([]);
  const [yearlyDed,   setYearlyDed]   = useState(0);
  const [loading,     setLoading]     = useState(true);
  const [showModal,   setModal]       = useState(false);
  const [form,        setForm]        = useState({
    freelancer_id: 1, category_id: 1,
    amount: '', expense_date: new Date().toISOString().split('T')[0],
    description: '', receipt_reference: ''
  });

  const load = () => {
    setLoading(true);
    Promise.all([
      getExpenses(), getExpensesByCategory(),
      getDeductibleSplit(), getYearlyDeductible(2024)
    ]).then(([e, bc, ds, yd]) => {
      setExpenses(e.data);
      setByCategory(bc.data.map(x => ({
        name: x.category_name.length > 10
          ? x.category_name.substring(0, 10) + '...'
          : x.category_name,
        total: Math.round(x.total),
        deductible: x.is_fbr_deductible
      })));
      setDeductSplit(ds.data);
      setYearlyDed(yd.data[0]?.total_deductible || 0);
    }).finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  const handleCreate = () => {
    createExpense({
      ...form,
      amount: parseFloat(form.amount),
      category_id: parseInt(form.category_id)
    }).then(() => { load(); setModal(false); }).catch(() => {});
  };

  const handleDelete = (id) => {
    if (window.confirm('Delete expense?')) {
      deleteExpense(id).then(load).catch(() => {});
    }
  };

  const deductible    = deductSplit.find(d => d.is_fbr_deductible)?.total_amount || 0;
  const nonDeductible = deductSplit.find(d => !d.is_fbr_deductible)?.total_amount || 0;

  return (
    <div className="page-container">
      <div className="page-title">Expenses</div>
      <div className="page-subtitle">Track business expenses and FBR deductions</div>

      {/* Summary Cards */}
      <div className="expense-summary">
        <div className="card exp-stat">
          <div className="exp-stat-label">FBR Deductible (2024)</div>
          <div className="exp-stat-value" style={{color:'var(--mint)'}}>
            ₨ {fmt(yearlyDed)}
          </div>
        </div>
        <div className="card exp-stat">
          <div className="exp-stat-label">Total Deductible</div>
          <div className="exp-stat-value" style={{color:'var(--green)'}}>
            ₨ {fmt(deductible)}
          </div>
        </div>
        <div className="card exp-stat">
          <div className="exp-stat-label">Non-Deductible</div>
          <div className="exp-stat-value" style={{color:'var(--red)'}}>
            ₨ {fmt(nonDeductible)}
          </div>
        </div>
        <div className="card exp-stat">
          <div className="exp-stat-label">Total Expenses</div>
          <div className="exp-stat-value" style={{color:'var(--amber)'}}>
            ₨ {fmt(parseFloat(deductible) + parseFloat(nonDeductible))}
          </div>
        </div>
      </div>

      {/* Chart + Table Row */}
      <div className="exp-content-row">
        <div className="card exp-chart">
          <div className="chart-title" style={{marginBottom:16}}>
            Expenses by Category
          </div>
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={byCategory} layout="vertical">
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(14,124,123,0.1)" horizontal={false}/>
              <XAxis type="number" tick={{fill:'#94A3B8',fontSize:11}} axisLine={false}
                tickFormatter={v=>`₨${(v/1000).toFixed(0)}k`}/>
              <YAxis type="category" dataKey="name"
                tick={{fill:'#94A3B8',fontSize:11}} axisLine={false} width={80}/>
              <Tooltip
                contentStyle={{background:'#0F1E35',border:'1px solid rgba(14,124,123,0.3)',borderRadius:10}}
                formatter={v=>[`₨ ${fmt(v)}`,'Amount']}
              />
              <Bar dataKey="total" radius={[0,4,4,0]}
                fill="#0E7C7B"
              />
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="card exp-table">
          <div className="table-header">
            <div className="chart-title">All Expenses</div>
            <button className="btn-primary" onClick={() => setModal(true)}>
              <Plus size={16}/> Add
            </button>
          </div>
          {loading
            ? <div className="loading"><div className="spinner"/></div>
            : <div className="expense-list">
                {expenses.map((e, i) => (
                  <div key={i} className="expense-item">
                    <div className={`exp-deduct-indicator ${e.is_fbr_deductible ? 'deduct-yes' : 'deduct-no'}`}/>
                    <div className="exp-info">
                      <div className="exp-desc">{e.description || e.category_name}</div>
                      <div className="exp-meta">
                        {e.category_name} ·
                        {new Date(e.expense_date).toLocaleDateString()}
                        {e.receipt_reference &&
                          <span className="exp-receipt"> · {e.receipt_reference}</span>
                        }
                      </div>
                    </div>
                    <div className="exp-right">
                      <div className="exp-amount">₨ {fmt(e.amount)}</div>
                      <span className={`badge ${e.is_fbr_deductible ? 'badge-active' : 'badge-overdue'}`}>
                        {e.is_fbr_deductible ? 'Deductible' : 'Non-Ded.'}
                      </span>
                    </div>
                    <button className="delete-btn"
                      onClick={() => handleDelete(e.expense_id)}>
                      <Trash2 size={14}/>
                    </button>
                  </div>
                ))}
              </div>
          }
        </div>
      </div>

      {showModal && (
        <div className="modal-overlay" onClick={() => setModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h3>Add Expense</h3>
            <div className="form-row">
              <div className="form-group">
                <label>Category</label>
                <select value={form.category_id}
                  onChange={e => setForm({...form, category_id: e.target.value})}>
                  <option value={1}>Internet</option>
                  <option value={2}>Home Office</option>
                  <option value={3}>Software</option>
                  <option value={4}>Equipment</option>
                  <option value={5}>Marketing</option>
                  <option value={6}>Entertainment</option>
                  <option value={7}>Personal</option>
                </select>
              </div>
              <div className="form-group">
                <label>Amount (PKR)</label>
                <input type="number" value={form.amount}
                  onChange={e => setForm({...form, amount: e.target.value})}
                  placeholder="3500"/>
              </div>
            </div>
            <div className="form-group">
              <label>Description</label>
              <input value={form.description}
                onChange={e => setForm({...form, description: e.target.value})}
                placeholder="Monthly internet - PTCL"/>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Date</label>
                <input type="date" value={form.expense_date}
                  onChange={e => setForm({...form, expense_date: e.target.value})}/>
              </div>
              <div className="form-group">
                <label>Receipt Reference</label>
                <input value={form.receipt_reference}
                  onChange={e => setForm({...form, receipt_reference: e.target.value})}
                  placeholder="PTCL-MAY-2024"/>
              </div>
            </div>
            <div className="modal-actions">
              <button className="btn-secondary" onClick={() => setModal(false)}>Cancel</button>
              <button className="btn-primary" onClick={handleCreate}>
                <Plus size={16}/> Add Expense
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}