import { useState, useEffect } from 'react';
import { useLocation }         from 'react-router-dom';
import { Bell, X }             from 'lucide-react';
import { getNotifications, markNotificationRead } from '../api';
import './TopBar.css';

const titles = {
  '/dashboard': 'Dashboard',
  '/clients':   'Clients',
  '/projects':  'Projects',
  '/invoices':  'Invoices',
  '/payments':  'Payments',
  '/expenses':  'Expenses',
  '/tax':       'FBR Tax Report',
};

export default function TopBar() {
  const location = useLocation();
  const [notifs, setNotifs]     = useState([]);
  const [showPanel, setShow]    = useState(false);

  useEffect(() => {
    getNotifications()
      .then(r => setNotifs(r.data))
      .catch(() => {});
  }, []);

  const dismiss = (id) => {
    markNotificationRead(id)
      .then(() => setNotifs(n => n.filter(x => x.notification_id !== id)))
      .catch(() => {});
  };

  return (
    <header className="topbar">
      <div className="topbar-title">
        {titles[location.pathname] || 'HisaabPro'}
      </div>

      <div className="topbar-right">
        <div className="notif-wrap">
          <button
            className="notif-btn"
            onClick={() => setShow(s => !s)}
          >
            <Bell size={18} />
            {notifs.length > 0 &&
              <span className="notif-badge">{notifs.length}</span>
            }
          </button>

          {showPanel && (
            <div className="notif-panel">
              <div className="notif-header">
                <span>Notifications</span>
                <button onClick={() => setShow(false)}>
                  <X size={14} />
                </button>
              </div>
              {notifs.length === 0
                ? <p className="notif-empty">All caught up!</p>
                : notifs.map(n => (
                  <div key={n.notification_id} className="notif-item">
                    <div className={`notif-dot notif-${n.type}`} />
                    <p>{n.message}</p>
                    <button onClick={() => dismiss(n.notification_id)}>
                      <X size={12} />
                    </button>
                  </div>
                ))
              }
            </div>
          )}
        </div>

        <div className="topbar-date">
          {new Date().toLocaleDateString('en-PK', {
            weekday: 'short', month: 'short', day: 'numeric'
          })}
        </div>
      </div>
    </header>
  );
}