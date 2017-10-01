<?php



class Sponsor implements Sponsor_interface{
			
			private $SPONSOR_ID;
			private $name;
			private $image;
			private $bio;
			private $status;
			
			private $sponsorImageLocation =  "../uploads/eventImages/eventSponsors/";
			
			
		function __construct(  $id = null,  $status = 'new' ) {	

					if(strtolower($status) != 'new' && strtolower($status) !='updated' && strtolower($status) != 'deleted'){
						throw new Exception("guest status passed can only be one of these (new, updated, deleted )", 1);
						
					}else if ((strtolower($status) == "updated" or strtolower($status) == "deleted") && $id == null) {
							throw new Exception("guest initialized with status updated or deleted require fourth argument for id be set", 1);
					}else{
						self::set_status(strtolower($status));
						self::set_id($id);

					}
				}

			
			private function set_status($value) {
				$this->status = $value;
			}			

			public function get_status() {
				return $this->status;
			}	

		public function set_bio($value) {
				$this->bio = $value;
			}			

			public function get_bio() {
				return $this->bio;
			}			
			public function set_name($value) {
				return ($this->name = ucwords(VALIDATOR::validate_string($value))) ? $this->name : trigger_error("INVALID value for sponsor Name. Valid name should contain atleast one or more characters ", E_USER_ERROR);
			}

			public static function get_event_sponsor($id) {
					$connection = new DB_CONNECTION();

					$sql = "CALL getEventSponsor(".$id.")";
					
					$statement = $connection->prepare_query($sql);
					
					$statement->execute();
					
						if($result = $statement->fetch() ) {
							return $result;
						} else {
							return null;
						}
					 						
			}


			public function set_sponsor(Sponsor $sponsor) {
				return false;
			}

			

			public function get_sponsor_count() {
				return 1;
			}

			public function set_sponsor_count($value) {
				return false;
			}

			public function get_sponsor($index){
				if($index = 1){
					return $this;
				} else {
					return null;
				}
			}

			public function get_image_upload_location($value){
				return $this->sponsorImageLocation.basename($value['name']);
			}

			
			public function set_image($image) {
					if (VALIDATOR::validate_image($image)){
					if (VALIDATOR::validate_image_size($image, 5000000)){
						if(move_uploaded_file($image["tmp_name"], self::get_image_upload_location($image))) {
						return $this->image = basename($image["name"]);
						} else {
							trigger_error(" Sponsor ImageUpload failed ", E_USER_ERROR );	
						}
					} else {
						trigger_error("invalid Image Size for Sponsor valid image size should be less than or equal to 5 mb  ", E_USER_ERROR );
					}

				} else {
					trigger_error("Invalid Sponsor image", E_USER_ERROR);
				}  

			}

			public function set_id($new_id) {
				 return ( !isset($this->SPONSOR_ID)) ? $this->SPONSOR_ID = $new_id : false ;
			}
			
			public function get_id() {
				return $this->SPONSOR_ID;
			}

			public function get_name() {
				return $this->name;
			}

			public function get_image(){
				return $this->image;
			}


	}



?>