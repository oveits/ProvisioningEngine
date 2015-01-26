  var mySetReload, pattern, regex;


  pattern = "/customers$|customers/[1-9][0-9]*$|sites$|sites/[1-9][0-9]*$|users$|users/[1-9][0-9]*$|provisionings$|provisionings/[1-9][0-9]*$";
  // same without customers/[1-9][0-9]*
  pattern = "/customers$|sites$|sites/[1-9][0-9]*$|users$|users/[1-9][0-9]*$|provisionings$|provisionings/[1-9][0-9]*$";
  // same without sites/[1-9][0-9]*
  pattern = "/customers$|sites$|users$|users/[1-9][0-9]*$|provisionings$|provisionings/[1-9][0-9]*$";
  // same without users/[1-9][0-9]*
  pattern = "/customers$|sites$|users$|provisionings$|provisionings/[1-9][0-9]*$";
  //pattern = "/customers$|customers/[1-9][0-9]*$|sites$|sites/[1-9][0-9]*$" //|customers/[1-9][0-9]*$|sites$|sites/[1-9][0-9]*$|users$|users/[1-9][0-9]*$|provisionings$||provisionings/[1-9][0-9]*$";
  regex = RegExp("" + pattern);

  mySetReload = function() {
//    if (window.myRefresh != null) {
//      clearTimeout(window.myRefresh);
//      window.myRefresh = null;
//      //alert("Cleared page refresh");
//    }
    myClearReload();
    //if (regex.test(window.location.pathname)) {
      //window.myRefresh = setTimeout("location.reload(true);", 10000);
      window.myRefresh = setTimeout("myReload();", 10000);
      console.log("set timout for page reload");
      //alert(window.myRefresh);
    //} 
  };  //  mySetReload = function()
  
  myReload = function() {
      //console.log($('form').get(0));
    if ( regex.test(window.location.pathname) && $('form').get(0) == null ) {
      // this is autmatically loading/starting mySetReload because of the document ready and document page reload statements:
      location.reload(true);
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
