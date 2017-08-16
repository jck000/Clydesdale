

var templates = {
  'pemscheckbox':' <div class="checkbox-inline"> <label> <input type="chekbox" name="{{cbx_name}}" id="{{cbx_id}" value="1" {{cbx_checked}}> {{cbx_label}} </label> </div>'};






    var modal = bootbox.dialog({
        message: $(".form-content").html(),
        title: "Your awesome modal",
        buttons: [
          {
            label: "Save",
            className: "btn btn-primary pull-left",
            callback: function() {

              alert($('form #email').val());
             
              return false;
            }
          },
          {
            label: "Close",
            className: "btn btn-default pull-left",
            callback: function() {
              console.log("just do something on close");
            }
          }
        ],
        show: false,
        onEscape: function() {
          modal.modal("hide");
        }
    });
    
    modal.modal("show");

<!--
    <div class="form-content" style="display:none;">
      <form class="form" role="form">
        <div class="checkbox">
          <label>
            <input type="checkbox"> Check me out
          </label>
        </div>
      </form>
    </div>
-->




};





var TMPLDIR = 'templates/';
var ATMPL   = new Array();

load_templates();
 
function load_templates() {
  // Extend this array if you have more templates
  var templates = ['permission_menu.html'];

  $.each( templates, function( idx, tmpl ) {
    var temp_template = TMPLDIR + tmpl + '.tmpl';

    $.ajax({
      url:      temp_template,
      success:  function( data ) {
                  ATMPL[ tmpl ] = data;
                }, // async:    false,
      dataType: 'html'
    });  // ajax
  });    // each
}

/* used??? */
function renderTemplate( tmpl, json ) {
  console.log("In renderTemplate");
  console.log("tmpl:" + tmpl);
  console.log("json:" + json);

  var rendered;

  if ( ATMPL[ tmpl ] ) {
    rendered =  Mustache.render( ATMPL[tmpl], json);
  } else {
    rendered =  Mustache.render( tmpl, json);
  }
  return rendered;
}  



