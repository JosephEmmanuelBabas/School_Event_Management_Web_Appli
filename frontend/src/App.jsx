import { BrowserRouter, Route, Routes } from 'react-router'
import AuthProvider from './auth/AuthProvider'
import RequireAuth from './auth/RequireAuth'
import AppLayout from './components/AppLayout'
import NotificationProvider from './components/notifications/NotificationProvider'
import DashboardPage from './pages/dashboard/DashboardPage'
import EventDetailPage from './pages/events/EventDetailPage'
import EventsPage from './pages/events/EventsPage'
import HomePage from './pages/HomePage'
import LoginPage from './pages/LoginPage'
import NotFoundPage from './pages/NotFoundPage'
import ParticipantsPage from './pages/participants/ParticipantsPage'
import ReportsPage from './pages/reports/ReportsPage'
import VenuesPage from './pages/venues/VenuesPage'

export default function App() {
  return (
    <BrowserRouter>
      <NotificationProvider>
        <AuthProvider>
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route element={<RequireAuth />}>
              <Route element={<AppLayout />}>
                <Route path="/" element={<HomePage />} />
                <Route path="/events" element={<EventsPage />} />
                <Route path="/events/:eventId" element={<EventDetailPage />} />
                <Route path="/venues" element={<VenuesPage />} />
                <Route path="/participants" element={<ParticipantsPage />} />

                {/* Super Admin only. The server enforces this too. */}
                <Route element={<RequireAuth roles={['Super Admin']} />}>
                  <Route path="/dashboard" element={<DashboardPage />} />
                  <Route path="/reports" element={<ReportsPage />} />
                </Route>

                <Route path="*" element={<NotFoundPage />} />
              </Route>
            </Route>
          </Routes>
        </AuthProvider>
      </NotificationProvider>
    </BrowserRouter>
  )
}