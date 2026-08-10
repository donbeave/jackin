/**
 * Capture HTML SoT baselines for QI (QI_VERIFICATION scene catalog).
 * Usage:
 *   node plans/previews/desktop-ui/qi/capture-html-baselines.mjs [outDir]
 */
import { chromium } from "playwright";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");
const outDir = path.resolve(process.argv[2] || path.join(root, "../../../advisor-plans/qi-artifacts/html"));
fs.mkdirSync(outDir, { recursive: true });

const indexUrl = "file://" + path.join(root, "index.html");
const popoverUrl = "file://" + path.join(root, "popover.html");

async function setTheme(page, theme) {
  await page.evaluate((t) => {
    document.documentElement.setAttribute("data-theme", t);
  }, theme);
}

async function shot(page, name) {
  const file = path.join(outDir, name);
  await page.screenshot({ path: file, fullPage: false });
  console.log("WROTE", file);
}

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1100, height: 900 } });

for (const theme of ["dark", "light"]) {
  // --- index hub: status desktop ---
  await page.goto(indexUrl);
  await setTheme(page, theme);
  await page.click('button[data-panel="flow"]');
  await page.waitForTimeout(200);
  const flow = page.locator("#flow .desktop, #flow-stage").first();
  if (await flow.count()) {
    await flow.screenshot({ path: path.join(outDir, `status-desktop-${theme}.png`) });
    console.log("WROTE", `status-desktop-${theme}.png`);
  } else {
    await shot(page, `status-desktop-${theme}.png`);
  }

  // --- usage window panel ---
  await page.click('button[data-panel="usage"]');
  await page.waitForTimeout(200);
  const usageDesktop = page.locator("#usage .desktop").first();
  if (await usageDesktop.count()) {
    await usageDesktop.screenshot({
      path: path.join(outDir, `usage-window-${theme}.png`),
    });
    console.log("WROTE", `usage-window-${theme}.png`);
  }
  const usageWin = page.locator("#usage-win").first();
  if (await usageWin.count()) {
    await usageWin.screenshot({
      path: path.join(outDir, `usage-detail-openai-${theme}.png`),
    });
    console.log("WROTE", `usage-detail-openai-${theme}.png`);
    // try select overview
    const ov = page.locator('#usage-win [data-nav="overview"]').first();
    if (await ov.count()) {
      await ov.click();
      await page.waitForTimeout(150);
      await usageWin.screenshot({
        path: path.join(outDir, `usage-overview-${theme}.png`),
      });
      console.log("WROTE", `usage-overview-${theme}.png`);
    }
    const openai = page.locator('#usage-win [data-nav="openai"]').first();
    if (await openai.count()) {
      await openai.click();
      await page.waitForTimeout(150);
      await usageWin.screenshot({
        path: path.join(outDir, `usage-provider-nest-${theme}.png`),
      });
      console.log("WROTE", `usage-provider-nest-${theme}.png`);
    }
    // toolbar crop from top of win
    const box = await usageWin.boundingBox();
    if (box) {
      await page.screenshot({
        path: path.join(outDir, `usage-toolbar-${theme}.png`),
        clip: { x: box.x, y: box.y, width: box.width, height: Math.min(60, box.height) },
      });
      console.log("WROTE", `usage-toolbar-${theme}.png`);
    }
  }
}

// --- popover standalone (full plate: Session + Weekly meters, not mid-SESSION crop) ---
// Expand max-height/overflow so multi-limit heroes are in the PNG (live menu-bar still clips+scrolls).
const expandCss = `
  html, body { height: auto !important; overflow: visible !important; }
  .pop, html.embed .pop { max-height: none !important; height: auto !important; overflow: visible !important; }
  .pop .inner, .scroll-shell, .ov-scroll, .detail-scroll {
    max-height: none !important; min-height: 0 !important; flex: none !important;
    overflow: visible !important; mask-image: none !important; -webkit-mask-image: none !important;
  }
`;
for (const theme of ["dark", "light"]) {
  for (const [provider, name] of [
    ["openai", "popover-openai"],
    ["anthropic", "popover-anthropic"],
  ]) {
    const url = `${popoverUrl}?embed=1&mode=providers&provider=${provider}&theme=${theme}`;
    await page.goto(url);
    await page.setViewportSize({ width: 520, height: 1800 });
    await page.addStyleTag({ content: expandCss });
    await page.waitForTimeout(400);
    const pop = page.locator("#app.pop, .card-popover .pop, .pop").first();
    if (await pop.count()) {
      await pop.screenshot({
        path: path.join(outDir, `${name}-${theme}.png`),
      });
    } else {
      await page.screenshot({
        path: path.join(outDir, `${name}-${theme}.png`),
        fullPage: true,
      });
    }
    console.log("WROTE", `${name}-${theme}.png`);
  }
}

await browser.close();
console.log("DONE html baselines →", outDir);
