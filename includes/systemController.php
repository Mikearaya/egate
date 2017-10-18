<?php





include('session.php');
include('classes.php');
include_once('errorHandler.php');




$SESSION = new SESSION();

$result = new stdclass();
$get_request = null;
$submitted_form = null;
$result->message = '';


 function generate_message($message){
 	$result = new stdclass();
	$result->message = $message;
	$result->warning =  $GLOBALS['ERROR_HANDLER']->get_all_warnings();
	$result->error = $GLOBALS['ERROR_HANDLER']->get_all_errors();
	$result->notice = $GLOBALS['ERROR_HANDLER']->get_all_notices();

	return $result;
}



if(isset($_POST['get'])){

	$get_request =  $_POST['get'];

}
if(isset($_GET['get'])){

	$get_request =  $_GET['get'];

}









if(isset($_POST['form'])){
	$submitted_form = $_POST['form'];
}


 if($submitted_form === 'log_in'){
			$email = null;
			$password = null;
			$result->success = null;
			 $result->organizer_id = null;

  		if(isset($_POST['log-in-mail'])) {
  			$email = $_POST['log-in-mail'];
  		}
  		if(isset($_POST['log-in-password'])) {

  		$password = $_POST['log-in-password'];

  		}
  		if(isset($email) && isset($password)){
  			$log = Organizer::log_in($email, $password, $SESSION) ;

  			if($SESSION->is_loged_in()) {

  				$result->success = 'true';
  				$result->organizer_id = $log['organizerId'];
  				$result->organizer_name = $log['firstName'];

  			} else {
  				$result->success = 'false';
  			}

	echo json_encode($result);
exit;
}

exit;
}

$allowed = array('png', 'jpg', 'gif','zip');


if($submitted_form === 'order_form' && isset($_POST['event_id'])) {

$attendee = null;
$event_id = $_POST['event_id'];

      			if(isset($_POST['att-first-name']) && isset($_POST['att-telephone']) && isset($_POST['att-last-name'])){

					$subscriber = null;

		      			if(isset($_POST['att-subscription'])){
		      			$subscriber  = $_POST['att-subscription'];

		      			}

      			$attendee = new Attendee($event_id, $_POST['att-first-name'],$_POST['att-last-name'], $_POST['att-telephone'], $subscriber);


      	$i = 0;
      	$result->message = '';

      			while($i < count($_POST['ticket-id'])) {

      				if(isset($_POST['orderQuantity'][$i]) && $_POST['orderQuantity'][$i] != '') {
      				$book = new Booking($_POST['ticket-id'][$i], $_POST['orderQuantity'][$i]);

      					$attendee->set_booking($book);
					}

      				$i++;
      			}

      			if($ERROR_HANDLER->get_error_count() == 0 ) {

      			$result->success = $attendee->book_event();

      			} else {
      				echo "hello";
      			}

      					if(!$result->success){
      						$result->message .= "<div class='alert alert-danger' > Error Occured While Processing Order Please Try Again </div>";
      					} else {
      						$result->message .= "<div class='alert alert-success' > Order Created Successfuly <b> Reservation CODE is ".$attendee->get_id()." </b>";
      						$result->message .=  " Click  Your <a href='#' id='".$attendee->get_id()."' class='complete-order-btn'>  HERE to Complete Order Now </a>  Or You Can Complete Your Payment Later And Use Your Reservation ID To Get Your Ticket </div>";
      					}




      } else {
      	trigger_error("Required event attendee First name, Last name and phone number missing", E_USER_ERROR);

      }


		echo $result->message;
		exit;
}





if($get_request === 'has_billing_address' && isset($_GET['organizer_id']) && $_GET['organizer_id'] == $SESSION->get_session_id() ){

			$organizer = Organizer::get_organizer($_GET['organizer_id']);

			if($organizer->has_billing_address() ) {
				$result->message = 'true';
				$result->success = 'true';
			} else {
				$result->message = 'false';
				$result->success = 'true';

			}

	echo json_encode($result);


}


