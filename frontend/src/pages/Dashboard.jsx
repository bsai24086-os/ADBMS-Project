import { useState, useEffect } from 'react';
import {
  AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer
} from 'recharts';
import {
  Users, FolderOpen, FileText,
  TrendingUp, AlertCircle
} from 'lucide-react';
import {
  getDashboard, getMonthlyTrend, getPaymentsByPlatform,
  getRecentPayments, getUnpaidInvoices
} from '../api';
import './Dashboard.css';

const COLORS = ['#0E7C7B', '#14B8A6', '#F59E0B', '#60A5FA'];

const fmt = (n) => new Intl.NumberFormat('en-PK').format(Math.round(n || 0));

export default function Dashboard() {
  const [stats,    setStats]    = useState(null);
  const [trend,    setTrend]    = useState([]);
  const [platforms,setPlatforms]= useState([]);
  const [recent,   setRecent]   = useState([]);
  const [unpaid,   setUnpaid]   = useState([]);
  const [loading,  setLoading]  = useState(true);

  useEffect(() => {
    Promise.all([
      getDashboard(),
      getMonthlyTrend(),
      getPaymentsByPlatform(),
      getRecentPayments(),
      getUnpaidInvoices(),
    ]).then(([d, t, p, r, u]) => {
      setStats(d.data || d);
      setTrend((t.data || []).map(x => ({
        month: new Date(x.month).toLocaleString('default',{month:'short'}),
        pkr:   Math.round(x.net_income_pkr || 0)
      })));
      setPlatforms((p.data || []).map(x => ({
        name:  x.platform_name,
        value: Math.round(x.total_net_pkr || 0)
      })));
      setRecent(r.data || []);
      setUnpaid(u.data || []);
    }).catch(err => {
      console.error('Dashboard error:', err);
      setStats({});
    }).finally(() => setLoading(false));
  }, []);

  if (loading) return (
    <div className="page-container">
      <div className="loading"><div className="spinner"/>Loading dashboard...</div>
    </div>
  );

  const cards = [
    {
      label: 'Total Income 2024',
      value: `₨ ${fmt(stats?.total_income_pkr_2024)}`,
      icon: TrendingUp,
      color: '#14B8A6',
      sub: 'Net after platform fees'
    },
    {
      label: 'Active Projects',
      value: stats?.active_projects || 0,
      icon: FolderOpen,
      color: '#60A5FA',
      sub: 'Currently in progress'
    },
    {
      label: 'Total Clients',
      value: stats?.total_clients || 0,
      icon: Users,
      color: '#0E7C7B',
      sub: 'Across all platforms'
    },
    {
      label: 'Unpaid Invoices',
      value: stats?.unpaid_invoices || 0,
      icon: FileText,
      color: '#F59E0B',
      sub: 'Awaiting payment'
    },
  ];

  return (
    <div className="page-container">
      <div className="page-title">Welcome back, Ahmed 👋</div>
      <div className="page-subtitle">Here's your financial overview for 2024</div>

      {/* Stat Cards */}
      <div className="stats-grid">
        {cards.map((c, i) => (
          <div className="stat-card" key={i}
            style={{ animationDelay: `${i * 0.08}s` }}>
            <div className="stat-top">
              <div className="stat-icon" style={{ background: `${c.color}22` }}>
                <c.icon size={20} color={c.color} />
              </div>
              <span className="stat-label">{c.label}</span>
            </div>
            <div className="stat-value" style={{ color: c.color }}>
              {c.value}
            </div>
            <div className="stat-sub">{c.sub}</div>
          </div>
        ))}
      </div>

      {/* Charts Row */}
      <div className="charts-row">
        {/* Area Chart - Monthly Trend */}
        <div className="card chart-card-wide">
          <div className="chart-header">
            <div>
              <div className="chart-title">Monthly Income Trend</div>
              <div className="chart-sub">Net income in PKR per month</div>
            </div>
          </div>
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={trend}>
              <defs>
                <linearGradient id="tealGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%"  stopColor="#14B8A6" stopOpacity={0.3}/>
                  <stop offset="95%" stopColor="#14B8A6" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(14,124,123,0.1)" />
              <XAxis dataKey="month" tick={{ fill: '#94A3B8', fontSize: 12 }} axisLine={false} />
              <YAxis tick={{ fill: '#94A3B8', fontSize: 12 }} axisLine={false}
                tickFormatter={v => `₨${(v/1000).toFixed(0)}k`} />
              <Tooltip
                contentStyle={{ background: '#0F1E35', border: '1px solid rgba(14,124,123,0.3)', borderRadius: 10 }}
                labelStyle={{ color: '#fff' }}
                formatter={v => [`₨ ${fmt(v)}`, 'Net Income']}
              />
              <Area type="monotone" dataKey="pkr"
                stroke="#14B8A6" strokeWidth={2}
                fill="url(#tealGrad)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Pie Chart - Platform Split */}
        <div className="card chart-card-small">
          <div className="chart-header">
            <div>
              <div className="chart-title">Income by Platform</div>
              <div className="chart-sub">PKR breakdown</div>
            </div>
          </div>
          <ResponsiveContainer width="100%" height={180}>
            <PieChart>
              <Pie data={platforms} cx="50%" cy="50%"
                innerRadius={50} outerRadius={75}
                paddingAngle={4} dataKey="value">
                {platforms.map((_, i) => (
                  <Cell key={i} fill={COLORS[i % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip
                contentStyle={{ background: '#0F1E35', border: '1px solid rgba(14,124,123,0.3)', borderRadius: 10 }}
                formatter={v => [`₨ ${fmt(v)}`, '']}
              />
            </PieChart>
          </ResponsiveContainer>
          <div className="pie-legend">
            {platforms.map((p, i) => (
              <div key={i} className="legend-item">
                <span className="legend-dot"
                  style={{ background: COLORS[i % COLORS.length] }} />
                <span className="legend-name">{p.name}</span>
                <span className="legend-val">₨ {fmt(p.value)}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Bottom Row */}
      <div className="bottom-row">
        {/* Recent Payments */}
        <div className="card">
          <div className="chart-title" style={{ marginBottom: 16 }}>
            Recent Payments
          </div>
          {recent.length === 0
            ? <div className="empty-state"><p>No payments yet</p></div>
            : recent.map((p, i) => (
              <div key={i} className="activity-item">
                <div className="activity-dot" />
                <div className="activity-info">
                  <div className="activity-client">{p.client_name}</div>
                  <div className="activity-invoice">
                    {p.invoice_number} · {p.channel_name}
                  </div>
                </div>
                <div className="activity-amount">
                  ₨ {fmt(p.net_pkr)}
                </div>
              </div>
            ))
          }
        </div>

        {/* Overdue Invoices */}
        <div className="card">
          <div className="chart-title" style={{ marginBottom: 16, color: '#F59E0B' }}>
            <AlertCircle size={16} style={{ display:'inline', marginRight: 8 }} />
            Overdue / Unpaid Invoices
          </div>
          {unpaid.length === 0
            ? <div className="empty-state"><p>No unpaid invoices 🎉</p></div>
            : unpaid.slice(0, 5).map((inv, i) => (
              <div key={i} className="overdue-item">
                <div>
                  <div className="overdue-num">{inv.invoice_number}</div>
                  <div className="overdue-client">{inv.client_name}</div>
                </div>
                <div className="overdue-right">
                  <div className="overdue-amount">
                    ${new Intl.NumberFormat().format(inv.amount_due)}
                  </div>
                  {inv.days_overdue > 0 &&
                    <div className="overdue-days">
                      {inv.days_overdue}d overdue
                    </div>
                  }
                </div>
              </div>
            ))
          }
        </div>
      </div>
    </div>
  );
}