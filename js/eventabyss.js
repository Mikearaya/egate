
var POSTER_LOCATION = "http://localhost/project/egate/uploads/eventImages/";
var GUESTS_LOCATION = "http://localhost/project/egate/uploads/eventImages/eventGuests/";
var SPONSORS_LOCATION = "http://localhost/project/egate/uploads/eventImages/eventSponsors/";
var sponsorImagePlaceholder = "http://localhost/project/egate/img/placeholder2.jpg";
var imagePlaceholder = "http://localhost/project/egate/img/placeholder2.jpg";
var eventImagePlaceholder = "http://localhost/project/egate/img/noImage.jpg";
var EVENT_PICTURE_LOCATION = "http://localhost/project/egate/uploads/eventImages/";
var eventManagmentOption = "<a href='#event-managment-panel' data-role='button'  data-theme='b' class='ui-btn-left' data-icon='gear' data-iconpos='right'>Settings</a>";
var accountManagmentOption = "<a href='http://localhost/project/egate/pages/accountManagment.html' data-role='button'  data-theme='b' class='ui-btn-left' data-icon='gear' data-iconpos='right'>Settings</a>";
var BACK_BUTTON = "<a href='#' data-rel='back' class='left-panel-button ui-btn ui-btn-left ui-alt-icon ui-nodisc-icon ui-corner-all ui-btn-icon-notext ui-icon-carat-l'>Back</a> ";
var SEARCH_BUTTON = "<a href='#event-categ-panel'   data-theme='d' class='left-panel-button ui-btn ui-btn-left ui-alt-icon ui-nodisc-icon ui-corner-all  ui-icon-search'  data-iconpos='right'   > Search </a> ";

var EVENT_PANEL_BUTTON = "<a href='#event-managment-panel'  id='search-button' data-theme='a' class='left-panel-button ui-btn ui-btn-left ui-alt-icon ui-nodisc-icon ui-corner-all  ui-icon-gear'    > Options </a> ";
var ACCOUNT_PANEL_BUTTON = "<a href='#account-managment-panel'  id='search-button' data-theme='a' class='left-panel-button ui-btn ui-btn-left ui-alt-icon ui-nodisc-icon ui-corner-all  ui-icon-gear'    > Options </a> ";


var total_ticket = 1;
var total_address = 1;
      var  total_sponsors = 1;
      var total_guest_field = 1;


var dateOptions = {
                    language:  "en",
                    weekStart: 1,
                    todayBtn:  1,
                    autoclose: 1,
                    todayHighlight: 1,
                    startView: 2,
                    minView: 2,
                    forceParse: 0

                 };

var timeOptions =   {
                      language:  "en",
                      weekStart: 1,
                      todayBtn:  1,
                      autoclose: 1,
                      todayHighlight: 1,
                      startView: 1,
                      minView: 0,
                      maxView: 1,
                      forceParse: 0

                   };



var formOptions = {

                    url: "../includes/systemController.php",
                    type: 'POST',
                    resetForm: false,
                    data: "",

                    beforesubmit: function (formData, jqForm, options) {
                       $.mobile.loading('show');
                    },

                    success:    function (responseText, statusText, xhr, $form)  {

                                       $.mobile.loading('hide');

                                       if(statusText === 'success'){

                                              $("#message-title").append('<h5 class="alert alert-success"> Upload Completed </h5>');

                                              $("#message-body").append(responseText);
                                              $("#modal-message").modal("show");

                                       } else if(statusText === 'error'){


                                            $("#message-title").append('<h5 class="alert alert-danger"> Upload Completed </h5>');
                                            $("#message-body").append(responseText);
                                            $("#modal-message").modal("show");
                                       }

                    }




                 };


 var ajaxFormOptions =  {

              url: "../includes/systemController.php",
              type: 'POST',
              dataType : 'JSON',
              resetForm: false,
              data: '',
              context : '',

              beforesubmit: function (formData, jqForm, options) {
                 $.mobile.loading('show');
              },
              beforeSend : function(formData, jqxhr,options) {
                            $.mobile.loading('show');
              },
              success:  function (data, statusText, xhr, $form)  {

                          $.mobile.loading('hide');
                          var message = '';
                          $("#message-title").text('');

                           if(data.error.length == 0 ) {

                            message += "<div class='alert alert-success' > <b> " + data.message + " </b> </div>";
                            } else {
                              $("#message-title").text('Error!!!');
                              message += "<div class='alert alert-danger' >  <b> "+ data.message + "  </b> <br/>";

                             for(i = 0 ; i < data.error.length ; i++) {
                              message +=  data.error[i] + "<br/>";
                             }

                            message += "</div>";
                            }

                            if(data.warning.length) {
                              message += "<div class='alert alert-warning' > <b>  WARNING!!! </b> <br/>";
                            for(i = 0 ; i < data.warning.length ; i++) {
                              message +=  data.warning[i] + "<br/>";

                              if(i+1 == data.warning.length) {

                              }

                            }
                                message += "</div>";
                          }
                          if(data.notice.length) {
                              message += "<div class='alert alert-info' > <b> NOTICE !!! </b> <br/>";

                                  for(i = 0 ; i < data.notice.length ; i++) {
                                    message +=  data.notice[i] + "<br/>";
                                  }
                              message += "</div>";
                          }

                          $("#message-body").empty();
                              $("#message-body").append(message);

                                            $("#modal-message").modal("show");
                    } ,
                    error: function(data, error, errorCode){

                   $("#message-body").empty();
                       $("#message-body").append(error.responseText);

                                     $("#modal-message").modal("show");
                  }
                   }

$(document).on("click",".ticket-info", function(){

          var discription = $(this).data("Discription");
          $("#message-body").empty();
                       $("#message-body").append(discription);

                                     $("#modal-message").modal("show");

});

function getEventDetails(data) {

    var organizer =  (data.organizationName) ? data.organizationName : data.organizerName;

        $("#event-name").text(data.eventName);
        $("#event-locat").text(data.location);
        $("#venue-name").text(data.venue);
        $("#organizer-name").text(organizer);
        $("#organizer-bio").text(data.aboutOrganizer);

        $("#eventDiscription").text(data.aboutEvent);
        $("#event-startdate").attr("datatime", data.startDate + 'T' + data.startTime );
        $("#event-enddate").attr("datatime", data.endDate + 'T' + data.endTime );
        $("#event-startdate").text(data.startDate + ' at ' +  data.startTime );
        $("#event-enddate").text(data.endDate+ ' at ' +  data.endTime );



        var eventImage = (data.eventImage!= null) ? POSTER_LOCATION+data.eventImage : eventImagePlaceholder;



        $("#event-image-container").attr("src" , eventImage);





        if(!data.ticket){

          $("#ticket-area").hide();
        } else {
        ticket="";
        $("#ticket-area").show();
        total_created = data.ticket.length;
        sold_out = 0;
         $("#tickets-table-body").empty();
        for(x = 0; x < data.ticket.length ; x++ ){


            var ticketRecord = $("<tr/>");

            var ticketName = $("<td/>", { text : data.ticket[x].ticketName } );
            var ticketType = $("<td/>", { text : data.ticket[x].ticketType } );
            var ticketDiscription = $("<td/>");
            var infoButton = $("<button/>");
            infoButton.data("Discription" , data.ticket[x].aboutTicket );
            infoButton.data("enhanced" , true);
            infoButton.attr("class" , "btn btn-link ticket-info");

            infoButton.append("<span class='glyphicon glyphicon-cloud'> </span>" );
            ticketDiscription.append(infoButton);

            var ticketAvailable = $("<td/>", {
                                                text : (data.ticket[x].availableTicket >= 1 ) ?
                                                        data.ticket[x].availableTicket :
                                                        "SOLD OUT"
                                                });

              var ticketPrice = $("<td/>", { text : (data.ticket[x].ticketPrice > 0 ) ?
                                                      data.ticket[x].ticketPrice :
                                                      "FREE"
                                            });


                $(ticketRecord).append(ticketName)
                                .append(ticketType)
                                .append(ticketAvailable)
                                .append(ticketPrice)
                                .append(ticketDiscription);

              $("#tickets-table-body").append(ticketRecord);
        }
        if(sold_out == total_created){

        }



        }


      guest="";


    $("#guests-container").empty();

      if(data.guest == undefined ){
              $("#guest-area").hide();

      } else {


            $("#guest-area").show();

            for(x = 0; x < data.guest.length; x++ ){

                var guestDiv = $("<div/>", { "class" :"col-sm-4 col-md-6" } );
                $(guestDiv).attr("style" , "{text-align : center}");


          //      thumbnailDiv.attr({"width" : "100px", "height": "100px" , "position": "relative"});
            //    thumbnailDiv.append($("<div/>", {"class" : "loading-gif"} ));

                var guestImage = $("<img/>", {
                                                src : (data.guest[x].guestImage) ?
                                                      GUESTS_LOCATION + data.guest[x].guestImage :
                                                      sponsorImagePlaceholder,
                                               alt : "Error Loading Image",
                                               class : "img-circle",
                                               width : "100"


                                            }
                                  );


              var AKA = $("<em/>" ,  { text : data.guest[x].akaName });
              var guestName = $("<h3/>" , { text : data.guest[x].guestName});


                guestDiv.append(guestImage)
                        .append(guestName)
                        .append(AKA);


              $("#guests-container").append(guestDiv);

            }



        }



      $("#sponsors-container").empty();


         if(data.sponsor == undefined){
      $("#sponsors-area").hide();
    } else {
      $("#sponsors-area").show();
      sponsors = '';

              for(x = 0; x < data.sponsor.length; x++ ){


                      var sponsorLI =  $("<li/>")
                                        .append($("<img/>", {
                                                      src : (data.sponsor[x].sponsorImage) ?
                                                              SPONSORS_LOCATION + data.sponsor[x].sponsorImage :
                                                              sponsorImagePlaceholder,
                                                      alt : "Error Loading Image",
                                                      width : "100px",
                                                      class : "img-thumbnail img-responsive",
                                                      load : function() {

                                                      }

                                                    }
                                          ))

                                        .append($("<h5/>" , {text : data.sponsor[x].sponsorName }) );

                    $("#sponsors-container").append(sponsorLI);
              }

              $("#sponsors-container").listview("refresh");


          }


       comments = "";
       $("#comments-container").empty();
         if(data.comment == undefined){

        }else {

              for(x = 0; x < data.comment.length; x++ ){

                var commentLi = $("<li/>")
                               .append($("<h3/>", { text : data.comment[x].commenter } ) )
                               .append($("<p/>" , { text : data.comment[x].comment }))
                                .append($("<p/>" , {
                                                  text : data.comment[x].commentedOn,
                                                  class : "ui-li-aside"
                                                }));



                  $("#comments-container").append(commentLi);
              }


        $("#comments-container").listview('refresh');

      }
        $("#available-tickets").table("refresh");

         $('#event-map').locationpicker({
                                    location: {latitude: data.latitude , longitude:   data.longitude }
                     });

}

$(document).on("ready", function(){



});


function get_event_category(category){
$("#event-container").empty();
  $.ajax({
    type: "get",
    dataType : "JSON",
    data : {"get" : "event_category" , "category" : category },
    success : function(data, result, jqXHR) {
        $("#event-container").empty();
        $("#browse-event-container").empty();
          if(data != null) {

            display_events(data.event, "#event-container");
           $("#browse-event-container").append($("<h2/>", { "text" : "Current Event" }));

          } else {
              $("#browse-event-container").append("<h2 > Currently No Active Event Under This Category </h2> ");
          }

    }
  });
}
$(document).on("click", "#eventsList-btn", function(){

  get_event_category("ALL");

});


function display_events(events, container) {



       $.each(events,function(i,trending) {

          var priceRange = '';
          if(trending.minPrice == 0 && (trending.minPrice == trending.maxPrice)) {
              priceRange = 'FREE';
          } else if (trending.minPrice == trending.maxPrice) {
            priceRange = trending.minPrice + ' ETB';
          } else if (trending.minPrice != trending.maxPrice) {
            priceRange = trending.minPrice + ' - '+ trending.maxPrice+ ' ETB';
          }

        var image = (trending.eventImage) ? EVENT_PICTURE_LOCATION+trending.eventImage : eventImagePlaceholder;
        var location = trending.location+', '+ trending.address;

        var event = $("<li/>")

                      .append($("<a/>" , {
                                            "href" : "#",
                                            "class" : "show-detail",
                                            "data-id" : trending.eventId
                                            }))
                      .find("a")
                      .append($("<img/>" , {
                                              "src" : image,
                                              "alt": "ERROR Loading Image",
                                              "class" : "ui-li-thumb img-responsive",
                                              load : function () {
                                                  $(this).siblings("div.loading-gif").remove();
                                              }
                                              }
                                )
                              )

                      .append($("<h2/>" , { "text" : trending.eventName }))
                        .append($("<div/>", {"class" : "ui-li-aside",
                                            "text" : priceRange
                                          }))
                       .append($("<p/>", {
                                                              "text" : trending.startDate + " @ " + trending.startTime
                                                            }
                                                      )
                                                  )

                      .append($("<div/>", {"class" : "loading-gif" }))


                      .end()
                      .append($("<a/>" , {
                                            "href" : "#",
                                            "class" : "show-detail",
                                            "data-icon" : "gear"
                                            }
                                )
                              );

                    $(container).append(event).listview("refresh");


              });

}




