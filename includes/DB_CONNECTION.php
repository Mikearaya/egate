<?php




class DB_CONNECTION	{
			 
			private $HOST  = '127.0.0.1';
			private $DB   = 'egate_db';
			private $USER = 'user';
			private $PASSWORD = 'user@egate';
           	private $CHAR_SET = 'utf8mb4';
       

			private $PDO;
			public $Statement;
			private $data_set;



			function __construct() {
				$this->DSN = "mysql:host=$this->HOST;dbname=$this->DB;charset=$this->CHAR_SET";
				$Options = [
  						  PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    					  PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    					  PDO::ATTR_EMULATE_PREPARES  => true,
					];

				try {
				  		 return $this->PDO = new PDO($this->DSN , $this->USER , $this->PASSWORD, $Options );
				  				  
				 } catch(PDOException $e) {
				 	echo "ERROR Establishing Database Connecttion: ". $e->getMessage();
				 }

			}

			public function begin_transaction(){
				$this->PDO->beginTransaction();
			}
			public static function add_ticket($val){
				$connection = new DB_CONNECTION();

				$statement = $connection->prepare_query("CALL addEventTicket(45, ".$val.", @x)");
				$statement->execute();



			}

			public static function get_organization_socialAddress($organizer_id) {

				$connection = new DB_CONNECTION();
				$sql = 'CALL getOrganizationSocials('.$organizer_id.')';
				$statement = $connection->set_query($sql);

				return($result = $statement->fetch()) ? $result : null;


			}	
			public static function get_event_category($request){


				$sql = "CALL getEventCategory(1, 12)";

					$connection = new DB_CONNECTION();
					$statement = $connection->set_query($sql);
															
				return ($events["event"] = $statement->fetchAll() >= 1 ) ? $events : null;

			}
				
		
			public static function get_event_booking_stat($organizer_id, $eventId){
				$connection = new DB_CONNECTION();

				$sql = "CALL getEventBookingStat(".$organizer_id.",".$eventId." ) ";
				
				$statement = $connection->set_query($sql);
				
				return ( $row = $statement->fetchAll()) ? $row : NULL;

			}

			public function get_organizer_id($event_id){

				 $sql = "CALL getEventOrganizerId(".$event_id.")";
					
					return	($row = $statement->fetch()) ? $row : null;

			}

			public function set_query($query) {
				try{
						
					return $this->Statement =  $this->PDO->query($query);
					
				} catch(PDOException $e) {
				 	echo 'Prepare Statement ERROR !!! : '.  $e->getMessage();
				 }
			
			}
			public function prepare_query($query) {
				try{
						
					return $this->Statement =  $this->PDO->prepare($query);
					
				} catch(PDOException $e) {
				 	echo 'Prepare Statement ERROR !!! : '.  $e->getMessage();
				 }
			
			}

			public function execute_query() {
				try{
						
					 return $this->Statement->execute();
					
				} catch(PDOException $e) {
				 	echo 'Excution of Query ERROT !!!: '.  $e->getMessage();
				 }
			}

			public function affected_rows(){
					return  $this->Statement->rowCount();
			}

			public function change_fetch_mode($mode, $class){
				$this->Statement->setFetchMode($mode, $class);
			}

				public static function get_organizer_events($id){
					$connecttion = new DB_CONNECTION();
					 $sql = 'CALL getOrganizerEvents('.$id.')';
					 $statement = $connecttion->set_query($sql);



						$row = $statement->fetchAll() ;
					return $row;					
//					return	($row = $statement->fetchAll()) ? $row : null;

			}


			public function get_active_events(){

					 $sql = "CALL getEventByStatus('OPEN')";
					$connection = new DB_CONNECTION();
					$statement = $connection->set_query($sql);         
	              	return	($row = $statement->fetch()) ? $row : null;

			}


		
				
			public static function get_event_ticket($event_id){
					$sql = "CALL getEventTicket(".$event_id .") ";
					$connection = new DB_CONNECTION();
					$statement = $connection->set_query($sql);
					
					return	($row = $statement->fetchAll()) ? $row : null;
			}


			

