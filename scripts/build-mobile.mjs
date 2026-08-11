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
  await cp(resolve(root, file), target);
}

const indexPath = resolve(out, "index.html");
const html = await readFile(indexPath, "utf8");
await writeFile(
  indexPath,
  html.replace(
    "<body>",
    '<body data-native-shell="capacitor">',
  ),
  "utf8",
);

console.log(`Prepared Capacitor web assets in ${out}`);
