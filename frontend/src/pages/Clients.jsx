import { useState, useEffect } from 'react';
import { Plus, Search, Trash2, Globe, Users } from 'lucide-react';
import { getClients, createClient, deleteClient, searchClients } from '../api';
import './Clients.css';

const platformBadge = (name) => {
  const map = { Fiverr: 'fiverr', Upwork: 'upwork', Direct: 'direct' };
  return map[name] || 'direct';
};

export default function Clients() {
  const [clients,  setClients]  = useState([]);
  const [loading,  setLoading]  = useState(true);
  const [search,   setSearch]   = useState('');
  const [showModal,setModal]    = useState(false);
  const [selected, setSelected] = useState(null);
  const [form,     setForm]     = useState({
    freelancer_id: 1, platform_id: 1,
    client_name: '', country: '', currency: 'USD',
    platform_metadata: {}
  });

  const load = () => {
    setLoading(true);
    getClients()
      .then(r => {
        console.log('Loaded clients:', r.data);
        setClients(r.data || []);
      })
      .catch((err) => {
        console.error('Failed to load clients:', err.response?.data || err.message);
        setClients([]);
      })
      .finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  const handleSearch = (e) => {
    setSearch(e.target.value);
    if (e.target.value.length > 1) {
      searchClients(e.target.value)
        .then(r => setClients(r.data))
        .catch((err) => console.error('Search failed:', err.message));
    } else if (e.target.value === '') {
      load();
    }
  };

  const handleCreate = () => {
    createClient(form)
      .then(() => { 
        console.log('Client created successfully:', form.client_name);
        load(); 
        setModal(false); 
        resetForm(); 
      })
      .catch((err) => {
        console.error('Failed to create client:', err.response?.data || err.message);
        alert('Error creating client: ' + (err.response?.data?.detail || err.message));
      });
  };

  const handleDelete = (id) => {
    if (window.confirm('Delete this client?')) {
      deleteClient(id)
        .then(() => {
          console.log('Client deleted:', id);
          load();
        })
        .catch((err) => {
          console.error('Failed to delete client:', err.message);
          alert('Error deleting client: ' + err.message);
        });
    }
  };

  const resetForm = () => setForm({
    freelancer_id: 1, platform_id: 1,
    client_name: '', country: '', currency: 'USD',
    platform_metadata: {}
  });

  return (
    <div className="page-container">
      <div className="page-title">Clients</div>
      <div className="page-subtitle">Manage your clients across all platforms</div>

      {/* Toolbar */}
      <div className="toolbar">
        <div className="search-box">
          <Search size={16} color="#64748B" />
          <input
            placeholder="Search clients..."
            value={search}
            onChange={handleSearch}
          />
        </div>
        <button className="btn-primary" onClick={() => setModal(true)}>
          <Plus size={16} /> Add Client
        </button>
      </div>

      {/* Client Cards */}
      {loading
        ? <div className="loading"><div className="spinner"/>Loading clients...</div>
        : clients.length === 0
          ? <div className="empty-state">
              <Users size={32} color="#64748B" />
              <p>No clients yet. Add your first client!</p>
            </div>
          : <div className="clients-grid">
              {clients.map(c => (
                <div
                  key={c.client_id}
                  className={`client-card ${selected?.client_id === c.client_id ? 'client-card-active' : ''}`}
                  onClick={() => setSelected(s =>
                    s?.client_id === c.client_id ? null : c
                  )}
                >
                  <div className="client-card-top">
                    <div className="client-avatar">
                      {c.client_name.charAt(0).toUpperCase()}
                    </div>
                    <div className="client-info">
                      <div className="client-name">{c.client_name}</div>
                      <div className="client-meta">
                        <Globe size={12} />
                        {c.country || 'Unknown'}
                      </div>
                    </div>
                    <button
                      className="delete-btn"
                      onClick={e => { e.stopPropagation(); handleDelete(c.client_id); }}
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>

                  <div className="client-card-footer">
                    <span className={`badge badge-${platformBadge(c.platform_name)}`}>
                      {c.platform_name}
                    </span>
                    <span className="client-currency">{c.currency}</span>
                    {c.fee_percentage > 0 &&
                      <span className="client-fee">{c.fee_percentage}% fee</span>
                    }
                  </div>

                  {/* Expanded metadata */}
                  {selected?.client_id === c.client_id && c.platform_metadata && (
                    <div className="client-metadata">
                      {Object.entries(c.platform_metadata).map(([k, v]) =>
                        v !== null && (
                          <div key={k} className="meta-row">
                            <span className="meta-key">
                              {k.replace(/_/g, ' ')}
                            </span>
                            <span className="meta-val">{String(v)}</span>
                          </div>
                        )
                      )}
                    </div>
                  )}
                </div>
              ))}
            </div>
      }

      {/* Add Client Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setModal(false)}>
          <div className="modal" onClick={e => e.stopPropagation()}>
            <h3>Add New Client</h3>

            <div className="form-group">
              <label>Client Name</label>
              <input
                value={form.client_name}
                onChange={e => setForm({...form, client_name: e.target.value})}
                placeholder="John Mitchell"
              />
            </div>

            <div className="form-row">
              <div className="form-group">
                <label>Platform</label>
                <select
                  value={form.platform_id}
                  onChange={e => setForm({...form, platform_id: parseInt(e.target.value)})}
                >
                  <option value={1}>Fiverr</option>
                  <option value={2}>Upwork</option>
                  <option value={3}>Direct</option>
                </select>
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
                  <option value="AED">AED</option>
                  <option value="CAD">CAD</option>
                </select>
              </div>
            </div>

            <div className="form-group">
              <label>Country</label>
              <input
                value={form.country}
                onChange={e => setForm({...form, country: e.target.value})}
                placeholder="United States"
              />
            </div>

            <div className="modal-actions">
              <button className="btn-secondary" onClick={() => { setModal(false); resetForm(); }}>
                Cancel
              </button>
              <button className="btn-primary" onClick={handleCreate}>
                <Plus size={16} /> Add Client
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}