function new_ticket_slot(){

        total_ticket = total_ticket + 1;

        var ticket_ROW = $("<tr/>");
              var TYPE = $("<td/>")
                           .append($("<fieldset/>", {"class" : "ui-field-contain"}))
                           .find("fieldset")
                           .append($("<label/>", {
                                                    "text": "ticket-type",
                                                    "for" : "ticket-type"+total_ticket,
                                                    "class": "ui-hidden-accessible"
                                                  }
                                    ))
                           .append($("<select/>", {
                                                    "name" : "ticket-type[]",
                                                    "data-role" : "flipswitch",
                                                    "required" : "required",
                                                    "class" : "ticket-type",
                                                    "id" : "ticket-type"+total_ticket
                                                }
                                    ))
                           .find("select")
                           .append($("<option/>", {
                                                "value" : "free",
                                                "selected" : "selected",
                                                "text" : "Free"
                           }))
                           .append($("<option/>", {
                                                "value" : "paid",
                                                "text" : "Pree"
                           }))
                           .end()
                           .end();

              var NAME = $("<td/>")
                            .append($("<fieldset/>", {"class" : "ui-field-contain"} ))
                            .find("fieldset")
                            .append($("<label/>" , {
                                                    "for" : "ticket-name"+total_ticket,
                                                    "class" : "ui-hidden-accessible",
                                                    "text" : "Ticket Name"
                                                 }
                                    ))
                            .append($("<input/>" , {
                                                    "type" : "text",
                                                    "required" : "required",
                                                    "placeholder" : "Name eg. Vip, EarlyBird, normal... ",
                                                    "name" : "ticket-name[]",
                                                    "id" : "ticket-name"+total_ticket,
                                                    "class" : "speech-input"
                                                 }
                                      )
                                    )
                            .end();
              var QUANTITY = $("<td/>")
                            .append($("<fieldset/>", {"class" : "ui-field-contain"} ))
                            .find("fieldset")
                            .append($("<label/>", {
                                                    "for" : "ticket-quantity"+total_ticket,
                                                    "class" : "ui-hidden-accessible",
                                                    "text" : "Ticket Quantity"
                                                 }
                                    ))
                            .append($("<input/>" , {
                                                    "type" : "number",
                                                    "required" : "required",
                                                    "min" : 0,
                                                    "placeholder" : "Quantity",
                                                    "name" : "ticket-quantity[]",
                                                    "id" : "ticket-quantity"+total_ticket,
                                                    "class" : "speech-input"
                                                 }
                                      )
                                    )
                            .end();
              var PRICE = $("<td/>")
                            .append($("<fieldset/>", {"class" : "ui-field-contain"} ))
                            .find("fieldset")
                            .append($("<label/>" , {
                                                    "for" : "ticket-price"+total_ticket,
                                                    "class" : "ui-hidden-accessible",
                                                    "text" : "Ticket Price"
                                                 }
                                    ))
                            .append($("<input/>" , {
                                                    "type" : "number",
                                                    "required" : "required",
                                                    "min" : 0,
                                                    "placeholder" : "Price",
                                                    "name": "ticket-price[]",
                                                    "id" : "ticket-price"+total_ticket,
                                                    "class" : "speech-input"
                                                 }
                                      )
                                    )
                            .end();
              var DISCRIPTION = $("<td/>")
                            .append($("<fieldset/>" , {"class" : "ui-field-contain"} ))
                            .find("fieldset")
                            .append($("<label/>" , {
                                                    "for" : "ticket-discription"+total_ticket,
                                                    "class" : "ui-hidden-accessible",
                                                    "text" : "Ticket Discription"
                                                 }
                                    ))
                            .append($("<textarea/>" , {
                                                    "required" : "required",
                                                    "placeholder" : "Ticket Discription",
                                                    "name" : "ticket-discription[]",
                                                    "id" : "ticket-discription"+total_ticket,
                                                    "class" : "speech-input"
                                                 }
                                      )
                                  )
                            .end();
                  var deleteButton = $("<td/>")
                                  .append($("<a/>", {
                                                    "data-role" : "button",
                                                    "data-icon" : "delete",
                                                    "data-iconpos" : "notext",
                                                    "data-theme" : "e",
                                                    "class" : "delete-record ui-corner-all",
                                                    "text" : "Delete",
                                                    "data-item" : "ticket"
                                  }));

                ticket_ROW.append(TYPE)
                          .append(NAME)
                          .append(QUANTITY)
                          .append(PRICE)
                          .append(DISCRIPTION)
                          .append(deleteButton);




                  return ticket_ROW;
}



function get_sponsor_field(total_sponsors){


  var  sponsor_field = $("<tr/>" , {"class" : "sponsor-field" });

            var NAME = $("<td/>", {"class" : "sponsor-name" } )
                          .append($("<fieldset/>", {"class" : "ui-field-contain" }))
                          .find("fieldset")
                          .append($("label", {
                                                "class" : "ui-hidden-accessible",
                                                "for" : "sponsor-name"+total_sponsors,
                                                "text" : "Sponsor Name"
                                                }
                                    )
                                  )
                          .append($("<input/>", {
                                                  "type" : "text",
                                                  "name" : "sponsor-name[]",
                                                  "id" : "sponsor-name"+total_sponsors,
                                                  "class" : "speech-input",
                                                  "required" : "required",
                                                  "placeholder" : "Sponsor Name"
                                                }
                                    )
                                  )
                            .end();


          var IMAGE = $("<td/>")
                          .append($("<a/>", {
                                                "data-enhanced" : "true",
                                                "class" : "add-image",
                                                "href" : "#"

                                                }
                                      )
                                    )
                          .find("a")
                          .append($("<img/>", {
                                                "src" : imagePlaceholder,
                                                "alt" : "ERROR loading Image",
                                                "width" : "100px",
                                                "class" : "img-thumbnail image-preview img-responsive"
                                             }
                                    )
                                  )
                          .end()
                          .append($("<input/>", {
                                                    "type" : "file",
                                                    "name" : "sponsor-image[]",
                                                    "accept" : "image/*",
                                                    "data-enhanced" : "true",
                                                    "class" : "ui-hidden-accessible"
                                                  }));



              var deleteButton = $("<td/>" , {"class" : "sponsor-remove"} )
                                .append($("<input/>", {
                                                    "data-theme" : "e",
                                                    "data-iconpos": "notext",
                                                    "data-icon" : "delete",
                                                    "class" : "delete-record ui-shadow ui-corner-all",
                                                    "text" : "Delete",
                                                    "data-item" : "sponsor"
                                                    }
                                          )
                                        );


                      sponsor_field.append(NAME)
                                  .append(IMAGE)
                                  .append(deleteButton);

                return sponsor_field;
}



function get_guest_field(total_guests){


      var GUEST_FIELD = $("<tr/>" , { "class" : "guest-field" } );


      var firstName = $("<td/>")
                      .append("<fieldset/>" , {"class" : "ui-field-contain" })
                      .find("fieldset")
                      .append($("<label/>", {
                                            "for" : "guest-first-name"+total_guests,
                                            "class" : "ui-field-contain",
                                            "text" : "First Name (required) "
                                          }
                                )
                              )
                      .append($("<input/>", {
                                              "type" : "text",
                                              "required" : "required",
                                              "name" : "guest-first-name[]",
                                              "id" : "guest-first-name"+total_guests,
                                              "placeholder" : "First Name (Required)",
                                              "class" : "speech-input"
                                            }
                                )
                              )
                      .end();

        var lastName = $("<td/>")
                      .append("<fieldset/>" , {"class" : "ui-field-contain" })
                      .find("fieldset")
                      .append($("<label/>", {
                                            "for" : "guest-last-name"+total_guests,
                                            "class" : "ui-field-contain",
                                            "text" : "Last Name (required) "
                                          }
                                )
                              )
                      .append($("<input/>", {
                                              "type" : "text",
                                              "required" : "required",
                                              "name" : "guest-last-name[]",
                                              "id" : "guest-last-name"+total_guests,
                                              "placeholder" : "Last Name (Required)",
                                              "class" : "speech-input"
                                            }
                                )
                              )
                      .end();

        var akaName = $("<td/>")
                      .append("<fieldset/>" , {"class" : "ui-field-contain" })
                      .find("fieldset")
                      .append($("<label/>", {
                                            "for" : "guest-aka-name"+total_guests,
                                            "class" : "ui-field-contain",
                                            "text" : "Stage/Nick Name (Optional)"
                                          }
                                )
                              )
                      .append($("<input/>", {
                                              "type" : "text",
                                              "name" : "guest-aka-name[]",
                                              "id" : "guest-aka-name"+total_guests,
                                              "placeholder" : "Stage/Nick Name (Optional)",
                                              "class" : "speech-input"
                                            }
                                )
                              )
                      .end();

      var guestImage = $("<td/>")
                          .append($("<a/>" , {
                                              "data-enhanced" : "true",
                                              "class" : "add-image",
                                              "href" : "#"
                                            }
                                    )
                                  )
                          .find("a")
                          .append($("<img/>" , {
                                                "class" : "img-thumbnail image-preview img-responsive ",
                                                "width" : "100px",
                                                "src" : sponsorImagePlaceholder,
                                                "alt" : "ERROR LOADING Image! "
                                              }
                                    )
                                  )
                          .end()
                          .append($("<input/>" , {
                                                    "type" : "file",
                                                    "class" : "ui-hidden-accessible",
                                                    "data-clear-btn" : "false",
                                                    "data-enhanced" : "true",
                                                    "accept" : "image/*",
                                                    "name" : "guest-image[]"

                                                }
                                      )
                                    );


          var deleteButton = $("<td/>", { "class" : "guest-remove"})
                            .append($("<a/>", {
                                                  "class" : "delete-record ui-shadow ui-corner-all",
                                                  "text" : "Delete Row",
                                                  "data-role" : "button",
                                                  "data-icon" : "delete",
                                                  "data-iconpos" : "notext" ,
                                                  "data-theme" : "e",
                                                  "data-item" : "guest"
                                                  }
                                      )
                                    );

        GUEST_FIELD.append(firstName)
                    .append(lastName)
                    .append(akaName)
                    .append(guestImage)
                    .append(deleteButton);


          return GUEST_FIELD;
}






function initialize_guest_fields(data, total_guests){
  var image = imagePlaceholder;


      if(data.guestImage) {
        image = GUESTS_LOCATION+data.guestImage;
      }

      var GUEST_FIELD = $("<tr/>" , { "class" : "guest-field" } );


      var firstName = $("<td/>")
                      .append("<fieldset/>" , {"class" : "ui-field-contain" })
                      .find("fieldset")
                      .append($("<label/>", {
                                            "for" : "guest-first-name-update"+total_guests,
                                            "class" : "ui-field-contain",
                                            "text" : "First Name (required) "
                                          }
                                )
                              )
                      .append($("<input/>", {
                                              "type" : "text",
                                              "required" : "required",
                                              "name" : "guest-first-name-update[]",
                                              "id" : "guest-first-name-update"+total_guests,
                                              "placeholder" : "First Name (Required)",
                                              "class" : "speech-input",
                                              "value" : data.firstName
                                            }
                                )
                              )
                      .end();

        var lastName = $("<td/>")
                      .append("<fieldset/>" , {"class" : "ui-field-contain" })
                      .find("fieldset")
                      .append($("<label/>", {
                                            "for" : "guest-last-name-update"+total_guests,
                                            "class" : "ui-field-contain",
                                            "text" : "Last Name (required) "
                                          }
                                )
                              )
                      .append($("<input/>", {
                                              "type" : "text",
                                              "required" : "required",
                                              "name" : "guest-last-name-update[]",
                                              "id" : "guest-last-name-update"+total_guests,
                                              "placeholder" : "Last Name (Required)",
                                              "class" : "speech-input",
                                              "value" : data.lastName
                                            }
                                )
                              )
                      .end();

        var akaName = $("<td/>")
                      .append("<fieldset/>" , {"class" : "ui-field-contain" })
                      .find("fieldset")
                      .append($("<label/>", {
                                            "for" : "guest-aka-name-update"+total_guests,
                                            "class" : "ui-field-contain",
                                            "text" : "Stage/Nick Name (Optional)"
                                          }
                                )
                              )
                      .append($("<input/>", {
                                              "type" : "text",
                                              "name" : "guest-aka-name-update[]",
                                              "id" : "guest-aka-name-update"+total_guests,
                                              "placeholder" : "Stage/Nick Name (Optional)",
                                              "class" : "speech-input",
                                              "value" : data.akaName
                                            }
                                )
                              )
                      .end();

            var guestImage = $("<td/>", {"class" : "selected-file" })
                          .append($("<a/>" , {
                                                "data-enhanced" : "true",
                                                "class" : "add-image",
                                                "href" : "#"
                                              }
                                    )
                                  )
                          .find("a")
                          .append($("<img/>" , {
                                                "class" : "img-thumbnail image-preview img-responsive ",
                                                "width" : "100px",
                                                "src" : image,
                                                "alt" : "ERROR LOADING Image! "
                                              }
                                    )
                                  )
                          .end()
                          .append($("<input/>" , {
                                                    "type" : "file",
                                                    "class" : "ui-hidden-accessible",
                                                    "data-clear-btn" : "false",
                                                    "data-enhanced" : "true",
                                                    "accept" : "image/*",
                                                    "name" : "guest-image[]"
                                                }
                                      )
                                    );


          var deleteButton = $("<td/>", { "class" : "guest-remove"})
                            .append($("<a/>", {
                                                  "class" : "delete-record ui-shadow ui-corner-all",
                                                  "text" : "Delete Row",
                                                  "data-role" : "button",
                                                  "data-icon" : "delete",
                                                  "data-iconpos" : "notext" ,
                                                  "data-theme" : "e",
                                                  "data-id" : data.guestId,
                                                  "data-item" : "guest"
                                                  }
                                      )
                                    )
                            .append($("<input/>", {
                                                    "name" : "guest_id[]",
                                                    "data-enhanced" : "true",
                                                    "class" : "ui-hidden-accessible",
                                                    "value" : data.guestId,
                                                    "type" : "text"
                                                  }));

        GUEST_FIELD.append(firstName)
                    .append(lastName)
                    .append(akaName)
                    .append(guestImage)
                    .append(deleteButton);






        $("#guest-preview").append(GUEST_FIELD).enhanceWithin();
        $("#guest-preview").closest('table').table('refresh');

}



