<?php




class CHECK_IN_CONTROLLER 
{
	
	function __construct()
	{
		$connection = new DB_CONNECTION();

	}
	public static function get_check_in($id){
		$connection = new DB_CONNECTION();
		
		$sql = "SELECT * ";
		$sql .= "FROM `checked_reciepts` ";
		$sql .= "WHERE `CHECK_IN_ID` = :id ";

		$placeholder = array(':id' => $id );

			$statement  = $connection->prepare_query($sql);
			$statement->execute($placeholder);

			if($statement->rowCount() == 1 ){
			return	$statement->fetch();
			} else {
				return false;
			}

	}

	public static function get_event_check_ins($event_id){
				
		$connection  = new DB_CONNECTION();

			$sql = "CALL getEventCheckIns(".$event_id.")";
			
			$statement = $connection->set_query($sql);
			
				
		return ($result = $statement->fetchAll()) ? $result : null ;
						
}



	public static function check_out($eventId, $recieptId){
				$result;
		$connection = new DB_CONNECTION();
		$statement;
			try {
		

		$sql = "CALL attendeeCheckOut(".$eventId.",".$recieptId.")";
	
			$statement = $connection->prepare_query($sql);
			
			$statement->execute();
		} catch (Exception $e) {
					trigger_error($e->getMessage(), E_USER_ERROR);
					$error = 1;	
		
				}
			return ($error == 0 && $result = $statement->fetch()) ? $result : false;



	}

	public static function check_in($eventId, $recieptId){
		$error = 0;
		$result;
		$connection = new DB_CONNECTION();
		$statement;
			try {
					$connection = new DB_CONNECTION();
					$sql = "CALL attendeeCheckIn(".$eventId.",".$recieptId.")";
					$statement = $connection->prepare_query($sql);
					$statement->execute();
					
				} catch (Exception $e) {
					trigger_error($e->getMessage(), E_USER_ERROR);
					$error = 1;	
		
				}
			return ($error == 0 && $result = $statement->fetch()) ? $result : false;

		}

	
}




?>