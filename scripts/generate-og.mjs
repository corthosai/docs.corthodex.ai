// One-off generator for the OpenGraph card at public/og.png.
//
// Run: node scripts/generate-og.mjs
//
// Re-run when the logo, brand color, or wordmark changes. Output is
// committed; build does not invoke this.

import sharp from 'sharp';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, '..');

const logoPath = resolve(root, 'src/assets/logo.svg');
const outPath = resolve(root, 'public/og.png');

// Read the corthos logo and force its fill to white (it has a CSS
// dark-mode rule that sharp/librsvg won't honor since we're rasterizing
// to a PNG with no theme context).
const logoRaw = readFileSync(logoPath, 'utf8');
const logoWhite = logoRaw
	.replace(/<style>[\s\S]*?<\/style>/, '')
	.replace('<path ', '<path fill="#ffffff" ');

// Compose the OG card. 1200×630 is the canonical OpenGraph size.
// Embedding the logo as an inline <svg> rather than a separate <image>
// element keeps everything in one rasterization pass.
const ogSvg = `
<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
  <rect width="1200" height="630" fill="#131e4f"/>
  <g transform="translate(472, 110) scale(2)">
    ${logoWhite.replace(/<\/?svg[^>]*>/g, '')}
  </g>
  <text x="600" y="490" text-anchor="middle"
        font-family="Inter, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
        font-size="68" font-weight="700" fill="#ffffff">
    Corthodex API
  </text>
  <text x="600" y="555" text-anchor="middle"
        font-family="Inter, system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
        font-size="28" font-weight="400" fill="#c0cdfb">
    Education + employment data REST API documentation
  </text>
</svg>
`;

await sharp(Buffer.from(ogSvg))
	.png({ compressionLevel: 9 })
	.toFile(outPath);

console.log(`✓ wrote ${outPath}`);
