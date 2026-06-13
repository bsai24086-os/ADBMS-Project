import { useState, useEffect } from 'react';
import {
  Calculator, CheckCircle, AlertTriangle,
  Save, RefreshCw, FileText
} from 'lucide-react';
import { calculateTax, saveTaxReport, getTaxReports, refreshSummary } from '../api';
import './TaxReport.css';

const fmt = n => new Intl.NumberFormat('en-PK').format(Math.round(parseFloat(n) || 0));

export default function TaxReport() {
  const [year,     setYear]    = useState(2024);
  const [result,   setResult]  = useState(null);
  const [reports,  setReports] = useState([]);
  const [loading,  setLoading] = useState(false);
  const [saving,   setSaving]  = useState(false);
  const [msg,      setMsg]     = useState('');

  useEffect(() => {
    getTaxReports()
      .then(r => setReports(r.data))
      .catch(() => {});
  }, []);

  const handleCalculate = () => {
    setLoading(true);
    setMsg('');
    calculateTax(year)
      .then(r => setResult(r.data))
      .catch(() => setMsg('Error calculating tax. Check if data exists for this year.'))
      .finally(() => setLoading(false));
  };

  const handleSave = () => {
    if (!result) return;
    setSaving(true);
    saveTaxReport({ freelancer_id: 1, tax_year: year })
      .then(() => {
        setMsg('Tax report saved successfully!');
        getTaxReports().then(r => setReports(r.data));
      })
      .catch(() => setMsg('Error saving report.'))
      .finally(() => setSaving(false));
  };

  const handleRefresh = () => {
    refreshSummary()
      .then(() => setMsg('Dashboard summary refreshed!'))
      .catch(() => {});
  };

  const rows = result ? [
    {
      label: 'Total Income (PKR)',
      value: `₨ ${fmt(result.total_income_pkr)}`,
      color: 'var(--white)',
      icon: '💰',
      note: 'All payments converted at locked PKR rates'
    },
    {
      label: 'SRO 586 Exempt Income',
      value: `₨ ${fmt(result.exempt_income)}`,
      color: 'var(--mint)',
      icon: '✓',
      note: 'Received via compliant banking channels — income tax exempt'
    },
    {
      label: 'Taxable Income',
      value: `₨ ${fmt(result.taxable_income)}`,
      color: 'var(--amber)',
      icon: '⚠',
      note: 'Received via non-compliant channels — subject to bracket tax'
    },
    {
      label: 'Total Deductions',
      value: `₨ ${fmt(result.total_deductions)}`,
      color: 'var(--green)',
      icon: '−',
      note: 'FBR-deductible business expenses (internet, software, equipment)'
    },
    {
      label: 'Income After Deductions',
      value: `₨ ${fmt(result.income_after_deductions)}`,
      color: 'var(--white)',
      icon: '=',
      note: 'Taxable income minus deductions'
    },
    {
      label: 'Withholding Tax',
      value: `₨ ${fmt(result.withholding_tax)}`,
      color: 'var(--red)',
      icon: '🏦',
      note: 'Applied on TOTAL income — 0.15% (filer) / 0.30% (non-filer). Cannot be exempted by SRO 586.'
    },
    {
      label: 'Bracket Tax',
      value: `₨ ${fmt(result.bracket_tax)}`,
      color: 'var(--red)',
      icon: '📊',
      note: 'Progressive FBR income tax on taxable income after deductions'
    },
    {
      label: 'Net Tax Liability',
      value: `₨ ${fmt(result.net_tax_liability)}`,
      color: 'var(--amber)',
      icon: '=',
      note: 'Total amount owed to FBR — enter in Iris portal'
    },
  ] : [];

  return (
    <div className="page-container">
      <div className="page-title">FBR Tax Report</div>
      <div className="page-subtitle">
        Calculate your tax liability under SRO 586(I)/2024
      </div>

      <div className="tax-layout">
        {/* Left: Calculator */}
        <div>
          {/* Year Selector */}
          <div className="card tax-calculator">
            <div className="calc-header">
              <Calculator size={20} color="var(--mint)"/>
              <div className="chart-title">Tax Calculator</div>
            </div>

            <div className="year-selector">
              <label>Tax Year</label>
              <select value={year}
                onChange={e => setYear(parseInt(e.target.value))}>
                <option value={2024}>2024</option>
                <option value={2023}>2023</option>
                <option value={2022}>2022</option>
              </select>
            </div>

            {msg && (
              <div className={`tax-msg ${msg.includes('Error') ? 'tax-msg-error' : 'tax-msg-success'}`}>
                {msg}
              </div>
            )}

            <div className="calc-actions">
              <button className="btn-primary calc-btn"
                onClick={handleCalculate} disabled={loading}>
                {loading
                  ? <><div className="spinner"/>Calculating...</>
                  : <><Calculator size={16}/>Calculate Tax</>
                }
              </button>
              <button className="btn-secondary" onClick={handleRefresh}>
                <RefreshCw size={14}/> Refresh Summary
              </button>
            </div>
          </div>

          {/* Results */}
          {result && (
            <div className="card tax-results">
              <div className="results-header">
                <div className="chart-title">
                  Tax Breakdown — {year}
                </div>
                <button
                  className="btn-primary"
                  onClick={handleSave}
                  disabled={saving}
                >
                  {saving
                    ? <><div className="spinner"/>Saving...</>
                    : <><Save size={14}/>Save Report</>
                  }
                </button>
              </div>

              {rows.map((row, i) => (
                <div key={i}
                  className={`tax-row ${row.label === 'Net Tax Liability' ? 'tax-row-final' : ''}`}>
                  <div className="tax-row-left">
                    <span className="tax-icon">{row.icon}</span>
                    <div>
                      <div className="tax-label">{row.label}</div>
                      <div className="tax-note">{row.note}</div>
                    </div>
                  </div>
                  <div className="tax-value" style={{color: row.color}}>
                    {row.value}
                  </div>
                </div>
              ))}

              {/* Iris Export Note */}
              <div className="iris-note">
                <FileText size={14}/>
                <span>
                  Enter <strong>Net Tax Liability</strong> in FBR Iris portal
                  under Income Tax Return → Foreign Income section
                </span>
              </div>
            </div>
          )}
        </div>

        {/* Right: Saved Reports */}
        <div className="card saved-reports">
          <div className="chart-title" style={{marginBottom: 16}}>
            Saved Tax Reports
          </div>
          {reports.length === 0
            ? <div className="empty-state">
                <FileText size={28} color="#64748B"/>
                <p>No reports saved yet</p>
              </div>
            : reports.map((r, i) => (
              <div key={i} className="report-item">
                <div className="report-year">{r.tax_year}</div>
                <div className="report-details">
                  <div className="report-income">
                    ₨ {fmt(r.total_income_pkr)} total income
                  </div>
                  <div className="report-liability">
                    Net liability: ₨ {fmt(r.net_tax_liability)}
                  </div>
                  <div className="report-date">
                    Generated: {new Date(r.generated_at).toLocaleDateString()}
                  </div>
                </div>
                <div className={`report-badge ${parseFloat(r.net_tax_liability) === 0 ? 'badge-active' : 'badge-unpaid'}`}>
                  {parseFloat(r.net_tax_liability) === 0 ? 'Nil' : 'Payable'}
                </div>
              </div>
            ))
          }
        </div>
      </div>
    </div>
  );
}