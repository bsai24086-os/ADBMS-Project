import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard, Users, FolderOpen,
  FileText, CreditCard, Receipt, Calculator
} from 'lucide-react';
import './Sidebar.css';

const links = [
  { to: '/dashboard', icon: LayoutDashboard, label: 'Dashboard'  },
  { to: '/clients',   icon: Users,           label: 'Clients'    },
  { to: '/projects',  icon: FolderOpen,      label: 'Projects'   },
  { to: '/invoices',  icon: FileText,        label: 'Invoices'   },
  { to: '/payments',  icon: CreditCard,      label: 'Payments'   },
  { to: '/expenses',  icon: Receipt,         label: 'Expenses'   },
  { to: '/tax',       icon: Calculator,      label: 'FBR Tax'    },
];

export default function Sidebar() {
  return (
    <aside className="sidebar">
      <div className="sidebar-logo">
        <div className="logo-icon">₨</div>
        <div>
          <div className="logo-name">HisaabPro</div>
          <div className="logo-sub">Financial Intelligence</div>
        </div>
      </div>

      <nav className="sidebar-nav">
        {links.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            className={({ isActive }) =>
              `nav-link ${isActive ? 'nav-link-active' : ''}`
            }
          >
            <Icon size={18} />
            <span>{label}</span>
          </NavLink>
        ))}
      </nav>

      <div className="sidebar-footer">
        <div className="sidebar-user">
          <div className="user-avatar">AR</div>
          <div>
            <div className="user-name">Ahmed Raza</div>
            <div className="user-status">● Filer</div>
          </div>
        </div>
      </div>
    </aside>
  );
}