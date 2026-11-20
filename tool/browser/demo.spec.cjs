const { test: base, expect, webkit } = require('@playwright/test');

const test = base.extend({
  context: async ({ context, browserName, baseURL }, use, testInfo) => {
    if (browserName !== 'webkit') {
      await use(context);
      return;
    }
    // WebKit rejects OPFS access in an ephemeral context. A fresh on-disk
    // profile lets this test inspect the same storage available in normal use.
    const profile = await webkit.launchPersistentContext(
      testInfo.outputPath('webkit-profile'), { baseURL, headless: true },
    );
    try {
      await use(profile);
    } finally {
      await profile.close();
    }
  },
});
async function boot(page) {
  await page.goto('/');
  await page.locator('flt-semantics-placeholder').evaluate(e => e.click());
  await page.getByText('DEMO — All records', { exact: false }).waitFor({ timeout: 10000 });
}
async function searchTimeline(page, query) {
  const field = page.getByRole('textbox', { name: 'Search timeline' });
  // Flutter Web applies the field's editing attributes only after attaching
  // its input client to the semantics textbox.
  await expect(async () => {
    await field.click();
    await expect(field).toHaveAttribute('autocorrect', 'on', { timeout: 750 });
    await expect(field).toBeFocused({ timeout: 750 });
    await field.fill(query);
    await expect(field).toHaveValue(query, { timeout: 750 });
  }).toPass({ timeout: 8000 });
}
test('reload, independent tabs and browser storage', async ({ page, context }) => {
  await boot(page);
  await page.getByRole('tab', { name: 'Medications', exact: true }).click();
  await page.getByRole('button', { name: 'Add medication' }).click();
  const name = page.getByRole('textbox', { name: 'Medication name', exact: true });
  await name.click();
  await expect(name).toBeFocused();
  await name.press('ControlOrMeta+A', { delay: 100 });
  await page.keyboard.insertText('Fictional browser edit');
  await expect(name).toHaveValue('Fictional browser edit');
  await page.getByRole('button', { name: 'Add', exact: true }).click();
  await expect(page.getByText('Fictional browser edit', { exact: true })).toBeVisible();
  const storage = await page.evaluate(async () => ({
    local: { ...localStorage }, session: { ...sessionStorage },
    caches: await caches.keys(),
    databases: await indexedDB.databases(),
    opfs: await (async () => {
      const root = await navigator.storage.getDirectory();
      const names = [];
      for await (const name of root.keys()) names.push(name);
      return names;
    })(),
  }));
  expect(storage.local).toEqual({});
  expect(storage.session).toEqual({});
  expect(storage.caches).toEqual([]);
  expect(storage.databases).toEqual([]);
  expect(storage.opfs).toEqual([]);
  const second = await context.newPage();
  await boot(second);
  await second.getByRole('tab', { name: 'Medications', exact: true }).click();
  await expect(second.getByText('Fictional browser edit', { exact: true })).toHaveCount(0);
  await page.reload();
  await page.locator('flt-semantics-placeholder').evaluate(e => e.click());
  await page.getByText('DEMO — All records', { exact: false }).waitFor({ timeout: 10000 });
  await page.getByRole('tab', { name: 'Medications', exact: true }).click();
  await expect(page.getByText('Fictional browser edit', { exact: true })).toHaveCount(0);
});
test('manual measurement remains and resets on reload', async ({ page }) => {
  await boot(page);
  await page.getByRole('button', { name: 'Record measurement' }).click();
  await expect(page.getByText('DEMO — All records', { exact: false })).toBeVisible();
  await page.getByRole('textbox', { name: /Value/ }).click();
  const value = page.getByRole('textbox', { name: /Value/ });
  await expect(value).toBeFocused();
  await value.press('ControlOrMeta+A', { delay: 100 });
  await value.pressSequentially('72.25', { delay: 100 });
  await expect(value).toHaveValue('72.25');
  await page.getByRole('button', { name: 'Save measurement' }).click();
  await page.getByRole('tab', { name: 'Timeline', exact: true }).click();
  await searchTimeline(page, '72.25');
  await expect(page.getByText(/Weight · 72.25 kg/)).toBeVisible();
  expect(await page.evaluate(() => JSON.stringify({ ...localStorage, ...sessionStorage }))).not.toContain('72.25');
  await page.reload();
  await page.locator('flt-semantics-placeholder').evaluate(e => e.click());
  await page.getByText('DEMO — All records', { exact: false }).waitFor({ timeout: 10000 });
  await page.getByRole('tab', { name: 'Timeline', exact: true }).click();
  await page.getByRole('checkbox', { name: 'Measurements', exact: true }).click();
  await page.setViewportSize({ width: 1280, height: 1250 });
  await expect(page.getByText(/Weight · 72 kg/)).toBeVisible();
  await expect(page.getByText(/Weight · 72\.25 kg/)).toHaveCount(0);
});

test('demo settings identify private device features as unavailable', async ({ page }) => {
  await boot(page);
  await page.getByRole('button', { name: 'Settings' }).click();
  await expect(page.getByText('PIN and biometrics are unavailable in this build.')).toBeVisible();
  await expect(page.getByText('Encrypted backups and restore are unavailable.')).toBeVisible();
  await expect(page.getByText('This build does not send notifications.')).toBeVisible();
});
