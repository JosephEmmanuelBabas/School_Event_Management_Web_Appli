import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'




// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],

    server: {
    port: 5173,
    strictPort: true, // fail loudly instead of silently switching ports
    proxy: {
      // The browser calls /api/... on port 5173; Vite forwards it to Spring Boot.
      '/api': 'http://localhost:8080',
    },
  },

})
