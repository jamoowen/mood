const assert = require('assert');

global.window = {};
require('../Board/calendar.js');
require('../Board/store.js');

const C = global.window.MoodCalendar;
const S = global.window.MoodStore;

// October 2026 begins on a Thursday; weeks start on Monday.
const weeks = C.weeksOfMonth('2026-10');
assert.strictEqual(weeks.length, 5, 'October 2026 spans 5 Monday-start weeks');
assert.strictEqual(weeks[0].key, '2026-09-28', 'first week starts on the preceding Monday');
assert.strictEqual(weeks[0].days[0].key, '2026-09-28');
assert.strictEqual(weeks[0].days[3].key, '2026-10-01');
assert.strictEqual(weeks[0].days[3].inMonth, true, 'Oct 1 is inside the month');
assert.strictEqual(weeks[0].days[0].inMonth, false, 'Sep 28 is an adjoining date');
assert.strictEqual(weeks[4].key, '2026-10-26');
assert.strictEqual(weeks[4].days[6].key, '2026-11-01', 'last week reaches into November');

assert.strictEqual(C.monthTitle('2026-10'), 'October 2026');
assert.strictEqual(C.shiftMonth('2026-10', 1), '2026-11');
assert.strictEqual(C.shiftMonth('2026-10', -1), '2026-09');
assert.strictEqual(C.shiftMonth('2026-12', 1), '2027-01');

// Store: monthly goals.
const data = S.emptyData();
const goal = S.addMonthly(data, '2026-10', 'Ship it');
assert.strictEqual(data.months['2026-10'].monthlyGoals.length, 1);
assert.strictEqual(goal.text, 'Ship it');
assert.strictEqual(goal.done, false);
assert.strictEqual(S.toggleMonthly(data, '2026-10', goal.id), true);
assert.strictEqual(goal.done, true);
S.updateMonthly(data, '2026-10', goal.id, 'Shipped');
assert.strictEqual(goal.text, 'Shipped');
S.removeMonthly(data, '2026-10', goal.id);
assert.strictEqual(data.months['2026-10'].monthlyGoals.length, 0);

// Store: weekly goals and theme.
S.addWeekly(data, '2026-09-28', 'Plan the week');
assert.strictEqual(data.weeks['2026-09-28'].length, 1);
S.setTheme(data, '2026-10', 'Build momentum');
assert.strictEqual(data.months['2026-10'].theme, 'Build momentum');

console.log('All calendar and store tests passed.');
