(() => {
  'use strict';
  const english = document.documentElement.lang === 'en';
  const copy = english ? {
    sample: 'Polish the first paragraph\nFind two references',
    empty: 'No note · badge off',
    filled: 'Note waiting · ! badge on',
    open: 'Open or close the note',
    settings: 'Note settings',
    cleared: 'Note cleared · undo available'
  } : {
    sample: '기획안 첫 문단 다듬기\n참고 자료 2개 확인하기',
    empty: '메모 없음 · 배지 꺼짐',
    filled: '메모 있음 · ! 배지 켜짐',
    open: '메모 열기 또는 닫기',
    settings: '메모 및 설정',
    cleared: '메모 비움 · 되돌리기 가능'
  };
  const note = document.getElementById('demo-note');
  const pet = document.getElementById('pet-toggle');
  const badge = document.getElementById('memo-badge');
  const popover = document.getElementById('demo-popover');
  const settings = document.getElementById('demo-settings');
  const settingsToggle = document.getElementById('settings-toggle');
  const clear = document.getElementById('clear-note');
  const undo = document.getElementById('undo-clear');
  const stateLabel = document.getElementById('demo-state');
  if (!note || !pet) return;
  let text = copy.sample;
  let undoText = null;
  let opened = true;
  let settingsOpened = false;
  // Demo text stays in memory only. No cookies, browser storage, or network writes.
  function render() {
    const hasMemo = /[^\p{White_Space}]/u.test(text);
    if (note.value !== text) note.value = text;
    badge.hidden = !hasMemo;
    badge.style.display = hasMemo ? '' : 'none';
    pet.classList.toggle('has-note', hasMemo);
    pet.setAttribute('aria-expanded', String(opened));
    pet.setAttribute('aria-label', copy.open);
    popover.hidden = !opened;
    settings.hidden = !settingsOpened;
    settingsToggle.setAttribute('aria-expanded', String(settingsOpened));
    settingsToggle.setAttribute('aria-label', copy.settings);
    clear.disabled = text.length === 0;
    undo.disabled = undoText === null;
    const label = undoText !== null ? copy.cleared : hasMemo ? copy.filled : copy.empty;
    if (stateLabel.textContent !== label) stateLabel.textContent = label;
  }
  function focusNote() { note.focus({ preventScroll: true }); }
  function closePopover() {
    opened = false;
    settingsOpened = false;
    render();
  }
  note.addEventListener('input', () => {
    text = note.value;
    undoText = null;
    render();
  });
  pet.addEventListener('click', () => {
    opened = !opened;
    settingsOpened = false;
    render();
    if (opened) focusNote();
  });
  settingsToggle.addEventListener('click', () => {
    settingsOpened = !settingsOpened;
    render();
  });
  clear.addEventListener('click', () => {
    if (text.length) {
      undoText = text;
      text = '';
    }
    settingsOpened = false;
    render();
    focusNote();
  });
  undo.addEventListener('click', () => {
    if (undoText !== null) {
      text = undoText;
      undoText = null;
    }
    settingsOpened = false;
    render();
    focusNote();
  });
  document.getElementById('reset-demo').addEventListener('click', () => {
    text = copy.sample;
    undoText = null;
    opened = true;
    settingsOpened = false;
    render();
    focusNote();
  });
  document.addEventListener('pointerdown', (event) => {
    if (opened && !popover.contains(event.target) && !pet.contains(event.target)
      && !event.target.closest('#reset-demo')) closePopover();
  });
  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && !event.isComposing && opened) {
      event.preventDefault();
      if (settingsOpened) {
        settingsOpened = false;
        render();
        settingsToggle.focus({ preventScroll: true });
      } else {
        closePopover();
        pet.focus({ preventScroll: true });
      }
    }
  });
  for (const link of document.querySelectorAll('[data-open-install], [data-open-privacy]')) {
    link.addEventListener('click', () => {
      const details = document.querySelector(link.getAttribute('href'));
      if (details) details.open = true;
    });
  }
  const initialDetails = ['#install', '#site-privacy'].includes(location.hash)
    ? document.querySelector(location.hash) : null;
  if (initialDetails) initialDetails.open = true;
  render();
})();
