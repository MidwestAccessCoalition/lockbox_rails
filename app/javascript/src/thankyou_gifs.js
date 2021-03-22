document.addEventListener('turbolinks:load', () => {
    const thankYouGifs = [ 
      'https://i.pinimg.com/originals/12/ae/a1/12aea1561f7f0bcdcc75824471d0c937.gif', 
    ]
    const thankYouGif = document.getElementById('thankyou_gif');
    const random = Math.floor(Math.random() * thankYouGifs.length);
    thankYouGif.src = thankYouGifs[random]
  });