#!/usr/bin/env node
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const original = readFileSync(resolve(root, 'docs/index.html'), 'utf8');
const english = JSON.parse(readFileSync(resolve(root, 'scripts/site-en.json'), 'utf8'));
const expected = new Set([...original.matchAll(/\bdata-copy="([^"]+)"/g)].map(match => match[1]));
const replaced = new Set();
const escape = text => text.replaceAll('&', '&amp;').replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;').replaceAll('"', '&quot;').replaceAll("'", '&#39;');
let page = original.replace(/(<([a-z][\w-]*)\b[^>]*\bdata-copy="([^"]+)"[^>]*>)([^<]*)(<\/\2>)/g,
  (full, opening, tag, key, text, closing) => {
    if (typeof english[key] !== 'string') throw new Error(`Missing English copy: ${key}`);
    replaced.add(key);
    return opening + escape(english[key]) + closing;
  });
for (const key of expected) {
  if (!replaced.has(key)) throw new Error(`Could not translate element: ${key}`);
}
page = page.replace('<html lang="ko">', '<html lang="en">')
  .replace(/<title>[^<]+<\/title>/, `<title>${escape(english.pageTitle)}</title>`)
  .replace(/(<meta name="description" content=")[^"]+/, `$1${escape(english.metaDescription)}`)
  .replace(/(<meta property="og:title" content=")[^"]+/, `$1${escape(english.pageTitle)}`)
  .replace(/(<meta property="og:description" content=")[^"]+/, `$1${escape(english.metaDescription)}`)
  .replace('content="ko_KR"', 'content="en_US"')
  .replace(/(<meta property="og:url" content=")[^"]+/, '$1https://s4lmon-sh.github.io/BookmarkPet/en/')
  .replace(/(<link rel="canonical" href=")[^"]+/, '$1https://s4lmon-sh.github.io/BookmarkPet/en/')
  .replaceAll('href="assets/', 'href="../assets/')
  .replaceAll('src="assets/', 'src="../assets/')
  .replaceAll('src="images/', 'src="../images/')
  .replace('<a href="./" lang="ko" aria-current="page" data-language="ko">', '<a href="../" lang="ko" data-language="ko">')
  .replace('<a href="en/" lang="en" data-language="en">', '<a href="./" lang="en" aria-current="page" data-language="en">')
  .replaceAll('README.ko.md#소스에서-빌드하기', 'README.md#build-from-source')
  .replaceAll('README.ko.md', 'README.md')
  .replaceAll('https://support.apple.com/ko-kr/102445', 'https://support.apple.com/en-us/102445')
  .replace('>메모 있음 · ! 배지 켜짐</p>', '>Note waiting · ! badge on</p>')
  .replace('기획안 첫 문단 다듬기\n참고 자료 2개 확인하기</textarea>', 'Polish the first paragraph\nFind two references</textarea>');
mkdirSync(resolve(root, 'docs/en'), { recursive: true });
writeFileSync(resolve(root, 'docs/en/index.html'), page);
console.log(`Built English page: ${replaced.size} translated elements; no external dependencies.`);
