<?php




		function is_attendee_registered() {

					}




function generate_salt( $length){
		$unique_random_string = md5(uniqid(mt_rand(), true));

		$base64_string = base64_encode($unique_random_string);

		$modified_base64_string = str_replace('+', '.', $base64_string);
		$salt = substr($modified_base64_string,0, $length);
		return $salt;
	}


function password_check($submited_pass, $stored_pass) {

		$hased = crypt($submited_pass, $stored_pass);

		if($hased == $stored_pass){
			return true;
		} else {
					return false;
		}
}

function password_encrypt($password) {
		
	$hash_format = "$2y$10$";
	$salt_length = 22;
	$salt = generate_salt($salt_length);

	$format_and_salt = $hash_format . $salt;
	$hash = crypt($password, $format_and_salt);


	return $hash;

}



	function date_difference($start_date, $end_date) {

		$start = new DateTime(date('Y-m-d', strtotime($start_date)));
		$end =  new DateTime(date('Y-m-d', strtotime($end_date)));
		
		$difference  = $start->diff($end);

		if($difference->days > 0 && $difference->invert === 0 ) {
			return $difference->days;
		} else if( $difference->days > 0 && $difference->invert === 1 ) {
			return $difference->days * -1;
		} else if( $difference->days == 0 ) {
			return $difference->days;
		}

	}
function mail_exists($mail) {
		
		$DB_driver = new DB_CONNECTION();

		$sql = "SELECT *  ";
		$sql .= "FROM `organizer` ";
		$sql .= "WHERE `e_mail` = :mail ";

		$placeholder = array( ':mail' => $mail );
		
		$statement = $DB_driver->prepare_query($sql);
		$statement->execute($placeholder);

		if ($statement->rowCount() == 1 ) {
				$organizer = $statement->fetch();
				return $organizer['ORGANIZER_ID'];
		} else {
			return false;
		}

}

 ?>