<?php



abstract class Event_Model implements Event_interface, Comment_interface, Ticket_interface,
									Sponsor_interface, Guest_interface, Location_interface {

	    private $tickets = array();
	    private $ticketCount;
	    private $comments = array();
	    private $commentCount;
	    private $sponsors = array();
	    private $sponsorCount;
	    private $guests = array();
	    private $guestCount;
	    private $bookings= array();
	    private $bookingCount;
	    protected $DB_Driver;


				function __construct() {
					$this->DB_Driver = new DB_CONNECTION();
				}


		    abstract function add_comment(Comment $comment);
		    abstract function remove_comment(Comment $comment);
	     	abstract function set_ticket(Ticket $tiket);

    	    abstract function add_event(Event $event);
			abstract function update_event(Event $event);
			abstract function delete_event(Event $event);


			abstract function add_event_guest(Event $guest);
			abstract function delete_event_guest(Event $event );
			abstract function update_event_guest(Event $guest);

			abstract function add_event_sponsor(Event $sponsor);
			abstract function delete_event_sponsor(Event $sponsor);
			abstract function update_event_sponsor(Event $sponsor);

			abstract function add_event_ticket(Event $ticket);
			abstract function delete_event_ticket(Event $ticket);
			abstract function update_event_ticket(Event $ticket);



			public function set_guest_count($new_count){
				$validated = VALIDATOR::validate_integer($new_count);
				 return ($validated >= 0) ? $this->guestCount = $validated :  trigger_error("INVALID guest count value. valid value should be a positive integer", E_USER_ERROR);

			}

			public function set_event_count($new_count) {
				return false;
			}

			public function get_event_count() {
				return 1;
			}

			public function get_event($index){

				return ($index = 1 ) ?  $this : trigger_error("INVALID event index, event can only contain 1 instance of event", E_USER_ERROR);
			}

			public function get_guest_count(){
				return $this->guestCount;
			}
			public function set_ticket_count($new_count) {
					$validated = VALIDATOR::validate_integer($new_count);
				 return $this->ticketCount = ($validated >= 0  ) ?  $validated :  trigger_error("INVALID ticket count value. valid value should be a positive integer", E_USER_ERROR);
						}
			public function get_ticket_count() {
							return $this->ticketCount;
						}
			public function set_comment_count($new_count){
			$validated = VALIDATOR::validate_integer($new_count);
				 return ($validated >= 0) ? $this->commentCount = $validated :  trigger_error("INVALID comment count value. valid value should be a positive integer", E_USER_ERROR);
			}

			public function get_comment_count(){
				      		return $this->commentCount;
			}
			public function set_sponsor_count($new_count){
					$validated = VALIDATOR::validate_integer($new_count);
				 return ($validated >= 0) ? $this->sponsorCount = $validated :  trigger_error("INVALID sponsor count value. valid value should be a positive integer", E_USER_ERROR);
			}
			public function get_sponsor_count(){
							return 	$this->sponsorCount ;
						}
	}

class Event extends Event_Model{

		private $EVNT_ID;
		private $name;
		private $venue;
		private $discription;
		private $picture;
		private $start_date;
		private $end_date;
		private $start_time;
		private $end_time;
		private $category;
		private $topic;
		private $active;
		private $ADDRESS;
		private $status;
		private $addressCount;
	private $ImageTargetFile =  "../uploads/eventImages/";





				function __construct() {

						$this->set_comment_count(0);
						$this->set_ticket_count(0);
						$this->set_sponsor_count(0);
						$this->set_guest_count(0);
						$this->set_event_status("open");
						parent::__construct();



				}

			public static function get_organizer_event($organizer_id , $id) {

				$connection = new DB_CONNECTION();
				$sql = "CALL getOrganizerEvent(".$organizer_id.", ".$id.")";


					$statement = $connection->prepare_query($sql);
					$statement->execute();

						if($result = $statement->fetch())	{

							$event = new Event();
							$event->set_id($result["eventId"]);
							$event->set_name($result["eventName"]);
							$event->set_venue($result["venue"]);
							$event->set_discription($result["aboutEvent"]);
							$event->set_start_date($result["startDate"]);
							$event->set_start_time($result["startTime"]);
							$event->set_end_date($result["endDate"]);
							$event->set_end_time($result["endTime"]);
							$event->set_category($result["eventCategory"]);

							$eventAddress = new Address();
							$eventAddress->set_city($result["city"]);
							$eventAddress->set_sub_city($result["subCity"]);
							$eventAddress->set_country($result["country"]);
							$eventAddress->set_location($result["location"]);
							$eventAddress->set_longitude($result["longitude"]);
							$eventAddress->set_latitude($result["latitude"]);

							$event->set_address($eventAddress);


					 		return $event;
					 	} else {
					 		return null;
					 	}

			}

