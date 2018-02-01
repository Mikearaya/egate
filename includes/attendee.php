<?php







abstract class Client {
		protected $first_name;
		protected $last_name;
		protected $e_mail;
		protected $DB_Driver;

		public function set_first_name($value){
			$this->first_name = $value;
		}

		public function set_last_name($value) {
			$this->last_name = $value;
		}

		public function set_mail_address($value) {
			$this->e_mail = $value;
		}

		public function get_first_name() {
			return $this->first_name;
		}

		public function get_last_name() {
			return $this->last_name;
		}

		public function get_mail_address(){
			return $this->e_mail;
		}

		abstract public function set_id($value);
		abstract public function get_id();


}

class Attendee extends Client{
		private $BOOKINGS = array();
		private $ATTENDEE_ID;
		private $EVNT_ID;
		private $total_booking;
		private $registered_on;
		private $service_provider;
		private $phone;




			 function __construct($evnt_id = null, $fname = null, $lname = null, $phone = null, $subscriber = null) {

					$this->DB_Driver = new DB_CONNECTION();


					$this->set_first_name($fname);
					$this->set_last_name($lname);
					$this->set_phone($phone);
					$this->set_event_id($evnt_id);
					$this->set_service_provider($subscriber);
					$this->set_booking_count(0);

			}

			public static function get_attendee($id){
				$connection = new DB_CONNECTION();

				$sql = "CALL getAttendee(".$id.") ";


				$statement = $connection->set_query($sql);


				if($attendee = $statement->fetch()) {
					return true;
				} else {
					return null;
				}

			}


			public function set_service_provider($value) {
				$this->service_provider = $value;
			}
			public function set_event_id($value){
				$this->EVNT_ID = $value;
			}

			public function get_id(){
				return $this->ATTENDEE_ID;
			}

			public function set_phone($value) {
				$this->phone = $value;
			}
			public function set_id($value) {
				$this->ATTENDEE_ID = $value;
			}

			public function get_event_id() {
				return $this->EVNT_ID;
			}


			public function get_service_provider() {
				return $this->service_provider ;
			}

			public function get_phone() {
				return $this->phone ;
			}

			public function has_payment_provide(){
				return (isset($this->service_provider)) ? true : false;

			}
			public function set_booking(Booking $new_booked){
				self::set_booking_count(self::get_booking_count() + 1);
				$this->BOOKINGS[self::get_booking_count()] = $new_booked ;

			}

			public function get_booking($index){
				return ($index <= self::get_booking_count()) ? $this->BOOKINGS[$index] : null;
			}

			function set_booking_count($value){
				return $this->total_booking = $value;
			}

			function get_booking_count(){
				return $this->total_booking;
			}


			public function book_event(){

				try {

				if(self::get_event_id() == null) {
					throw new Exception("trying to book without seting event id", 1);

				} else {




					$attendeeInfo["firstName"] =  $this->get_first_name();
					$attendeeInfo["lastName"] 	= $this->get_last_name();
					$attendeeInfo["phoneNumber"] = $this->get_phone();


					$attendeeInfo = json_encode($attendeeInfo);


					$ticketInfo;
					$count = 0;
					while ($count < self::get_booking_count() ) {

							$ticketInfo[$count]["ticketId"] =  self::get_booking($count + 1)->get_ticket_id();
							$ticketInfo[$count]["ticketQuantity"] = self::get_booking($count + 1)->get_quantity();


							$count++;
					}

						$ticketInfo = json_encode($ticketInfo);
					$sql = "CALL bookEvent(".self::get_event_id().", ".json_encode($attendeeInfo)." , ".json_encode($ticketInfo)." )";

					$statement = $this->DB_Driver->prepare_query($sql);
					$statement->execute();

					if($row = $statement->fetch()) {
						self::set_id( $row["reservationId"]);					
						return true;
					} else {
							return false;
					}


				}

								} catch (Exception $e) {
					echo $e->getMessage();
				}


				}

				public  function get_reciept(){

					try {
							if(self::get_id() == null) {
							throw new Exception("trying to access attendee information without seting id", 1);
						}

							$sql = "CALL getReciept(".self::get_id().")";

							$statement = $this->DB_Driver->set_query($sql);

								if($row["reciept"] = $statement->fetchAll()) {
									return $row;
								} else {
									return false;
								}





					} catch (Exception $e) {
						echo $e->getMessage();
					}
				}

				public function view_bookings(){

					try {
							if(self::get_id() == null) {
							throw new Exception("trying to access attendee information without seting id", 1);
						}

							$sql = "CALL getAttendeeReservation(".self::get_id().")";

							$statement = $this->DB_Driver->set_query($sql);

								if($row["booking"] = $statement->fetchAll()) {
									return $row;
								} else {
									return false;
								}





					} catch (Exception $e) {
						echo $e->getMessage();
					}
				}


				public static function check_in($eventId ,$rescieptId) {

					$result = CHECK_IN_CONTROLLER::check_In($eventId, $rescieptId);

					return $result;
				}


				public static function check_Out($eventId ,$rescieptId) {

					$result = CHECK_IN_CONTROLLER::check_Out($eventId, $rescieptId);

					return $result;
				}


}


class Viewer extends Client {


	private	$ORGANIZER_ID;
	private	$VIEWER_ID;
	private	$subject;
	private	$mail;


	 function __construct() {

	 	$this->DB_Driver = new DB_CONNECTION();

	 }


		public function set_id($value){
			if(isset($this->VIEWER_ID)) {
				return false;
			} else {
				$this->VIEWER_ID = $value;
			}
		}

		public function get_id(){
			return $this->VIEWER_ID;
		}

		public function set_mail($value) {
			$this->mail = $value;
		}

		public function get_mail() {
			return $this->mail;
		}

		public function set_subject($value) {
			$this->subject = $value;
		}

		public function get_subject() {
			return $this->subject;
		}


		public function send_mail(Organizer $recipent){

			$sql = "INSERT INTO `viewers` ( ";
			$sql .= " `first_name`, `last_name`, `e_mail`, `mail`, `ORGANIZER_ID`, `subject` ";
			$sql .= " ) VALUES ( ";
			$sql .= " :fname, :lname, :email, :mail, :id, :subject ) ";

			$placeholder = array (
									":fname" => $this->get_first_name(),
									":lname" => $this->get_last_name(),
									":email" => $this->get_mail_address(),
									":mail" => self::get_mail(),
									":subject" => self::get_subject(),
									":id" => $recipent->get_id()
								);

				$statement = $this->DB_Driver->prepare_query($sql);
				$statement->execute($placeholder);

				if($statement->rowCount() == 1) {
					$new_id = $this->DB_Driver->get_last_inserted_id();
					self::set_id($new_id);
					return true;
				} else {
					return false;
				}

		}

}



?>
