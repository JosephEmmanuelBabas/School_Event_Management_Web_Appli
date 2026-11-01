import { BrowserRouter, Route, Routes } from 'react-router'
import AuthProvider from './auth/AuthProvider'
import RequireAuth from './auth/RequireAuth'
import AppLayout from './components/AppLayout'
import NotificationProvider from './components/notifications/NotificationProvider'
import HomePage from './pages/HomePage'
import LoginPage from './pages/LoginPage'
import NotFoundPage from './pages/NotFoundPage'
import VenuesPage from './pages/venues/VenuesPage'
import ParticipantsPage from './pages/participants/ParticipantsPage'
import EventsPage from './pages/events/EventsPage'

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
                <Route path="/venues" element={<VenuesPage />} />
                <Route path="/participants" element={<ParticipantsPage />} />
                <Route path="/events" element={<EventsPage />} />
                <Route path="*" element={<NotFoundPage />} />
              </Route>
            </Route>
          </Routes>
        </AuthProvider>
      </NotificationProvider>
    </BrowserRouter>
  )
}