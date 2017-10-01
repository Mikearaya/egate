<?php 




//include('DB_CONNECTION.php');

class Booking {
	

		
		
		private $BOOKING_ID;
		private $ATTENDEE_ID;
		private $TIK_ID;
		private $status;
		private $ticket;
		private $unit_price;
		private $total_price;
		private $available;
		private $DB_Driver;



				function __construct( $ticketId , $quantity ) {
				
					
							self::set_ticket_id($ticketId);
							self::set_quantity($quantity);
							self::set_status('PENDING');
													
				


				}
			public static function get_booking($id){
				$connection = new DB_CONNECTION();

				$sql = "SELECT * ";
				$sql .= "FROM `billing` ";
				$sql .= "WHERE `ATTENDEE_ID` = :id ";

				$placeholder = array(':id' => $id );

				$statement = $connection->prepare_query($sql);
				
				$statement->execute($placeholder);

				if($statement->rowCount() >= 1) {
					return $statement->fetchAll(PDO::FETCH_CLASS, 'Booking');

				} else {
					return null;
				}

			}

			public static function get_event_bookings($id){
				$connection = new DB_CONNECTION();

				$sql = "CALL SELECT * ";
				$sql .= "FROM `billing`, `event_tickets`, `event`  ";
				$sql .= "WHERE `event`.`EVNT_ID` = :event_id AND  `billing`.`TIK_ID` = `event_tickets`.`TIK_ID` AND `event_tickets`.`EVNT_ID` = `event`.`EVNT_ID` ";

				$placeholder = array( ':event_id' =>  $id );

				$statement = $connection->prepare_query($sql);
				$statement->execute($placeholder);

				if($statement->rowCount() >= 1) {
					return $statement->fetchAll();
				} else {
					return null;
				}

			}

			public function is_available() {
				return $this->available;
			}

			public function set_availability($bool){
				$this->available = $bool;
			}

			public function set_ticket_id($value) {
				$this->TIK_ID = $value;
			}



	
			
			public function set_id($new_id ) {
				$this->BOOKING_ID = $new_id;
			}

			public function get_id() {
				return	$this->BOOKING_ID;
			}

			public function set_status($new_status) {
				$this->status = $new_status;
			}

			public function get_unit_price() {
				return $this->unit_price;
			}

			public function set_unit_price($value) {
				 $this->unit_price = $value;
			}

			public function set_total_price() {
				$this->total_price = self::get_unit_price() * self::get_quantity() ;
			}

			public function set_quantity($quantity) {
				$this->quantity = $quantity;
			}

			public function get_quantity() {
				return $this->quantity;
			}

			public function get_ticket_id() {
				return $this->TIK_ID;

			}

			public function set_paid(){

			}

			public function get_total_price() {
				return $this->total_price;
			}

			public function get_status() {
				return $this->status;
			}


			 
}



	
	




?>