if($submitted_form === 'new_event' && $_POST['organizer_id'] == $SESSION->get_session_id() ) {

		$organizer = new Organizer();
		$organizer->set_id($SESSION->get_session_id());

		$event = new Event();

				if(isset($_POST['event-title'])) $event->set_name($_POST['event-title']);
				if(isset($_POST['venue-name']))	$event->set_venue($_POST['venue-name']);

				if(isset($_POST['event-start-date']) && isset($_POST['event-start-time']) )
					$event->set_start_datetime($_POST['event-start-date'], $_POST['event-start-time']);
				if(isset($_POST['event-end-date']) && isset($_POST['event-end-time']))
					$event->set_end_datetime($_POST['event-end-date'], $_POST['event-end-time']);
				if(isset($_POST['event-discription']))	$event->set_discription($_POST['event-discription']);
				if(isset($_POST['event-type'])) $event->set_category($_POST['event-type']);
				if(isset($_POST['option']))		$event->set_status($_POST['option']);
				if(isset($_POST['event-latitude'])) 	$event->set_latitude($_POST['event-latitude']);
				if(isset($_POST['event-longitude'])) 	$event->set_longitude($_POST['event-longitude']);
				if(isset($_FILES['event-image']))	$event->set_picture($_FILES['event-image']);

		$address = new Address();

				if(isset($_POST['event-country']))	$address->set_country($_POST['event-country']);
				if(isset($_POST['event-city'])) $address->set_city($_POST['event-city']);
				if(isset($_POST['event-sub-city'])) $address->set_sub_city($_POST['event-sub-city']);
				if(isset($_POST['event-longitude'])) $address->set_longitude($_POST['event-longitude']);
				if(isset($_POST['event-latitude'])) $address->set_latitude($_POST['event-latitude']);
				if(isset($_POST['event-common-name'])) $address->set_location($_POST['event-common-name']);

		$event->set_address($address);

	$i = 0;
				if(isset($_POST['ticket-type'])  &&	isset($_POST['ticket-quantity'])
					&&	isset($_POST['ticket-discription']) && isset($_POST['ticket-sales-start-date']) &&
					isset($_POST['ticket-sales-end-date'])	) {


						while($i < count($_POST['ticket-type'])){

							$ticket = new Ticket();

								if(isset($_POST['ticket-type'][$i]))	$ticket->set_type($_POST['ticket-type'][$i]);
								if(isset($_POST['ticket-name'][$i]))		$ticket->set_name($_POST['ticket-name'][$i]);
								if(isset($_POST['ticket-quantity'][$i]))		$ticket->set_quantity($_POST['ticket-quantity'][$i]);

								if(isset($_POST['ticket-price'][$i])){
									$ticket->set_price($_POST['ticket-price'][$i]);
								}	else {
									$ticket->set_price(0); }


								if(isset($_POST['ticket-discription'][$i]))	$ticket->set_discription($_POST['ticket-discription'][$i]);
								if(isset($_POST['ticket-sales-start-date']))	$ticket->set_sale_start($_POST['ticket-sales-start-date']);
								if(isset($_POST['ticket-sales-end-date']))	$ticket->set_sale_end($_POST['ticket-sales-end-date']);

							$i++;

							$event->set_ticket($ticket);
						}


				}




		$i= 0;
				if(isset($_POST['sponsor-name'])) {

					while($i < count($_POST['sponsor-name'])) {

							$sponsor = new Sponsor();

							if (isset($_POST['sponsor-name'][$i])) $sponsor->set_name( $_POST['sponsor-name'][$i]);
							if(isset($_FILES['sponsor-image']['tmp_name'][$i])){

								$image['tmp_name'] = $_FILES['sponsor-image']['tmp_name'][$i];
								$image['name'] = $_FILES['sponsor-image']['name'][$i];
								$image['size'] = $_FILES['sponsor-image']['size'][$i];
								$image['type'] = $_FILES['sponsor-image']['type'][$i];
								$image['error'] = $_FILES['sponsor-image']['error'][$i];
								$sponsor->set_image($image);
							}
						$event->set_sponsor($sponsor);
						$i++;

					}


				}


$i= 0;

			if(isset($_POST['guest-first-name']) && isset($_POST['guest-last-name'])) {

					while($i < count($_POST['guest-first-name'])) {

							$guest = new Guest();

							if(isset($_POST['guest-first-name'][$i])) 	$guest->set_first_name($_POST['guest-first-name'][$i]);
							if(isset($_POST['guest-last-name'][$i]))	$guest->set_last_name($_POST['guest-last-name'][$i]);
							if(isset($_POST['guest-aka-name'][$i]) && strlen($_POST['guest-aka-name'][$i]) > 0 )	$guest->set_aka_name($_POST['guest-aka-name'][$i]);



							if(isset($_FILES['guest-image']['tmp_name'][$i])) {

								$image['tmp_name'] = $_FILES['guest-image']['tmp_name'][$i];
								$image['name'] = $_FILES['guest-image']['name'][$i];
								$image['size'] = $_FILES['guest-image']['size'][$i];
								$image['type'] = $_FILES['guest-image']['type'][$i];
								$image['error'] = $_FILES['guest-image']['error'][$i];
								$guest->set_image($image);
							}


							$event->set_guest($guest);

							$i++;
					}
			}

if($ERROR_HANDLER->get_error_count() == 0 && $organizer->add_event($event) ) {
		echo json_encode(generate_message("event Created Successfuly"));

	} else {
		echo json_encode(generate_message("Event was not created!!!"));
	}

	exit;

}



if($submitted_form === 'guest_update' && $_POST['organizer_id'] == $SESSION->get_session_id() && isset($_POST['event_id'])){

	$event_id = $_POST['event_id'];



			$organizer = new Organizer();
			$organizer->set_id($SESSION->get_session_id());
			$event = new Event();
			$event->set_id($event_id);

			$i= 0;

			if(isset($_POST['guest-first-name']) && isset($_POST['guest-last-name'])) {

				while($i < count($_POST['guest-first-name'])) {

						$guest = new Guest();

						if(isset($_POST['guest-first-name'][$i]))	$guest->set_first_name($_POST['guest-first-name'][$i]);

						if(isset($_POST['guest-last-name'][$i])) $guest->set_last_name($_POST['guest-last-name'][$i]);


				if(isset($_POST['guest-aka-name'][$i]) && strlen($_POST['guest-aka-name'][$i]) > 0 )	$guest->set_aka_name($_POST['guest-aka-name'][$i]);


						if(isset($_FILES['guest-image'][$i])) {
							$image = null;
							$image['tmp_name'] = $_FILES['guest-image']['tmp_name'][$i];
							$image['name'] = $_FILES['guest-image']['name'][$i];
							$image['size'] = $_FILES['guest-image']['size'][$i];
							$image['type'] = $_FILES['guest-image']['type'][$i];
							$image['error'] = $_FILES['guest-image']['error'][$i];

							$guest->set_image($image);

						}

					$event->set_guest($guest);

					$i++;
				}



			if($ERROR_HANDLER->get_error_count() == 0 && $organizer->add_event_guest($event)){
				$result = generate_message(' Guests Was success fully updated' );
			} else {
				$result = generate_message(' Error updating Guests ' );
			}


		}

$i = 0;
				if(isset($_POST['guest-first-name-update']) && isset($_POST['guest-last-name-update'])) {
						$event1 = new Event();

				$old_guest = null;

					while($i < count($_POST['guest-first-name-update'])) {
							if(isset($_POST['guest_id'][$i])) {
							$old_guest = new Guest($_POST['guest_id'][$i], 'updated');


							if(isset($_POST['guest-first-name-update'][$i])){
								$old_guest->set_first_name($_POST['guest-first-name-update'][$i]);
							}
							if(isset($_POST['guest-last-name-update'][$i])){
								$old_guest->set_last_name($_POST['guest-last-name-update'][$i]);
							}

							if(isset($_POST['guest-aka-name-update'][$i]) &&  (strlen($_POST['guest-aka-name-update'][$i]) > 0)){
									$old_guest->set_aka_name($_POST['guest-aka-name-update'][$i]);
							}

						if(isset($_FILES['guest-image-update']['tmp_name'][$i])){

							$image = null;
							$image['tmp_name'] = $_FILES['guest-image-update']['tmp_name'][$i];
							$image['name'] = $_FILES['guest-image-update']['name'][$i];
							$image['size'] = $_FILES['guest-image-update']['size'][$i];
							$image['type'] = $_FILES['guest-image-update']['type'][$i];
							$image['error'] = $_FILES['guest-image-update']['error'][$i];

							$old_guest->set_image($image);

						}



							$event->set_guest($old_guest);

						}
						$i++;

				}

			if($ERROR_HANDLER->get_error_count() == 0 && $organizer->update_event_guest($event)){
				$result = generate_message(' Guests Was success fully updated' );

			} else {
				$result = generate_message(' Error updating Guests ' );
			}

		}

		echo json_encode($result);
		exit;

}




