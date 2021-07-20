$(function () {
  // TODO: put some testing in place here. Could be Jasmine, or maybe just use feature specs since this is pretty simple
  $('#text_message_text').on('keyup', function (e) {
    // console.log(e.target.value);
    let text = e.target.value || '';
    let language_id = $('#text_message_language_id').val();
    let show_analysis = $('#show_analysis_').is(':checked');

    // console.log({ show_analysis });

    // $.ajax({
    Rails.ajax({
      url: '/text_messages/suggest',
      type: 'GET',
      // dataType: 'json',
      // data: JSON.stringify({ current_message }),
      data: new URLSearchParams({
        text,
        language_id,
        show_analysis,
      }).toString(),
      success: function (data) {
        // console.log('back from suggestions with succes');
      },
      error: function (data) {
        console.log('something went wrong');
        console.error(data);
      },
    });
  });
});
