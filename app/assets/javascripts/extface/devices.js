// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$(document).ready(function()  {
  $('#push').click(function(e) {
    $.ajax({
      type: "POST",
      url: $(this).attr('href'),
      data: $('#data').val(),
      contentType: "application/octet-stream"
    });
    e.preventDefault();
  });
});