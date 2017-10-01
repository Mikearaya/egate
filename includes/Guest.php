<?php



class Guest implements Guest_interface {
			
			private $GUEST_ID;
			private $first_name;
			private $last_name;
			private $aka_name;
			private $image;
			private $title;
			private $bio;
			private $status;
			private $guestImageLocation =  "../uploads/eventImages/eventGuests/";
			
			
				function __construct(  $id = null,  $status = 'new' ) {	

					if(strtolower($status) != 'new' && strtolower($status) !='updated' && strtolower($status) != 'deleted'){
						trigger_error("guest status passed can only be one of these (new, updated, deleted )", E_USER_ERROR);
						
					}else if ((strtolower($status) == "updated" or strtolower($status) == "deleted") && $id == null) {
							trigger_error("guest initialized with status updated or deleted require fourth argument for id be set", E_USER_ERROR);
					} else {
						self::set_status(strtolower($status));
						self::set_id($id);
									
					}
				}


			public function set_id($new_id) {
				
				return  (!isset($this->GUEST_ID) ) ? $this->GUEST_ID = $new_id : trigger_error("Invalid guest Id value or trying to set id to an existing guest", E_USER_ERROR) ;
			}
			
			public static function get_event_guest($id){

				$connection = new DB_CONNECTION();
					$sql = "CALL getEventGuest(".$id.")";
					
					$statement = $connection->prepare_query($sql);
					$statement->execute();
							
							if($result = $statement->fetchAll()){

								$guests = new Guest();
								for ($i = 0; $i < count($result) ; $i++) {
									$guest = new Guest();
									$guests[$i] = $guest->set_first_name($result[$i]["firstName"]);	
									$guests[$i] = $guest->set_last_name($result[$i]["lastName"]);	
									$guests[$i] = $guest->set_aka_name($result[$i]["akaName"]);	
									$guests[$i] = $guest->set_title($result[$i]["guestTitle"]);	
									$guests[$i] = $guest->set_bio($result[$i]["aboutGuest"]);	
									$guests[$i] = $guest->set_image($result[$i]["guestImage"]);	
									$guests[$i] = $guest->set_id($result[$i]["guestId"]);
									$guests[$i] = $guest->set_status("SAVED");

								}
								
								return $guests;
							} else {
								return null;
							}

					 	
			}

			private function set_status($new_status) {
				return $this->status = $new_status;
			}

			public function get_status() {
				return $this->status;
			}
			public function get_id() {
				return isset($this->GUEST_ID) ? $this->GUEST_ID : false ;
			}

			public function set_guest(Guest $guest) {
				return false;
			}

		
			public function get_guest_count() {
				return 1;
			}

			public function set_guest_count($value) {
				return false;
			}

			public function get_guest($index){
				if($index = 1) {
					return $this;
				} else {
					trigger_error("trying to get guest index value out of bound guest can only contain instance of one guest", E_USER_ERROR);
				}
			}

		
			public function get_first_name() {
				return $this->first_name;
			}

			public function get_last_name() {
				return $this->last_name;
			}

			public function get_aka_name() {
				return $this->aka_name;
			}

			public function get_bio() {
				return $this->bio;
			}

			public function get_image(){
				return $this->image;
			}

			public function set_bio($value) {
				return ($this->bio = VALIDATOR::validate_text($value)) ? $this->bio : trigger_error("Invalid value for guest bio. valid bio must contain atleast one or more chacters", E_USER_ERROR);
			}

			public function set_first_name($value) {
			return ($this->first_name = VALIDATOR::validate_name($value)) ? $this->first_name : trigger_error("Invalid value for guest first name. valid name should only contain alphabetic characters", E_USER_ERROR);
			}

			public function set_last_name($value) {
			return ($this->last_name = VALIDATOR::validate_name($value)) ? $this->last_name : trigger_error("Invalid value for guest last name. valid name should only contain alphabetic characters", E_USER_ERROR);
			}

			public function set_aka_name($value) {
				return ($this->aka_name = VALIDATOR::validate_string($value)) ? $this->aka_name : trigger_error("Invalid value for guest aka name. valid name should contain atleast one or more characters", E_USER_ERROR);
			}
			public function get_image_upload_location($value){
				return $this->guestImageLocation.basename($value['name']);
			}

			public function set_image($image) {

						if (VALIDATOR::validate_image($image)){
					if (VALIDATOR::validate_image_size($image, 5000000)){
						if(move_uploaded_file($image["tmp_name"], self::get_image_upload_location($image))) {
						return $this->image = basename($image["name"]);
						} else {
							trigger_error(" Image Upload failed ", E_USER_ERROR );	
						}
					} else {
						trigger_error("invalid Image Size for Guest valid image size should be less than or equal to 5 mb  ", E_USER_ERROR );
					}

				} else {
					trigger_error("Invalid Guest image", E_USER_ERROR);
				}  

			}

			public function set_title($value) {
				return ($this->title = VALIDATOR::validate_regExp($value, '/[a-ZA-Z]+[.]?/')) ? $this->title : trigger_error("invalid Guest title");
			}
			

			public function get_title() {
				return $this->title;
			}


			


} //Event special GUEST class End


?>