if($submitted_form === 'organization_address' && $_POST['organizer_id'] == $SESSION->get_session_id() ){

				$organizer = new Organizer();
				$organizer->set_id($SESSION->get_session_id());

				$i = 0;
		$address;
				if(isset($_POST['organization-country'])) {
						while($i < count($_POST['organization-country']) ) {
						$address = new Address();


						if(isset($_POST['organization-country'][$i])  && strlen($_POST['organization-country'][$i]) > 0 )
							$address->set_country($_POST['organization-country'][$i]);

						if(isset($_POST['organization-city'][$i])  && strlen($_POST['organization-city'][$i]) > 0 )
							$address->set_city($_POST['organization-city'][$i]);
						if(isset($_POST['organization-sub-city'][$i])  && strlen($_POST['organization-sub-city'][$i]) > 0 )
							$address->set_sub_city($_POST['organization-sub-city'][$i]);
						if(isset($_POST['common-name'][$i])  && strlen($_POST['common-name'][$i]) > 0 )
							$address->set_location($_POST['common-name'][$i]);
						if(isset($_POST['organization-latitude'][$i]) && strlen($_POST['organization-latitude'][$i]) > 0)
							$address->set_latitude($_POST['organization-latitude'][$i]);
						if(isset($_POST['organization-longitude'][$i]) && strlen($_POST['organization-longitude'][$i]) > 0 )
							$address->set_longitude($_POST['organization-longitude'][$i]);

								$i++;
								$organizer->set_address($address);


					}


					if($ERROR_HANDLER->get_error_count() == 0 && $organizer->add_address()) {
						echo json_encode(generate_message('Address Added Successfuly'));
					} else {
						echo json_encode(generate_message('Failed to add Address'));
					}

				}
					if(isset($_POST['organization-country-update'])) {

					$i = 0;

						while($i < count($_POST['organization-country-update']) ) {

							$address = new Address($_POST['address-id'][$i], 'updated');

						if(isset($_POST['organization-country-update'][$i]) && strlen($_POST['organization-country-update'][$i]) > 0)
							$address->set_country($_POST['organization-country-update'][$i]);
						if(isset($_POST['organization-city-update'][$i]) && strlen($_POST['organization-city-update'][$i]) > 0)
							$address->set_city($_POST['organization-city-update'][$i]);
						if(isset($_POST['organization-sub-city-update'][$i]) && strlen($_POST['organization-sub-city-update'][$i]) > 0)
								$address->set_sub_city($_POST['organization-sub-city-update'][$i]);
						if(isset($_POST['common-name-update'][$i]) && strlen($_POST['common-name-update'][$i]) > 0  )
							$address->set_location($_POST['common-name-update'][$i]);
						if(isset($_POST['organization-latitude-update'][$i]) && strlen($_POST['organization-latitude-update'][$i]) > 0  )
							$address->set_latitude($_POST['organization-latitude-update'][$i]);
						if(isset($_POST['organization-longitude-update'][$i]) && strlen($_POST['organization-longitude-update'][$i]) > 0)
							$address->set_longitude($_POST['organization-longitude-update'][$i]);


								$i++;

								$organizer->set_address($address);
						}


					if($ERROR_HANDLER->get_error_count() == 0 && $organizer->update_address()) {
						echo json_encode(generate_message('Address Updated Successfuly'));
					} else {
						echo json_encode(generate_message('Failed to Update Address'));
					}

					}




}

if ($submitted_form === 'sponsor_update' && $_POST['organizer_id'] == $SESSION->get_session_id() && isset($_POST['event_id'])) {

		$organizer = new Organizer();
		$organizer->set_id($SESSION->get_session_id());

			$event = new Event();
			$event->set_id($_POST['event_id']);
			$success = true;


		$i= 0;
				if(isset($_POST['sponsor-name'])) {

					while($i < count($_POST['sponsor-name'])){

							$sponsor = new Sponsor();

							if (isset($_POST['sponsor-name'][$i])) {
								$sponsor_name = $_POST['sponsor-name'][$i];
								$sponsor->set_name($sponsor_name);
							}

							if(isset($_FILES['sponsor-image']['tmp_name'][$i])){
								$image = null;
								$image['tmp_name'] = $_FILES['sponsor-image']['tmp_name'][$i];
								$image['name'] = $_FILES['sponsor-image']['name'][$i];
								$image['size'] = $_FILES['sponsor-image']['size'][$i];
								$image['type'] = $_FILES['sponsor-image']['type'][$i];
								$image['error'] = $_FILES['sponsor-image']['error'][$i];

								$sponsor->set_image($image);
							}


						$event->set_sponsor($sponsor);
						$i++;


				}

			$success = ($ERROR_HANDLER->get_error_count() == 0 && $organizer->add_event_sponsor($event)) ? true : false;


			}

$i=0;

					if(isset($_POST['sponsor-name-update'])) {

					while($i < count($_POST['sponsor-name-update'])){

							if(isset($_POST['sponsor-id'][$i])) {
								$sponsor = new  Sponsor($_POST['sponsor-id'][$i], 'updated');

								if (isset($_POST['sponsor-name-update'][$i])) 	$sponsor->set_name($_POST['sponsor-name-update'][$i]);
							if(isset($_FILES['sponsor-image-update']['tmp_name'][$i])){
									$image = null;
									$image['tmp_name'] = $_FILES['sponsor-image-update']['tmp_name'][$i];
									$image['name'] = $_FILES['sponsor-image-update']['name'][$i];
									$image['size'] = $_FILES['sponsor-image-update']['size'][$i];
									$image['type'] = $_FILES['sponsor-image-update']['type'][$i];
									$image['error'] = $_FILES['sponsor-image-update']['error'][$i];

									$sponsor->set_image($image);
								}

									$event->set_sponsor($sponsor);



					}
					$i++;

					}

					$success = ($ERROR_HANDLER->get_error_count() == 0 && $organizer->update_event_sponsor($event)) ? true : false;
				}


			echo ($success) ? json_encode(generate_message("Event Sponsors Updated Successfuly!!!")) : json_encode(generate_message("Failed to Update Event Sponsor!!!"));

	exit;
}