function initialize_sponsor_fields(data, total_sponsors){

  var image = imagePlaceholder;

      if(data.sponsorImage) {
        image = SPONSORS_LOCATION+data.sponsorImage;
      }

 var  sponsor_field = $("<tr/>" , {"class" : "sponsor-field" });

            var NAME = $("<td/>", {"class" : "sponsor-name" } )
                          .append($("<fieldset/>", {"class" : "ui-field-contain" }))
                          .find("fieldset")
                          .append($("label", {
                                                "class" : "ui-hidden-accessible",
                                                "for" : "sponsor-name-update"+total_sponsors,
                                                "text" : "Sponsor Name"
                                                }
                                    )
                                  )
                          .append($("<input/>", {
                                                  "type" : "text",
                                                  "name" : "sponsor-name-update[]",
                                                  "id" : "sponsor-name-update"+total_sponsors,
                                                  "class" : "speech-input",
                                                  "required" : "required",
                                                  "placeholder" : "Sponsor Name",
                                                  "value" : data.sponsorName
                                                }
                                    )
                                  )
                            .end();


          var IMAGE = $("<td/>" , {"class" : "sponsor-image-cell selected-file" } )
                          .append($("<a/>", {
                                                "data-enhanced" : "true",
                                                "class" : "add-image",
                                                "href" : "#"

                                                }
                                      )
                                    )
                          .find("a")
                          .append($("<img/>", {
                                                "src" : image,
                                                "alt" : "ERROR loading Image",
                                                "width" : "100px",
                                                "class" : "img-thumbnail image-preview img-responsive"
                                             }
                                    )
                                  )
                          .end()
                          .append($("<input/>", {
                                                    "type" : "file",
                                                    "name" : "sponsor-image-update[]",
                                                    "accept" : "image/*",
                                                    "data-enhanced" : "true",
                                                    "class" : "ui-hidden-accessible"
                                                  }));



              var deleteButton = $("<td/>" , {"class" : "sponsor-remove"} )
                                .append($("<a/>", {
                                                    "data-role" : "button",
                                                    "data-theme" : "e",
                                                    "data-iconpos": "notext",
                                                    "data-icon" : "delete",
                                                    "class" : "delete-record ui-shadow ui-corner-all",
                                                    "text" : "Delete",
                                                    "data-id" : data.sponsorId,
                                                    "data-item" : "sponsor"
                                                    }
                                          )
                                        )
                                .append($("<input/>", {
                                                        "type" : "text",
                                                        "value" : data.sponsorId,
                                                        "data-enhanced" : "true",
                                                        "name" : "sponsor-id[]",
                                                        "class" : "ui-hidden-accessible"
                                                      }
                                          )
                                        );


                      sponsor_field.append(NAME)
                                  .append(IMAGE)
                                  .append(deleteButton);





        $("#sponsor-box").append(sponsor_field).enhanceWithin();
        $("#sponsor-box").closest("table").table("refresh");


}


var CONFIRMATION =  "<h4 class='alert alert-warning ' > Are You Sure You Want To Delete This Item ??? </h4>";

  CONFIRMATION += "<button type='button' class='answer' data-theme='e' id='yes' > Yes </button> ";

  CONFIRMATION += "<button type='button' class='answer'  id='cancel' data-theme='b' > Cancel </button> ";


function initialize_ticket(data) {

    var event_tickets = '';

    for(i=0 ; i < data.length ; i++) {

    $("#ticket-box").empty();

        event_tickets = $("<tr/>")

        TYPE = $("<td/>")
                          .append($("<fieldset/>", { "class" : "ui-field-contain" } ))
                          .find("fieldset")
                          .append($("<label/>", {
                                                  "for" : "ticket-type-update"+i,
                                                  "class" : "ui-hidden-accessible",
                                                  "text" : "Ticket Type"
                                              }
                                    )
                                  )
                          .append($("<select/>", {
                                                  "name" : "ticket-type-update[]",
                                                  "required" : "required",
                                                  "class" : "ticket-type",
                                                  "id" : "ticket-type-update"+i,
                                                  "data-role" : "flipswitch"
                                                }
                                    )
                                )
                          .find("select")
                          .append($("<option/>", {
                                                    "value" : "free",
                                                    "text" : "Free"
                                                  }
                                    )
                                  )
                          .append($("<option/>", {
                                                    "value" : "paid",
                                                    "text" : "Paid"
                                                  }
                                    )
                                  )
                          .end()
                          .end();

            var NAME = $("<td/>")
                                .append($("<fieldset/>", { "class" : "ui-field-contain" } ))
                                .find("fieldset")
                                .append($("<label/>", {
                                                        "for" : "ticket-name-update",
                                                        "class" : "ui-hidden-accessible",
                                                        "text" : "Name"
                                                        }
                                          )
                                        )
                                .append($("<input/>", {
                                                        "type" : "text",
                                                        "required" : "required",
                                                        "placeholder" : "Name eg. Normal, VIP ... ",
                                                        "minlength" : "3",
                                                        "id" : "ticket-name-update"+i,
                                                        "class" : "speech-input",
                                                        "name" : "ticket-name-update[]",
                                                        "value" : data[i].ticketName

                                                      }
                                          )
                                        )
                                 .end();

                 var QUANTITY = $("<td/>")
                                  .append($("<fieldset/>", { "class" : "ui-field-contain" }))
                                  .find("fieldset")
                                  .append($("<label/>", {
                                                          "for" : "ticket-quantity-update"+i,
                                                          "class" : "ui-hidden-accessible",
                                                          "text" : "Quantity"
                                                        }
                                            )
                                          )
                                  .append($("<input/>" , {
                                                            "type" : "number",
                                                            "id" : "ticket-quantity-update"+i,
                                                            "class" : "speech-input",
                                                            "required" : "required",
                                                            "min" : "0",
                                                            "placeholder" : "Quantity",
                                                            "name" : "ticket-quantity-update[]",
                                                            "value" : data[i].availableTicket
                                                          }
                                            )
                                          )
                                  .end();
                    var PRICE = $("<td/>")
                                  .append($("<fieldset/>", {"class" : "ui-field-contain" }))
                                  .find("fieldset")
                                  .append($("<label/>", {
                                                          "for" : "ticket-price-update"+i ,
                                                          "class" : "ui-hidden-accessible",
                                                          "text" : "Price"
                                                         }
                                            )
                                          )
                                  .append($("<input/>", {
                                                          "type" : "number",
                                                          "name" : "ticket-price-update[]",
                                                          "id" : "ticket-price-update"+i,
                                                          "class" : "speech-input",
                                                          "required" : "required",
                                                          "value" : data[i].ticketPrice
                                                          }
                                            )
                                          )
                                  .end();

            (data[i].ticketPrice == 0  || data[i].ticketPrice == 'FREE') ? PRICE.find("input[type=number]").prop("disabled" , true) : PRICE.find("input[type=number]").prop("disabled" , false);


                    var DISCRIPTION = $("<td/>")
                                        .append($("<fieldset/>", {"class" : "ui-field-contain"}) )
                                        .find("fieldset")
                                        .append($("<label/>", {
                                                                "for" : "ticket-discription-update"+i,
                                                                "class" : "ui-hidden-accessible",
                                                                "value" : "Discription"
                                                              }
                                                  )
                                                )
                                        .append($("<textarea/>", {
                                                                  "value" : data[i].aboutTicket,
                                                                  "name" : "ticket-discription-update[]",
                                                                  "id" : "ticket-discription-update"+i,
                                                                  "required" :"required",
                                                                  "placeholder" : "Write some Discription",
                                                                  "class" : "speech-input"

                                                                }
                                                  )
                                                )
                                        .end();


                var deleteButton = $("<td/>")
                                      .append($("<a/>", {
                                                          "data-role" : "button",
                                                          "data-icon" : "delete",
                                                          "data-iconpos" : "notext",
                                                          "data-theme" : "e",
                                                          "data-id" : data[i].ticketId,
                                                          "data-item" : "ticket",
                                                          "class" : "ui-btn-icon-right ui-btn-e ui-corner-all delete-record speech-input",
                                                          "text" : "Delete"
                                                        }
                                                )
                                              )
                                    .append($("<input/>", {
                                                              "type": "text",
                                                              "name" : "ticket_id[]",
                                                              "data-enhanced" : "true",
                                                              "value" : data[i].ticketId,
                                                              "class" : "ui-hidden-accessible"
                                                          }
                                              )
                                            );



        event_tickets.append(TYPE)
                      .append(NAME)
                      .append(QUANTITY)
                      .append(PRICE)
                      .append(DISCRIPTION)
                      .append(deleteButton);

         $("#ticket-box").append(event_tickets).enhanceWithin();




            }




                      table = $("#ticket-box").closest("table");
                      table.table("refresh");



}


$(document).on("change", ".change-status", function(e) {
var CHANGE = null;

        if(this.val() === "ON" ) {
          CHANGE = "ACTIVE";
        } else {
          CHANGE = "DRAFT";
        }

        var Event = $(this).attr("id");

        $.ajax({
                  url: "includes/systemController.php",
                  data: {get: "change_status", event_id : Event , organizer_id: localStorage.organizer_id, change_to: CHANGE },
                  dataType : "JSON",
                  type: "GET",
                  cache : false,
                  success : function(data, resultText, jqxhr ) {


                            $("#message-body").empty();
                            $("#message-body").append( data.message);
                            $("#modal-message").modal('show');

                  },
                  error: function(data, error, errorCode){
                    alert(error +' '+errorCode);
                  }
        });

});

function display_event_summary(data, statusText, jqxhr) {

  status_change =  "<select class='change-status' id=''+data.EVNT_ID+'' data-role='flipswitch' >";
  status_change +=  "<option value='OFF'  selected='selected' >  Deactivate </option>";
  status_change +=   "<option value='ON' > Make Active </option>";
  status_change += "</select>";

  $("#change-status").empty();
        $("#change-status").append(status_change).enhanceWithin();

          if(statusText === "success") {

             $("#selected-event-image").empty();

            if(data.eventImage != null){

                  $("#selected-event-image").attr( "src", EVENT_PICTURE_LOCATION+data.eventImage);

            } else {
                $("#selected-event-image").attr( "src", eventImagePlaceholder);
            }


             $("#selected-event").text(data.eventName);

            $("#selected-event-venue").text(data.venue);
            $("#selected-event-location").text(data.location);
            $("#selected-event-start").text(data.startDate);
            $("#selected-event-end").text(data.endDate);
            $("#selected-event-about").text(data.aboutEvent);
            $("#selected-event-status").text(data.eventStatus);
            console.log(data);

            var ticket = '';

              if(data.ticket) {
              for(i = 0; i < data.ticket.length; i++) {
                ticket += "<tr>"+

                              "<td><strong>"+data.ticket[i].ticktetName+" </strong> </td>"+
                                  "<td>"+data.ticket[i].ticketType+"</td>"+
                                          "<td>"+data.ticket[i].ticketPrice+"</td>"+

                                          "<td>"+data.ticket[i].confirmedBooking   +"</td>"+


                                  "</tr>";
              }

               $("#selected-event-ticket").empty();
              $("#selected-event-ticket").append(ticket);

            }




var sponsor_field = "<li data-role='list-divider'> Event Sponsors  </li>";
             if(data.sponsor) {

                  for(i=0 ; i < data.sponsor.length; i++ ) {
                    sponsor_field +=  "<li>";
                    if(data.sponsor[i].sponsorImage) {
                    sponsor_field += "<img src='"+SPONSORS_LOCATION+ data.sponsor[i].sponsorImage +"' width='80' class='img-thumbnail'  />  ";
                    } else {
                     sponsor_field += "<img src='"+sponsorImagePlaceholder+"' width='80' class='iimg-thumbnail'  />  ";
                    }
                    sponsor_field +=  "<h3 >"+ data.sponsor[i].sponsorName +"</h3>  ";
                    sponsor_field += "</li>";
                  }

                  $("#selected-event-sponsor").empty();
                  $("#selected-event-sponsor").append(sponsor_field);
                   $("#selected-event-sponsor").listview("refresh");
              }
var guest_field = "  <li data-role='list-divider'> Event Guest  </li>";
              if(data.guest) {

                  for(i=0 ; i < data.guest.length; i++ ) {
                    guest_field +=  "<li>";
                    if(data.guest[i].guestImage) {
                    guest_field += "<img src='"+GUESTS_LOCATION+ data.guest[i].guestImage +"' width='80' class='img-thumbnail'  />  ";
                    } else {
                     guest_field += "<img src='"+sponsorImagePlaceholder+"' width='80' class='img-thumbnail'  />  ";
                    }
                    guest_field +=  "<h3 >"+  data.guest[i].guestName +"</h3>  ";
                    guest_field +=  "<em >"+ data.guest[i].akaName  +"</em>  ";
                    guest_field += "</li>";

                  }

                  $("#selected-event-guest").empty();
                  $("#selected-event-guest").append(guest_field);
                   $("#selected-event-guest").listview("refresh");
              }
          }


}

