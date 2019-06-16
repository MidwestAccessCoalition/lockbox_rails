const scrollNotes = (animate = false) => {
  let river = document.querySelector('.notes-river');
  // TODO animate
  river.scrollTop = river.scrollHeight;
};

const setupNotes = () => {
  document.addEventListener('ajax:success', response => {
    const data = response.detail[0];
    if (data.note) {
      const div = document.createElement('div');
      div.innerHTML = data.note;
      const river = document.querySelector('.notes-river');
      river.appendChild(div.firstChild);
      const input = document.querySelector('#new_note textarea');
      input.value = '';
    }
    scrollNotes(true);
  });
};

document.addEventListener('turbolinks:load', () => {
  if (document.getElementsByClassName('notes-area')) {
    setupNotes();
    scrollNotes();
  }
});
