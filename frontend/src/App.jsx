import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Sidebar from './components/Sidebar';
import TopBar  from './components/TopBar';
import Dashboard  from './pages/Dashboard';
import Clients    from './pages/Clients';
import Projects   from './pages/Projects';
import Invoices   from './pages/Invoices';
import Payments   from './pages/Payments';
import Expenses   from './pages/Expenses';
import TaxReport  from './pages/TaxReport';
import './App.css';

export default function App() {
  return (
    <BrowserRouter>
      <div className="app-layout">
        <Sidebar />
        <div className="main-area">
          <TopBar />
          <div className="content-area">
            <Routes>
              <Route path="/"          element={<Navigate to="/dashboard" />} />
              <Route path="/dashboard" element={<Dashboard />} />
              <Route path="/clients"   element={<Clients />} />
              <Route path="/projects"  element={<Projects />} />
              <Route path="/invoices"  element={<Invoices />} />
              <Route path="/payments"  element={<Payments />} />
              <Route path="/expenses"  element={<Expenses />} />
              <Route path="/tax"       element={<TaxReport />} />
            </Routes>
          </div>
        </div>
      </div>
    </BrowserRouter>
  );
}