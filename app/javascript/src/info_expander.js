const toggleInfoExpander = event => {
  const expander = $(event.target).parents('.info-expander')
  expander.toggleClass('closed')
  const content = expander.children('.info-expander-content')
  content.slideToggle('fast')
}

const setupInfoExpander = () => {
  const infoExpander = $('.info-expander');
  if (infoExpander) {
    $('.info-expander-header').off('click',toggleInfoExpander)
    $('.info-expander-header').on('click',toggleInfoExpander)
  }
}

document.addEventListener('turbolinks:load', () => {
  setupInfoExpander();
});