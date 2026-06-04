import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const projectRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const read = (path) => readFileSync(join(projectRoot, path), 'utf8');
const fail = (message) => {
  throw new Error(message);
};

const auth = read('ExpiryAlert/Services/AuthViewModel.swift');
for (const snippet of [
  'ProductMode',
  'productMode',
  'isLocalMode',
  'startLocalMode',
  'prepareCloudLogin',
  'expiry_alert_ios_product_mode',
]) {
  if (!auth.includes(snippet)) {
    fail(`AuthViewModel local mode snippet missing: ${snippet}`);
  }
}

const content = read('ExpiryAlert/App/ContentView.swift');
for (const snippet of [
  'authViewModel.isLocalMode',
  'MainTabView()',
  'LoginView()',
]) {
  if (!content.includes(snippet)) {
    fail(`ContentView local mode snippet missing: ${snippet}`);
  }
}

const dataStore = read('ExpiryAlert/Services/DataStore.swift');
for (const snippet of [
  'LocalDataExport',
  'notificationService',
  'refreshExpiryNotifications',
  'scheduleExpiryNotifications(for: activeFoodItems)',
  'localStorageURL',
  'loadLocalData',
  'saveLocalData',
  'exportLocalData',
  'importLocalData',
  'localGroups(from:',
  'UserDefaults.standard.set(localGroupId, forKey: activeGroupIdKey)',
  'guard authViewModel?.isLocalMode != true else',
]) {
  if (!dataStore.includes(snippet)) {
    fail(`DataStore local persistence snippet missing: ${snippet}`);
  }
}

const app = read('ExpiryAlert/App/ExpiryAlertApp.swift');
for (const snippet of [
  'NotificationService()',
  'dataStore.configure(authViewModel: authViewModel, notificationService: notificationService)',
]) {
  if (!app.includes(snippet)) {
    fail(`ExpiryAlertApp notification wiring snippet missing: ${snippet}`);
  }
}

const login = read('ExpiryAlert/Views/Auth/LoginView.swift');
for (const snippet of [
  'continueLocal',
  'startLocalMode',
  'localModeNote',
]) {
  if (!login.includes(snippet)) {
    fail(`LoginView local mode snippet missing: ${snippet}`);
  }
}

const settings = read('ExpiryAlert/Views/Settings/SettingsView.swift');
for (const snippet of [
  'exportLocalData',
  'importLocalData',
  'Private Local Mode',
  'cloudOnlyFeatureTitle',
  'prepareCloudLogin',
]) {
  if (!settings.includes(snippet)) {
    fail(`SettingsView local export/import snippet missing: ${snippet}`);
  }
}

console.log('iOS Phase 2 local mode checks passed.');
