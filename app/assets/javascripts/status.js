function worker() {
  //var urlpattern = "customers/[1-9][0-9]*$|sites/[1-9][0-9]*$|users/[1-9][0-9]*$";
  //var urlpattern = "customers/[1-9][0-9]*$|sites/[1-9][0-9]*$";
  var urlpattern = "dummydummydummydummydummy$";
  // perform ajax updates only on pages, which need this function (currently customers/xy only)
  if( document.URL.match(new RegExp(urlpattern, "g"))) {
    $.ajax({
      // get full information in json format and update the field(s)
      url: document.URL + ".json",
      success: function(data) {
        // both next lines work fine:
           //console.log(data.status);
        //alert(data.status); 
        var oldobj = $('#status');
          console.log("oldobj: " + oldobj);
        if(oldobj == null)  {
          // return if no element with id=status was found on the page
          return;
        }
        var oldhtml = oldobj.get(0).innerHTML;
        // same as: var oldhtml = document.getElementById("status").innerHTML;
           //console.log("oldhtml: " + oldhtml);
        // find the text that is to be replaced:
        var oldtext = oldhtml.replace(/<[^>]*>/g, "").replace(/^[\s\n\r]*/, "").replace(/[\s\n\r]*$/, "").replace(/\(/g,"\\\(").replace(/\)/g,"\\\)");
           //console.log("oldtext: ---" + oldtext + "---");
        var newtext = data.status;

        // we want to replace oldtext by newtext, so we eed a RegExp of oldtext
        var regex = new RegExp(oldtext,"g");
           //console.log("regex: " + regex);
 
        var newhtml = oldhtml.replace(regex, newtext);
           //console.log("newhtml: " + newhtml);
        //$('#customer_status').get(0).innerHTML = newhtml;
        //document.getElementById("status").innerHTML = newhtml;
        // is the same as:
        // $('#status').get(0).innerHTML = newhtml;
        // is the same as:
        oldobj.get(0).innerHTML = newhtml;
        console.log("status updated to \"" + newtext + "\"");
      },
      complete: function() {
        // Schedule the next request when the current one's complete
        if(!document.getElementById("status").innerHTML.match(/success/g) && !document.getElementById("status").innerHTML.match(/fail/g)){
           setTimeout(worker, 5000);
           console.log("updating in 5 sec");
        } else {
           // if the status is not success or failure, we update more othen, than if it is in such a "final" state
           setTimeout(worker, 60000);
           console.log("updating in 60 sec");
        }
      }
    });
  } 
};

$(document).on('page:load', worker);
$(document).ready(worker);
