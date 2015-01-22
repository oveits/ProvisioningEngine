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
    if (regex.test(window.location.pathname)) {
      if (window.myRefresh != null) {
        clearTimeout(window.myRefresh);
      }
      return window.myRefresh = setTimeout("location.reload(true);", 10000);
      //alert(window.myRefresh);
    } else {
      if (window.myRefresh != null) {
        clearTimeout(window.myRefresh);
      }
      //alert(window.myRefresh);
      return window.myRefresh = null;
    }
  };

  $(document).ready(mySetReload);

  $(document).on('page:load', mySetReload);
