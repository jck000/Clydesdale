
function cldl_set_message(mess) {
  try {
    $("#message").val(mess);
    setTimeout(  function() { cldl_clear_message(); }, 3000);
  } catch {
    // do nothing
  }
}

function cldl_clear_message() {
  try {
    $("#message").val("");
  } catch {
    // do nothing
  }
}
