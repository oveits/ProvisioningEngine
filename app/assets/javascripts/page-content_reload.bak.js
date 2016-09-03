  //var mySetReload, pattern, regex;
  var pattern, regex;

  // specify the URLs, where we want to perform page reloads:
  pattern = "customers[/#]*$|customers/[1-9][0-9]*[/#]*$|sites[/#]*$|sites/[1-9][0-9]*[/#]*$|users[/#]*$|users/[1-9][0-9]*[/#]*$|provisionings[/#]*$|provisionings/[1-9][0-9]*[/#]*$";

// temporarily switched off:
//pattern = "@@@@@@@@@@@@@@@@@@@@@---switched--off---@@@@@@@@@@@@@@@@@@@@@@@";
  //pattern = "customers[/#]*$|customers/[1-9][0-9]*[/#]*$|sites[/#]*$|sites/[1-9][0-9]*[/#]*$|provisionings[/#]*$|provisionings/[1-9][0-9]*[/#]*$";
  var idArray = ["page-content-wrapper", "flash", "sidebar-wrapper"];

  regexInclude = RegExp(pattern);

  // page reload is skipped on pages with a form, unless they are included in the pattern below:
  regexIncludeEvenIfForm = RegExp("@@@@@@@@@@@@@@@@@@@@@dummy@@@@@@@@@@@@@@@@@@@@@@@");
  var aj;
var timeout = 240000;

var refreshRunning = false;
window.ajaxWaiting = false;

function page_ajax_id_refresh(idArray) {
  refreshRunning = true;
  console.log("page_ajax_id_refresh called!");

  $.ajax({
    // get full information in json format and update the field(s)
    url: document.URL,
    timeout: timeout,
    beforeSend: function() {
        // wait, if ajax is already waiting for a response:
        window.ajaxWaiting = true;
    },
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

                  // calculate newhtml:
                  var parser = new DOMParser();
                  var doc = parser.parseFromString(data, "text/html");
                  var newhtml = doc.getElementById(id).innerHTML;

                  // replace old html by newhtml:
                  oldobj.get(0).innerHTML = newhtml;
                  console.log("page reloaded successfully:");
                  console.log("HTML element with id=" + id + " updated");
                } // for (var i = 0; i < idArray.length; i++)
              }, // success: function(data)
    failure: function(data) {
                timeout = 2 * timeout; 
              },
    complete: function(data) {
                // Schedule the next request when the current one's complete
                mySetReload();
                window.ajaxWaiting = false;
              }
  }); // $.ajax
}  // page_ajax_id_refresh(id)               


  mySetReload = function() {
    console.log("mySetReload called!");
    myClearReload();
    // in the moment, document.getElementById("page-content-wrapper") yields null, and would cause the refresh to stop; threrefore we set the timer manually only for now:
//    if(document.getElementById("page-content-wrapper").innerHTML.match(/waiting/g) && document.getElementById(id).innerHTML.match(/progress/g)){
//     // once every 10 seconds, if at least an item is in 'waiting' or 'progress' status
      refreshTimer = 5000;
//    } else {
//      // else once every minute should be sufficient:
//      refreshTimer = 60000;
//    }
    window.myRefresh = setTimeout("myReload();", refreshTimer);
    console.log("set timout for page reload to " + refreshTimer);
  };  //  mySetReload = function()
  
  myReload = function() {
    console.log("myReload called!");
    if ( regexInclude.test(window.location.pathname) && ( $('form').get(0) == null  || regexIncludeEvenIfForm.test(window.location.pathname))) {
      // this is autmatically loading/starting mySetReload because of the document ready and document page reload statements:

      // see: https://coderwall.com/p/ii0a_g/page-reload-refresh-every-5-sec-using-turbolinks-js-rails-jquery
      // 1) disable page scrolling to top after loading page content
      Turbolinks.enableTransitionCache(true);
      // 2) pass current page url to visit method
      if(window.ajaxWaiting == true) {
        console.log("skipped ajax because of pending ajax request");
        setTimeout("myReload();", refreshTimer);
      } else {
        aj = page_ajax_id_refresh(idArray);
      }
      // 3) enable page scroll reset in case user clicks other link
      Turbolinks.enableTransitionCache(false);
      //mySetReload();
      console.log("reload initiated (ajax: background)");
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

// the next 2 statements had the problem that the refresh queue was ever increasing, if the time for a reload took longer than the timer:
//  $(document).ready(mySetReload);

 $(document).on('page:load', mySetReload);
 $(document).on('page:load', function()
 {
    // executes when HTML-Document is loaded and DOM is ready
    console.log("(document).on('page:load') was called - page is loaded!");
    if(window.ajaxWaiting == false) {
        console.log("skipped ajax because of pending ajax request");
        setTimeout("myReload();", refreshTimer);
}
 });
// replaced by a singular 'mySetReload();' here at first javascript document load and a 'mySetReload();' in the complete: part of the ajax statement (plus a 'mySetReload();' in the skipped page reload of the myReload function; but that is not new):

  //mySetReload();
  // window load waits until the page if fully loaded (see http://www.codeproject.com/Tips/632672/JavaScripts-document-ready-vs-window-load):
  $(document).ready(function() 
 {
    // executes when HTML-Document is loaded and DOM is ready
    console.log("(document).ready was called - document is ready!");  
 });  

  $(window).load(mySetReload);
  $(window).load(function() 
{
   // executes when complete page is fully loaded, including all frames, objects and images
   console.log("(window).load was called - window is loaded!");
});  
//  $(window).load(mySetReload);
  $( window ).unload(function()
{
  if(window.ajaxWaiting == true) {
    console.log("aborting active ajax request");
    aj.abort();
    window.ajaxWaiting = false;
  }
  myClearReload();
});

