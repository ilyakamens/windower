import { fileURLToPath, URL } from 'node:url';
import { svelte } from '@sveltejs/vite-plugin-svelte';
import tailwindcss from '@tailwindcss/vite';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  plugins: [
    tailwindcss(),
    svelte(),
    {
      name: 'portless-url',
      configureServer(server) {
        const url = process.env.PORTLESS_URL;
        if (url) {
          // Display the public proxy URL instead of Vite's internal address.
          server.printUrls = () => server.config.logger.info(`  ➜  Local:   ${url}/`);
        }
      },
    },
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  test: {
    include: ['src/**/*.test.ts'],
  },
});
