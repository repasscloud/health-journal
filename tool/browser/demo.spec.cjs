const { test, expect } = require('@playwright/test');
async function boot(page) {
  await page.goto('/');
  await page.locator('flt-semantics-placeholder').evaluate(e => e.click());
  await page.getByText('DEMO — All records', { exact: false }).waitFor({ timeout: 10000 });
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
    databases: await indexedDB.databases(),
    opfs: await (async () => {
      const root = await navigator.storage.getDirectory();
      const names = [];
      for await (const name of root.keys()) names.push(name);
      return names;
    })(),
  }));
  expect(JSON.stringify(storage)).not.toContain('Fictional browser edit');
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
  await page.getByRole('textbox', { name: 'Search timeline' }).click();
  await expect(page.getByRole('textbox', { name: 'Search timeline' })).toBeFocused();
  await page.getByRole('textbox', { name: 'Search timeline' }).press('ControlOrMeta+A', { delay: 100 });
  await page.getByRole('textbox', { name: 'Search timeline' }).pressSequentially('72.25', { delay: 100 });
  await expect(page.getByText(/Weight · 72.25 kg/)).toBeVisible();
  expect(await page.evaluate(() => JSON.stringify({ ...localStorage, ...sessionStorage }))).not.toContain('72.25');
  await page.reload();
  await page.locator('flt-semantics-placeholder').evaluate(e => e.click());
  await page.getByText('DEMO — All records', { exact: false }).waitFor({ timeout: 10000 });
  await page.getByRole('tab', { name: 'Timeline', exact: true }).click();
  await page.getByRole('textbox', { name: 'Search timeline' }).click();
  await expect(page.getByRole('textbox', { name: 'Search timeline' })).toBeFocused();
  await page.getByRole('textbox', { name: 'Search timeline' }).press('ControlOrMeta+A', { delay: 100 });
  await page.getByRole('textbox', { name: 'Search timeline' }).pressSequentially('72.25', { delay: 100 });
  await expect(page.getByText('No matching events.')).toBeVisible();
});
