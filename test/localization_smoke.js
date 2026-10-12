// node plugins/redcase/test/localization_smoke.js (no browser or npm dependencies)
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

let filter = 'all';
const names = ['Passed', 'Failed', 'Blocked', 'Not Available'];
const rows = Object.fromEntries(names.map(name => [name, {display: 'table-row'}]));
function jquery(selector) {
  if (typeof selector === 'function') return; // Do not start the application.
  if (typeof selector === 'object') return {css: (key, value) => { selector[key] = value; }};
  if (selector === '#filter_id_') return {val: () => filter};
  const name = /^\[name="(.*)"\]$/.exec(selector)?.[1];
  if (name) return [rows[name]];
  return {change() {}, on() {}};
}
jquery.each = (items, callback) => items.forEach((item, index) => callback(index, item));
const context = vm.createContext({jQuery: jquery, $: jquery, LogManager: {getLog: () => ({})}});
for (const file of ['api.js', 'combos.js']) {
  vm.runInContext(fs.readFileSync(path.join(__dirname, '../assets/javascripts', file), 'utf8'), context);
}
context.Redcase.result_names = names;
context.Redcase.translations = {issue_created: 'Ticket #%{id} wurde angelegt.'};
context.Redcase.resultLabels = {Passed: 'Bestanden'};
assert.equal(context.Redcase.t('issue_created', {id: 84}), 'Ticket #84 wurde angelegt.');
assert.equal(context.Redcase.resultLabel('Passed'), 'Bestanden');
assert.equal(context.Redcase.resultLabel('Custom result'), 'Custom result');
const combos = new context.RedcaseCombos(jquery);
for (filter of ['all', 'not_passed', ...names]) {
  combos.refreshFilter();
  for (const name of names) {
    const expected = filter === 'all' || filter === name || (filter === 'not_passed' && name !== 'Passed');
    assert.equal(rows[name].display, expected ? 'table-row' : 'none', `${filter}: ${name}`);
  }
}
console.log('PASS: translated messages and result labels; all six report filters use stable values.');
