/**
 * IIS / mpsec publish: SPA fallback + deep-link folders for /pssurvey/
 */
import { cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const site = join(root, 'dist/mp-election-survey/browser');

if (!existsSync(join(site, 'index.html'))) {
  console.error('Missing dist output:', site);
  process.exit(1);
}

writeFileSync(join(site, '.nojekyll'), '');
cpSync(join(site, 'index.html'), join(site, '404.html'));

for (const route of ['location', 'checklist']) {
  const dir = join(site, route);
  mkdirSync(dir, { recursive: true });
  cpSync(join(site, 'index.html'), join(dir, 'index.html'));
}

console.log('IIS SPA routes ready:', site);
