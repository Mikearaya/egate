<?php
include('../includes/SESSION.php');
include('../includes/classes.php');


$SESSION = new SESSION();
$connection = new DB_CONNECTION();


$submitted_form = '';
	if(isset($_POST['form'])) {
			$submitted_form = $_POST['form'];

	}


		$result = new stdclass();


if($submitted_form == 'event_basics_update') {



					
				
		$organizer = Organizer::get_organizer($SESSION->get_session_id());
					
						$event_id = $_POST['event_id'];

				$event = Event::get_event($event_id);
					         
					if(isset($_POST['event-title-update'])){
					$event->set_name($_POST['event-title-update']);
				}
					if(isset($_POST['venue-name-update'])){
					$event->set_venue($_POST['venue-name-update']);
				}
					if(isset($_POST['event-start-datetime-update'])){
					$event->set_start_datetime($_POST['event-start-datetime-update']);
				}
				if(isset($_POST['event-end-datetime-update'])){
					$event->set_end_datetime($_POST['event-end-datetime-update']);
				}
				if(isset($_POST['event-discription-update'])){
					$event->set_discription($_POST['event-discription-update']);
				}

				if(isset($_POST['event-type-update'])){
					$event->set_category($_POST['event-type-update']);
				}
			
			$organizer->update_event($event);					

				$address = new Address();
				if(isset($_POST['event-country-update'])){
					$address->set_country($_POST['event-country-update']);
				}
				if(isset($_POST['event-city-update'])){
					$address->set_city($_POST['event-city-update']);
				}
				if(isset($_POST['event-location-update'])){
					$address->set_location($_POST['event-location-update']);
				}
				if(isset($_POST['event-longitude-update'])){
					$address->set_longitude($_POST['event-longitude-update']);
				}

				if(isset($_POST['event-latitude-update'])){
					$address->set_latitude($_POST['event-latitude-update']);
				}

			
					if($event->update_address($address)) {
						$result->message = 'event created';
					} else {
						$result->message = 'problem creating Event';
					}


echo json_encode($result);
}

if($submitted_form === 'delete_event'){
$organizer = Organizer::get_organizer($SESSION->get_session_id());
	if(isset($_POST['event_id'])){

		$event = Event::get_event($_POST['event_id']);

		$result = $organizer->remove_event($event);

		if($result){
			echo 'Event Deleted';
		} else {
			echo 'Error Deleting Event';
		}
	}
}

if($submitted_form === 'event_schedule_update'){
$organizer = Organizer::get_organizer($SESSION->get_session_id());
	if(isset($_POST['event_id'])){

		$event = Event::get_event($_POST['event_id']);

		if(isset($_POST['event-start-datetime-update'])) {
		$event->set_start_datetime($_POST['event-start-datetime-update']);
		}
		if(isset($_POST['event-end-datetime-update'])) {
		$event->set_start_datetime($_POST['event-end-datetime-update']);
		}

		$result = $organizer->update_event($event);
		
		

		if($result){
			echo '<div class="alert alert-success" > Event Schedule Updated   </div> ';
		} else {
			echo '<div class="alert alert-danger" >  Sorry, Error Updating Event Schedule, Try Again!!! </div> ';
		}
	}
}
?>