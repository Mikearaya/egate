<?php





class Ticket implements Ticket_interface{
				
		private $TIK_ID;
		public $EVNT_ID;
		private $type;
		private $quantity;
		private $price;
		private $discription;
		private $sale_start;
		private $pending;
		private $sold;
		private $sale_end;
		private $available;
		private $active;
		private $name;
		private $DB_Driver;
		private $status;

				
				

					function __construct(  $id = null,  $status = 'new' ) {	

					if(strtolower($status) != 'new' && strtolower($status) !='updated' && strtolower($status) != 'deleted'){
						throw new Exception("Ticket status passed can only be one of these (new, updated, deleted )", 1);
						
					}else if ((strtolower($status) == "updated" or strtolower($status) == "deleted") && $id == null) {
							throw new Exception("Ticket initialized with status updated or deleted require fourth argument for id be set", 1);
					}else{
						self::set_status(strtolower($status));
					
						self::set_id($id);
					

					}
				}
			
			
			
			public static function get_event_ticket($id) {

				$connection = new DB_CONNECTION();
				$sql = "CALL getEventTicket(".$id.")";
					
					
					$statement = $connection->prepare_query($sql);
					$statement->execute();
						
						if($result = $statement->fetch())	{
					 		return $result;
					 	} else {
					 		return null;
					 	}

		
			}



			public function set_ticket(Ticket $ticket) {
				return false;
			}

			public function get_ticket_count() {
				return 1;
			}

			public function set_ticket_count($value) {
				return false;
			}

			public function get_ticket($index){
				if($index = 1) {
					return $this;
				}else {
					return null;
				}
			}

		
			public function onBooked($quantity) {
				self::set_available(self::get_available() - $quantity);
				self::set_pending(self::get_pending() + $quantity );


				
			}
			public function get_event_id() {
				return $this->EVNT_ID;
			}
			public function set_pending($value) {
				return true;
			}

			public function onBookingPaid($quanity) {
				self::set_sold(self::get_sold() + $quantity );
				self::set_pending(self::get_pending() - $quantity );


			}

			public function onBookingCancel($quantity){
				self::set_pending(self::get_pending() + $quantity);
				self::ser_available(self::get_available() + $quantity);

			}

			public function set_sold($new_value) {
				$this->sold = $new_value;
			}

			

			public function set_available($new_value){
				$validated = VALIDATOR::validate_integer($new_value);
				return ($validated >= 0 ) ? $this->available = $validated : trigger_error("Invalid value for available tickets, available ticket can only have a positive integer value", E_USER_ERROR);
			
			}

			public function get_available(){
				return $this->available;
			}
			public function set_name($value) {
				return ($this->name = VALIDATOR::validate_string($value)) ? $this->name : trigger_error("invalid ticket name , valid name should contain atleast one or more characters");
			}

			public function get_name() {
				return $this->name;
			}


			public function get_type() {
				return $this->type;
			}

			public function get_quantity() {
				return $this->quantity;
			}

			public function get_discription(){
				return $this->discription;
			}

			public function get_price(){
				return $this->price;
			}

			public function get_id () {
				return isset($this->TIK_ID) ? $this->TIK_ID : false; 
			}


			public function get_sale_start(){
				return $this->sale_start;
			}

			public function get_sale_end(){
				return $this->sale_end;
			}

			public function get_pending() {
				return $this->pending;
			}
			public function get_sold() {
				return $this->sold;
			}

			public function set_quantity($value){
				if(!isset($this->available)) {
					$this->quantity = ($value) ?  $value : 0 ;
					$this->available = $value;	
				}
				
			}

			public function set_id($value){
				return (!isset($this->TIK_ID)) ? $this->TIK_ID = $value : false ;
			}

			public function set_type($value){
				
				if(is_null(self::get_price())) {
					$this->type = strtoupper($value);	
				}  else if(!is_null(self::get_price()) && ((self::get_price() == 0 && strtoupper(trim($value)) == 'FREE' ) 
					|| (self::get_price() > 0 && strtoupper(trim($value))  == 'PAID') )) 
				{
					$this->type = strtoupper($value);	
				} else if(!is_null(self::get_price()) && (self::get_price() > 0 && strtoupper(trim($value))  == 'FREE') ) {
					trigger_error("Ticket that have price grater than 0 birr cant be of type 'FREE' ", E_USER_ERROR);
				} else if(!is_null(self::get_price()) && (self::get_price() == 0 && strtoupper(trim($value))  == 'PAID') ) {
					trigger_error("Ticket that have price  0 birr cant be of type 'PAID' ", E_USER_ERROR);
				}
				
			}

			public function set_price($value){
				if(is_null(self::get_type())) {
					$this->price = $value;	
				}  else if(!is_null(self::get_type()) && ((self::get_type() == 'FREE' && $value == 0 ) 
					|| (self::get_type() == 'PAID' && $value  > 0 ) ) )
				{
					$this->price = $value;	
				} else if(!is_null(self::get_type()) && (self::get_type() == 'PAID' && $value  <= 0 ) ) {
					trigger_error(" Ticket that have type 'PAID' cant have price of 0 birr ", E_USER_ERROR);
				} else if(!is_null(self::get_type()) && (self::get_type() == 'FREE' && $value  >= 0 ) ) {
					trigger_error("Ticket that have type 'FREE' cant have a price greater than  0 birr  ", E_USER_ERROR);
				}
				
			}

			public function set_sale_start($value){

			if ($validated = VALIDATOR::validate_date($value)) {

				$start = new DateTime($validated);
				$today = new DateTime(date('Y-m-d', time()));
				$end = ($this->get_sale_end()) ? new DateTime($this->get_sale_end()) : null;
				
				if(  $today > $start ) {
					trigger_error("Ticket Sale starting Date can not be less than the current date", E_USER_ERROR);
				} else if(!is_null($end) && ($end < $start) ) {
					trigger_error("Ticket Sale starting Date can not be greater than ticket sale ending date", E_USER_ERROR);
				} else {
					$this->sale_start = $validated;
				}
			} else {
				 trigger_error("invalid ticket start date value. ", E_USER_ERROR);
				}

				return $this->sale_start;
			
		}

			public function set_sale_end($value){
				if ($validated = VALIDATOR::validate_date($value)) {

				$end = new DateTime($validated);
				$today = new DateTime(date('Y-m-d', time()));
				$start = ($this->get_sale_start()) ? new DateTime($this->get_sale_start()) : null;

				if(  $today > $end ) {
					trigger_error("Ticket Sale Ending date can not be less than the current date", E_USER_ERROR);
				} else if(!is_null($start) && ($end < $start) ) {
					trigger_error("Ticket Sale Ending Date can not be less than ticket sale starting date", E_USER_ERROR);
				} else {
					$this->sale_end = $validated;
				}
			} else {
				 trigger_error("invalid ticket end date value. ", E_USER_ERROR);
				}

				return $this->sale_end;
			}

			public function set_discription($value){
				return ($this->discription = VALIDATOR::validate_string($value)) ? $this->discription : trigger_error("invalid ticket discription value. valid discription should contain atleast one or more characters", E_USER_ERROR);
			}
			
			public function set_status($value){
				$this->status = $value;
			}


			public function get_status(){
				return $this->status;
			}

			public function is_active(){
				return ($this->active) ? true : false;
			}

			public function is_available($amount) {

				if( $amount <=  self::get_available() ) {
					return true;
				}  else {
					return false;
				}
			}
		

}



?>