if($submitted_form === 'comment' && isset($_POST['event_id'])){

  	$commenter = NULL;
  	$content = NULL;


  		$event = new Event();
  		$event->set_id($_POST['event_id']);


  		if(isset($_POST['commenter-name'])){
  				$commenter = $_POST['commenter-name'];
  		}

  		if(isset($_POST['comment-content'])){
  			$content = $_POST['comment-content'];
  		}


  		$comment = new Comment($commenter, $content);





	      	if($event->add_comment($comment)){

	      		    $new_comment = "<li>";
                    $new_comment .= "<h5>".$comment->get_commenter()."</h5>";

                     $new_comment .= "<p><strong>". $comment->get_comment()."</strong>.</p>";
                      $new_comment .= "<p class='ui-li-aside'><strong>just now</strong></p>";
                      $new_comment .= "</li>";
                      echo $new_comment;
	      	} else {

	      	}





      }


      if($get_request === 'available_tickets' && isset($_POST['event_id'])) {

      		      	$ticket['ticket'] = DB_CONNECTION::get_event_ticket($_POST['event_id']);

      			echo json_encode($ticket);
      }





  if($submitted_form === 'contact_organizer' && isset($_POST['event_id']) ) {
$connection = new DB_CONNECTION();
      	$id = $connection->get_organizer_id($_POST['event_id']);
      		$organizer = Organizer::get_organizer($id);

      		$sender = new Viewer();
      		if(isset($_POST['contact-org-firstname'])){
      			$fname = $_POST['contact-org-firstname'];
      			$sender->set_first_name($fname);
      		}
      		if(isset($_POST['contact-org-lastname'])){
      			$lname = $_POST['contact-org-lastname'];
      			$sender->set_last_name($lname);
      		}
      		if(isset($_POST['contact-org-email'])){
      			$email = $_POST['contact-org-email'];
      			$sender->set_mail_address($email);
      		}

      		if(isset($_POST['contact-org-message'])){
      			$mail = $_POST['contact-org-message'];
      			$sender->set_mail($mail);
      		}

      		if(isset($_POST['contact-org-subject'])){
      			$subject = $_POST['contact-org-subject'];
      			$sender->set_subject($subject);
      		}









      			$result = $sender->send_mail($organizer);
      			if($result){
      				echo "<div class='alert alert-success' > Message Sent!!! </div> ";
      			} else {
      				echo "<div class='alert alert-danger' > Sorry, Sending Message Failed Try Again </div>" ;
      			}

      }


 if($submitted_form === 'sign_up') {

    // Decode JSON object into readable PHP object


$fname = null;
$lname = null;
$mail = null;
$password = null;


    if(isset($_POST['organizer-first-name'])) $fname = $_POST['organizer-first-name'];
	if(isset($_POST['organizer-last-name']))  $lname = $_POST['organizer-last-name'];
	if(isset($_POST['organizer-email'])) $mail = $_POST['organizer-email'];
	if(isset($_POST['organizer-password'])) $password = $_POST['organizer-password'];



    	if($ERROR_HANDLER->get_error_count() == 0 &&
    		 Organizer::sign_up($fname, $lname, $mail, $password, $SESSION) &&
    		 $SESSION->is_loged_in()) {

				$result->message = "<div class='alert alert-success'> Registration Completed Successfuly!!! You Are Now Loged In As ".$fname."</div>";
				$result->success = 'true';
				$result->organizer_id = $SESSION->get_session_id();
				$result->organizer_name = $SESSION->get_session_name();


		}	else {
				$result->message = "<div class='alert alert-danger'> E-mail Already Exsists!!! </div> ";
				$result->success = 'false';

		}

		echo  json_encode($result);
		exit;


}



if($submitted_form == 'event_basics_update' && isset($_POST['event_id']) && $_POST['organizer_id'] == $SESSION->get_session_id()) {


			$event = new Event();
			$event->set_id($_POST['event_id']);

		$organizer = new Organizer();
		$organizer->set_id($SESSION->get_session_id());


				if(isset($_POST['event-title-update']))	$event->set_name($_POST['event-title-update']);
				if(isset($_POST['venue-name-update']))	$event->set_venue($_POST['venue-name-update']);
				if(isset($_POST['event-discription-update']))	$event->set_discription($_POST['event-discription-update']);
				if(isset($_POST['event-type-update']))	$event->set_category($_POST['event-type-update']);
				if(isset($_POST['event-latitude-update']))	$event->set_latitude($_POST['event-latitude-update']);
				if(isset($_POST['event-longitude-update']))	$event->set_longitude($_POST['event-longitude-update']);
				if(isset($_FILES['event-image-update']) )	$extension = $event->set_picture($_FILES['event-image-update']);

		$address = new Address();
				if(isset($_POST['event-country-update']))	$address->set_country($_POST['event-country-update']);
				if(isset($_POST['event-city-update']))	$address->set_city($_POST['event-city-update']);
				if(isset($_POST['event-sub-city-update']))	$address->set_sub_city($_POST['event-sub-city-update']);
				if(isset($_POST['event-common-name-update']))	$address->set_location($_POST['event-common-name-update']);
				if(isset($_POST['event-location-update']))	$address->set_location($_POST['event-location-update']);
				if(isset($_POST['event-longitude-update']))	$address->set_longitude($_POST['event-longitude-update']);
				if(isset($_POST['event-latitude-update']))	$address->set_latitude($_POST['event-latitude-update']);

				$event->set_address($address);
				if($ERROR_HANDLER->get_error_count() == 0  && $organizer->update_event_information($event)) {
					$result = generate_message("Event Updated Successfuly!!!");
				} else {
					$result = generate_message("Event Update Failed!!!");
				}

	echo json_encode($result);
exit;
}




