  var mySetReload, pattern, regex;


  pattern = "customers$|customers/[1-9][0-9]*$|sites$|sites/[1-9][0-9]*$|users$|users/[1-9][0-9]*$|provisionings$|provisionings/[1-9][0-9]*$";
  var idArray = ["page-content-wrapper", "flash", "sidebar-wrapper"];
  // same without customers/[1-9][0-9]*
  //pattern = "/customers$|sites$|sites/[1-9][0-9]*$|users$|users/[1-9][0-9]*$|provisionings$|provisionings/[1-9][0-9]*$";
  // same without sites/[1-9][0-9]*
  //pattern = "/customers$|sites$|users$|users/[1-9][0-9]*$|provisionings$|provisionings/[1-9][0-9]*$";
  // same without users/[1-9][0-9]*
  //pattern = "/customers$|sites$|users$|provisionings$|provisionings/[1-9][0-9]*$";
  regexInclude = RegExp(pattern);
  regexIncludeEvenIfForm = RegExp("customers/[1-9][0-9]*$|sites/[1-9][0-9]*$|users/[1-9][0-9]*$");

function page_ajax_id_refresh(idArray) {
  $.ajax({
    // get full information in json format and update the field(s)
    url: document.URL,
    success: function(data) {
                for (var i = 0; i < idArray.length; i++) {
                  id = idArray[i];
                  var oldobj = $('#' + id);
                    console.log("oldobj: " + oldobj);
                  if(oldobj == null)  {
                    // return if no element with id=page-content-wrapper was found on the page
                    console.log("HTML elemnet with id=" + id + " not found on the page");
                    return;
                  }
                  var oldhtml = oldobj.get(0).innerHTML;
                  // same as: var oldhtml = document.getElementById("status").innerHTML;
                     //console.log("oldhtml: " + oldhtml);
                     //console.log(data);

                  // calculate newhtml:
                  var parser = new DOMParser();
                  var doc = parser.parseFromString(data, "text/xml");
                  var newhtml = doc.getElementById(id).innerHTML;

                     //console.log("newhtml: " + newhtml);

                  // replace old html by newhtml:
                  // $('#status').get(0).innerHTML = newhtml;
                  // is the same as:
                  oldobj.get(0).innerHTML = newhtml;
                  console.log("HTML element with id=" + id + " updated");
                } // for (var i = 0; i < idArray.length; i++)
              }, // success: function(data)
    complete: function(data) {
                // Schedule the next request when the current one's complete
                if(document.getElementById(id).innerHTML.match(/waiting/g) && document.getElementById(id).innerHTML.match(/progress/g)){
                   //setTimeout(page_ajax_id_refresh(id), 5000);
                   //console.log("updating in 5 sec");
                } else {
                   // if the status is not success or failure, we update more othen, than if it is in such a "final" state
                   //setTimeout(page_ajax_id_refresh(id), 60000);
                   //console.log("updating in 60 sec");
                }
              }
  }); // $.ajax
}  // page_ajax_id_refresh(id)               


function page_content_reload() {
  //var urlpattern = "customers/[1-9][0-9]*$|sites/[1-9][0-9]*$|users/[1-9][0-9]*$";
  //var urlpattern = "customers/[1-9][0-9]*$|sites/[1-9][0-9]*$";
  var urlpattern = "customers$|customers/[1-9][0-9]*$|sites$|sites/[1-9][0-9]*$|users$|users/[1-9][0-9]*$|provisionings$|provisionings/[1-9][0-9]*$";
  // perform ajax updates only on pages, which need this function (currently customers/xy only)
  if( document.URL.match(new RegExp(urlpattern, "g"))) {
    $.ajax({
      // get full information in json format and update the field(s)
      url: document.URL,
      success: function(data) {
        var oldobj = $('#page-content-wrapper');
          console.log("oldobj: " + oldobj);
        if(oldobj == null)  {
          // return if no element with id=page-content-wrapper was found on the page
          return;
        }
        var oldhtml = oldobj.get(0).innerHTML;
        // same as: var oldhtml = document.getElementById("status").innerHTML;
           //console.log("oldhtml: " + oldhtml);
           //console.log(data);
        
        // calculate newhtml:
        var parser = new DOMParser();
        var doc = parser.parseFromString(data, "text/xml");
        var newhtml = doc.getElementById("page-content-wrapper").innerHTML;
        
           //console.log("newhtml: " + newhtml);
        
        // replace old html by newhtml:
        // $('#status').get(0).innerHTML = newhtml;
        // is the same as:
        oldobj.get(0).innerHTML = newhtml;
        console.log("page-content updated");
      },
    });
  } 
};
  mySetReload = function() {
//    if (window.myRefresh != null) {
//      clearTimeout(window.myRefresh);
//      window.myRefresh = null;
//      //alert("Cleared page refresh");
//    }
    myClearReload();
    //if (regex.test(window.location.pathname)) {
      //window.myRefresh = setTimeout("location.reload(true);", 10000);
    // full page reload only every 10 minutes:
      window.myRefresh = setTimeout("myReload();", 5000);
      console.log("set timout for page reload");
      //alert(window.myRefresh);
    //} 
  };  //  mySetReload = function()
  
  myReload = function() {
      //console.log($('form').get(0));
    if ( regexInclude.test(window.location.pathname) && ( $('form').get(0) == null  || regexIncludeEvenIfForm.test(window.location.pathname))) {
      // this is autmatically loading/starting mySetReload because of the document ready and document page reload statements:

      //location.reload(true);
      // replaced by next 3 Turbolink lines and a mySetReload command see: https://coderwall.com/p/ii0a_g/page-reload-refresh-every-5-sec-using-turbolinks-js-rails-jquery
      // 1) disable page scrolling to top after loading page content
      Turbolinks.enableTransitionCache(true);
      // 2) pass current page url to visit method
      //Turbolinks.visit(location.toString());
      // replaced by:
      //page_content_reload(); 
      
      page_ajax_id_refresh(idArray);
      mySetReload();
      // 3) enable page scroll reset in case user clicks other link
      Turbolinks.enableTransitionCache(false);
      // needed, since we do not reload the page anymore:
      //mySetReload();
      console.log("reloaded");
    } else {
      // if there was no reload, we still want to start another timeout:
      mySetReload();
      console.log("skipped page reload for this page URL");
    }
  };

  myClearReload = function() {
    if (window.myRefresh != null) {
      clearTimeout(window.myRefresh);
      window.myRefresh = null;
      console.log("Cleared page refresh");
    }};

  $(document).ready(mySetReload);

  $(document).on('page:load', mySetReload);
  $( window ).unload(myClearReload);
  //$( window ).beforeunload(myClearReload);
//$(window).unload(function(){ alert('do unload stuff here'); }); 
