$(function () {
  $(".candidate a").on("click", function (event) {
    event.preventDefault();

    // break text entered so far into pieces
    split_text = $("#text_message_text").val().split(/\s/);

    // replace last piece with what the user just clicked on
    split_text[split_text.length - 1] = $(event.target).text();

    $("#text_message_text").val(split_text.join(" ") + " ");

    // get suggestions for the new text
    text = $("#text_message_text").val();
    textr.get_suggestions(text);

    $("#text_message_text").focus();
  });
});