if($submitted_form === 'event_ticket_update' && $_POST['organizer_id'] == $SESSION->get_session_id() && isset($_POST['event_id'])){

			$organizer = new Organizer();
			$organizer->set_id($SESSION->get_session_id());
			$event = new Event();
			$event->set_id($_POST['event_id']);

			$success = true;

				$i = 0;
				if(isset($_POST['ticket-type']) 	) {


							while($i < count($_POST['ticket-type'])){
								$ticket = new Ticket();
								if(isset($_POST['ticket-name'][$i]))	$ticket->set_name($_POST['ticket-name'][$i]);
								if(isset($_POST['ticket-type'][$i]))	$ticket->set_type($_POST['ticket-type'][$i]);
								if(isset($_POST['ticket-quantity'][$i]))	$ticket->set_quantity($_POST['ticket-quantity'][$i]);

								if(isset($_POST['ticket-price'][$i])) {
									$ticket->set_price($_POST['ticket-price'][$i]);
								} else {
									$ticket->set_price(0);
								}
								if(isset($_POST['ticket-discription'][$i])) $ticket->set_discription($_POST['ticket-discription'][$i]);
								if(isset($_POST['ticket-sales-start-update']))	$ticket->set_sale_start($_POST['ticket-sales-start-update']);
								if(isset($_POST['ticket-sales-end-update']))	$ticket->set_sale_end($_POST['ticket-sales-end-update']);
								$i++;

							$event->set_ticket($ticket);
						}

							$success = ($ERROR_HANDLER->get_error_count() == 0  && $organizer->add_event_ticket($event)) ? true : false;

				}

		$i = 0;
					if(isset($_POST['ticket_id'])){

							while($i < count($_POST['ticket_id'])){

								if(isset($_POST['ticket_id'][$i])){

									$ticket = new Ticket($_POST['ticket_id'][$i], 'updated');

									if(isset($_POST['ticket-name-update'][$i]))		$ticket->set_name($_POST['ticket-name-update'][$i]);
									if(isset($_POST['ticket-type-update'][$i]))		$ticket->set_type($_POST['ticket-type-update'][$i]);
									if(isset($_POST['ticket-quantity-update'][$i]))	$ticket->set_quantity($_POST['ticket-quantity-update'][$i]);
									if(isset($_POST['ticket-price-update'][$i])) {
										$ticket->set_price($_POST['ticket-price-update'][$i]);
									} else {
										$ticket->set_price(0);
									}
									if(isset($_POST['ticket-name-update'][$i]))		$ticket->set_discription($_POST['ticket-discription-update'][$i]);
									if(isset($_POST['ticket-sales-start-update']))	$ticket->set_sale_start($_POST['ticket-sales-start-update']);
									if(isset($_POST['ticket-sales-end-update']))	$ticket->set_sale_end($_POST['ticket-sales-end-update']);


									$event->set_ticket($ticket);


							}
								$i++;

							}

							$success = ($ERROR_HANDLER->get_error_count() == 0 && $organizer->update_event_ticket($event)) ? true : false;
				}


								if($success) {

							 		$result = generate_message(" Ticket Updated Successfuly!! ");
								} else {
									$result = generate_message(" Failed to updated Tickets!! ");
								}

		echo json_encode($result);



}








if($submitted_form === 'event_schedule_update' && isset($_POST['event_id']) && $_POST['organizer_id'] == $SESSION->get_session_id() ){

		$organizer = new Organizer();
		$organizer->set_id($SESSION->get_session_id());

		$event = new Event();
		$event->set_id($_POST['event_id']);

		if(isset($_POST['event-start-date-update']) && isset($_POST['event-start-time-update']))
			$event->set_start_datetime($_POST['event-start-date-update'], $_POST['event-start-time-update']);

		if(isset($_POST['event-end-date-update']) && isset($_POST['event-end-time-update']))
			$event->set_end_datetime($_POST['event-end-date-update'], $_POST['event-start-time-update']);


		if($ERROR_HANDLER->get_error_count() == 0 && $organizer->update_event_schedule($event)) {
			$result = json_encode(generate_message("Event Updated Successfuly!!!"));
		} else {
			$result = json_encode(generate_message("Event Update Failed!!! "));
		}

		echo $result;
		exit;
}


if($submitted_form === 'contact_info_update' && $_POST['organizer_id'] == $SESSION->get_session_id()) {


		$organizer = new Organizer();
		$organizer->set_id($SESSION->get_session_id());

      			if(isset($_POST['UP-organizer-first-name'])) $organizer->set_first_name($_POST['UP-organizer-first-name']);
       			if(isset($_POST['UP-organizer-last-name']))	$organizer->set_last_name($_POST['UP-organizer-last-name']);
      	   		if(isset($_POST['edit-birthday']))	$organizer->set_birthdate($_POST['edit-birthday']);
		      	if(isset($_POST['organizer-title'])) 	$organizer->set_title($_POST['organizer-title']);
  		      	if(isset($_POST['organizer-position']))	$organizer->set_position($_POST['organizer-position']);
		      	if(isset($_POST['organizer-bio']))		$organizer->set_bio($_POST['organizer-bio']);
      			if(isset($_FILES['organizer-profile-pic']['tmp_name']))	$organizer->set_picture($_FILES['organizer-profile-pic']);



      			if($ERROR_HANDLER->get_error_count() == 0 && $organizer->update_profile()) {
      				echo json_encode(generate_message("Profile Updated Successfuly!!!"));
      			} else {
      				echo json_encode(generate_message("Failed to Update Profile!!!"));
      			}
      exit;
}