function initialize_address_form(data){
var address_form = "";

$("#address-container").empty();
      for(i=0; i < data.length; i++){

         var  address_form = $("<tr/>", { "class" : "address-field" } )

    var  COUNTRY =  $("<td/>")
                      .append($("<fieldset/>", {"class" : "ui-field-contain"} ))
                      .find("fieldset")
                      .append($("<label/>", {
                                                "class" : "ui-hidden-accessible",
                                                "text" : "Country",
                                                "for" : "organization-country-update"+total_address,

                                            }
                                )
                              )
                      .append($("<input/>", {
                                            "type" : "text",
                                            "name" : "organization-country-update[]",
                                            "id" : "organization-country-update"+total_address,
                                            "placeholder" : "country",
                                            "value" : data[i].country
                                          }
                                )
                            )
                      .end();
        var  CITY =  $("<td/>")
                      .append($("<fieldset/>", {"class" : "ui-field-contain"} ))
                      .find("fieldset")
                      .append($("<label/>", {
                                                "class" : "ui-hidden-accessible",
                                                "text" : "City",
                                                "for" : "organization-city-update"+total_address

                                            }
                                )
                              )
                      .append($("<input/>", {
                                            "type" : "text",
                                            "name" : "organization-city-update[]",
                                            "id" : "organization-city-update"+total_address,
                                            "placeholder" : "City",
                                            "value" : data[i].city
                                          }
                                )
                            )
                      .end();

          var  SUB_CITY =  $("<td/>")
                      .append($("<fieldset/>", {"class" : "ui-field-contain"} ))
                      .find("fieldset")
                      .append($("<label/>", {
                                                "class" : "ui-hidden-accessible",
                                                "text" : "Sub-City",
                                                "for" : "organization-sub-city-update"+total_address,
                                            }
                                )
                              )
                      .append($("<input/>", {
                                            "type" : "text",
                                            "name" : "organization-sub-city-update[]",
                                            "id" : "organization-sub-city-update"+total_address,
                                            "placeholder" : "Sub-City",
                                            "value" : data[i].subCity
                                          }
                                )
                            )
                      .end();

          var  COMMON_NAME =  $("<td/>")
                      .append($("<fieldset/>", {"class" : "ui-field-contain"} ))
                      .find("fieldset")
                      .append($("<label/>", {
                                                "class" : "ui-hidden-accessible",
                                                "text" : "Common Name or Building Name",
                                                "for" : "common-name-update"+total_address,
                                            }
                                )
                              )
                      .append($("<input/>", {
                                            "type" : "text",
                                            "name" : "common-name-update[]",
                                            "id" : "common-name-update"+total_address,
                                            "placeholder" : "Common Name or Building Name",
                                            "value" : data[i].location
                                          }
                                )
                            )
                      .end();



      MAP  = "<td>";
      MAP += " <a href='#event-map-popup"+total_address+"' data-transition='slideup' data-rel='popup' class='ui-btn ui-btn-c  ui-alt-icon ui-nodisc-icon ui-corner-all ui-btn-icon-notext ui-icon-plus'  data-position-to='window' > Use Map</a> ";
      MAP +=  " <div data-role='popup' id='event-map-popup"+total_address+"' class='ui-content' data-overlay-theme='c' data-theme='b' >";
      MAP +=       "<a href='#'  data-rel='back' data-role='button' data-transition='slidedown' data-theme='a' data-icon='delete' data-iconpos='notext' class='ui-btn-right' > Close</a>";
      MAP +=           "<div id='organization-map"+total_address+"'  class='ui-body-b' style='margin-top: 10px;  width: 300px; height: 150px;'> </div>";
      MAP +=            "<fieldset class='ui-field-contain'>";
      MAP +=               "<label for='organization-longitude"+total_address+"' class='ui-hidden-accessible'> Longtiude </label>";
      MAP +=               "<input type='text' name='organization-longitude-update[]' data-clear-btn='false'  value='"+data[i].longitude+"' readonly id='organization-longitude"+total_address+"' />";
      MAP +=             "</fieldset>";
      MAP +=             "<fieldset class='ui-field-contain'>";
      MAP +=                "<label for='organization-latitude"+total_address+"' class='ui-hidden-accessible'> Longtiude </label>";
      MAP +=                "<input type='text' name='organization-latitude-update[]'   data-clear-btn='false' value='"+data[i].latitude+"' readonly id='organization-latitude"+total_address+"' />";
      MAP +=              "</fieldset>";
      MAP +=          "</div>"
      MAP += "</td>";



       var deleteButton = $("<td/>")
                        .append($("<a/>" , {
                                            "data-role" : "button",
                                            "class" : "delete-record ui-btn ui-btn-e  ui-alt-icon ui-nodisc-icon ui-corner-all ui-btn-icon-notext ui-icon-delete",
                                            "text" : "Delete",
                                            "data-id" : data[i].addressId,
                                            "data-item" : "address"
                                          }
                                )
                              )
                        .append($("<input/>", {
                                                "type" : "text",
                                                "name" : "address-id[]",
                                                "id" : "address-id"+total_address,
                                                "class" : "ui-hidden-accessible",
                                                "data-enhanced" : "true",
                                                "value" : data[i].addressId
                                              }
                                  )
                                );


      address_form.append(COUNTRY)
                  .append(CITY)
                  .append(SUB_CITY)
                  .append(COMMON_NAME)
                  .append(MAP)
                  .append(deleteButton);

        $("#address-container").append(address_form);
                  $("#address-container").enhanceWithin();
                     $("#address-table").table("refresh");
                     $("#organization-map"+total_address).locationpicker({
                            location: {latitude: data[i].latitude  , longitude:   data[i].longitude},
                            enableAutocomplete: true,
                            radius: 20,
                            inputBinding: {
                                              latitudeInput: $('#organization-latitude'+total_address),
                                              longitudeInput: $('#organization-longitude'+total_address),


                                            },
                                onchanged: function(currentLocation, radius, isMarkerDropped) {
                              //  alert("Location changed. New location (" + currentLocation.latitude + ", " + currentLocation.longitude +", "+ currentLocation.locationNameInput +" )");
                              var addressComponents = $(this).locationpicker("map").location.addressComponents;
                                  $("#organization-city"+total_address).val(addressComponents.city);
                                   $("#organization-country"+total_address).val(addressComponents.country);
                              },
                               oninitialized: function(component){
                                                   var addressComponents = $(component).locationpicker("map").location.addressComponents;
                                              }
                              });



        total_address = total_address + 1;
      }




}


function create_address_form(){


    var  address_form = $("<tr/>", { "class" : "address-field" } )

    var  COUNTRY =  $("<td/>")
                      .append($("<fieldset/>", {"class" : "ui-field-contain"} ))
                      .find("fieldset")
                      .append($("<label/>", {
                                                "class" : "ui-hidden-accessible",
                                                "text" : "Country",
                                                "for" : "organization-country"+total_address,
                                            }
                                )
                              )
                      .append($("<input/>", {
                                            "type" : "text",
                                            "name" : "organization-country[]",
                                            "id" : "organization-country"+total_address,
                                            "placeholder" : "country"
                                          }
                                )
                            )
                      .end();
        var  CITY =  $("<td/>")
                      .append($("<fieldset/>", {"class" : "ui-field-contain"} ))
                      .find("fieldset")
                      .append($("<label/>", {
                                                "class" : "ui-hidden-accessible",
                                                "text" : "City",
                                                "for" : "organization-city"+total_address,
                                            }
                                )
                              )
                      .append($("<input/>", {
                                            "type" : "text",
                                            "name" : "organization-city[]",
                                            "id" : "organization-city"+total_address,
                                            "placeholder" : "City"
                                          }
                                )
                            )
                      .end();

          var  SUB_CITY =  $("<td/>")
                      .append($("<fieldset/>", {"class" : "ui-field-contain"} ))
                      .find("fieldset")
                      .append($("<label/>", {
                                                "class" : "ui-hidden-accessible",
                                                "text" : "Sub-City",
                                                "for" : "organization-sub-city"+total_address,
                                            }
                                )
                              )
                      .append($("<input/>", {
                                            "type" : "text",
                                            "name" : "organization-sub-city[]",
                                            "id" : "organization-sub-city"+total_address,
                                            "placeholder" : "Sub-City"
                                          }
                                )
                            )
                      .end();

          var  COMMON_NAME =  $("<td/>")
                      .append($("<fieldset/>", {"class" : "ui-field-contain"} ))
                      .find("fieldset")
                      .append($("<label/>", {
                                                "class" : "ui-hidden-accessible",
                                                "text" : "Common Name or Building Name",
                                                "for" : "common-name"+total_address,
                                            }
                                )
                              )
                      .append($("<input/>", {
                                            "type" : "text",
                                            "name" : "common-name[]",
                                            "id" : "common-name"+total_address,
                                            "placeholder" : "Common Name or Building Name"
                                          }
                                )
                            )
                      .end();


      MAP = "<td>";
      MAP += " <a href='#event-map-popup"+total_address+"' data-transition='slideup' data-rel='popup' class='ui-btn ui-btn-c  ui-alt-icon ui-nodisc-icon ui-corner-all ui-btn-icon-notext ui-icon-plus'  data-position-to='window' > Use Map</a> ";
      MAP +=  " <div data-role='popup' id='event-map-popup"+total_address+"' class='ui-content' data-overlay-theme='c' data-theme='b' >";
      MAP +=       "<a href='#'  data-rel='back' data-role='button' data-transition='slidedown' data-theme='a' data-icon='delete' data-iconpos='notext' class='ui-btn-right' > Close</a>";
      MAP +=           "<div id='organization-map"+total_address+"'  class='ui-body-b' style='margin-top: 10px;  width: 300px; height: 150px;'> </div>";
      MAP +=           "<div class='ui-grid-a' > ";
      MAP +=           "<div class='ui-block-a' > ";
      MAP +=            "<fieldset class='ui-field-contain'>";
      MAP +=               "<label for='organization-longitude"+total_address+"' class='ui-hidden-accessible'> Longtiude </label>";
      MAP +=               "<input type='text' name='organization-longitude[]' class='ui-hidden-accessible' data-clear-btn='false' data-enhanced='true'  readonly id='organization-longitude"+total_address+"' />";
      MAP +=             "</fieldset>";
      MAP +=           "</div> ";
      MAP +=           "<div class='ui-block-b' > ";
      MAP +=             "<fieldset class='ui-field-contain'>";
      MAP +=                "<label for='organization-latitude"+total_address+"' class='ui-hidden-accessible'> Longtiude </label>";
      MAP +=                "<input type='text' name='organization-latitude[]' class='ui-hidden-accessible'  data-clear-btn='false' data-enhanced='true'  readonly id='organization-latitude"+total_address+"' />";
      MAP +=              "</fieldset>";
      MAP +=           "</div> ";
      MAP +=           "</div> ";
      MAP +=          "</div>"
      MAP += "</td>";


      var deleteButton = $("<td/>")
                        .append($("<a/>" , {
                                            "data-role" : "button",
                                            "class" : "delete-record ui-btn ui-btn-e  ui-alt-icon ui-nodisc-icon ui-corner-all ui-btn-icon-notext ui-icon-delete",
                                            "text" : "Delete",
                                            "data-item" : "address"
                                          }
                                )
                              );


address_form.append(COUNTRY)
            .append(CITY)
            .append(SUB_CITY)
            .append(COMMON_NAME)
            .append(MAP)
            .append(deleteButton);

                $("#address-container").append(address_form)
                  $("#address-container").enhanceWithin();
                     $("#address-table").table("refresh");
                     $("#organization-map"+total_address).locationpicker({
                            location: {latitude: 9.005401  , longitude:   38.763611},
                            enableAutocomplete: true,
                            radius: 20,
                            inputBinding: {
                                              latitudeInput: $("#organization-latitude"+total_address),
                                              longitudeInput: $("#organization-longitude"+total_address),


                                            },
                                onchanged: function(currentLocation, radius, isMarkerDropped) {
                              //  alert("Location changed. New location (" + currentLocation.latitude + ", " + currentLocation.longitude +", "+ currentLocation.locationNameInput +" )");
                              var addressComponents = $(this).locationpicker("map").location.addressComponents;
                                  $("#organization-city"+total_address).val(addressComponents.city);
                                   $("#organization-country"+total_address).val(addressComponents.country);
                              },
                               oninitialized: function(component){

                                              }
                              });



        total_address = total_address + 1;
}


$(document).on("mobileinit", function() {

      $.extend(  $.mobile , {
                              pageLoadErrorMessage: "Sorry Error Loading Page...",
                              defaultPageTransition: "slide",
                              defaultDialogTransition: "slideup",
                              loadingMessage: "Loading Request...",
                              loadingMessageTextVisible: true,
                              loadingMessageTheme: "b",
                              pageLoadErrorMessageTheme: "e",
                              hashListeningEnabled: true
                        //   subPageUrlKey: "E-gate",
                            }
              );

  // LOADING
      $.mobile.loader.prototype.options.text = "loading";
      $.mobile.loader.prototype.options.textVisible = true;
      $.mobile.loader.prototype.options.disabled = false;
      $.mobile.loader.prototype.options.theme = "a";
      $.mobile.loader.prototype.options.html = "";

     $.mobile.ajaxEnabled = true;
     $.mobile.linkBindingEnabled = true; //external Page ajax load
  //    $.mobile.ajaxEnabled = false;
//$.mobile.linkBindingEnabled = false;
//$.mobile.hashListeningEnabled = false;
//$.mobile.pushStateEnabled = false;
//$.mobile.changePage.defaults.changeHash = false;

    //LISTVIEW WIDGET SETTING
      $.mobile.listview.prototype.options.splitIcon = "gear";
      $.mobile.listview.prototype.options.splitTheme = "b";
      $.mobile.listview.prototype.options.inset = false;
      $.mobile.listview.prototype.options.dividerTheme = "b";
      $.mobile.listview.prototype.options.autodividersSelector = true;
      $.mobile.listview.prototype.options.filter = false;
      $.mobile.listview.prototype.options.filterTheme = "b";
      $.mobile.listview.prototype.options.filterPlaceholder = "Search...";
    //$.mobile.listview.prototype.options.filterCallback = customFilter;

    //$.mobile.page.prototype.options.keepNative = "button";
   $.mobile.toolbar.prototype.options.addBackBtn = true;
   //   $.mobile.dialog.prototype.options.addBackBtn = true;
      $.mobile.page.prototype.options.domCache =  false;
     $.mobile.dialog.prototype.options.backBtnText = "Back";
      $.mobile.textinput.prototype.options.clearBtnText = "Remove";
      $.mobile.textinput.prototype.options.mini = true;
      $.mobile.textinput.prototype.options.clearBtn = true;

//$.mobile.dialog.prototype.options.theme = "d";
      $.mobile.dialog.prototype.options.overlayTheme = "a";


   //  $.mobile.ignoreContentEnabled = true;
      $.mobile.orientationChangeEnabled = false;



});





$(function(){

      $( window ).orientationchange();
      $( window ).on( "orientationchange", function( event ) {

          if(event.orientation === "landscape"){

            } else if (event.orientation === "portrait"){

            }
      });

});

$( document ).ajaxComplete(function( event, request, settings ) {
       $.mobile.loading("hide");
});

$.ajaxSetup({

      url: "http://localhost/project/egate/includes/systemController.php",
      cache: false,
      ifModifid: true
});


