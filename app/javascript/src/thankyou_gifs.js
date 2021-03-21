document.addEventListener('turbolinks:load', () => {
  const thankYouGifs = [ 'https://i.pinimg.com/originals/0c/ce/9c/0cce9cb8cbdda46dae3531a12b73c7fa.gif']
  const thankYouGif = document.getElementById('thankyou_gif');
  const random = Math.floor(Math.random() * thankYouGifs.length)
  thankYouGif.src = thankYouGifs[random]
});