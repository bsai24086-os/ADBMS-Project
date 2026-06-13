import { useState, useEffect } from 'react';
import { Plus } from 'lucide-react';
import {
  BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer
} from 'recharts';
import {
  getPayments, getPaymentsByPlatform, getMonthlyTrend,
  getSRO586Split, getTopClients, getPaymentsByCurrency,
  createPayment, getLatestRate
} from '../api';
import './Payments.css';

const COLORS = ['#0E7C7B','#14B8A6','#F59E0B','#60A5FA'];
const fmt = n => new Intl.NumberFormat('en-PK').format(Math.round(n || 0));

export default function Payments() {
  const [payments,  setPayments]  = useState([]);
  const [platforms, setPlatforms] = useState([]);
  const [trend,     setTrend]     = useState([]);
  const [sro,       setSro]       = useState([]);
  const [topClients,setTop]       = useState([]);
  const [byCurrency,setByCurrency]= useState([]);
  const [loading,   setLoading]   = useState(true);
  const [showModal, setModal]     = useState(false);
  const [form,      setForm]      = useState({
    invoice_id: '', channel_id: 1,
    amount_paid: '', pkr_rate: '',
    gross_amount: '', platform_fee: '0',
    payment_date: new Date().toISOString().split('T')[0],
    notes: ''
  });

  const load = () => {
    setLoading(true);
    Promise.all([
      getPayments(), getPaymentsByPlatform(),
      getMonthlyTrend(), getSRO586Split(),
      getTopClients(), getPaymentsByCurrency()
    ]).then(([p, pl, t, s, tc, bc]) => {
      setPayments(p.data);
      setPlatforms(pl.data.map(x => ({
        name: x.platform_name,
        value: Math.round(x.total_net_pkr || 0)
      })));
      setTrend(t.data.map(x => ({
        month: new Date(x.month).toLocaleString('default',{month:'short'}),
        pkr: Math.round(x.net_income_pkr || 0)
      })));
      setSro(s.data);
      setTop(tc.data);
      setByCurrency(bc.data);
    }).finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  const fetchRate = () => {
    getLatestRate('USD')
      .then(r => setForm(f => ({...f, pkr_rate: r.data.rate})))
      .catch(() => {});
  };

  const handleCreate = () => {
    createPayment({
      invoice_id:   parseInt(form.invoice_id),
      channel_id:   parseInt(form.channel_id),
      amount_paid:  parseFloat(form.amount_paid),
      pkr_rate:     parseFloat(form.pkr_rate),
      gross_amount: parseFloat(form.gross_amount),
      platform_fee: parseFloat(form.platform_fee),
      payment_date: form.payment_date,
      notes:        form.notes || null
    }).then(() => { load(); setModal(false); }).catch(() => {});
  };

  const sroExempt = sro.find(s => s.is_fbr_compliant)?.total_pkr || 0;
  const sroTaxable = sro.find(s => !s.is_fbr_compliant)?.total_pkr || 0;

  return (
    <div className="page-container">
      <div className="page-title">Payments</div>
      <div className="page-subtitle">Income breakdown and payment history</div>

      {/* SRO 586 Banner */}
      <div className="sro-banner">
        <div className="sro-item">
          <div className="sro-label">✓ SRO 586 Exempt Income</div>
          <div className="sro-value sro-green">₨ {fmt(sroExempt)}</div>
        </div>
        <div className="sro-divider" />
        <div className="sro-item">
          <div className="sro-label">⚠ Taxable Income</div>
          <div className="sro-value sro-amber">₨ {fmt(sroTaxable)}</div>
        </div>
      </div>

      {/* Charts */}
      <div className="charts-row">
        <div className="card">
          <div className="chart-title" style={{marginBottom:16}}>
            Monthly Income (PKR)
          </div>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={trend}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(14,124,123,0.1)" />
              <XAxis dataKey="month" tick={{fill:'#94A3B8',fontSize:12}} axisLine={false}/>
              <YAxis tick={{fill:'#94A3B8',fontSize:12}} axisLine={false}
                tickFormatter={v=>`₨${(v/1000).toFixed(0)}k`}/>
              <Tooltip
                contentStyle={{background:'#0F1E35',border:'1px solid rgba(14,124,123,0.3)',borderRadius:10}}
                formatter={v=>[`₨ ${fmt(v)}`,'Income']}
              />
              <Bar dataKey="pkr" fill="#0E7C7B" radius={[4,4,0,0]}/>
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div className="card">
          <div className="chart-title" style={{marginBottom:16}}>
            By Platform
          </div>
          <ResponsiveContainer width="100%" height={160}>
            <PieChart>
              <Pie data={platforms} cx="50%" cy="50%"
                innerRadius={40} outerRadius={65}
                paddingAngle={4} dataKey="value">
                {platforms.map((_,i) => (
                  <Cell key={i} fill={COLORS[i % COLORS.length]}/>
                ))}
              </Pie>
              <Tooltip
                contentStyle={{background:'#0F1E35',border:'1px solid rgba(14,124,123,0.3)',borderRadius:10}}
                formatter={v=>[`₨ ${fmt(v)}`]}
              />
            </PieChart>
          </ResponsiveContainer>
          <div className="pie-legend">
            {platforms.map((p,i) => (
              <div key={i} className="legend-item">
                <span className="legend-dot" style={{background:COLORS[i%COLORS.length]}}/>
                <span className="legend-name">{p.name}</span>
                <span className="legend-val">₨ {fmt(p.value)}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="card">
          <div className="chart-title" style={{marginBottom:16}}>
            By Currency
          </div>
          {byCurrency.map((c,i) => (
            <div key={i} className="currency-row">
              <span className="currency-code">{c.currency}</span>
              <span className="currency-foreign">
                {c.currency} {fmt(c.total_net_foreign)}
              </span>
              <span className="currency-pkr">₨ {fmt(c.total_net_pkr)}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Payments Table */}
      <div className="card" style={{marginTop:16}}>
        <div className="table-header">
          <div className="chart-title">Payment History</div>
          <button className="btn-primary" onClick={() => setModal(true)}>
            <Plus size={16}/> Record Payment
          </button>
        </div>
        <table>
          <thead>
            <tr>
              <th>Date</th>
              <th>Client</th>
              <th>Invoice</th>
              <th>Amount</th>
              <th>PKR Rate</th>
              <th>Net PKR</th>
              <th>Channel</th>
              <th>SRO 586</th>
            </tr>
          </thead>
          <tbody>
            {payments.length === 0
              ? <tr><td colSpan={8} style={{textAlign:'center',color:'var(--gray-2)',padding:40}}>
                  No payments yet
                </td></tr>
              : payments.map((p,i) => (
                <tr key={i}>
                  <td className="text-gray">
                    {new Date(p.payment_date).toLocaleDateString()}
                  </td>
                  <td>{p.client_name}</td>
                  <td className="inv-number">{p.invoice_number}</td>
                  <td>${fmt(p.amount_paid)}</td>
                  <td className="text-gray">{p.pkr_rate}</td>
                  <td style={{color:'var(--mint)',fontWeight:700}}>
                    ₨ {fmt(p.net_pkr)}
                  </td>
                  <td>{p.channel_name}</td>
                  <td>
                    <span className={`badge ${p.is_fbr_compliant ? 'badge-active' : 'badge-overdue'}`}>
                      {p.is_fbr_compliant ? 'Exempt' : 'Taxable'}
                    </span>
                  </td>
                </tr>
              ))
            }
          </tbody>
        </table>
      </div>

      {showModal && (
        <div className="modal-overlay" onClick={() => setModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h3>Record Payment</h3>
            <div className="form-group">
              <label>Invoice ID</label>
              <input type="number" value={form.invoice_id}
                onChange={e => setForm({...form, invoice_id: e.target.value})}
                placeholder="1"/>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Gross Amount ($)</label>
                <input type="number" value={form.gross_amount}
                  onChange={e => setForm({...form, gross_amount: e.target.value})}
                  placeholder="500"/>
              </div>
              <div className="form-group">
                <label>Platform Fee ($)</label>
                <input type="number" value={form.platform_fee}
                  onChange={e => setForm({...form, platform_fee: e.target.value})}
                  placeholder="100"/>
              </div>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Amount Paid ($)</label>
                <input type="number" value={form.amount_paid}
                  onChange={e => setForm({...form, amount_paid: e.target.value})}
                  placeholder="400"/>
              </div>
              <div className="form-group">
                <label>PKR Rate
                  <button className="fetch-rate-btn" onClick={fetchRate}>
                    Get Latest
                  </button>
                </label>
                <input type="number" value={form.pkr_rate}
                  onChange={e => setForm({...form, pkr_rate: e.target.value})}
                  placeholder="280.50"/>
              </div>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Payment Channel</label>
                <select value={form.channel_id}
                  onChange={e => setForm({...form, channel_id: e.target.value})}>
                  <option value={1}>Bank Transfer</option>
                  <option value={2}>Payoneer</option>
                  <option value={3}>Wise</option>
                  <option value={4}>Cash</option>
                  <option value={5}>Crypto</option>
                </select>
              </div>
              <div className="form-group">
                <label>Payment Date</label>
                <input type="date" value={form.payment_date}
                  onChange={e => setForm({...form, payment_date: e.target.value})}/>
              </div>
            </div>
            <div className="form-group">
              <label>Notes (optional)</label>
              <input value={form.notes}
                onChange={e => setForm({...form, notes: e.target.value})}
                placeholder="Fiverr milestone payment"/>
            </div>
            <div className="modal-actions">
              <button className="btn-secondary" onClick={() => setModal(false)}>
                Cancel
              </button>
              <button className="btn-primary" onClick={handleCreate}>
                <Plus size={16}/> Record
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}