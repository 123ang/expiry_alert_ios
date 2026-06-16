import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const projectRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const source = readFileSync(join(projectRoot, 'ExpiryAlert/Services/NotificationService.swift'), 'utf8');

const fail = (message) => {
  throw new Error(message);
};

const scheduleStart = source.indexOf('func scheduleExpiryNotifications');
const testStart = source.indexOf('func sendTestNotification');
if (scheduleStart === -1 || testStart === -1 || testStart <= scheduleStart) {
  fail('Could not isolate scheduleExpiryNotifications section.');
}

const expiryScheduling = source.slice(scheduleStart, testStart);

for (const snippet of [
  'UNCalendarNotificationTrigger',
  'dateMatching:',
  'DateComponents',
  'scheduledDate: Date',
  'expiryDateFormatted',
  'reminderDays',
]) {
  if (!source.includes(snippet)) {
    fail(`Calendar notification scheduling snippet missing: ${snippet}`);
  }
}

for (const forbidden of [
  'timeInterval: 1',
  'timeInterval:',
  'UNTimeIntervalNotificationTrigger',
]) {
  if (expiryScheduling.includes(forbidden)) {
    fail(`Expiry notification scheduling still uses interval trigger: ${forbidden}`);
  }
}

console.log('Calendar notification scheduling checks passed.');
