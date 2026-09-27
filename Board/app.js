(function () {
  'use strict';

  var C = window.MoodCalendar;
  var S = window.MoodStore;

  var SHORT_MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  var DOW_LABELS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  var state = {
    data: null,
    monthKey: '2026-10',
    pendingReload: false
  };

  var bridge = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.bridge;
  var writeTimer = null;

  function el(tag, className, text) {
    var node = document.createElement(tag);
    if (className) node.className = className;
    if (text !== undefined) node.textContent = text;
    return node;
  }

  function persist() {
    if (!bridge) return;
    clearTimeout(writeTimer);
    writeTimer = setTimeout(function () {
      bridge.postMessage({ action: 'write', payload: JSON.stringify(state.data) });
    }, 120);
  }

  function isEditing() {
    var active = document.activeElement;
    return !!(active && (active.tagName === 'INPUT' || active.tagName === 'TEXTAREA' || active.isContentEditable));
  }

  function requestNativeReload() {
    if (bridge) bridge.postMessage({ action: 'reload' });
    else window.location.reload();
  }

  function maybeReload() {
    if (!state.pendingReload) return;
    if (isEditing()) return;
    state.pendingReload = false;
    requestNativeReload();
  }

  window.__moodRequestReload = function () {
    if (isEditing()) {
      state.pendingReload = true;
      setTimeout(function () {
        if (state.pendingReload && !isEditing()) {
          state.pendingReload = false;
          requestNativeReload();
        }
      }, 4000);
    } else {
      requestNativeReload();
    }
  };

  function formatShort(date) {
    return SHORT_MONTHS[date.getMonth()] + ' ' + date.getDate();
  }

  function weekRange(week) {
    var first = week.days[0].date;
    var last = week.days[6].date;
    if (first.getMonth() === last.getMonth()) {
      return formatShort(first) + ' \u2013 ' + last.getDate();
    }
    return formatShort(first) + ' \u2013 ' + formatShort(last);
  }

  // ---- rendering ----

  function render() {
    document.getElementById('month-title').textContent = C.monthTitle(state.monthKey);
    document.getElementById('theme-input').value = S.ensureMonth(state.data, state.monthKey).theme || '';

    var board = document.getElementById('board');
    board.textContent = '';
    board.appendChild(renderMonthlySection());
    C.weeksOfMonth(state.monthKey).forEach(function (week, index) {
      board.appendChild(renderWeekSection(week, index));
    });
  }

  function monthlyHandlers(goal) {
    return {
      edit: function (text) { S.updateMonthly(state.data, state.monthKey, goal.id, text); persist(); },
      toggle: function () { var d = S.toggleMonthly(state.data, state.monthKey, goal.id); persist(); return d; },
      remove: function () { S.removeMonthly(state.data, state.monthKey, goal.id); persist(); }
    };
  }

  function weeklyHandlers(weekKey, goal) {
    return {
      edit: function (text) { S.updateWeekly(state.data, weekKey, goal.id, text); persist(); },
      toggle: function () { var d = S.toggleWeekly(state.data, weekKey, goal.id); persist(); return d; },
      remove: function () { S.removeWeekly(state.data, weekKey, goal.id); persist(); }
    };
  }

  function renderMonthlySection() {
    var month = S.ensureMonth(state.data, state.monthKey);
    var section = el('section', 'card month-card');

    var header = el('header', 'section-header');
    header.appendChild(el('h2', 'section-title', 'Monthly goals'));
    header.appendChild(el('span', 'section-count', String(month.monthlyGoals.length)));
    section.appendChild(header);

    var list = el('ul', 'goals');
    month.monthlyGoals.forEach(function (goal) {
      list.appendChild(renderGoal(goal, monthlyHandlers(goal)));
    });
    section.appendChild(list);

    var form = renderAddForm('Add a monthly goal');
    bindAddForm(form, list, function (text) {
      return S.addMonthly(state.data, state.monthKey, text);
    }, monthlyHandlers);
    section.appendChild(form);

    return section;
  }

  function renderWeekSection(week, index) {
    var section = el('section', 'card week-card');

    var header = el('header', 'week-header');
    header.appendChild(el('h2', 'week-range', weekRange(week)));
    header.appendChild(el('span', 'week-index', 'Week ' + (index + 1)));
    section.appendChild(header);

    section.appendChild(renderDayStrip(week));
    section.appendChild(el('div', 'week-goals-label', 'Weekly goals'));

    var list = el('ul', 'goals');
    var weekly = S.ensureWeek(state.data, week.key);
    weekly.forEach(function (goal) {
      list.appendChild(renderGoal(goal, weeklyHandlers(week.key, goal)));
    });
    section.appendChild(list);

    var form = renderAddForm('Add a weekly goal');
    bindAddForm(form, list, function (text) {
      return S.addWeekly(state.data, week.key, text);
    }, function (goal) { return weeklyHandlers(week.key, goal); });
    section.appendChild(form);

    return section;
  }

  function renderDayStrip(week) {
    var todayKey = C.keyOf(new Date());
    var strip = el('div', 'week-days');
    week.days.forEach(function (d, i) {
      var classes = 'day' + (d.inMonth ? '' : ' is-outside') + (d.key === todayKey ? ' is-today' : '');
      var cell = el('div', classes);
      cell.appendChild(el('span', 'day-dow', DOW_LABELS[i]));
      cell.appendChild(el('span', 'day-num', String(d.dayNum)));
      strip.appendChild(cell);
    });
    return strip;
  }

  function renderGoal(goal, handlers) {
    var li = el('li', 'goal' + (goal.done ? ' is-done' : ''));

    var label = el('label', 'goal-main');
    var checkbox = el('input', 'goal-check');
    checkbox.type = 'checkbox';
    checkbox.checked = goal.done;
    checkbox.addEventListener('change', function () {
      li.classList.toggle('is-done', handlers.toggle());
    });
    var text = el('span', 'goal-text', goal.text);
    text.title = 'Click to edit';
    label.appendChild(checkbox);
    label.appendChild(text);
    li.appendChild(label);

    var del = el('button', 'goal-delete', '\u00d7');
    del.type = 'button';
    del.setAttribute('aria-label', 'Delete goal');
    del.addEventListener('click', function () {
      li.remove();
      handlers.remove();
    });
    li.appendChild(del);

    text.addEventListener('click', function () {
      beginEdit(text, goal.text, function (value) {
        if (value !== goal.text) {
          handlers.edit(value);
        }
      });
    });

    return li;
  }

  function beginEdit(span, value, commit) {
    var input = document.createElement('input');
    input.type = 'text';
    input.className = 'goal-edit';
    input.value = value;
    input.maxLength = 200;
    span.replaceWith(input);
    input.focus();
    input.select();

    var finished = false;
    function finish() {
      if (finished) return;
      finished = true;
      var next = input.value.trim();
      if (!next) { input.replaceWith(span); return; }
      span.textContent = next;
      input.replaceWith(span);
      commit(next);
    }

    input.addEventListener('keydown', function (e) {
      if (e.key === 'Enter') input.blur();
      else if (e.key === 'Escape') {
        finished = true;
        input.replaceWith(span);
      }
    });
    input.addEventListener('blur', finish);
  }

  function renderAddForm(placeholder) {
    var form = el('form', 'goal-add');
    var input = el('input', 'goal-add-input');
    input.type = 'text';
    input.placeholder = placeholder;
    input.maxLength = 200;
    form.appendChild(input);
    return form;
  }

  function bindAddForm(form, list, addFn, handlersFor) {
    form.addEventListener('submit', function (e) {
      e.preventDefault();
      var input = form.querySelector('.goal-add-input');
      var text = input.value.trim();
      if (!text) return;
      var goal = addFn(text);
      persist();
      list.appendChild(renderGoal(goal, handlersFor(goal)));
      input.value = '';
      input.focus();
    });
  }

  // ---- boot ----

  function init() {
    var initial = window.__MOOD_INITIAL_DATA__;
    if (initial && initial.version && initial.months && initial.weeks) {
      state.data = initial;
    } else {
      state.data = S.emptyData();
    }

    document.getElementById('prev-month').addEventListener('click', function () {
      state.monthKey = C.shiftMonth(state.monthKey, -1);
      render();
    });
    document.getElementById('next-month').addEventListener('click', function () {
      state.monthKey = C.shiftMonth(state.monthKey, 1);
      render();
    });
    document.getElementById('today-btn').addEventListener('click', function () {
      state.monthKey = C.monthKeyOf(new Date());
      render();
    });

    var themeInput = document.getElementById('theme-input');
    themeInput.addEventListener('change', function () {
      S.setTheme(state.data, state.monthKey, themeInput.value.trim());
      persist();
    });
    themeInput.addEventListener('keydown', function (e) {
      if (e.key === 'Enter') themeInput.blur();
    });

    document.addEventListener('blur', function () {
      setTimeout(maybeReload, 0);
    }, true);

    render();

    if (!initial || Object.keys(initial.months).length === 0) {
      persist();
    }
  }

  init();
})();