			public function get_image_upload_location($value){
				return $this->ImageTargetFile.basename($value['name']);
			}

			public function add_event(Event $new_event) {
				return false;
			}

			public function update_event(Event $event) {
				return false;

			}
			public function delete_event(Event $event){
				return false;
			}



			public function is_active(){
				 return ($this->active == 1 ) ? true : false;
			}

			public function set_event_status($bool){
				$validated = VALIDATOR::is_valid_event_status($bool);
				return ($validated) ? $this->active = $validated : trigger_error("INVALID boolean value for event status", E_USER_ERROR);
			}



			public function set_category($value){
			return ($this->category = VALIDATOR::validate_regExp($value, '/^[a-zA-Z ]+$/')) ? $this->category : trigger_error("INVALID event category value", E_USER_ERROR);
			}

			public function set_topic($value){
			return ($this->topic = VALIDATOR::validate_regExp($value, '/^[a-zA-Z ]+$/')) ? $this->topic : trigger_error("INVALID event category value", E_USER_ERROR);
			}

			public function set_start_date($value){
			return ($this->start_date = VALIDATOR::validate_date($value)) ? $this->start_date : trigger_error("INVALID event start date  value. valid date value should be in a format YYYY-mm-dd ", E_USER_ERROR);
			}

			public function set_end_date($value){
			return ($this->end_date = VALIDATOR::validate_date($value)) ? $this->end_date : trigger_error("INVALID event end date  value. valid date value should be in a format YYYY-mm-dd ", E_USER_ERROR);
			}


			public function set_start_datetime($date, $time ){
							$validated_date = VALIDATOR::validate_date($date);
							$validated_time = VALIDATOR::validate_time($time);
					$start = new DateTime($validated_date.' '.$validated_time);
					$today = new DateTime(date('Y-m-d h:m:s', time()));
					$end = (self::get_end_date() && self::get_end_time()) ? new DateTime(self::get_end_date().' '.self::get_end_time()) : null;
					$difference =  $today->diff($start);

					if($difference->days  < 2 && $difference->invert  == 0 || $difference->days  > 0 && $difference->invert  == 1 ) {
						trigger_error("Invalid Event Start Date,event Start Date should be atleast 2 days greater than current date . ", E_USER_ERROR);
					} else if (!is_null($end) && ($end < $start )) {
						trigger_error("Invalid Event start date. event start time can not be greater than event event time . ", E_USER_ERROR);
					} else {
						$this->start_time = $validated_time;
						$this->start_date = $validated_date;

					}

			}



			public function set_end_datetime($date, $time ){
							$validated_date = VALIDATOR::validate_date($date);
							$validated_time = VALIDATOR::validate_time($time);
					$end = new DateTime($validated_date.' '.$validated_time);
					$today = new DateTime(date('Y-m-d h:m:s', time()));
					$start = (self::get_start_date() && self::get_start_time()) ? new DateTime(self::get_start_date().' '.self::get_start_time()) : null;
					$difference =  $today->diff($end);

					if($today > $end ) {
						trigger_error("Invalid Event end Date,event end Date  can not be less than than the current date ", E_USER_ERROR);
					} else if (!is_null($start) && ($end < $start )) {
						trigger_error("Invalid Event end date. event end time can not be less than event start time . ", E_USER_ERROR);
					} else {
						$this->end_time = $validated_time;
						$this->end_date = $validated_date;

					}

			}

			public function set_start_time($date){

				return ($this->start_time = VALIDATOR::validate_time($date)) ? $this->start_time : trigger_error("INVALID event start time  value. valid date value should be in a format hh:mm:ss ", E_USER_ERROR);
			}

			public function set_end_time($value){
			return ($this->end_time = VALIDATOR::validate_time($value)) ? $this->end_time : trigger_error("INVALID event end time  value. valid date value should be in a format hh:mm:ss ", E_USER_ERROR);
			}

