<?php

include('../includes/classes.PHP');
include('../includes/SESSION.PHP');
$SESSION = new SESSION();

$get_request = '';
$connection = new DB_CONNECTION();
	
if(isset($_POST['get'])){

	$get_request = $_POST['get'];

}


if($get_request === 'organizer_mail') {
	$email = $connection->get_organizer_mail($SESSION->get_session_id());

	if($email){
		echo json_encode($email);
	} else {
		echo json_encode($email);
	}

}

if($get_request === 'organizer_info'){

	$info = $connection->get_organizer_info($SESSION->get_session_id());
	echo	json_encode($info);

}

if($get_request === 'event_basics'){

if(isset($_POST['event_id'])){

	$eve  = $connection->get_event_assoc($_POST['event_id']);

	echo json_encode($eve);
}
}

if($get_request === 'event_schedule'){

	if(isset($_POST['event_id'])){

		$eve  = $connection->get_event_assoc($_POST['event_id']);

		echo json_encode($eve);
	}
}


	if($get_request === 'organizer_events')	{
		$org = $connection->get_organizer_events($SESSION->get_session_id());

		echo json_encode($org);
	}


?>
