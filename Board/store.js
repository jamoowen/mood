(function () {
  'use strict';

  function newId() {
    return 'g-' + Date.now().toString(36) + '-' + Math.random().toString(36).slice(2, 10);
  }

  function emptyData() {
    return { version: 1, months: {}, weeks: {} };
  }

  function ensureMonth(data, monthKey) {
    if (!data.months[monthKey]) data.months[monthKey] = { theme: '', monthlyGoals: [] };
    return data.months[monthKey];
  }

  function ensureWeek(data, weekKey) {
    if (!data.weeks[weekKey]) data.weeks[weekKey] = [];
    return data.weeks[weekKey];
  }

  function makeGoal(text) {
    return { id: newId(), text: text, done: false };
  }

  function findGoal(list, id) {
    for (var i = 0; i < list.length; i++) {
      if (list[i].id === id) return list[i];
    }
    return null;
  }

  function addMonthly(data, monthKey, text) {
    var goal = makeGoal(text);
    ensureMonth(data, monthKey).monthlyGoals.push(goal);
    return goal;
  }

  function updateMonthly(data, monthKey, id, text) {
    var goal = findGoal(ensureMonth(data, monthKey).monthlyGoals, id);
    if (goal) goal.text = text;
  }

  function toggleMonthly(data, monthKey, id) {
    var goal = findGoal(ensureMonth(data, monthKey).monthlyGoals, id);
    if (goal) goal.done = !goal.done;
    return goal ? goal.done : false;
  }

  function removeMonthly(data, monthKey, id) {
    var month = ensureMonth(data, monthKey);
    month.monthlyGoals = month.monthlyGoals.filter(function (g) { return g.id !== id; });
  }

  function setTheme(data, monthKey, theme) {
    ensureMonth(data, monthKey).theme = theme;
  }

  function addWeekly(data, weekKey, text) {
    var goal = makeGoal(text);
    ensureWeek(data, weekKey).push(goal);
    return goal;
  }

  function updateWeekly(data, weekKey, id, text) {
    var goal = findGoal(ensureWeek(data, weekKey), id);
    if (goal) goal.text = text;
  }

  function toggleWeekly(data, weekKey, id) {
    var goal = findGoal(ensureWeek(data, weekKey), id);
    if (goal) goal.done = !goal.done;
    return goal ? goal.done : false;
  }

  function removeWeekly(data, weekKey, id) {
    data.weeks[weekKey] = ensureWeek(data, weekKey).filter(function (g) { return g.id !== id; });
  }

  function toggleMonthComplete(data, monthKey) {
    var goals = ensureMonth(data, monthKey).monthlyGoals;
    if (goals.length === 0) return false;
    var target = !goals.every(function (g) { return g.done; });
    goals.forEach(function (g) { g.done = target; });
    return target;
  }

  function toggleWeekComplete(data, weekKey) {
    var goals = ensureWeek(data, weekKey);
    if (goals.length === 0) return false;
    var target = !goals.every(function (g) { return g.done; });
    goals.forEach(function (g) { g.done = target; });
    return target;
  }

  window.MoodStore = {
    newId: newId,
    emptyData: emptyData,
    ensureMonth: ensureMonth,
    ensureWeek: ensureWeek,
    addMonthly: addMonthly,
    updateMonthly: updateMonthly,
    toggleMonthly: toggleMonthly,
    removeMonthly: removeMonthly,
    setTheme: setTheme,
    addWeekly: addWeekly,
    updateWeekly: updateWeekly,
    toggleWeekly: toggleWeekly,
    removeWeekly: removeWeekly,
    toggleMonthComplete: toggleMonthComplete,
    toggleWeekComplete: toggleWeekComplete
  };
})();