			public function set_picture($image){


					if (VALIDATOR::validate_image($image)){
					if (VALIDATOR::validate_image_size($image, 10000000)){
						if(move_uploaded_file($image["tmp_name"], self::get_image_upload_location($image))) {
						return $this->picture = basename($image["name"]);
						} else {
							trigger_error(" Image Upload failed ", E_USER_ERROR );
						}
					} else {
						trigger_error("invalid Image Size for event valid image size should be less than or equal to 10 mb  ", E_USER_ERROR );
					}

				} else {
					trigger_error("Invalid image", E_USER_ERROR);
				}


			}



			public function set_discription($value){
				return ($this->discription = ucfirst(VALIDATOR::validate_string($value))) ? $this->discription : trigger_error("invalid event discription value. valid discription should contain atleast one or more characters", E_USER_ERROR);
			}

			public function set_name($value){
			return ($this->name = ucwords(VALIDATOR::validate_string($value))) ? $this->name : trigger_error("invalid event name value. valid name should contain atleast one or more characters", E_USER_ERROR);
			}
			public function set_venue($value){
			return ($this->venue = ucwords(VALIDATOR::validate_string($value))) ? $this->venue : trigger_error("invalid event venue name value. valid venue name should contain atleast one or more characters", E_USER_ERROR);
			}

			public function get_id() {
				return  $this->EVNT_ID ;
			}

			public function set_id($new_id) {

			return $this->EVNT_ID = $new_id;
			}



			public function get_name() {
				return $this->name;
			}


			public function get_venue() {
				return $this->venue;
			}

			public function get_discription() {
				return $this->discription;
			}

			public function get_picture() {
				if(!isset($this->picture)) {
					return NULL;
				} else {
					return $this->picture;
				}
			}
			public function get_address($index) {
				return  $this->ADDRESS;
			}

			public function get_start_date() {
				return ($this->start_date) ? $this->start_date : NULL;
			}

			public function get_end_date() {
				return ($this->end_date) ? $this->end_date : NULL;
			}

			public function get_start_time() {
				return ($this->start_time) ? $this->start_time : NULL;
			}

			public function get_end_time() {
				return ($this->end_time) ? $this->end_time : NULL;
			}
			public function get_category() {
				return $this->category;
			}
			public function get_topic() {
				return $this->topic;
			}



			public function get_guest($index) {
				return $this->guests[$index];
			}

			public function get_ticket($index){
			return  $this->tickets[$index];
			}

	       	public function get_comment($index)	{
	        	return ($index = VALIDATOR::is_positive_int($index) && $index <= $this->get_comment_count() ) ?  $this->comments[$index] : trigger_error("comment index out of bound", E_USER_ERROR) ;
	        }

			public function get_sponsor($index) {
				return  $this->sponsors[$index] ;
			}

 			public function set_address(Address $location) {

				return ($this->ADDRESS = $location) ? $this->ADDRESS : trigger_error("invalid address value passed for event set address ", E_USER_ERROR);

			}



			public function change_status($new_status){
				self::set_status($new_status);

				$sql ="CALL updateEventStatus(".self::get_organizer_id().",".self::get_id().",".self::get_status().",". $result .") ";



				$statement = $this->DB_Driver->prepare_query($sql);
				$statement->execute();

					if($result){
						return true;

					} else {
						return false;
					}
			}

			public function update_address() {

					if($address != null ) {



						$newAddress= array(
												':id' => self::get_id(),
												':country' => $address->get_country(),
												':city' => $address->get_city(),
												':sub_city' => $address->get_sub_city(),
												':common' => $address->get_common_name(),
												':latitude' => $address->get_latitude(),
												':longitude' => $address->get_longitude()
											);
						$sql = "call updateEventAddress(".$newAddress.") ";
						$statement = $this->DB_Driver->prepare_query($sql);
						$statement->execute();

						return ($statement->rowCount() == 1 ) ? true : false;



					} else {

						return false;
					}

			}

			public function remove_address($Address) {
				return false;
			}





			public function set_guest(Guest $new_guest) {

					$last_index = $this->set_guest_count($this->get_guest_count() + 1);
					$this->guests[$last_index] = $new_guest;

			}

			public function add_event_guest(Event $guest){

				return false;

			}

			public function update_event_guest(Event $guest){

				return false;

			}

			public function delete_event_guest(Event $event){

				return false;

			}

