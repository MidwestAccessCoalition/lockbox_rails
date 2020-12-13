const addNewNote = note => {
  $('tbody').prepend(note);
  highlightTopNote();
};

const openNoteForm = () => {
  $('#new-note-form').slideDown(100);
  $('#new-note')
    .parent()
    .addClass('selected');
  $('#new-note-form textarea').focus();
};

const displayNoteSuccess = text => {
  $('#note-success #note-event').text('New note created');
  $('#note-success #note-text').text(text);
  $('#note-success').slideDown(100);
};

const displayNoteUpdate = text => {
  $('#note-success #note-event').text('Note updated');
  $('#note-success #note-text').text(text);
  $('#note-success').slideDown(100);
};

const hideNoteSuccess = () => {
  $('#note-success').slideUp(100);
  clearHighlights();
};

const clearHighlights = () => {
  $('.notes-log tbody tr').removeClass('green');
};

const highlightTopNote = () => {
  clearHighlights();
  highlightNote($('.notes-log tbody tr').first());
};

const highlightNote = note => {
  note.addClass('green');
};

const clearNoteForm = () => {
  $('#new-note-form').slideUp(100);
  $('#new-note-form textarea').val('');
};

const removeSelection = () => {
  $('#new-note')
    .parent()
    .removeClass('selected');
};

const handleNoteResponse = response => {
  const data = response.detail[0];
  if (data.note) {
    addNewNote(data.note);
    clearNoteForm();
    displayNoteSuccess(data.text);
  } else {
    console.log(data);
  }
};

const editGreenNote = () => {
  const greenNote = $('tr.green');
  getNoteForm(greenNote);
};

const getNoteForm = note => {
  const id = note.data('id');
  const noteEditUrl = window.location + '/notes/' + note.data('id') + '/edit';
  $.ajax(noteEditUrl).done(response => {
    note.replaceWith(response);
    const newNote = $(`tr[data-id=${id}]`);
    newNote.on('ajax:success', handleUpdateNote);
    newNote.find('textarea').focus();
  });
};

const cancelNoteForm = note => {
  const noteShowUrl = window.location + '/notes/' + note.data('id');
  $.ajax(noteShowUrl).done(response => note.replaceWith(response));
};

const handleUpdateNote = response => {
  const data = response.detail[0];
  if (data.note) {
    const note = $(response.target).closest('tr');
    const id = note.data('id');
    note.replaceWith(data.note);
    highlightNote($(`tr[data-id=${id}]`));
    displayNoteUpdate(data.text);
  } else {
    console.log(data);
  }
};

const setupNotes = () => {
  const notesLog = $('.notes-log');
  if (notesLog) {
    $('#new-note').on('click', event => {
      event.preventDefault();
      openNoteForm();
      hideNoteSuccess();
    });
    $('#cancel-note').on('click', event => {
      event.preventDefault();
      clearNoteForm();
      removeSelection();
      hideNoteSuccess();
    });
    $('#success-new-note').on('click', event => {
      event.preventDefault();
      clearNoteForm();
      openNoteForm();
      hideNoteSuccess();
    });
    $('#success-edit-note').on('click', event => {
      event.preventDefault();
      editGreenNote();
      hideNoteSuccess();
      removeSelection();
    });
    notesLog.on('click', '.edit-note-button', event => {
      event.preventDefault();
      getNoteForm($(event.target).closest('tr'));
      hideNoteSuccess();
      removeSelection();
    });
    notesLog.on('click', '.cancel-note', event => {
      event.preventDefault();
      cancelNoteForm($(event.target).closest('tr'));
    });
    $('#new-note-form').off('ajax:success', handleNoteResponse);
    $('#new-note-form').on('ajax:success', handleNoteResponse);
  }
};

document.addEventListener('turbolinks:load', () => {
  setupNotes();
});
