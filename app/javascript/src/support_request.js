document.addEventListener('turbolinks:load', () => {
  $("#lockbox-partner-info-show").click(function(event) {
    $("#lockbox-partner-info").show();
    $("#lockbox-partner-info-show").hide();
    $("#lockbox-partner-info-hide").show();
  });

  $("#lockbox-partner-info-hide").click(function(event) {
    $("#lockbox-partner-info").hide();
    $("#lockbox-partner-info-show").show();
    $("#lockbox-partner-info-hide").hide();
  });
});