			public function set_sponsor(Sponsor $sponsor) {

					$last_index = $this->set_sponsor_count($this->get_sponsor_count() + 1);
					$this->sponsors[$last_index] = $sponsor;

			}


			public function add_event_sponsor(Event $sponsor) {
				return false;
			}

			public function delete_event_sponsor(Event $sponsor) {
				return false;
			}

			public function update_event_sponsor(Event $sponsor) {
				return false;
			}


			public function set_status($new_status) {

				return ($this->status = VALIDATOR::is_valid_event_status($new_status) ) ? $this->status : trigger_error("invalid event status value event status can only have OPEN or DRAFT values ", E_USER_ERROR);
			}
			public function get_status() {
				return $this->status;
			}


			public function remove_sponsor(Sponsor $sponsor){

					$counter = 0;

					while(++$counter <= $this->get_sponsor_count() ) {

							if($this->sponsors[$counter] == $sponsor ) {

								for($x = $counter; $x < $this->get_sponsor_count() ; $x++ ) {
										$this->sponsors[$x] = $this->sponsors[$x + 1];
								}

								$this->set_sponsor_count($this->get_sponsor_count() - 1);
							}
					}


			}



	      	public function add_comment(Comment $comment){

	          $this->set_comment_count($this->get_comment_count()+1 );
	          $this->comments[$this->get_comment_count()] = $comment;


					$newComment = array(
									  	  'commenter' => $comment->get_commenter(),
										  'comment' => $comment->get_comment()

										  );

					$newComment = json_encode($newComment);

					$sql = "CALL addComment(".self::get_id().", ".json_encode($newComment).")";

					$statement = $this->DB_Driver->prepare_query($sql);
					$statement->execute();

					if ($result = $statement->fetch()) {
						$this->comments[$this->get_comment_count()]->set_id($result["commentId"]);
						return true;
					} else {
						return false;
					}


	          	      	}


	      	public function remove_comment(Comment $comment){

		          	$counter = 0;

		          	$sql = "DELETE FROM `comments` ";
					$sql .= "WHERE `CMT_ID` = :id ";

					$placeholder = array(':id' => $comment->get_id() );

					$statement = $this->DB_Driver->prepare_query($sql);
					$statement->execute($placeholder);



		          while(++$counter <= $this->get_comment_count()){

		              if($this->comments[$counter] == $comment->get_comment() ){
		                  for($x = $counter ; $x < $this->get_comment_count(); $x++ ){
		                    $this->comments[$x] = $this->comments[$x +1];
		                  }

		                  $this->set_comment_count($this->get_comment_count() - 1 );
		              }
		          }

	         	return ($statement->rowCount() == 1 ) ?	true : false;
	      	}


			public function remove_ticket(Ticket $tik_id){

					$counter = 0;
					while(++$counter < $this->get_ticket_count()) {

							if($this->tickets[$counter]->get_id(1) == $tik_id ) {


								for($x = $counter ; $x < $this->get_ticket_count() ; $x++ ) {
									$this->tickets[$x] = $this->tickets[$x + 1];
								}

								$this->set_ticket_count($this->get_ticket_count() - 1);
								break;

							}

					}


				return $this->get_ticket_count();

			}


			public function update_event_ticket(Event $tiket){
				return false;
			}

			public function add_event_ticket(Event $ticket) {
				return false;
			}

			public function delete_event_ticket(Event $ticket) {
				return false;
			}

			public function set_ticket(Ticket $new_ticket)	{

				$event_start = (self::get_start_date()) ? new DateTime(self::get_start_date()) : null;
				$event_end = (self::get_end_date()) ? new DateTime(self::get_end_date()) : null;

				$ticket_start = new DateTime($new_ticket->get_sale_start());
				$ticket_end = new DateTime($new_ticket->get_sale_end());

				if(!is_null($event_start) && $event_start < $ticket_start ) {
					trigger_error("Error, Ticket sale start date can not be greater than event start date", E_USER_ERROR);
				} else if(!is_null($event_end) && $event_end < $ticket_end){
					trigger_error("Error, Ticket sale end date can not be greater than event end date", E_USER_ERROR);
				} else {
					self::set_ticket_count(self::get_ticket_count() + 1);

					$this->tickets[self::get_ticket_count()] = $new_ticket;

					return $this->get_ticket_count();
				}


			}



}



?>
