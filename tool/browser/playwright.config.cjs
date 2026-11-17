const { defineConfig } = require('@playwright/test');
module.exports = defineConfig({
  testDir: '.', testMatch: '*.spec.cjs', timeout: 60000,
  use: { headless: true, channel: 'chrome', baseURL: 'http://127.0.0.1:8765' },
  webServer: { command: 'python3 -m http.server 8765 --bind 127.0.0.1 --directory ../../build/web', port: 8765 },
});
