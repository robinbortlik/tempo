import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import react from '@vitejs/plugin-react'
import { resolve } from 'path'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    react(),
  ],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'app/frontend'),
    },
  },
})
