import { expect, test } from '@playwright/test';

test('home page renders greeting', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('heading', { name: 'Hi.' })).toBeVisible();
});
