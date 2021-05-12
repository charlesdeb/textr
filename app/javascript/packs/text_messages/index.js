$(function () {
  $('#text_message_text').on('keyup', function (e) {
    console.log(e.target.value);
    let current_message = e.target.value || '';
    let language_id = $('#text_message_language_id').val();

    // $.ajax({
    Rails.ajax({
      url: '/text_messages/suggestions',
      type: 'GET',
      // dataType: 'json',
      // data: JSON.stringify({ current_message }),
      data: new URLSearchParams({ current_message, language_id }).toString(),
      success: function (data) {
        console.log('back from suggestions with succes');
      },
      error: function (data) {
        console.log('back from suggestions with error');
      },
    });
  });
});
