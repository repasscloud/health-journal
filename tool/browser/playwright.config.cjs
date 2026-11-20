const { defineConfig } = require('@playwright/test');
module.exports = defineConfig({
  testDir: '.', testMatch: '*.spec.cjs', timeout: 60000,
  use: { headless: true, baseURL: 'http://127.0.0.1:8765' },
  projects: [
    { name: 'chrome', use: { channel: 'chrome' } },
    ...(process.env.HJ_BROWSER_MATRIX === '1' ? [
      { name: 'edge', use: { channel: 'msedge' } },
      { name: 'firefox', use: { browserName: 'firefox' } },
      { name: 'webkit', use: { browserName: 'webkit' } },
    ] : []),
  ],
  webServer: { command: 'python3 -m http.server 8765 --bind 127.0.0.1 --directory ../../build/web', port: 8765 },
});
