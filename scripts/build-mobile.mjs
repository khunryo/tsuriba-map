import { cp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";

const root = resolve(import.meta.dirname, "..");
const out = resolve(root, "www");
const files = [
  "index.html",
  "manifest.webmanifest",
  "bait_live.json",
  "bathy.json",
  "tide_stations.json",
  "privacy.html",
  "terms.html",
  "support.html",
  "tide_data",
  "icon-192.png",
  "icon-512.png",
  "icon-512-maskable.png",
  "apple-touch-icon-180.png",
  "assets/fish-species-sprite-v1.png",
];

await rm(out, { recursive: true, force: true });
for (const file of files) {
  const target = resolve(out, file);
  await mkdir(dirname(target), { recursive: true });
  await cp(resolve(root, file), target, { recursive: true });
}

await mkdir(resolve(out, "assets"), { recursive: true });
await cp(
  resolve(root, "node_modules/@capacitor/core/dist/capacitor.js"),
  resolve(out, "assets/capacitor-runtime.js"),
);
await cp(
  resolve(root, "node_modules/@capacitor-community/admob/dist/plugin.js"),
  resolve(out, "assets/admob-plugin.js"),
);
const androidBannerId = process.env.ADMOB_ANDROID_BANNER_ID
  || "ca-app-pub-3940256099942544/6300978111";
const admobScript = await readFile(resolve(root, "scripts/admob-mobile.js"), "utf8");
await writeFile(
  resolve(out, "assets/admob-mobile.js"),
  admobScript.replaceAll("__ADMOB_ANDROID_BANNER_ID__", androidBannerId),
  "utf8",
);

const indexPath = resolve(out, "index.html");
const html = await readFile(indexPath, "utf8");
await writeFile(
  indexPath,
  html.replace(
    "<body>",
    '<body data-native-shell="capacitor">',
  ).replace(
    "</body>",
    '<script src="assets/capacitor-runtime.js"></script><script src="assets/admob-plugin.js"></script><script src="assets/admob-mobile.js"></script></body>',
  ),
  "utf8",
);

console.log(`Prepared Capacitor web assets in ${out}`);
