import { readFile } from 'node:fs/promises';
import vm from 'node:vm';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const read = (path) => readFile(resolve(root, path), 'utf8');
const fail = (message) => { throw new Error(message); };
const requireText = (source, value, label) => {
  if (!source.includes(value)) fail(`${label} is missing: ${value}`);
};

const [html, privacy, mobileHtml, mobilePrivacy, swift, scene, project] = await Promise.all([
  read('index.html'),
  read('privacy.html'),
  read('ios/App/App/public/index.html'),
  read('ios/App/App/public/privacy.html'),
  read('ios/App/App/AdRemovalPlugin.swift'),
  read('ios/App/App/SceneDelegate.swift'),
  read('ios/App/App.xcodeproj/project.pbxproj'),
]);

const scripts = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((match) => match[1]);
if (scripts.length !== 2) fail(`Expected 2 inline scripts, found ${scripts.length}`);
scripts.forEach((source, index) => new vm.Script(source, { filename:`index-inline-${index + 1}.js` }));

const stringsMatch = html.match(/const STRINGS = (\{[\s\S]*?\n    \});/);
if (!stringsMatch) fail('Could not read the translation dictionary');
const strings = vm.runInNewContext(`(${stringsMatch[1]})`);
const languages = ['ja', 'en', 'zh', 'ko', 'es'];
const referenceKeys = Object.keys(strings.ja).sort();
for (const language of languages) {
  const keys = Object.keys(strings[language] || {}).sort();
  if (JSON.stringify(keys) !== JSON.stringify(referenceKeys)) {
    fail(`Translation keys do not match for ${language}`);
  }
  for (const key of ['removeAdsTitle', 'removeAdsDescription', 'oneTimePurchase', 'removeAdsButton', 'restoreAdsPurchase', 'adFreeActive', 'purchaseError', 'restoreError']) {
    if (!strings[language][key]) fail(`Missing ${language}.${key}`);
  }
}

const expectedMobileHtml = html.replace('<body>', '<body data-native-shell="capacitor">');
if (mobileHtml !== expectedMobileHtml) fail('Capacitor index.html is not synchronized');
if (mobilePrivacy !== privacy) fail('Capacitor privacy.html is not synchronized');

requireText(html, "displayPrice", 'Localized StoreKit price UI');
requireText(html, "if (adsRemoved", 'Ad-removal gate');
requireText(html, "npa:true", 'Non-personalized ad request');
requireText(html, ".edit-item-input {", 'Editable item style');
requireText(html, "font-size:16px", 'iOS-safe input font size');
requireText(swift, 'Transaction.currentEntitlements', 'StoreKit entitlement check');
requireText(swift, 'try await AppStore.sync()', 'Explicit purchase restore');
requireText(swift, 'case .verified', 'StoreKit verification');
requireText(swift, 'jp.khunryo.forgetcheck.removeads', 'StoreKit product ID');
requireText(scene, 'BridgeViewController()', 'Custom Capacitor bridge');
requireText(project, 'AdRemovalPlugin.swift in Sources', 'Xcode source membership');
requireText(project, 'BridgeViewController.swift in Sources', 'Xcode bridge membership');
requireText(privacy, '非消費型（買い切り）', 'Japanese purchase privacy notice');
requireText(privacy, 'non-consumable, one-time in-app purchase', 'English purchase privacy notice');

console.log(`Release verification passed: ${referenceKeys.length} keys × ${languages.length} languages, StoreKit bridge, ad gate, privacy, and Capacitor assets.`);
