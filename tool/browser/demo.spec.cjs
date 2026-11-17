const { test, expect } = require('@playwright/test');
async function boot(page) {
  await page.goto('/');
  await page.locator('flt-semantics-placeholder').evaluate(e => e.click());
  await expect(page.getByText('DEMO — All records', { exact: false })).toBeVisible();
}
test('reload, independent tabs and browser storage', async ({ page, context }) => {
  await boot(page);
  await page.getByRole('button', { name: 'Add fictional medication' }).click();
  await page.getByRole('textbox').fill('Fictional browser edit');
  await page.getByRole('button', { name: 'Add', exact: true }).click();
  await expect(page.getByText('Fictional browser edit', { exact: false })).toBeVisible();
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
  await expect(second.getByText('Fictional browser edit', { exact: false })).toHaveCount(0);
  await page.reload();
  await page.locator('flt-semantics-placeholder').evaluate(e => e.click());
  await expect(page.getByText('DEMO — All records', { exact: false })).toBeVisible();
  await expect(page.getByText('Fictional browser edit', { exact: false })).toHaveCount(0);
});
