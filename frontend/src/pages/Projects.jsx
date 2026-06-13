import { useState, useEffect } from 'react';
import { Plus, Trash2, ChevronDown } from 'lucide-react';
import { getProjects, createProject, updateProject, deleteProject } from '../api';
import './Projects.css';

const fmt = n => new Intl.NumberFormat('en-PK').format(Math.round(n || 0));

export default function Projects() {
  const [projects, setProjects] = useState([]);
  const [loading,  setLoading]  = useState(true);
  const [filter,   setFilter]   = useState('all');
  const [showModal,setModal]    = useState(false);
  const [form,     setForm]     = useState({
    client_id: '', contract_type_id: 1,
    project_title: '', agreed_amount: '',
    currency: 'USD', status: 'active',
    start_date: new Date().toISOString().split('T')[0],
    end_date: ''
  });

  const load = () => {
    setLoading(true);
    getProjects()
      .then(r => setProjects(r.data))
      .finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  const filtered = filter === 'all'
    ? projects
    : projects.filter(p => p.status === filter);

  const handleCreate = () => {
    createProject({
      ...form,
      client_id: parseInt(form.client_id),
      agreed_amount: parseFloat(form.agreed_amount),
      end_date: form.end_date || null
    }).then(() => { load(); setModal(false); }).catch(() => {});
  };

  const handleStatus = (id, status) => {
    updateProject(id, { status })
      .then(load).catch(() => {});
  };

  const handleDelete = (id) => {
    if (window.confirm('Delete this project?')) {
      deleteProject(id).then(load).catch(() => {});
    }
  };

  const cols = ['active', 'completed', 'paused', 'cancelled'];

  return (
    <div className="page-container">
      <div className="page-title">Projects</div>
      <div className="page-subtitle">Track all your projects by status</div>

      <div className="toolbar">
        <div className="filter-tabs">
          {['all', 'active', 'completed', 'paused'].map(f => (
            <button
              key={f}
              className={`filter-tab ${filter === f ? 'filter-tab-active' : ''}`}
              onClick={() => setFilter(f)}
            >
              {f.charAt(0).toUpperCase() + f.slice(1)}
              <span className="filter-count">
                {f === 'all'
                  ? projects.length
                  : projects.filter(p => p.status === f).length}
              </span>
            </button>
          ))}
        </div>
        <button className="btn-primary" onClick={() => setModal(true)}>
          <Plus size={16} /> New Project
        </button>
      </div>

      {loading
        ? <div className="loading"><div className="spinner"/>Loading projects...</div>
        : filtered.length === 0
          ? <div className="empty-state"><p>No projects found</p></div>
          : <div className="projects-list">
              {filtered.map(p => (
                <div key={p.project_id} className="project-row card">
                  <div className="project-left">
                    <div className={`project-status-dot status-${p.status}`} />
                    <div>
                      <div className="project-title">{p.project_title}</div>
                      <div className="project-meta">
                        {p.client_name} · {p.contract_type} ·
                        Started {new Date(p.start_date).toLocaleDateString()}
                      </div>
                    </div>
                  </div>
                  <div className="project-right">
                    <div className="project-amount">
                      {p.currency} {fmt(p.agreed_amount)}
                    </div>
                    <span className={`badge badge-${p.status}`}>{p.status}</span>
                    <div className="project-actions">
                      <select
                        value={p.status}
                        onChange={e => handleStatus(p.project_id, e.target.value)}
                        className="status-select"
                      >
                        {cols.map(c => (
                          <option key={c} value={c}>{c}</option>
                        ))}
                      </select>
                      <button
                        className="delete-btn"
                        onClick={() => handleDelete(p.project_id)}
                      >
                        <Trash2 size={14} />
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
      }

      {showModal && (
        <div className="modal-overlay" onClick={() => setModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h3>New Project</h3>
            <div className="form-group">
              <label>Project Title</label>
              <input
                value={form.project_title}
                onChange={e => setForm({...form, project_title: e.target.value})}
                placeholder="E-Commerce Website"
              />
            </div>
            <div className="form-group">
              <label>Client ID</label>
              <input
                type="number"
                value={form.client_id}
                onChange={e => setForm({...form, client_id: e.target.value})}
                placeholder="1"
              />
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Agreed Amount</label>
                <input
                  type="number"
                  value={form.agreed_amount}
                  onChange={e => setForm({...form, agreed_amount: e.target.value})}
                  placeholder="1500"
                />
              </div>
              <div className="form-group">
                <label>Currency</label>
                <select
                  value={form.currency}
                  onChange={e => setForm({...form, currency: e.target.value})}
                >
                  <option value="USD">USD</option>
                  <option value="GBP">GBP</option>
                  <option value="EUR">EUR</option>
                </select>
              </div>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label>Contract Type</label>
                <select
                  value={form.contract_type_id}
                  onChange={e => setForm({...form, contract_type_id: parseInt(e.target.value)})}
                >
                  <option value={1}>Fixed</option>
                  <option value={2}>Hourly</option>
                  <option value={3}>Retainer</option>
                </select>
              </div>
              <div className="form-group">
                <label>Start Date</label>
                <input
                  type="date"
                  value={form.start_date}
                  onChange={e => setForm({...form, start_date: e.target.value})}
                />
              </div>
            </div>
            <div className="modal-actions">
              <button className="btn-secondary" onClick={() => setModal(false)}>
                Cancel
              </button>
              <button className="btn-primary" onClick={handleCreate}>
                <Plus size={16} /> Create Project
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}