if($submitted_form === "mail_change" && $_POST['organizer_id'] == $SESSION->get_session_id()) {

			$organizer = new Organizer();
			$organizer->set_id($SESSION->get_session_id());


				if(isset($_POST['changed-email'])) {
					if($ERROR_HANDLER->get_error_count() == 0 &&$organizer->change_email($_POST['changed-email']) ) {
						echo json_encode(generate_message("E-mail updated Successfuly!!!, Provide this email next time you log in. "));
					} else {
						echo json_encode(generate_message("Error updating E-mail!!!"));
					}

			}

exit;

}



if ($submitted_form === "update_social_media"  &&  $_POST['organizer_id'] == $SESSION->get_session_id() ) {

					$organizer = new Organizer();
					$organizer->set_id($SESSION->get_session_id());


					if(isset($_POST['facebook-address'])) 	$organizer->set_facebook($_POST['facebook-address']);
					if(isset($_POST['twitter-address'])) 	$organizer->set_twitter($_POST['twitter-address']);
					if(isset($_POST['youtube-address'])) 	$organizer->set_youtube($_POST['youtube-address']);


					if($ERROR_HANDLER->get_error_count() == 0 && $organizer->update_socialMedia_address()) {
						echo  json_encode(generate_message('Social Media Address Updated Successfuly!!!'));
					} else {
						echo json_encode(generate_message('Failed to Updated Social Media Address, Please Try Again!!!'));
					}

			exit;
}

if($submitted_form === 'billing_address_update' && $_POST['organizer_id'] == $SESSION->get_session_id() ){

			$organizer = Organizer::get_organizer($_POST['organizer_id']);


			if(isset($_POST['service-provider']) && isset($_POST['billing-phone'])){
				$result->success = $organizer->update_billing_address( $_POST['service-provider'], $_POST['billing-phone']);
			}

			if($result->success){
				$result->message = "<div class='alert alert-success'> Billing Address Updated Successfuly </div>";
					} else {
						$result->message =  "<div class='alert alert-danger'> Error Occured While Billing Address Address Please Try Again!!! </div>";
					}

echo $result->message;
exit;
}

if($submitted_form === "organization_info_change" && isset($_POST['organization-id']) && $_POST['organizer_id'] == $SESSION->get_session_id()) {

				$organizer = new Organizer();
				$organizer->set_id($SESSION->get_session_id());
				$organizer->set_organization_id($_POST['organization-id']);

				if(isset($_POST['organization-name']))	$organizer->set_organization_name($_POST['organization-name']);
				if(isset($_POST['organization-mobile-number']) && strlen($_POST['organization-mobile-number']) > 0)
				 $organizer->set_mobile_number($_POST['organization-mobile-number']);
				if(isset($_POST['organization-office-number']) && strlen($_POST['organization-office-number']) > 0)
					$organizer->set_office_number($_POST['organization-office-number']);
				if(isset($_POST['organization-website']) && strlen($_POST['organization-website']) > 0)
					$organizer->set_website($_POST['organization-website']);
				if(isset($_POST['organization-info']) && strlen($_POST['organization-info']) > 0)
					$organizer->set_organization_info($_POST['organization-info']);
				if(isset($_FILES['organization-logo']) )	$organizer->set_organization_logo($_FILES['organization-logo']);
				if(isset($_POST['organization-post-no']) && strlen($_POST['organization-post-no']) > 0)
					$organizer->set_po_num($_POST['organization-post-no']);


				if($ERROR_HANDLER->get_error_count() == 0 && $organizer->update_organization()) {
					echo json_encode(generate_message("Information Updated Successfuly!!!"));
				} else {
					echo json_encode(generate_message("Failed to Update Information!!!"));
				}


		exit;
}


		if($submitted_form === 'password_change' && $_POST['organizer_id'] == $SESSION->get_session_id() ){

			$organizer = Organizer::get_organizer($_POST['organizer_id']);

						if(isset($_POST['new-password']) && isset($_POST['current-password']) ){

							$result->success = $organizer->change_password($_POST['current-password'], $_POST['new-password']);
						}

						if($result->success){

							$result->message .= '<h5 class="alert alert-success" > Password Changed Successfuly Your New Password Wiill Be Active On Your Next Log In </h5>';
						} else {
							$result->message .= '<h5 class="alert alert-danger" > Password Was Not Changed , Please verify Your Input And Try Again </h5>';
						}

			echo $result->message;


		}


/*
		GET[] REQUEST HANDLLING SECTION

*/



if($get_request === 'event_category' && isset($_GET['category'])) {

		$category = $_GET['category'];

		$connection = new DB_CONNECTION();
		$events = $connection->get_event_category($category);

		echo json_encode($events);

	exit;
}

if($get_request === 'organizer_mail' && $SESSION->is_loged_in() ) {
	$organizer = Organizer::get_organizer($SESSION->get_session_id());

		echo json_encode($organizer->get_email());
	exit;
}

 if($get_request === 'event_detail' && isset($_GET['event_id'])) {


		$event_detail = DB_CONNECTION::get_event_details($_GET['event_id']);

		 echo json_encode($event_detail);

 }




	if($get_request === 'trending_events') {
		$connection = new DB_CONNECTION();

			$events = $connection->fetch_events();


			echo json_encode($events);
	}


if($get_request === 'organizer_mail') {

	$organizer = Organizer::get_organizer($SESSION->get_session_id());


		echo json_encode($organizer->get_email());

}


if($get_request === 'event_basics' && isset($_GET['event_id']) ){
	$connection = new DB_CONNECTION();



	$eve  = $connection->get_event($_GET['event_id']);

echo json_encode($eve);

}


if($get_request === 'event_summary' && isset($_GET['event_id']) ){

	$event = DB_CONNECTION::get_event_details($_GET['event_id']);


	echo json_encode($event);

}




