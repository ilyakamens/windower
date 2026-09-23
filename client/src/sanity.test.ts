import { expect, test } from 'vitest';

test('app element exists in index.html', async () => {
  const html = await import('node:fs/promises').then((fs) =>
    fs.readFile(new URL('../index.html', import.meta.url), 'utf-8'),
  );
  expect(html).toContain('id="app"');
});
