#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
let colors = require('tailwindcss/colors');

function mkScssContent() {
  const scssLines = [];
  scssLines.push('// Tailwind colour variables generated automatically, do not edit');
  scssLines.push('');

  Object.entries(colors).forEach(([colorName, colorValues]) => {
    if (typeof colorValues == 'object' && colorValues != null) {
      Object.entries(colorValues).forEach(([shade, value]) => {
        scssLines.push(`$${colorName}-${shade}: ${value};`);
      });
    }
  });

  return scssLines.join('\n');
}

function main() {
  const externDir = path.join(__dirname, '..', 'assets', 'scss', 'extern');
  if (!fs.existsSync(externDir)) {
    fs.mkdirSync(externDir, { recursive: true });
  }

  const outputPath = path.join(externDir, 'tailwind-colors.scss');
  fs.writeFileSync(outputPath, mkScssContent());

  console.log(`wrote to: ${outputPath}`);
  console.log(`made ${Object.keys(colors).length} color families`);
}

if (require.main === module) {
  main();
}