if($get_request === 'event_schedule' && isset($_GET['event_id'])){

		$Schedule  = DB_CONNECTION::get_event_schedule($_GET['event_id']);

		echo json_encode($Schedule);
	exit;
}

if($get_request === 'event_guests' && isset($_GET['event_id']) && $_GET['organizer_id'] == $SESSION->get_session_id()){




	$guest  = DB_CONNECTION::get_event_guest($_GET['event_id']);

	echo json_encode($guest);

}


if($get_request === 'event_sponsors' && isset($_GET['event_id']) && $_GET['organizer_id'] == $SESSION->get_session_id()){

	$sponsor  = DB_CONNECTION::get_event_sponsor($_GET['event_id']);

	echo json_encode($sponsor);
exit;
}

if($get_request === 'event_tickets' && isset($_GET['event_id'])){

		$tickets  = DB_CONNECTION::get_event_ticket($_GET['event_id']);

		echo json_encode($tickets);
	exit;
}

	if($get_request === 'organizer_events' && $_GET['organizer_id'] == $SESSION->get_session_id())	{

		$events =	DB_CONNECTION::get_organizer_events($SESSION->get_session_id());

		echo json_encode($events);
	}





 if($submitted_form === 'delete_event'){

	$organizer = new Organizer();
	$organizer->set_id($SESSION->get_session_id());

	if(isset($_POST['event_id'])){

		$event = new Event();
		$event->set_id($_POST['event_id']);
		$organizer = new Organizer();
		$organizer->set_id($SESSION->get_session_id());

		if($ERROR_HANDLER->get_erro_count() == 0 && $organizer->delete_event($event)) {
			$result->message = 'Event Deleted';
		} else {
			$result->message = 'Error Deleting Event';
		}
	}

	echo $result->message;
}


 if($get_request === 'delete_ticket' && isset($_GET['ticket_id']) && isset($_GET['event_id'])  ){

		$ticket = new Ticket($_GET['ticket_id'], 'deleted');

		$event = new Event();
		$event->set_id($_GET['event_id']);

		$event->set_ticket($ticket);

		$organizer = new Organizer();
		$organizer->set_id($SESSION->get_session_id());


		if($ERROR_HANDLER->get_error_count() == 0 && $organizer->delete_event_ticket($event)) {

			$result->message =  '<h5 class="alert alert-success" > Ticket Deleted Successfuly </h5>';
		} else {
			$result->message =  '<h5 class="alert alert-danger" > Error Deleting Ticket </h5>';
		}

		echo $result->message;
	}


 if($get_request === 'delete_guest' &&
 				isset($_GET['guest_id']) &&
 						isset($_GET['event_id'])
 								&& $_GET['organizer_id'] == $SESSION->get_session_id()  )	{

		$guest = new Guest($_GET['guest_id'], 'deleted');

		$organizer = new Organizer();

		$event = new Event();
		$event->set_id($_GET['event_id']);
		$event->set_guest($guest);

		$organizer->set_id($SESSION->get_session_id());


		if($ERROR_HANDLER->get_error_count() == 0 &&  $organizer->delete_event_guest($event)){
			$result->message =  '<h5 class="alert alert-success" > Guest Deleted Successfuly </h5>';
		} else {
			$result->message .=  '<h5 class="alert alert-danger" > Error Deleting Guest </h5>';
		}

		echo $result->message;
	}

 if($get_request === 'delete_sponsor' &&
 				isset($_GET['sponsor_id']) &&
 						isset($_GET['event_id'])
 								&& $_GET['organizer_id'] == $SESSION->get_session_id()  )	{


		$sponsor = Sponsor($_GET['guest_id'], 'deleted');


		$event = Event();
		$event->set_id($_GET['event_id']);
		$event->set_sponsor($sponsor);

		$organizer->set_id($SESSION->get_session_id());


		if($ERROR_HANDLER->get_error_count() == 0 && $organizer->delete_event_guest($event)){
			$result->message =  '<h5 class="alert alert-success" >'.$sponsor->get_name().' Sponsor Deleted Successfuly </h5>';
		} else {
			$result->message .=  '<h5 class="alert alert-danger" >'.$sponsor->get_name().' Error Deleting Guest </h5>';
		}

		echo $result->message;
	}


if($get_request === 'organizer_info' && $_GET['organizer_id']  == $SESSION->get_session_id() ){

	$info = DB_CONNECTION::get_organizer_info($SESSION->get_session_id());
	echo	json_encode($info);

}




if($get_request === 'event_statstics' && $_GET['organizer_id'] == $SESSION->get_session_id() && isset($_GET['event_id'])) {

			$result =DB_CONNECTION::get_event_booking_stat($SESSION->get_session_id(),  $_GET['event_id']);
			echo json_encode($result);


}


if($get_request === 'check_ins' && isset($_GET['event_id']) && $_GET['organizer_id'] == $SESSION->get_session_id()){

	$checkins = CHECK_IN_CONTROLLER::get_event_check_ins(798);

	echo json_encode($checkins);

	exit;
}



if($get_request === 'manage_check_in' && isset($_GET['request']) && $_GET['organizer_id'] == $SESSION->get_session_id() && isset($_GET['reciept-id'])){

	$result;
		if($_GET['request'] == 'check_out'){
			$result =  Attendee::check_out($_GET['event_id'], $_GET['reciept-id']);

		} else {

			$result = Attendee::check_in($_GET['event_id'], $_GET['reciept-id']);
		}

		if($ERROR_HANDLER->get_error_count() == 0 ) {
			echo json_encode($reult);
		} else {
			echo json_encode(generate_message("Error"));
		}



}


if($get_request === 'check_in' &&  $_GET['organizer_id'] == $SESSION->get_session_id() && isset($_GET['reciept-id'])){
	$resu = new stdclass();
	$resu->message;
	$resu->data;
	$resu->success;
		$data = Attendee::check_in($_GET['event_id'], $_GET['reciept-id']);
		if($ERROR_HANDLER->get_error_count() == 0 ) {
			$resu->success = "true";
			 $resu->message = "Welcome!!!";
			$resu->data =$data;
		} else {
				$resu->success = "False";
			 $resu->message = "Invalid Ticket!!!";

		}

	echo json_encode($resu);

}



