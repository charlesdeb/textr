// TODO: put some testing in place here. Could be Jasmine, or maybe just use feature specs since this is pretty simple
textr = {
  get_suggestions: function (text) {
    // console.log(e.target.value);
    let language_id = $("#text_message_language_id").val();
    let show_analysis = $("#show_analysis_").is(":checked");

    // console.log({ show_analysis });

    Rails.ajax({
      url: "/text_messages/suggest",
      type: "GET",
      data: new URLSearchParams({
        text,
        language_id,
        show_analysis,
      }).toString(),
      success: function (data) {},
      error: function (data) {
        console.log("something went wrong");
        console.error(data);
      },
    });
  },
};

$(function () {
  $("#text_message_text").on("keyup", function (event) {
    let text = event.target.value || "";
    textr.get_suggestions(text);
  });
});