			public static function get_event_guest($event_id){
					$sql = "CALL getEventGuest(".$event_id.")";
						$connection = new DB_CONNECTION();
					$statement = $connection->set_query($sql);
					
				return	($row = $statement->fetchAll()) ? $row : null;
						
			}

			public static function get_event_sponsor($event_id){
					$sql = "CALL getEventSponsor(".$event_id.")";
					$connection = new DB_CONNECTION();
					$statement = $connection->set_query($sql);
					return	($row = $statement->fetchAll()) ? $row : null;
			}
			public static function get_event_comment($event_id){
					$sql = "CALL getEventGuest(".$event_id.")";
					$connection = new DB_CONNECTION();
					$statement = $connection->set_query($sql);
					return	($row = $statement->fetchAll()) ? $row : null;
			}

			public static function get_event_details($id) {
		       			
		       			$events;
		       			 $events['ticket'] = null;
		       			 $events['guest'] = null;
		       			 $events['sponsor'] = null;
		       			 $events['comments'] = null;
						$sql = "CALL getEventDetail(".$id.")";

						$connection = new DB_CONNECTION();

						$statement = $connection->set_query($sql);

						do{

							$row = $statement->fetchAll();
	
							if($row && isset($row[0]['eventId']) ) {
								 $events= $row[0];
							}

							elseif($row && isset($row[0]['ticketId']) ) {
								 $events['ticket'] = $row;
							}
							elseif($row && isset($row[0]['guestId']) ) {
								 $events['guest'] = $row;
							}
							elseif($row && isset($row[0]['sponsorId']) ) {
								 $events['sponsor'] = $row;
							}

							elseif($row && isset($row[0]['commentId']) ) {
								 $events['comment'] = $row;
							}

					}while($statement->nextRowset() && $statement->columnCount());

				    	
							    				    	
				   
				    	return $events;
			
			}


		


			public static function get_event($id) {
				 
				  $sql = "CALL getEventGeneralInfo(".$id .")";

				   $connection = new DB_CONNECTION();
        	        $statement = $connection->set_query($sql);
					 	              		
	             return	($row = $statement->fetch()) ? $row : null;
		
			
			}

			public static function get_event_schedule($id) {
				 
        	      $sql = "CALL getEventSchedule(".$id.")";
        	      $connection = new DB_CONNECTION();

        	      $statement = $connection->set_query($sql);
			
				return	($row = $statement->fetch()) ? $row : null;
				    					    			
			}

			public function query($query) {
				try{
						
						return $this->data_set =  $this->PDO->query($query);
					
				} catch(PDOException $e) {
				 	echo 'PDO Query Error: '.  $e->getMessage();
				 }
			
			}

			public function fetch_events() {

				 $sql = "CALL getEventsBasic(12)";
				 $statement = self::set_query($sql);
				return	($row = $statement->fetchAll()) ? $row : null;
	
			}

		

			
			public static function get_event_bookings($event_id){
				$sql = "CALL getEventBookings(".$event_id.")";

				    $connection = new DB_CONNECTION();
        	        $statement = $connection->set_query($sql);
					
				return	($row = $statement->fetchAll()) ? $row : null;
			}

		

			public static function get_organization_address($organizer_id){
				 
				 	$sql = "CALL getOrganizationAddress(".$organizer_id.")";
				    $connection = new DB_CONNECTION();
        	      
        	      $statement = $connection->set_query($sql);	
				
				return	($row = $statement->fetchAll()) ? $row : null;	
			}




			public static function get_organizer_info($org_id) {

					$sql = "CALL getOrganizerInformation(".$org_id.")";
				    $connection = new DB_CONNECTION();
        	             	      $statement = $connection->set_query($sql);	
				return	($row = $statement->fetch()) ? $row : null;
			}

			public function get_last_inserted_id(){
				return $this->PDO->lastInsertId();
			}

			public function fetch_query( ) {

				return	$this->Statement->fetch();
    				
			}


			public static function get_check_ins($event_id){
				
					try {
					$connection = new DB_CONNECTION();
					$sql = "CALL getEventCheckIns(".$event_id.")";
					
				    
	        	     $statement = $connection->set_query($sql);	
					return	($row = $statement->fetchAll()) ? $row : null;
				
				}catch(Exception $e) {
				
					echo $e->getMessage();
				
				}
				

			}
				




						


	}







?>


