//setWorker = 
function worker() {
  var pattern = "customers/[1-9][0-9]*";
  if( document.URL.match(new RegExp(pattern, "g"))) {
  $.ajax({
    //url: '17.json', 
    url: document.URL + ".json",
    success: function(data) {
      // both next lines work fine:
      console.log(data.status);
      //alert(data.status); 
      var beforeobj = $('#status');
      if(beforeobj == null)  {
      return;
      }
      console.log("beforeobj: " + beforeobj);
      //alert($('#customer_status'));
      var oldhtml = document.getElementById("status").innerHTML;
      // does not seem to be the same as:
      //var oldhtml = $('#customer_status').innerHTML;
      console.log("oldhtml: " + oldhtml);
      var oldtext = oldhtml.replace(/<[^>]*>/g, "").replace(/^[\s\n\r]*/, "").replace(/[\s\n\r]*$/, "").replace(/\(/g,"\\\(").replace(/\)/g,"\\\)");
      //console.log(beforeobj);
      console.log("oldtext: ---" + oldtext + "---");
      var regex = new RegExp(oldtext,"g");
      console.log("regex: " + regex);
 
      // in oldhtml, replace old text by new text:
      //var newhtml = oldhtml.replace(/provisioning successful/, data.status + " (newhtml)");
      //var newhtml = oldhtml.replace(regex, data.status + " newhtml");
      var newhtml = oldhtml.replace(regex, data.status);
      console.log("newhtml: " + newhtml);
      //$('#customer_status').html(data.status + " changed by jquery/ajax");

      //$('#customer_status').html(newhtml);
      // should be the same:
      //$('#customer_status').get(0).innerHTML = newhtml;
      // and is the same as:
      document.getElementById("status").innerHTML = newhtml;
      console.log("updated");
    },
    complete: function() {
      // Schedule the next request when the current one's complete
      if(!document.getElementById("status").innerHTML.match(/success/g)){
         setTimeout(worker, 5000);
         console.log("updating in 5 sec");
      } else {
         setTimeout(worker, 60000);
         console.log("updating in 60 sec");
      }
    }
  });
} else { 
   // this is a workaround only: if the the link is switched to by turbolink, the script is not reloaded, so it does not start again. 
   // TODO: search for a better solution based on document
   //$(document).on('page:load', mySetReload);
   //setTimeout(worker, 10000); 
}
};
$(document).on('page:load', worker);
$(document).ready(worker);
