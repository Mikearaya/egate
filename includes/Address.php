<?php


class Address {
		
		private $ORG_ADD_ID;
		private $country;
		private $city;
		private $sub_city;
		private $status;
		private $common_name;
		private $location;
		private $longitude;
		private $latitude;

	
				function __construct($id = null, $status = 'new' )	{
					if(strtolower($status) != 'new' && strtolower($status) !='updated' && strtolower($status) != 'deleted'){
						trigger_error("Address Type passed can only be one of these (new, updated, deleted )", E_USER_ERROR);
						
					}else if ((strtolower($status) == "updated" or strtolower($status) == "deleted") && $id == null) {
							trigger_error("Address initialized with status updated or deleted require first argument for id be set", E_USER_ERROR);
					} else {
						self::set_status($status);
						self::set_id($id);
									
					}
				 }

			public static function get_address($id){

				$connection = new DB_CONNECTION();

				 $sql = "CALL getOrganizationAddress(".$id.")";
				 
              	$statement = $connection->set_query( $sql );
                


				    	

				    	if($row = $statement->fetch()) {
				    			
				    			self::set_country($row["country"]);
				    			self::set_city($row["city"]);
				    			self::set_sub_city($row["subCity"]);
				    			self::set_longitude($row["longitude"]);
				    			self::set_latitude($row["latitude"]);
				    			self::set_location($row["location"]);
				    			self::set_id($row["addressId"]);

				    		return $this;

				    	} else {

				    		return null;
				    	}


			}
			public function set_status($status) {
				return (!is_null($status)) ? $this->status = strtolower($status) : trigger_error("Null value passed for address set status ", E_ERROR);
			}

			public function get_status() {
				return $this->status;
			}

			public function set_location($value) {
			
				return  ($this->common_name = ucwords(VALIDATOR::validate_string($value))) ? $this->common_name : false;
			}

			public function get_location() {
				return $this->common_name;
			}
			
			public function set_id($new_id){
				return   $this->ORG_ADD_ID = $new_id;
			}

			public function set_sub_city($value) {
				return  ($this->sub_city = ucwords(VALIDATOR::validate_string($value))) ? $this->sub_city : false;
			}
			
			public function set_country($value) {
				return  ($this->country = ucwords(VALIDATOR::validate_string($value))) ? $this->country : false;
			}

			public function set_city($value) {
				return  ($this->city = ucwords(VALIDATOR::validate_string($value))) ? $this->city : false;
			}


			public function set_longitude($value) {
				return  $this->longitude = $value ;
			}

			public function set_latitude($value) {
				return $this->latitude = $value;
			}

			public function get_id(){
				return  ( $this->ORG_ADD_ID != null) ? $this->ORG_ADD_ID : false;
			}
			

			public function get_country() {
				return $this->country;
			}

			public function get_city() {
				return $this->city;
			}

		    public function get_sub_city() {
		    	return $this->sub_city;
		    }

			public function get_latitude() {
				return $this->latitude;
			}

			public function get_longitude() {
				return $this->longitude;
			}

			

}


?>