$( document ).ajaxSend(function( event, jqxhr, settings ) {

      $.mobile.loading("show");

});


$( document ).ajaxError(function( error, request, settings ) {

         $("#message-body").empty();
        $("#message-body").text(request.responseText);
        $("#modal-message").modal("show");
        console.log(request);
});

$( document ).ajaxStart(function() {

});

$( document ).ajaxStop(function() {
 $.mobile.loading("hide");

});



$(window).unload(function(){

  if(localStorage.organizer_id !== "undefined"){
    localStorage.removeItem(localStorage.organizer_id);
  }
});



$(document).on("click", ".delete-record" ,function(){

          item = $(this);

          var    itemId = ($(this).data("id")) ? $(this).data("id") : null ;



                  if( item.closest("tbody").hasClass("one-required") &&
                      item.closest("tbody").find("tr").length == 1 )
                  {
                     message = "<div class='alert alert-warning' >  You Cannot have an event without atleast 1 Ticket  </div> ";


                     $("#message-body").empty();
                     $("#message-body").append(message);
                     $("#modal-message").modal("show");
                      return;
                  } else {
                      $("#message-body").empty();
                      $("#message-body").append(CONFIRMATION);
                      $("#message-body").enhanceWithin();
                      $("#modal-message").modal("show");
                  }

        var itemType = ($(this).data("item")) ? $(this).data("item") : null ;;




        $(document).on("click", ".answer", function() {

              answer = $(this).attr("id");

              if(answer == "yes"){

                  if(itemId) {
                    var deletedItem = null;


                      switch (itemType) {

                        case "sponsor":
                                        deletedItem = {get: "delete_sponsor" , sponsor_id : itemId, organizer_id: localStorage.organizer_id, event_id: localStorage.selected_event };
                                        break;
                        case "guest" :
                                        deletedItem = {get: "delete_guest" , guest_id : itemId, organizer_id: localStorage.organizer_id, event_id: localStorage.selected_event };
                                        break;
                        case "event" :
                                        deletedItem = "delete_event";
                                        break;
                        case "ticket" :
                                      deletedItem = {get: "delete_ticket" , ticket_id : itemId, organizer_id: localStorage.organizer_id, event_id: localStorage.selected_event };
                                      break;
                        case "address" :
                                      deletedItem = {get: "delete_address", address_id : itemId, organizer_id: localStorage.organizer_id };
                                      break;
                      }



                        $.ajax({

                                  data: deletedItem,
                                  type : "GET",

                                  success: function(data, result, jqxhr ){

                                      if(result == "success"){

                                          $("#message-body").empty();
                                          $("#message-body").append(data);

                                        } else {

                                          alert("error deleting");

                                        }

                                    }
                        });

                    } else {

                      $("#modal-message").modal("hide");

                    }

              item.closest("tr").remove();

              } else {

                  $("#modal-message").modal("hide");

              }

          });


});



 $(document).on("click","#log-off-button", function(e) {



                  $.ajax({

                          url: "logChecker.php",
                          data: {get: "log_out"},
                          dataType: "JSON",
                          type: "GET",
                          cache: false,
                          success: function(data){
                              if(data.success === "true"){
                                 update_navigation_to("normal");

                                  $("#menu-button").text("Menu");

                                      $( "body").pagecontainer( "change", "#homePage", { transition: "slide" });


                              } else {

                                    alert("error login out");
                              }
                          }
                  });




        });



$(document).on("pagecreate", "#signUpForm", function(){


        $("#registeration-form").validate({

          rules : {
            "organizer-re-password": {
              required: true,
              equalTo: "#organizer-password"
            }
          },
          messages: {

              "organizer-first-name": "Please Provide Your First Name",
              "organizer-last-name": "Please Provide Your Last Name",
              "organizer-password": "Please Provide Password",

              "organizer-email" : "Please Enter Valid Email address format like example@domain.com",
            "organizer-re-password": {
              required: "Please provide a password",

              equalTo: "Password Does't match"
            }
          }
        });



        formOptions.data = { form: "sign_up"};

        $("#registeration-form").ajaxForm({


                    type: "POST",
                    resetForm: false,
                    dataType: "JSON",
                    data: { form: "sign_up"},

                    beforesubmit: function (formData, jqForm, options) {
                       $.mobile.loading("show");
                    },

                    success:    function (data, statusText, xhr, $form)  {

                                       $.mobile.loading("hide");

                                       if(statusText === "success"){

                                       if(data.success == "true"){


                                              $("#message-title").append("<h5 class='alert alert-success'> Success!!! </h5>");
                                           update_navigation_to("admin");
                                              $("#message-body").append(data.message);
                                              $("#menu-button").text(data.organizer_name);
                                              $("#modal-message").modal("show");
                                              $.mobile.back();

                                       } else {
                                              $("#message-body").append(data.message);
                                              $("#modal-message").modal("show");
                                       }


                                       } else if(statusText === "error"){


                                            $("#message-title").append("<h5 class='alert alert-danger'> Upload Completed </h5>");
                                            $("#message-body").append(responseText);
                                            $("#modal-message").modal("show");
                                       }

                    },

                    uploadProgress: function(event, position, total, persentage){ }


                 });

});


$(document).on("pagebeforecreate", "#homePage", function(event, data){

      $.ajax(
              {

                  type:"GET",
                  dataType: "json",
                  data :{get : "trending_events"},
                  cache : false,

                    beforeSend: function() {
                                      //Show ajax spinner
                                        $.mobile.loading("show");
                                      },


                  success : function(data, status_code, jqXHR) {

                                if(status_code == 'success') {

                                    box = '';

                                    display_events(data, "#trending-events-box");

                                } else  {
                                          alert('Error While Loading Page Please Refresh Your Browser...');
                                }

                            },



                        complete: function(jqXHR, status_code){
                            //  alert(status_code +'   '+ jqXHR.responseJSON);
                         $.mobile.loading("hide");
                        }
              }

            );

});

$(document).on("click", ".show-detail", function(e){

        localStorage.selected_event = $(this).data("id");

        $("body").pagecontainer("change", "#eventsDetail", {transition: "slide"} );


});



// Update the contents of the toolbars
$( document ).on( "pagebeforeshow", "[data-role='page']", function() {


    var activePage = $.mobile.pageContainer.pagecontainer( "getActivePage" );
    $( "[data-role='header'] a.left-panel-button" ).remove();
    if($(activePage).hasClass('account-setting')){
      $( "[data-role='header']#main-header" ).prepend(ACCOUNT_PANEL_BUTTON);
    } else if($(activePage).hasClass('event-setting')) {
      $( "[data-role='header']#main-header" ).prepend(EVENT_PANEL_BUTTON);
    } else if($(activePage).hasClass('search-button')) {
      $( "[data-role='header']#main-header" ).prepend(SEARCH_BUTTON);
    } else if($(activePage).hasClass('back-button')) {


      $( "[data-role='header']#main-header" ).prepend(BACK_BUTTON);

    }
    var current = $( activePage ).jqmData( "title" );// Change the heading
    $( "[data-role='header'] h1" ).text( current );
    // Remove active class from nav buttons
    $( "[data-role='navbar'] a.ui-btn-active" ).removeClass( "ui-btn-active" );
    // Add active class to current nav button
    $( "[data-role='navbar'] a" ).each(function() {
        if ( $( this ).text() === current ) {
            $( this ).addClass( "ui-btn-active" );
        }
    });
});



$(document).on("click", "#event-creation-page-btn", function(){


Url = "http://localhost/project/egate/pages/eventCreationPage.html";

        $.ajax({
                  url: "logChecker.php",
                  type: "GET",
                  data:{get: "is_logged"},
                  dataType: "json",


                  success: function (data, statusText, jqXHR) {

                                if(data.loged === "true") {

                                 $( "body").pagecontainer( "change", Url , {transition : "flip"});

                                } else {
                                    $("body").pagecontainer( "change", "#signUpForm", { transition: "slideup" });
                                }
                         },
                  error: function (request,error, errorMessage) {

                    alert("error checking if loged in "+error+ "  "+ errorMessage);
                  }
              });

});




function update_navigation_to(value) {

  if(value === "admin") {
     admin_functions = "<li class='admin-panel'> <a href='http://localhost/project/egate/pages/eventManagment.html'> Manage Events </a> </li> "+
                    "<li class='admin-panel'> <a href='http://localhost/project/egate/pages/accountManagment.html'>  Manage Account </a>   </li>"+
                    "<li class='admin-panel'><a href='#' id='log-off-button'> Log Out </a></li>";

                      $(".normal-panel").remove();
                      if($(".admin-panel").length == 0){
                          $("#menu").append(admin_functions);
                          $("#menu-button").text(localStorage.organizer_name);
                      }
                      $("#menu").listview("refresh");







     } else if (value === 'normal') {

          normal_functions = "<li class='normal-panel' ><a href='#signUpForm' data-rel='dialog'> Sign Up </a></li>"+
                              "<li class='normal-panel' ><a href='#log-in-popup' data-position-to='window' data-rel='popup'> Log in </a></li>";


                      $(".admin-panel").remove();
                      if($(".normal-panel").length == 0){
                          $("#menu").append(normal_functions);
                      }
                         $("#menu").listview("refresh");


     }


}

$(document).on("pagecontainershow", function(event, data){
  // var sPageURL = window.location.search.substring(1);

         //   console.log(sPageURL);


         //   var event = sPageURL.split('=');







});
$(document).on("pagecontainerbeforecreate", function(event, data){ // When entering pagetwo




/*    var sURLVariables = sPageURL.split('&');
    for (var i = 0; i < sURLVariables.length; i++)
    {
        var sParameterName = sURLVariables[i].split('=');
        if (sParameterName[0] == sParam)
        {
            return sParameterName[1];
        }
    }

*/

          $( "[data-role='navbar']" ).navbar();
         $("[data-role=header]").toolbar({theme: "d"});
         $("[data-role=footer]").toolbar({theme:"d"});

        $("#event-categ-panel, #menu-panel,  #account-managment-panel,  #event-managment-panel").enhanceWithin().panel();
    $("#subscription-options-popup").enhanceWithin();
    //currentFile = document.location.pathname.match(/[^\/]+$/)[0];
    $("#subscription-options-popup").popup();
    $('#log-in-popup').popup();

          $("#log-in-form").enhanceWithin();



$(function($) {

       $.ajax({
                  url: 'logChecker.php',
                  type: 'GET',
                  data: {get: 'is_logged'},
                  dataType: 'json',

                  success: function (data, statusText, jqXHR) {

                                if(data.loged === 'true') {
                                  localStorage.organizer_id = data.organizer_id;
                                  localStorage.organizer_name = data.organizer_name;

                                     update_navigation_to('admin');

                              } else {
                                localStorage.organizer_id = null;
                                  update_navigation_to('normal');
                              }
                         },
                          error : function(yey, uuu, xxx, yyy) {
                    alert('error Getting Log Detail'+ yey +' '+uuu + '  '+ xxx, +'  '+ yyy);
                  }

              });
});



});


$(document).on("popuponcreate", "#log-in-popup", function(){

        $("#log-in-form").validate({
                                     messages: { "log-in-mail": "Please Provide The Email address you used to register",
                                      "log-in-password": "Please Provide the password you used when you register"
                                    },
                                    errorPlacement: function( error, element ) {
                                        error.insertAfter( element.parent() );
    }
                                  });


});




$(function() {

                  $("#log-in-form").ajaxForm({
                                        url: "includes/systemController.php",
                                        type: "POST",
                                        data: {form : "log_in" },
                                        dataType: "JSON",

                                         beforesubmit: function showRequest(formData, jqForm, options) {
                                                  $.mobile.loading("show");

                                            },
                                        success:    function showResponse(response, statusText, xhr)  {
                                              $.mobile.loading("hide");
                                                      if(response.success =="true") {
                                                        $("#menu-panel").panel("close");
                                                          $("#log-in-modal").modal("hide");
                                                        update_navigation_to("admin");
                                                        localStorage.organizer_id = response.organizer_id;
                                                        localStorage.organizer_name = response.organizer_name;
                                                        $("#menu-button").text(response.organizer_name);
                                                        $( "body").pagecontainer( "change", "#homePage", { transition: "slide" });
                                                      } else {
                                                        $("#log-in-error").html("<div class='alert alert-danger' >User Name or Password Incorrect Please try again </div>");
                                                      }

                                        },
                                           error : function(yey, uuu, xxx, yyy) {
                                               alert("error Login User "+ yey +" "+uuu + "  "+ xxx, +"  "+ yyy);
                                       }
                                  });

                });







$(document).on("pagecreate","#eventsDetail", function() {

         $("#share-buttons").sharepage();

          $('#comment-form').validate({
                                messages : {
                                  "commenter-name": "Please Enter Your Name ",
                                  "comment-content": "You should write Something  Minmum 20 characters"
                                }
                            });


         $("#comment-form").ajaxForm({

                                    type: "POST",
                                    data: {form: "comment", event_id: localStorage.selected_event},

                                    beforesubmit: function (formData, jqForm, options) {
                                       $.mobile.loading("show");
                                    },

                                   success:    function (responseText, statusText, xhr, $form)  {
                                         $.mobile.loading("hide");
                                         if(statusText = "success"){
                                             $("#comments-container").prepend(responseText).listview("refresh");
                                          } else {

                                          }
                                    }

                                  });

});




$(document).on("click", ".eventCategory", function(){

        requested_category =   $(this).attr("id");
              var activePage = $.mobile.pageContainer.pagecontainer( "getActivePage" );

              page = activePage.attr("id");



                $("body").pagecontainer("change", "#eventsList");
      var total_events = 0;
        get_event_category($requested_category);


});



