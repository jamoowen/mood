(function () {
  'use strict';

  var MONTHS = ['January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'];

  function pad(n) { return String(n).padStart(2, '0'); }

  function keyOf(date) {
    return date.getFullYear() + '-' + pad(date.getMonth() + 1) + '-' + pad(date.getDate());
  }

  function monthKeyOf(date) {
    return date.getFullYear() + '-' + pad(date.getMonth() + 1);
  }

  function addDays(date, n) {
    var d = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    d.setDate(d.getDate() + n);
    return d;
  }

  // Weeks start on Monday (ISO-style). Returns the Monday on or before `date`.
  function mondayOf(date) {
    var d = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    var dow = (d.getDay() + 6) % 7;
    d.setDate(d.getDate() - dow);
    return d;
  }

  function monthTitle(monthKey) {
    var parts = monthKey.split('-').map(Number);
    return MONTHS[parts[1] - 1] + ' ' + parts[0];
  }

  function shiftMonth(monthKey, delta) {
    var parts = monthKey.split('-').map(Number);
    var d = new Date(parts[0], parts[1] - 1 + delta, 1);
    return monthKeyOf(d);
  }

  // Full month grouped into weeks, including adjoining dates from the previous
  // and next months. Each week is keyed by its Monday.
  function weeksOfMonth(monthKey) {
    var parts = monthKey.split('-').map(Number);
    var first = new Date(parts[0], parts[1] - 1, 1);
    var last = new Date(parts[0], parts[1], 0);
    var weeks = [];
    var cursor = mondayOf(first);
    while (cursor <= last) {
      var days = [];
      for (var i = 0; i < 7; i++) {
        var d = addDays(cursor, i);
        days.push({
          date: d,
          key: keyOf(d),
          dayNum: d.getDate(),
          inMonth: d.getFullYear() === parts[0] && d.getMonth() === parts[1] - 1
        });
      }
      weeks.push({ key: keyOf(cursor), days: days });
      cursor = addDays(cursor, 7);
    }
    return weeks;
  }

  window.MoodCalendar = {
    keyOf: keyOf,
    monthKeyOf: monthKeyOf,
    addDays: addDays,
    mondayOf: mondayOf,
    monthTitle: monthTitle,
    shiftMonth: shiftMonth,
    weeksOfMonth: weeksOfMonth
  };
})();
