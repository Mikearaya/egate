<?php


include('../includes/SESSION.php');

$SESSION = new SESSION();
		
		$result = new stdclass();

		
if(isset($_GET['get']) && $_GET['get'] === 'is_logged' ){

		if($SESSION->is_loged_in() === true ){
				$result->loged = 'true';
				$result->organizer_id = $SESSION->get_session_id();
				$result->organizer_name = $SESSION->get_session_name();
		}else{
				$result->loged = 'false';
		}

	echo json_encode($result);

}




if(isset($_GET['get']) && $_GET['get'] === 'log_out'){

		$SESSION->reset_session();	

		if(!$SESSION->is_loged_in()){

			$result->success = 'true';
			
		} else {
				$result->sucess = 'false';
	
		}
	echo json_encode($result);
}

?>