$(document).on("pagebeforeshow", "#eventsDetail", function(e, data){



          $.ajax({
                  url: "includes/systemController.php",
                  type : "GET",
                  dataType: "json",


                  data: {get: "event_detail", event_id : localStorage.selected_event},
                  beforeSend: function() {
                                      //Show ajax spinner
                                        $.mobile.loading("show");

                                     $("#event-name").text("loading ...");

                                      $("#event-locat").text("loading ...");
                                      $("#venue-name").text("loading ...");



                                      $("#organizer-name").text("loading ...");
                                      $("#organizer-bio").text("loading ...");

                                      $("#eventDiscription").text("loading ...");
                                      $("#event-startdate").text("loading ...");
                                      $("#event-enddate").text("loading ...")
                                      $($("<div/>", {"class" : "loading-gif"})).appendTo("#event-image-container, #eventDiscription");

                                      },

                          complete: function() {
                                      // hide ajax spinner
                                      $.mobile.loading("hide");
                                    },

                  success: getEventDetails


          });



});


function display_tickets(data, statusText, jqXHR){
console.log(data);

      var tikets;
        $("#order-container").empty();
        for(i = 0 ; i < data.ticket.length; i++) {


          tikets = $("<tr/>");

          var ticketType =  $("<td/>")
                    .append($("<span/> ", { "text" : data.ticket[i].ticketType } ) );
          var ticketName = $("<td/>")
                    .append($("<span/> ", { "text" : data.ticket[i].ticketName } ) );
          var ticketDiscription = $("<td/>")
                    .append($("<span/> ", { "text" : data.ticket[i].aboutTicket } ) );
          var ticketAvailablity = $("<td/>")
                    .append($("<span/> ", { "text" : data.ticket[i].availableTicket } ) );
          var ticketPrice = $("<td/>")
                    .append($("<span/> ", { "text" : data.ticket[i].ticketPrice } ) );
          tikets.append(ticketType)
                  .append(ticketName)
                  .append(ticketDiscription)
                  .append(ticketAvailablity)
                  .append(ticketPrice);

        var ticketQuantity = $("<td/>");
          var ticketSelector = $("<td/>");

          if(data.ticket[i].availableTicket != 0 ) {
            ticketQuantity.append($("<input/>" , {
                                                    "type" : "number" ,
                                                    "pattern" : "[0-9]*",
                                                    "min" : '0',
                                                    "max" : data.ticket[i].availableTickets,
                                                    "data-clear-btn" : "true",
                                                    "class" : "ui-mini order-quantity ",
                                                    "disabled" : "disabled",
                                                    "required" : "required",
                                                    "name" : "orderQuantity[]",
                                                    "placeholder" : "Enter Amount ?"
                                                  }
                                    )
                                  );
            ticketSelector.append($("<input/>" , {
                                                    "type" : "checkbox" ,
                                                    "value" : data.ticket[i].ticketId,
                                                    "data-role" : "flipswitch",
                                                    "class" : "selected-ticket",
                                                    "data-on-text" : "Get",
                                                    "data-off-text" : "Off",

                                                    "name" : "ticket-id[]"

                                                  }
                                    )
                                  );

            tikets.append(ticketQuantity)
                  .append(ticketSelector);

            } else {
              ticketQuantity.append($("<span/>", {
                                                    "class" : "alert alert-info",
                                                    "text" : "SOLD OUT!!!"
                                                  }
                                      )
                                    )
                              .attr("colspan", "2");

                      tikets.append(ticketQuantity);
            }

        }

        $("#order-container").append(tikets);
        $("#ticket-list").enhanceWithin();
           $("#ticket-list").table("refresh");
}

$(document).on("change", ".selected-ticket", function(){


    if(this.checked == true){
      input = $(this).closest("tr").find(".order-quantity");
      $(input).textinput("enable");

    }else {

      input.textinput("disable");
    }

});

$(document).on("pagebeforeshow", "#ticket-order-page", function(){


      var payment = $("#has-mobile-payment");
    // newsletter topics are optional, hide at first
            $("#att-subscription").selectmenu("disable");
          payment.click(function(e) {

           if(this.checked == true){

               $("#att-subscription").selectmenu("enable");
           } else {
                $("#att-subscription").selectmenu("disable");
           }


});
            $("#ticket-order-form").validate({
                                          rules : {
                                               "att-subscription" : {
                                                        required : "#has-mobile-payment:checked"
                                                },
                                                orderQuantity : {
                                                      required : "#ticket-id:checked"
                                                }
                                          },

                                          messages :{
                                            "ticket-id": "you need to select ticket",
                                            "att-first-name": "Please Provide your first name",
                                            "att-last-name": "Please Provide your last name",
                                            "att-telephone": "Please Provide mobile number containing 10-13 Digits to finish booking"
                                          },

                                    errorPlacement: function( error, element ) {
                                          error.insertAfter( element.parent() );
                                     }


                                    });



            $("#ticket-order-form").ajaxForm({


                    type: "POST",
                    resetForm: true,
                    target: "#order-result",
                    data: { form: "order_form" ,event_id: localStorage.selected_event },

                    beforesubmit: function (formData, jqForm, options) {

                       $.mobile.loading("show");
                    },

                    success:    function (responseText, statusText, xhr, $form)  {

                                       $.mobile.loading("hide");

                                       if(statusText === "success"){

                                           $("#order-result").fadeIn("slow", 1000);
                                        } else if(statusText === "error"){

                                            $("#message-title").append("<h5 class='alert alert-danger'> Upload Completed </h5>");
                                            $("#message-body").append(responseText);
                                            $("#modal-message").modal("show");

                                       }

                    },



                 });


});



$(document).on("pagebeforeshow", "#ticket-order-page", function(){

      if(localStorage.selected_event === null){
        alert("sorry some error occured please try Again!!!");
      } else {
                  $.ajax({

                            type: "POST",
                            dataType: "JSON",
                            data: {get: "available_tickets", event_id : localStorage.selected_event },
                            success: display_tickets
                  });

      }


});

function create_reciept(data){

    var reciept = "";

      for(i=0; i < data.reciept.length ; i++){
              reciept += "<li> ";
              if(data.reciept[i].eventImage) {

                      reciept += "<img src='uploads/eventImages/"+data.reciept[i].eventImage+"' > ";

              } else {
                      reciept += "<img src='img/placeholder.jpg' > ";
              }

                  reciept += "<h2> Event : "+data.reciept[i].eventName+"</h2>";
                  reciept += "<h2> Event : "+data.reciept[i].venue+" </h2>";
                  reciept += "<p> Start Date : "+data.reciept[i].startDate+"    Time :  "+data.reciept[i].startTime+" </p>";
                  reciept += "<p> End Date : "+data.reciept[i].endDate+"    Time :  "+data.reciept[i].endTime+" </p>";
                  reciept += "<span class='ui-li-aside'> <strong> RECIEPT_No : </strong> "+data.reciept[i].recieptId+"</span>";
                  reciept += "</li>";

              }

          $("#ticket-container").empty();
          $("#ticket-container").append(reciept);
          $("#ticket-container").listview("refresh");



}

$(document).on("click", ".complete-order-btn", function(){


          localStorage.reservation_ID =   $(this).attr("id");

          $("body").pagecontainer("change", "#order-completion-page" );


});




$(document).on("click", "#download-pdf", function(){



          $.ajax({

                      data : {get: 'download_pdf', reservation_ID: localStorage.reservation_ID },
                      type: 'GET',
                      dataType: 'JSON',

                      success: function(data, statusText, jqxhr) {
                            $("#reservation-form").hide();

                                $.mobile.loading('hide');
                        }
              });




});


$(document).on("pagebeforeshow", "#order-completion-page", function(){

        $("#reciept-actions").hide();

                    if(localStorage.reservation_ID) {
                    $("#reservation-id-input").val(localStorage.reservation_ID);
                  $("#reservation-form").hide();


                    $.ajax({
                              url: "includes/systemController.php",
                              data : {get: "attendee_tickets", reservation_ID: localStorage.reservation_ID },
                              type: "GET",
                              dataType: "JSON",
                              cache: false,

                              success: function(data, statusText, jqxhr) {
                                    $("#reservation-form").hide();

                                    if(data.success === "true"){
                                      create_reciept(data.reciept);

                                    }

                              }
                    });

                    }else{
                      $("#reservation-form").show();
                    }

          $("#booking-confirmation-form").ajaxForm({
                                                      type: "POST",
                                                      resetForm: false,
                                                      data: "",

                                                      beforesubmit: function (formData, jqForm, options) {
                                                         $.mobile.loading("show");
                                                      },

                                                      success:    function (data, statusText, xhr, $form)  {

                                                                         $.mobile.loading("hide");

                                                                         if(data.success === "true"){

                                                                         create_reciept(data);

                                                                         } else if(data.success === "false"){

                                                                              $("#message-title").append("<h5 class='alert alert-danger'> Upload Completed </h5>");
                                                                              $("#message-body").append(data.message);
                                                                              $("#modal-message").modal("show");
                                                                         }

                                                      },

                                                      uploadProgress: function(event, position, total, persentage){ }


                                                   });
});


 function updateControls(addressComponents) {
      //$("#event-sub-city").val(addressComponents.addressLine1);
      $("#event-city").val(addressComponents.city);
      //$("#event-location").val(addressComponents.stateOrProvince);
      //$("#event-common-name").val(addressComponents.postalCode);
      $("#event-country").val(addressComponents.country);
}



$(document).on("pagebeforecreate", "#contact-organizer-page", function() {


              $("#contact-organizer-form").validate({
                                                        messages: {
                                                          "contact-org-firstname" : "Please Provide Your First Name",
                                                          "contact-org-lastname" : "Please Provide Your Last Name",
                                                          "contact-org-email" : "Please Provide a Valid email like example@something.com",
                                                          "contact-org-subject": "please provide Subject of Message",
                                                          "contact-org-message": "You need to write something before you can send the message"
                                                        }
                                                    });

              formOptions.data = {form: "contact_organizer", event_id: localStorage.selected_event };
                $("#contact-organizer-form").ajaxForm(formOptions);

});



$(document).on("pagebeforecreate","#event-creation-page", function(event) {

/*
      $("#event-create-map").locationpicker({
                                                location: {latitude: 9.005401  , longitude:   38.763611},
                                                enableAutocomplete: true,
                                                inputBinding: {
                                               latitudeInput :$("#event-latitude"),
                                               longitudeInput : $("#event-longitude")
                                             },
                                             radius : 10,
                                              onchanged: function(currentLocation, radius, isMarkerDropped) {
                                              //  alert("Location changed. New location (" + currentLocation.latitude + ", " +
                                              // currentLocation.longitude +", "+ currentLocation.locationNameInput +" )");
                                              },
                                              oninitialized: function(component){
                                                   var addressComponents = $(component).locationpicker('map').location.addressComponents;

                                              }
                                          });

*/


    $.ajax({
                  url: "logChecker.php",
                  type: "GET",
                  data: {get: "is_logged"},
                  dataType: "JSON",

                  success: function (data, statusText, jqXHR) {

                                if(data.loged !== "true") {
                                    $.mobile.pagecontainer("change", "#signUpForm");

                              } else {
                                        $.mobile.pagecontainer("change", "pages/eventCreationPage.html");
                              }
                         },
                  error: function (data, statusText, jqXHR) {
                      alert("hello");
                      console.log(statusText);

                  }


              });




});


$(document).on("pagebeforeshow","#event-creation-page", function() {

           $("#event-creation-form").validate({
                                          messages : {
                                                "ticket-type": "Please Specify The Ticket Type",
                                                "ticket-price": "Please Specify The Ticket Price",
                                                "ticket-quantity": "Please Specify the amount of ticket available for sale",
                                                "ticket-discription": "Please say something about the ticket like its purpose and what it can do",
                                                "ticket-sales-start-date": "Please Specify When the ticket should be available for sale",
                                                "ticket-sales-end-date": "Please Specify Till when the ticket will be Available",
                                                "event-start-date": "You Need to specify when the day your event starts",
                                                "event-end-date": "You Need to specify when the day your event ends",
                                                "event-start-time": "You Need to specify when the time your event starts",
                                                "event-end-time": "You Need to specify when the time your event end",
                                                "event-title": "Please specify name of event",
                                              "venue-name": "Please enter Venue name Where the event is hold",
                                              "event-common-name" : "Please Specify Common Name of the event location",
                                              "event-city" : "Pleace Provide City of the Event",
                                              "event-country": "Please Specify The  Country",
                                              "event-type": "Please Specify The  Type like Music, art, etc...",
                                              "event-discription" : "Please Say Something about the event so that viewers know what its about",

                                              "guest-first-name": "Please Provide First Name of the Guest",
                                                "guest-Last-name": "Please Provide Last Name of the Guest",
                                                 "sponsor-name" : "Please Provide Name Of this Sponsor or Remove this Row "
                                              }
                                          });


            $("#event-creation-post").click(function(){
                  ajaxFormOptions.data = {form: "new_event", organizer_id: localStorage.organizer_id, option: "OPEN" };
                  ajaxFormOptions.context = $("#event-creation-form");
                $("#event-creation-form").ajaxForm(ajaxFormOptions);
            });


            $("#event-creation-draft").click(function(){
              ajaxFormOptions.data = {form: "new_event", organizer_id: localStorage.organizer_id, option: "DRAFT" };
              ajaxFormOptions.context = $("#event-creation-form");

            $("#event-creation-form").ajaxForm(ajaxFormOptions);
            })

                    $(".date_input").datetimepicker(dateOptions);

                     $(".time_input").datetimepicker(timeOptions);

                     $(".date_input").datetimepicker(dateOptions);




 });



$(document).on("click", ".addticket", function(){


         $("#ticket-box").append(new_ticket_slot(total_ticket));
         $("#ticket-creator").enhanceWithin();
         table = $("#ticket-box").closest("table");
            table.table("refresh");


});



