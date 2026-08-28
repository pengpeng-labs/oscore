import { readFileSync, readdirSync } from 'node:fs';
import { extname, join } from 'node:path';

const forbidden = [/\b(outb|inb|cli|sti|hlt)\s*\(/, /0xB8000/i];
for (const name of readdirSync('src')) {
  if (!name.endsWith('.pp') || name === 'platform.pp') continue;
  const text = readFileSync(join('src', name), 'utf8');
  for (const pattern of forbidden) {
    if (pattern.test(text)) throw new Error(`${name}: direct hardware access is forbidden`);
  }
  if (text.includes('@osbare/')) {
    throw new Error(`${name}: only platform.pp may import osbare`);
  }
}

const textExtensions = new Set(['.md', '.pp', '.sh', '.mjs', '.toml', '.yml']);
function checkTextTree(directory) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    if (['.git', 'build', 'target'].includes(entry.name)) continue;
    const path = join(directory, entry.name);
    if (entry.isDirectory()) {
      checkTextTree(path);
      continue;
    }
    if (!textExtensions.has(extname(entry.name)) && entry.name !== 'VERSION') continue;
    const content = readFileSync(path, 'utf8');
    if (!content.endsWith('\n') || content.endsWith('\n\n')) {
      throw new Error(`${path}: expected exactly one final newline`);
    }
    if (/[ \t]+$/m.test(content)) {
      throw new Error(`${path}: trailing whitespace`);
    }
  }
}

checkTextTree('.');
console.log('OSCORE REPOSITORY PASS');
