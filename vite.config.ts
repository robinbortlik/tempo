import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import react from '@vitejs/plugin-react'
import { resolve } from 'path'

export default defineConfig({
  plugins: [
    react({
      include: /\.(tsx|ts|jsx|js)$/,
    }),
    RubyPlugin(),
  ],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'app/frontend'),
    },
  },
  server: {
    // Allow port override via VITE_PORT for parallel development environments
    port: process.env.VITE_PORT ? parseInt(process.env.VITE_PORT, 10) : undefined,
  },
})