$(document).on("pagebeforeshow", "#event-dashboard", function(){


                        $.ajax({

                            dataType: "JSON",
                            data: {get: "event_statstics", organizer_id: localStorage.organizer_id, event_id : localStorage.selected_event},
                            cache: false,
                            type: "GET",

                            success: function(data, statusText, jqXHR){
                                ticketStatus = "";

                                          for(i = 0; i < data.length; i++){

                                            ticketStatus = "<div class='progress'>";
                                            ticketStatus +=   "<div class='progress-bar progress-bar-success' role='progressbar' ";
                                            ticketStatus +=    "aria-valuenow='"+ data[i].confirmedBooking +"' aria-valuemin='0' aria-valuemax='"+data[i].quantity+"' style='width: "+ data[i].confirmedBooking +"%;' >";
                                            ticketStatus +=     "<span >"+ (data[i].confirmedBooking / data[i].quantity) * 100 +" % sold </span>";
                                            ticketStatus += "</div>";
                                            ticketStatus +=  "</div>";

                                          }


                                           $("#ticket-stat").empty();
                                          $("#ticket-stat").append(ticketStatus);
                            },

                            error: function(error, xxx, yyy, zzz){
                              alert("error  "+ error +"  "+xxx+"  "+ yyy+ "  "+ "  "+zzz);
                            }

                        });







});

function check_in(data){
  console.log(data);
  bookings = "<li data-filtertext='"+data.recieptId+"'>";


bookings +="<h4> RECIEPT ID : "+data.recieptId +" </h4>";
bookings +="<p class='ui-li-aside'> Checked In : "+data.firstCheckIn +" <br>";
bookings +="last Checked In : "+data.lastCheckIn+" </p>";
 if(data.status == "IN" ){
bookings +=    "<input type='checkbox' checked='checked' data-role='flipswitch' name='check-ins-flipswitch' id='"+data.recieptId+"'   data-on-text='IN' data-off-text='OUT' class='check-ins-flipswitch' >";
} else {
 bookings +=    "<input type='checkbox'  data-role='flipswitch' name='check-ins-flipswitch' id='"+data.recieptId+"'   data-on-text='IN' data-off-text='OUT' class='check-ins-flipswitch' >";
}

bookings += "</li>";

              $("#check-ins").prepend(bookings);

                $("#check-ins").enhanceWithin();
                $("#check-ins").listview("refresh");


}

$(document).on("change", ".ticket-type", function(){

var   element = $(this);
var price_input = null;


      selected_type = element.val();

      if(selected_type == "free"){
        price_input = $(element).closest("tr").find("input.ticket-price");
        $(price_input).textinput("disable");
        $(price_input).val("0.00");
      } else if(selected_type == "paid" ){

        price_input = element.closest("tr").find("input.ticket-price");
        $(price_input).textinput("enable");
        $(price_input).val("");

        $.ajax({

                data: {get : "has_billing_address", organizer_id : localStorage.organizer_id },
                dataType: "JSON",
                cache: false,
                type: "GET",

                success : function(data, resultText, jqxhr ) {

                        if(data.success === "true"  ) {

                            if(data.message === "true") {

                            } else {

                                  message = "<div class='alert alert-info' > You Should Provided Billing address in order to create PAID Events </div> ";
                                  $("#modal-body").empty();
                                  $("#modal-body").append(message);
                                  $("#modal-message").modal("show");
                                  $(price_input).textinput("disable");
                                  $(price_input).val("0.00");

                            }
                        } else {
                            alert("error");
                        }
                }

        })

      }
});

$( document ).on( "change", ".check-ins-flipswitch",  function( event, ui ) {

  var ID = null;
         var act = null;

          if($(this).prop("checked") == false){
            act = "check_out";
          } else {
            act = "check_in";
          }

 ID = $(this).attr("id");

          $.ajax({

                    data: {get: "manage_check_in", request: act, organizer_id: localStorage.organizer_id, "reciept-id": ID, event_id : localStorage.selected_event },
                    type: "GET",
                    dataType: "JSON",
                    cache: false,
                    success: function(data, statusText, jqxhr){
                      console.log(data);
                     $("#message-body").empty()
                    $("#message-body").append(data);


                                     $("#modal-message").modal("show");
                    },error: function(error, xx,yy) {
                      $("#message-body").empty();
  console.log(error);
              $("#message-body").append(error);

           $("#modal-message").modal("show");
                    }

          });


} );


$(document).on("pagebeforeshow" , "#check-in-page", function(){


                    $.ajax({

                            type: "GET",
                            data: {get: "check_ins" , organizer_id: localStorage.organizer_id , event_id: localStorage.selected_event },
                            dataType: "JSON",
                            cache:false,


                            success: function(data, statusText, jqxhr){

                                $("#check-ins").empty();
                              for(i=0;i < data.length; i++){
                                check_in(data[i]);

                              }






                            },
                            error: function(error, xxx,yyy,zzz){
                              alert(error +"  "+yyy);
                            }


                    });



          $("#attendee-check-in").ajaxForm({


                    type: "GET",
                    dataType: "JSON",
                    resetForm: false,
                    cache:false,
                    data: {get: "check_in", organizer_id: localStorage.organizer_id, event_id: localStorage.selected_event },

                    beforesubmit: function (formData, jqForm, options) {
                       $.mobile.loading("show");
                    },

                    success:    function (data, statusText, xhr, $form)  {
                         console.log(data);
                                       $.mobile.loading("hide");

                                         check_in(data);

                                           $("#message-body").empty()
                      $("#message-body").append(data.message);





                    },
                     error: function(error, xxx, yyy, zzz){
                              $("#message-body").empty()
                    $("#message-body").append(error);
                    $("#modal-message").modal("show");
                    alert('error');
                    console.log(error);

                            },

                    uploadProgress: function(event, position, total, persentage){ }


                 });

});
$(document).on("pagecreate" , "#events-managment-page", function(){


  var open_event = "";
  var active_event = "";
  var ended_event = "";
  var draft_event = "" ;

                $.ajax({

                          data: {get: "organizer_events", organizer_id : localStorage.organizer_id },
                          dataType: "JSON",
                          type: "GET",

                          success: function(data, result, jqXHR) {


                              for( i = 0; i < data.length ; i++) {

                                  if(data.status = "ACTIVE" ) {

                                      active_event += "<li> <a href='#manage-event-page' class='update_event' id='"+ data[i].eventId +"'' >"+
                                                   "<img src='"+POSTER_LOCATION+""+data[i].eventImage +"' alt='image Not Found' />"+
                                                   "<h4>"+data[i].eventName+"</h4>"+
                                                  "</a> "+
                                                  "<a href='#' data-toggle='modal'     data-target='#myModal' class='delete_event' id='"+data[i].eventId+"' data-theme='e' data-icon='delete'>Delete</a> "+
                                              "</li> ";

                                    }


                                  if(data.status = "DRAFT") {

                                  draft_event +=  "<li> <a href='#manage-event-page' class='update_event' id='"+ data[i].eventId +"'' >"+
                                                   "<img src='"+POSTER_LOCATION+""+data[i].eventImage +"' alt='image Not Found' />"+
                                                   "<h4>"+data[i].eventName+"</h4>"+
                                                  "</a> "+
                                                  "<a href='#' data-toggle='modal'     data-target='#myModal' class='delete_event' id='"+data[i].eventId+"' data-theme='e' data-icon='delete'>Delete</a> "+
                                              "</li> ";


                                }



                          if(data.status = "CLOSED") {

                                  ended_event +=  "<li> <a href='#manage-event-page' class='update_event' id='"+ data[i].eventId +"'' >"+
                                                   "<img src='"+POSTER_LOCATION+""+data[i].eventImage +"' alt='image Not Found' />"+
                                                   "<h4>"+data[i].eventName+"</h4>"+
                                                  "</a> "+
                                                  "<a href='#' data-toggle='modal'     data-target='#myModal' class='delete_event' id='"+data[i].eventId+"' data-theme='e' data-icon='delete'>Delete</a> "+
                                              "</li> ";

                            }

                            if(data.status = "OPEN") {

                                  open_event +=  "<li> <a href='#manage-event-page' class='update_event' id='"+ data[i].eventId +"'' >"+
                                                   "<img src='"+POSTER_LOCATION+""+data[i].eventImage +"' alt='image Not Found' />"+
                                                   "<h4>"+data[i].eventName+"</h4>"+
                                                  "</a> "+
                                                  "<a href='#' data-toggle='modal'     data-target='#myModal' class='delete_event' id='"+data[i].eventId+"' data-theme='e' data-icon='delete'>Delete</a> "+
                                              "</li> ";
                             }

                            }



                            $("#draft-events").append(draft_event).listview("refresh").tabs();
                            $("#active-events").append(active_event).listview("refresh").tabs();
                            $("#ended-events").append(ended_event).listview("refresh").tabs();
                            //$("#active-events").append(open_event).listview("refresh").tabs();

                          }





                    });
                  $("#evente-managment-tab  li:eq(0) a").tab("show");

  });




$(document).on("pagebeforeshow", "#social-setting-page", function(){


            $.ajax({

                      data: {get: "social_addresses", organizer_id: localStorage.organizer_id },
                      type : "GET",
                      dataType: "JSON",
                      success : function(data, resultText, jqxhr ) {
                        alert(data);
                            console.log(data);
                              var socialMedia = $.parseJSON(data.social);
                              $("#organization-id").val(data.organizationId);
                              $("#twitter-address").val(socialMedia.twitter);
                              $("#facebook-address").val(socialMedia.facebook);
                              $("#youtube-address").val(socialMedia.youtube);

                      },
                      error(xxx, yyy, zzz){
                        console.log(xxx);
                      }
            });

    ajaxFormOptions.data = { form: "update_social_media" , organizer_id: localStorage.organizer_id} ;
    $("#social-setting-form").ajaxForm(ajaxFormOptions);



});






$(document).on("pagebeforeshow", "#update-contact-info", function(){

                  $("#organizer-pic-upload-btn").click(function(){

                          $("#organizer-profile-pic").click();
                      });


                      $("#organizer-profile-pic").change(function(event){

                                  var inp = event.target;

                      var reader = new FileReader();

                        reader.onload = function(){

                            var dataURL = reader.result;


                            $("#profile-pic-placeholder").attr("src", dataURL);

                      };
                      reader.readAsDataURL(inp.files[0]);


                      });

                                $("#UP-organizer-first-name").val("");
                                 $("#UP-organizer-last-name").val("");
                                 $("#edit-birthday").val("");


                                 $("#organizer-bio").val("");
                                 $("#organizer-position").val("");

          $.ajax({

                data: {get: "organizer_info", organizer_id : localStorage.organizer_id },
                dataType: "JSON",
                type:'GET',
                success: function(data, result, jqxhr){
                        console.log(data);
                            if(result === "success") {

                            if(data){

                                 $("#UP-organizer-first-name").val(data.firstName);
                                 $("#UP-organizer-last-name").val(data.lastName);
                                 $("#edit-birthday").val(data.birthdate);
                                 gender = $("input:radio[name=up-organizer-gender]").val("male");
                                 gender.prop("checked", true).checkboxradio("refresh");
                                 $("#organizer-bio").val(data.aboutOrganizer);
                                 $("#organizer-position").val(data.organizerPosition);
                                 if(data.picture){
                                 $("#profile-pic-placeholder").attr("src","../uploads/organizerImages/"+data.organizerImage);
                               }

                           } else {
                            alert("some problem occured fetching your mail try again");
                           }
                   }

                }

          });

          $("#basic_info_update_form").validate({
            messages: {
              "#UP-organizer-last-name": "Last Name Is Required Please Fill this Field",
              "#UP-organizer-first-name": "First Name Is Required Please Fill this Field"
            }
          })
        $(".date_input").datetimepicker(dateOptions);


      ajaxFormOptions.data = { form: "contact_info_update" , organizer_id: localStorage.organizer_id };
        $("#basic_info_update_form").ajaxForm(ajaxFormOptions);


});

$(document).on("pagebeforeshow", "#mail-change-page", function(){



      $.ajax({

                data: {get: "organizer_mail" },
                dataType: "JSON",
                type:"GET",
                success: function(data, result, jqxhr){

                        if(result === "success") {

                          if(data){

                                  $("#current-address").text(data);

                         } else {

                                alert("some problem occured fetching your mail try again");

                          }
                        }

                }

      });


      ajaxFormOptions.data = { form: "mail_change" , organizer_id: localStorage.organizer_id };

      $("#email-change-form").ajaxForm(ajaxFormOptions);


});


$(document).on("pagebeforeshow", "#password-change-page", function(){



    formOptions.data = { form: "password_change" , organizer_id: localStorage.organizer_id };

      $("#password-setting-form").ajaxForm(formOptions);

      $("#password-setting-form").validate({
                                      messages :{
                                              "current-password" : "Please Provide your Current Password",
                                              "new-password" : "Please Provide your new Password",
                                              "new-password-retype" : "Passwords Given Do not Math "
                                            },
                                            rules :{
                                              "new-password-retype" : {
                                                required: true,
                                                equalTo : "#new-password"
                                              }
                                            }
                                          });


});

$(document).on("pagebeforeshow", "#billing-address-setting-page", function(){

    formOptions.data = { form: "billing_address_update" , organizer_id : localStorage.organizer_id };
    $("#billing-address-setting-form").ajaxForm(formOptions);


});


$(document).on("pagebeforeshow", "#organization-info-setting-page", function(){


                $("#organization-name").val("");
                $("#organization-website").val("");
                $("#organization-info").val("");
                $("#organization-office-number").val("");
                $("#organization-mobile-number").val("");
                $("#organization-post-no").val("");


                $('#organization-logo-upload-btn').click(function(){

                  $("#organization-logo").click();
              });

              $("#organization-logo").change(function(event){

               var inp = event.target;

                var reader = new FileReader();

                reader.onload = function(){

                    var dataURL = reader.result;
                    $("#logo-placeholder").attr('src', dataURL);

                };

               reader.readAsDataURL(inp.files[0]);


              });


                  $.ajax({

                          data: {get: "organizer_info", organizer_id: localStorage.organizer_id },
                          dataType: "JSON",
                          type:"GET",
                          success: function(data, result, jqxhr){

                                  if(result === "success") {

                                    if(data){

                                          if(data.organizationLogo){

                                              $("#logo-placeholder").attr("src","../uploads/Organizations/"+data.organizationLogo);

                                            }

                                           officePhone = $.parseJSON(data.officeNumber);
                                           mobilePhone = $.parseJSON(data.mobileNumber);
                                           $("#organization-id").val(data.organizationId);
                                             $("#organization-name").val(data.organizationName);
                                             $("#organization-website").val(data.website);
                                             $("#organization-info").val(data.aboutOrganization);
                                             $("#organization-office-number").val(officePhone[0]);
                                             $("#organization-mobile-number").val(mobilePhone[0]);
                                             $("#organization-post-no").val(data.po_num);

                                         } else {

                                              alert("some problem occured fetching your mail try again");

                                        }

                                  }

                          }

                });



              $("#organization-info-setting-form").validate({
                                                              messages: {
                                                                    "#organization-website" : "Your website should be given in the valid format like http://www.something.com ",
                                                                    "#organization-mobile-number" : "Please Provide a valid number beween 10 and 12 digits ",
                                                                    "#organization-office-number" : "Please Provide a valid number beween 10 and 12 digits "
                                                              }

                                                            });

         ajaxFormOptions.data = { form: "organization_info_change", organizer_id: localStorage.organizer_id },

              $("#organization-info-setting-form").ajaxForm(ajaxFormOptions);


});