if($get_request === 'attendee_tickets' && isset($_GET['reservation_ID'])) {

			$attendee  = new Attendee() ;
			$attendee->set_id($_GET['reservation_ID']);

		if($reciept = $attendee->get_reciept()){


				$result->reciept = $reciept;
				$result->success = 'true';

		} else {
			$result->success = 'false';
			$result->message = "<h5 class='alert alert-danger' >   Error Creating Reciept </h5> ";
		}


echo json_encode($result);
	exit;


}



if($get_request === 'download_pdf' && isset($_GET['reservation_ID'])) {

			$bookings  = Booking::get_booking($_GET['reservation_ID']);
				$reciept = new RecieptFactory();
				$result->success = $reciept->print_reciept($_GET['reservation_ID']);


				if($result->success){
					$result->success = 'true';
				}else {
					$result->success = 'false';
				}


echo json_encode($result);

		exit;

}



if($submitted_form === 'subscriber' && isset($_POST['option']) && $_POST['option'] === 'NEW' ) {

		if(isset($_POST['subscriber-mail'])) {
			$subscriber = new subscriber($_POST['subscriber-mail']);

			if($subscriber != null) {
				$result->success = 'true';
				$result->message = "Subscription Created Successfuly";
				$result->subscriber_id = $subscriber->get_id();
			} else {
				$result->success = 'false';
				$result->message = "Subscription Failed";
			}
		}

echo json_encode($result);
exit;

}
if($submitted_form === 'subscriber' && isset($_POST['option']) && $_POST['option'] === 'UPDATE' ) {

		if(isset($_POST['subscriber-mail'])) {
			$subscriber = Subscriber::get_subscriber_by_email($_POST['subscriber-mail']);

			if($subscriber != null) {
				$result->success = 'true';
				$result->message = "Subscriber Found Successfuly";
				$result->subscriber_id = $subscriber->get_id();
			} else {
				$result->success = 'false';
				$result->message = "Subscription Was Not Found please provide a the email you used to subscribe or create a new Subscription";
			}
		}

echo json_encode($result);
exit;

}



if($submitted_form === 'subscriber' && isset($_POST['option']) && $_POST['option'] === 'DELETE' ) {

		if(isset($_POST['subscriber-mail'])) {
			$subscriber = Subscriber::get_subscriber_by_email($_POST['subscriber-mail']);

			if($subscriber != null) {
				$result->success = 'true';
				$result->message = "Subscriber Found Successfuly";
				$result->subscriber_id = $subscriber->get_id();
			} else {
				$result->success = 'false';
				$result->message = "Subscription Was Not Found Failed provide a the email you used to subscribe or create a new Subscription";
			}
		}

echo json_encode($result);
exit;

}

if($submitted_form === 'new_subscription' && isset($_POST['subscriber_id']) ) {

		$subscriber = Subscriber::get_subscriber($_POST['subscriber_id']);

		$subscription = new Subscription();

			if(isset($_POST['subscription-lists'])) {

				$result->success = $subscription->add_subscription($subscriber, $_POST['subscription-lists'] );

			} else {
				$result->success = false;
				$result->message .= 'No Subscription Was Selected ';
			}

			if($result->success) {
				$result->message = "Subscription Successfuly Saved!!! ";
				$result->success = 'true';
			} else {
				$result->success = 'false';
			}


			echo $result->message;

		exit;
}


if($submitted_form === 'update_subscription' && isset($_POST['subscriber_id']) ) {

		$subscriber = Subscriber::get_subscriber($_POST['subscriber_id']);

		$subscription = new Subscription();

			if(isset($_POST['subscription-lists'])) {

				$result->success = $subscription->update_subscription($subscriber, $_POST['subscription-lists'] );

			} else {
				$result->success = false;
				$result->message .= 'No Subscription Was Selected ';
			}

			if($result->success) {
				$result->message = "Subscription Updated Successfuly Saved!!! ";
				$result->success = 'true';
			} else {
				$result->success = 'false';
			}


			echo $result->message;

		exit;
}

if($get_request === 'organization_address' && $_GET['organizer_id'] == $SESSION->get_session_id() ){

			$address = DB_CONNECTION::get_organization_address($_GET['organizer_id']);

			echo json_encode($address);
			exit;
}



if($get_request === 'delete_address' && $_GET['organizer_id'] == $SESSION->get_session_id() && isset($_GET['address_id']) ){

			$organizer = Organizer::get_organizer($_GET['organizer_id']);
			$address = Address::get_address($_GET['address_id']);

			$result->success = $organizer->remove_address($address);

			if($result->success){
				$result->message = "<h5 class='alert alert-success' > Address Removed Successfuly </h5> ";
			} else {
				$result->message = "<h5 class='alert alert-danger' > Address Was Not Removed Successfuly </h5> ";
			}


			echo $result->message;

			exit;
}


if($get_request === 'social_addresses' && isset($_GET['organizer_id']) && $_GET['organizer_id'] == $SESSION->get_session_id() ) {


					$socialAddress = DB_CONNECTION::get_organization_socialAddress($_GET['organizer_id']);
					echo json_encode($socialAddress);

			exit;
}



if($get_request === 'change_status' && isset($_GET['event_id']) && isset($_GET['organizer_id'])
			&& $_GET['organizer_id'] == $SESSION->get_session_id()) {

			$event = Event::get_event($_GET['event_id']);

			$result->success = $event->change_status($_GET['change_to'] );

				if($result->success) {
					$result->message = '<div class="alert alert-success" > Event Status Changed Successfuly </div> ';
					$result->success = 'true';
				} else {
					$result->message = '<div class="alert alert-danger" > Event Status Change Failed </div> ';
					$result->success = 'false';
				}

echo json_encode($result);

	exit;
}





?>