var eventLocation = {
                      location:  {latitude: 9.005401  , longitude:   38.763611},
                      enableAutocomplete: true,
       inputBinding: {

                      latitudeInput: $("#event-latitude-update"),
                      longitudeInput: $("#event-longitude-update")

                  },
                   radius: 10,
                onchanged: function(currentLocation, radius, isMarkerDropped) {
                  var addressComponents = $(this).locationpicker("map").location.addressComponents;
                       $("#event-city-update").val(addressComponents.city);
                       $("#event-country-update").val(addressComponents.country);

                    //  alert("Location changed. New location (" + currentLocation.latitude + ", " + currentLocation.longitude +", "+ currentLocation.locationNameInput +" )");
                  },
                oninitialized: function (component) {

                    var addressComponents = $(component).locationpicker("map").location.addressComponents;



                    }
              };

  $(document).on("pagebeforeshow", "#event-basics-update-page", function(){

                  $.ajax({

                            data: {"get": "event_basics", event_id: localStorage.selected_event },
                            type:"GET",
                            dataType: "JSON",
                            cache: false,

                            success : function(data, result, jqXHR){
                              console.log(data);


                                  if(result === "success") {

                                      if(data.eventImage){

                                        $("#event-image-placeholder").attr("src", "../uploads/eventImages/"+ data.eventImage);

                                      }
                                          $("#event-title-update").val(data.eventName);
                                          $("#venue-name-update").val(data.venue);
                                          $("#event-discription-update").val(data.aboutEvent);
                                          $("#event-country-update").val(data.country);
                                          $("#event-city-update").val(data.city);
                                          $("#event-sub-city-update").val(data.subCity);
                                          $("#event-common-name-update").val(data.location);


                                      }

                            } ,
                             error: function(data, result, jqxhr){

                                        alert(jqxhr);

                          }

                    });









             $("#event-image-update-btn").click(function(){
        // Simulate a click on the file input button
        // to show the file browser dialog
        $("#event-image-update").click();
    });

 $("#event-image-update").change(function(){
        readURL(this);
    });
            $("#event-basics-update-form").validate({

                                       messages: {
                                          "event-name-update": "Please specify name of event",
                                          "venue-name-update": "Please enter Venue name Where the event is hold",
                                          "event-common-name-update" : "Please Specify Common Name of the event location",
                                          "event-city-update" : "Pleace Provide City of the Event",
                                          "event-country-update": "Please Specify The  Country",
                                          "event-type-update": "Please Specify The  Type like Music, art, etc...",
                                          "event-discription-update" : "Please Say Something about the event so that viewers know what its about"
                                        }


            });

             ajaxFormOptions.data = { form: "event_basics_update", event_id: localStorage.selected_event, organizer_id : localStorage.organizer_id};

          $("#event-basics-update-form").ajaxForm(ajaxFormOptions);

});




$(document).on("pagebeforeshow", "#event-guest-update-page", function(){

                  $.ajax({

                            data: {get: "event_guests", organizer_id: localStorage.organizer_id, event_id: localStorage.selected_event },
                            type:"GET",
                            dataType: "JSON",

                            success : function(data, result, jqXHR){

                                  if(result === "success") {

                                     for(i = 0; i < data.length ; i++) {

                                         initialize_guest_fields(data[i], i);

                                   }

                                }
                            }
                    });


            $("#event-guest-update-form").validate({

                                        messages: {
                                                    "guest-firstname-update": "Please Provide First Name",
                                                    "guest-lastname-update": "Please Provide Last Name ",

                                                  }
                                      });

          ajaxFormOptions.data = {form: "guest_update" , organizer_id: localStorage.organizer_id, event_id: localStorage.selected_event };

            $("#guest-update-form").ajaxForm(ajaxFormOptions);




  });





    var total_guest_field = 1;

$(document).on("click", "#add-guest", function(e,data){

       var guest_image_table = $("#guest-preview");
       var guest_image_table = $("#guest-preview");


        guest_field = get_guest_field(total_guest_field);

              $(guest_field).appendTo(guest_image_table);
              $(guest_image_table).enhanceWithin();
              $(guest_image_table).closest("table").table("refresh");

        total_guest_field = total_guest_field + 1;

});



$(document).on("pagebeforeshow", "#sponsor-update-page", function(){

                 $.ajax({

                            data: {get: "event_sponsors", organizer_id: localStorage.organizer_id, event_id: localStorage.selected_event },
                            type:"GET",
                            dataType: "JSON",

                            success : function(data, result, jqXHR){

                                  if(result === "success") {
                        console.log(data);
                                      for(i = 0; i < data.length ; i++) {

                                         initialize_sponsor_fields(data[i], i);
                                   }

                                }

                            },  error: function(data, result, jqxhr){

                                        alert(jqxhr);

                          }
                });

        ajaxFormOptions.data = {form: "sponsor_update", organizer_id: localStorage.organizer_id, event_id: localStorage.selected_event };

                 $("#sponsor-update-form").ajaxForm(ajaxFormOptions);

});

  var  total_sponsors = 1;



$(document).on("click", "#add-sponsor", function(e,data) {
                   sponsor_add_table = $("#sponsor-box");

         sponsor_field = get_sponsor_field(total_sponsors);
        $(sponsor_add_table).append(sponsor_field).enhanceWithin();
        total_sponsors = total_sponsors + 1;
        $(sponsor_add_table).closest("table").table("refresh");

});


$(document).on("click", ".add-image", function() {

        var imageAnchor = $(this);
        var fileInput = $(this).siblings("input[type='file']");
        fileInput.click();


       $(document).one("change", fileInput, function(event){

            var inp = event.target;

            var reader = new FileReader();

              reader.onload = function(){

                        var dataURL = reader.result;

                        var previewImage = imageAnchor.children("img.image-preview");

                        $(previewImage).attr("src", dataURL);

                 };

            reader.readAsDataURL(inp.files[0]);

        });

});


$(document).on("pagebeforeshow", "#event-schedule-update-page", function(){


            $.ajax({

                      data: {get: "event_schedule", event_id: localStorage.selected_event },
                      type:"GET",
                      dataType: "JSON",
                      cache: false,

                      success : function(event, result, jqXHR){

                            if(result === "success") {

                              $("#event-start-date-update").val(event.startDate);
                              $("#event-end-date-update").val(event.endDate);
                              $("#event-start-time-update").val(event.startTime);
                              $("#event-end-time-update").val(event.endTime);

                            }
                      },
                         error: function(data, result, jqxhr){
                      alert(result+"  "+jqxhr);
                    }
            });


          $(".date_input").datetimepicker(dateOptions);

           $(".time_input").datetimepicker(timeOptions);




          $("#event-schedule-update-form").validate({

               messages: {
                  "event-start-date-update": "Please Provide the date the event is held",
                  "event-end-date-update": "Please Provide the date the event Is Ending",
                  "event-start-time-update": "Please Provide time the event is Start",
                  "event-end-time-update": "Please Provide time the event Is Ending",

                },



          });


         ajaxFormOptions.data = { form: "event_schedule_update", event_id: localStorage.selected_event, organizer_id: localStorage.organizer_id };

          $("#event-schedule-update-form").ajaxForm(ajaxFormOptions);


});





$(document).on("pagebeforeshow", "#event-tickets-update-page", function(){



        $(".date_input").datetimepicker(dateOptions);

            $.ajax({

                      data: {get: "event_tickets", event_id: localStorage.selected_event },
                      type:"GET",
                      dataType: "JSON",
                      cache: false,

                      success : function(data, result, jqXHR){

                                        if(result === "success") {
                                             $("#ticket-sales-start-update").val(data[0].saleStart);
                                          $("#ticket-sales-end-update").val(data[0].saleEnd);

                                          initialize_ticket(data);

                                         }


                    },

                   error: function(data, result, jqxhr){
                      alert(jqxhr);
                   }

          });


            $("#event-ticket-update-form").validate({

                                                   messages: {
                                                    "ticket-type-update": "Please Specify The Ticket Type",
                                                     "ticket-name-update": "Please Specify The Ticket Name",
                                                    "ticket-price-update": "Please Specify The Ticket Price",
                                                    "ticket-quantity-update": "Please Specify the amount of ticket available for sale",
                                                    "ticket-discription-update": "Please say something about the ticket like its purpose and what it can do",
                                                    "ticket-sales-start-date-update": "Please Specify When the ticket should be available for sale",
                                                    "ticket-sales-end-date-update": "Please Specify Till when the ticket will be Available"


                                                    }


             });


        ajaxFormOptions.data = { form: "event_ticket_update", event_id: localStorage.selected_event, organizer_id : localStorage.organizer_id };

          $("#event-ticket-update-form").ajaxForm(ajaxFormOptions);



});






$(document).one("pagecreate", "#account-managment", function () {

           $.ajax({
                    type: "GET",
                    data: {get: "organizer_info" , organizer_id : localStorage.organizer_id },
                    dataType: "JSON",

                    success : function(data, result, jqxhr){

                          displayAccountDetails(data);



                        }
              });



});


function displayAccountDetails(data) {

        if(data.title) { $("#admin-name").text(data.title+" "+data.firstName+" "+data.lastName);  }
        else { $("#admin-name").text(data.firstName+" "+data.lastName); }

        if(data.organizerPosition) {  $("#admin-position").text(data.organizerPosition);   }
        else {  $("#admin-position").text("");  }

           mobileNumber = $.parseJSON(data.mobileNumber);

              if(mobileNumber[0]){ $("#admin-mobile-number").text(mobileNumber[0]);
              } else { $("#admin-mobile-number").text("");
                        }
        if (data.aboutOrganizer) { $("#admin-bio").text(data.aboutOrganizer);   }
        else {$("#admin-bio").text(""); }
        if(data.organizationName) { $("#admin-organization-name").text(data.organizationName); }
        else { $("#admin-organization-name").text(""); }
        if(data.website) { $("#admin-website").text(data.website); }
        else {$("#admin-website").text("");}
        if(data.email) { $("#admin-email").text(data.email);
        } else { $("#admin-email").text(""); }

        social = $.parseJSON(data.social);

         if(social.facebook) { $("#admin-facebook").text(social.facebook); }
        else { $("#admin-facebook").text(""); }
        if(social.twitter) { $("#admin-twitter").text(social.twitter); }
        else { $("#admin-twitter").text(""); }
         if (social.youtube) {$("#admin-youtube").text(social.youtube);  }
          else {$("#admin-youtube").text(""); }


                   officeNumber = $.parseJSON(data.officeNumber);

                      if(officeNumber[0]) { $("#admin-office-number").text(officeNumber[0]);
                      } else {$("#admin-office-number").text(""); }

                      if (data.aboutOrganization) {  $("#admin-organization-info").text(data.aboutOrganization); }
                      else {  $("#admin-organization-info").text(""); }

                      if(data.gender) {  $("#admin-gender").text(data.gender);  }
                      else {  $("#admin-gender").text(""); }

                      if(data.birthdate) { $("#admin-birthday").text(data.birthdate);  }
                      else { $("#admin-birthday").text(""); }

                      if(data.registeredOn) { $("#admin-registered").text(data.registeredOn);   }
                      else {  $("#admin-registered").text(""); }


                    if(data.postalAddress) {$("#admin-po_num").text(data.postalAddress); }
                    else {  $("#admin-po_num").text(""); }


                      if(data.organizerImage){ $("#admin-picture").attr("src", "../uploads/organizersImage/profilePictures/"+data.organizerImage); }
                      if(data.organizationLogo){ $("#admin-organization-logo").attr("src", "../uploads/organizersImage/companyLogos/"+data.organizationLogo); }



        }


$(document).on("pagebeforeshow", "#manage-event-page", function () {

              $.ajax({

                        type: "GET",
                        data: {get: "event_summary" , organizer_id : localStorage.organizer_id, event_id : localStorage.selected_event },
                        dataType: "JSON",

                        success : display_event_summary





              });

});


$(document).on("click", ".update_event", function(e){

                localStorage.selected_event = $(this).attr("id");

});


$(document).on("click", ".delete_event", function(e){

             selected = $(this).attr("id");
                                         $.ajax({
                                                  type: "POST",
                                                  data: {form: "delete_event", event_id: selected},
                                                  success: function(data, result, jqXHR){
                                                        alert(result);
                                                  }



                                         });
                                         $(this).parent().remove().listview("refresh");
                                });

$(document).on("click", ".cancel-btn", function(){
  $.mobile.back();
});


$(document).on("click", "#add-address", function(){
        create_address_form();
});


 $(document).on("pagebeforeshow", "#organization-address-setting-page", function(){


                $.ajax({
                        type: "GET",
                        data: {get: "organization_address" , organizer_id : localStorage.organizer_id },
                        dataType: "JSON",

                        success : function(data, result, jqxhr){
                            console.log(data);
                            if(data) {
                              initialize_address_form(data);
                            }
                        }




              });


ajaxFormOptions.data = {form: "organization_address", organizer_id: localStorage.organizer_id };
    $("#address-update-form").ajaxForm(ajaxFormOptions);
 });
