<?php


abstract class Organization implements Event_interface, Location_interface {

		protected $ORGANIZATION_ID;
		protected $logo;
		protected $name;
		protected $facebook;
		protected $twitter;
		protected $youtube;
		protected $website;
		protected $info;
		protected $po_num;
		protected $date_created;
		protected $organizationLogoLocation = '../uploads/organizersImage/companyLogos/';

		protected $mobile_number;
		protected $office_number;
		protected $ADDRESS = array();
		protected $addressCount;
		protected $DB_Driver;
		protected $EVENTS = array();
		protected $eventCount;
	private $BILL_ADD_ID;

	private $service_provider;
	private $billing_number;


			abstract function add_event(Event $event);
			abstract function update_event(Event $event);
			abstract function delete_event(Event $event);

			abstract function update_profile();
			abstract function close_organization(Organizer $updated_organizer);

			abstract function add_event_guest(Event $guest);
			abstract function delete_event_guest(Event $event);
			abstract function update_event_guest(Event $guest);

			abstract function add_event_sponsor(Event $sponsor);
			abstract function delete_event_sponsor(Event $sponsor);
			abstract function update_event_sponsor(Event $sponsor);

			abstract function add_event_ticket(Event $ticket);
			abstract function delete_event_ticket(Event $ticket);
			abstract function update_event_ticket(Event $ticket);





			public function set_organization_id($new_id) {
				return $this->ORGANIZATION_ID = $new_id;
			}

			public function get_organization_id() {
				return $this->ORGANIZATION_ID;
			}
			public function get_organization_image_location($image) {
				return $this->organizationLogoLocation.basename($image['name']);
			}

			public function set_organization_logo($image) {
				if (VALIDATOR::validate_image($image)){
					if (VALIDATOR::validate_image_size($image, 3000000)){
						if(move_uploaded_file($image["tmp_name"], self::get_organization_image_location($image))) {
						return $this->logo = basename($image["name"]);
						} else {
							trigger_error(" Profile Picture Upload failed ", E_USER_ERROR );
						}
					} else {
						trigger_error("invalid Profile picture Image Size, image size should be less than or equal to 5 mb  ", E_USER_ERROR );
					}

				} else {
					trigger_error("Invalid Profile Picture", E_USER_ERROR);
				}
			}

			public function set_organization_name($value) {
				return ($this->name = ucwords(VALIDATOR::validate_string($value))) ?  $this->name : trigger_error("Invalid organizer name valid name should contain atleast one character", E_USER_ERROR);
			}

			public function set_facebook($value) {
				return ($this->facebook = VALIDATOR::validate_string($value)) ? $this->facebook : trigger_error("invalid facebook user name valid name should contain atleast one character", E_USER_ERROR);
			}
			public function set_twitter($value) {
			return ($this->twitter = VALIDATOR::validate_string($value)) ? $this->twitter : trigger_error("invalid twitter user name valid name should contain atleast one character", E_USER_ERROR);
			}

			public function set_youtube($value) {
				return ($this->youtube = VALIDATOR::validate_string($value)) ? $this->youtube : trigger_error("invalid youtube user name valid name should contain atleast one character", E_USER_ERROR);
			}

			public function set_website($value) {
				return ($this->website = VALIDATOR::validate_url($value)) ? $this->website :trigger_error("invalid url address for organization website", E_USER_ERROR);
			}

			public function set_organization_info($value) {
				return ($this->info = ucfirst(VALIDATOR::validate_string($value)))? $this->info :  trigger_error("Invalid organizer info valid info should contain atleast one character", E_USER_ERROR);
			}

			public function set_po_num($value) {
				return ($this->po_num = VALIDATOR::validate_string($value))? $this->po_num :  trigger_error("Invalid postal address", E_USER_ERROR);
			}

			public function set_mobile_number($value) {
				return ($this->mobile_number = VALIDATOR::validate_phone_number($value)) ? $this->mobile_number :trigger_error("Invalid mobile phone number valid phone number should contain 10 or 13 digits and optional + prefix", E_USER_ERROR);
			}

			public function set_office_number($value) {
			return ($this->office_number = VALIDATOR::validate_phone_number($value)) ? $this->office_number :trigger_error("Invalid office phone number valid phone number should contain 10 or 13 digits and optional + prefix", E_USER_ERROR);
			}


			public function get_organization_logo() {
				return $this->logo;
			}

			public function get_organization_name() {
				return $this->name;
			}

			public function get_facebook() {
				return $this->facebook;
			}

			public function get_twitter() {
				return $this->twitter;
			}

			public function get_youtube() {
				return $this->youtube;
			}
			public function get_website() {
				return $this->website;
			}

			public function get_organization_info() {
				return $this->info;
			}

			public function get_po_num() {
				return $this->po_num;
			}

			public function get_mobile_number() {
				return $this->mobile_number;
			}

			public function get_office_number() {
				return $this->office_number;
			}
				public function get_status() {
				return $this->status;
			}

				public function get_billing_address(){

		}

		public function set_service_provider($value){
			$this->service_provider = $value;
		}


		public function set_billing_number($value){
			$this->billing_number = $value;
		}




		public function set_id($value){
			return ($this->ORGANIZATION_ID = VALIDATOR::validate_integer($value)) ? $this->ORGANIZATION_ID : trigger_error("INVALID organization Id valid id integer is required", E_USER_ERROR);
		}


		public function get_service_provider(){
			return $this->service_provider;
		}


		public function get_billing_number(){
			return $this->billing_number;
		}


		public function get_id(){
			return $this->ORGANIZATION_ID;
		}





		public function update_billing_address( $service_provider, $mobile_number){
			self::set_service_provider($service_provider);
			self::set_billing_number($mobile_number);


			$sql = "INSERT INTO `billing_address` (";
			$sql .= "`ORGANIZATION_ID`, `service_provider`, `phone_number` ";
			$sql .= " ) VALUES ( :organization_id , :service_provider , :phone_number ) ";
			$sql .= " ON DUPLICATE KEY UPDATE    ";
			$sql .= " `phone_number`= :phone_number1" ;

			$placeholder = array(
									':organization_id' => self::get_organization_id(),
									':service_provider' => self::get_service_provider(),
									':phone_number' => self::get_billing_number(),
									':phone_number1' => self::get_billing_number()
								);

			$statement = $this->DB_Driver->prepare_query($sql);

			$statement->execute($placeholder);

			if($statement->rowCount() >= 1){
				return true;
			}else{
				return false;
			}
		}






		public function remove_billing_address($id){


			$sql = "DELETE FROM `billing_address` ";
			$sql .= "WHERE `BILLING_ID` = :id ";


			$placeholder = array(
									':id' => self::get_organization_id(),

								);

			$statement = $this->DB_Driver->prepare_query($sql);

			$statement->execute($placeholder);

			if($statement->rowCount() == 1){
				return true;
			}else{
				return false;
			}
		}


			public function set_address(Address $address) {
				$this->set_address_count(self::get_address_count() + 1);
				 $this->ADDRESS[$this->get_address_count()] = $address;
				 return $this->get_address_count();

			}
			public function get_address($index) {
				return $this->ADDRESS[$index];
			}

			public function set_address_count($value) {
				return $this->addressCount = $value;
			}
			public function get_address_count() {
				return $this->addressCount;
			}



			public function remove_address(Address $address) {

				$sql = "DELETE FROM `organization_address`  ";
				$sql .= "WHERE `ORG_ADD_ID` = :id ";

				$placeholder = array(':id' => $address->get_id() );

				$statement = $this->DB_Driver->prepare_query($sql);

					  $statement->execute( $placeholder );

					  	if($statement->rowCount() == 1){
					  		return true;
					  	} else {
					  		return false;
					  	}


			}





}


class Organizer extends Organization {

		private $ORGANIZER_ID;
		private $first_name;
		private $last_name;
		private $e_mail;
		private $password;
		private $registered_on;
		private $picture;
		private $bio;
		private $birthdate;
		private $gender;
		private $title;
		private $position;
		private $organizerPictureLocation = '../uploads/organizersImage/profilePictures/';


				function __construct() {

						$this->set_event_count(0);
						$this->set_address_count(0);
						$this->DB_Driver = new DB_CONNECTION();



				}


					public function add_address() {
					$this->set_address($new_address);
						//$last_index = $this->set_address_count($this->get_address_count() + 1 );
						//$this->ADDRESS[$last_index] = $address;
				$error = 0;
					$new = 0;
							$address;
				$count = 0;


				while($count < $this->get_address_count()) {


						if($this->get_address($count + 1)->get_status() == 'new' ) {

						if((!$address[$new]['country'] = $this->get_address($count + 1)->get_country()) && $error = 1)
							trigger_error('REQUIRED Organization (country) not provided', E_USER_ERROR);
						if((!$address[$new]['city'] = $this->get_address($count + 1)->get_city()) && $error = 1)
							trigger_error('REQUIRED Organization (city) not provided', E_USER_ERROR);
						if((!$address[$new]['subCity'] = $this->get_address($count + 1)->get_sub_city()) && $error = 1)
							trigger_error('REQUIRED Organization (Sub-City) not provided', E_USER_ERROR);
						if((!$address[$new]['location'] = $this->get_address($count + 1)->get_location()) && $error = 1)
							trigger_error('REQUIRED Organization (Location) not provided', E_USER_ERROR);
						if((!$address[$new]['latitude'] = $this->get_address($count + 1)->get_latitude()))
							trigger_error(' Organization (latitude) not provided', E_USER_WARNING);
						if((!$address[$new]['longitude'] = $this->get_address($count + 1)->get_longitude() ))
							trigger_error(' Organization (longitude) not provided', E_USER_WARNING);

							$new++;
						}

						$count++;

				}

					if($error == 0) {
						try {
								$address = json_encode($address);
								$sql = 'CALL addOrganizationAddress('.$this->get_id().', '.json_encode($address) .')';
								$statement = $this->DB_Driver->prepare_query($sql);
								$statement->execute();
						} catch(Exception $e) {
							trigger_error($e->getMessage(), E_USER_ERROR);
							$error = 1;
						}
					}
					return ($error == 0 ) ? true : false;


			}

			public function update_address(){


						//$last_index = $this->set_address_count($this->get_address_count() + 1 );
						//$this->ADDRESS[$last_index] = $address;
				$error = 0;
					$updated = 0;
							$address;
				$count = 0;


				while($count < $this->get_address_count()) {


						if($this->get_address($count + 1)->get_status() == 'updated' ) {
						if((!$address[$updated]['addressId'] = $this->get_address($count + 1)->get_id()) && $error = 1)
							trigger_error('REQUIRED Organization (ID) not provided', E_USER_ERROR);
						if((!$address[$updated]['country'] = $this->get_address($count + 1)->get_country()) && $error = 1)
							trigger_error('REQUIRED Organization (country) not provided', E_USER_ERROR);
						if((!$address[$updated]['city'] = $this->get_address($count + 1)->get_city()) && $error = 1)
							trigger_error('REQUIRED Organization (city) not provided', E_USER_ERROR);
						if((!$address[$updated]['subCity'] = $this->get_address($count + 1)->get_sub_city()) && $error = 1)
							trigger_error('REQUIRED Organization (Sub-City) not provided', E_USER_ERROR);
						if((!$address[$updated]['location'] = $this->get_address($count + 1)->get_location()) && $error = 1)
							trigger_error('REQUIRED Organization (Location) not provided', E_USER_ERROR);
						if((!$address[$updated]['latitude'] = $this->get_address($count + 1)->get_latitude()))
							trigger_error(' Organization (latitude) not provided', E_USER_WARNING);
						if((!$address[$updated]['longitude'] = $this->get_address($count + 1)->get_longitude() ))
							trigger_error(' Organization (longitude) not provided', E_USER_WARNING);

							$updated++;
						}

						$count++;

				}



					if($error == 0) {
						try {
								$address = json_encode($address);
								$sql = 'CALL updateOrganizationAddress('.$this->get_id().', '.json_encode($address) .')';
								$statement = $this->DB_Driver->prepare_query($sql);
								$statement->execute();
						} catch(Exception $e) {
							trigger_error($e->getMessage(), E_USER_ERROR);
							$error = 1;
						}
					}
					return ($error == 0 ) ? true : false;

			}

				public function delete_address(){


						//$last_index = $this->set_address_count($this->get_address_count() + 1 );
						//$this->ADDRESS[$last_index] = $address;
				$error = 0;
					$deleted = 0;
							$address;
				$count = 0;


				while($count < $this->get_address_count()) {


						if($this->get_address($count + 1)->get_status() == 'deleted' ) {

							if((!$address[$deleted]['addressId'] = $this->get_address($count + 1)->get_id()) && $error = 1)
								trigger_error('REQUIRED Organization (ID) not provided', E_USER_ERROR);
									$deleted++;
						}

						$count++;

				}



					if($error == 0) {
						try {
								$address = json_encode($address);
								$sql = 'CALL deleteOrganizationAddress('.$this->get_id().', '.json_encode($address) .')';
								$statement = $this->DB_Driver->prepare_query($sql);
								$statement->execute();
						} catch(Exception $e) {
							trigger_error($e->getMessage(), E_USER_ERROR);
							$error = 1;
						}
					}
					return ($error == 0 ) ? true : false;

			}
					public function update_socialMedia_address(){

					$error = 0;


					$socialAddress = array('socialMedia' =>
										array(
											'facebook' => self::get_facebook(),
											'twitter' => self::get_twitter(),
											'youtube' => self::get_youtube(),

										)
					 					);

					if($error == 0) {
						try {
								$socialAddress = json_encode($socialAddress);
								$sql = 'CALL updateOrganizationSocialAddress('.$this->get_id().','.json_encode($socialAddress) .')';
								$statement = $this->DB_Driver->prepare_query($sql);
								$statement->execute($placeholder);
						} catch(Exception $e) {
							$error = 1;
							trigger_error($e->getMessage(), E_USER_ERROR);
						}
					}

					return ($error == 0) ? true : false;


			}

		public function add_event_guest(Event $event){


			$last_Index = $this->set_event($event);

			$count = 0;
			$guest = null;
			$error = 0;
			$new = 0;
			while($count < $this->get_event($last_Index)->get_guest_count() ){


				if( $this->get_event($last_Index)->get_guest($count + 1 )->get_status() == "new" ){


					if((!$guest[$new]["firstName"] = $this->get_event($last_Index)->get_guest($count + 1)->get_first_name()) && $error = 1 )
						trigger_error("REQUIRED value Event Special Guest (First Name) Missing !!!", E_USER_ERROR);
					if((!$guest[$new]["lastName"] = $this->get_event($last_Index)->get_guest($count + 1)->get_last_name()) && $error = 1 )
						trigger_error("REQUIRED value Event Special Guest (Last Name) Missing !!!", E_USER_ERROR);
					if(!$guest[$new]["akaName"] = $this->get_event($last_Index)->get_guest($count + 1)->get_aka_name())
						trigger_error("Notice: No nick name saved for Guest -- ", E_USER_NOTICE);
					if(!$guest[$new]["aboutGuest"] = $this->get_event($last_Index)->get_guest($count + 1)->get_bio())
						trigger_error("Notice: Discription Missing for Guest -- ",E_USER_NOTICE);
					if(!$guest[$new]["title"] = $this->get_event($last_Index)->get_guest($count + 1)->get_title())
						trigger_error("Notice: (Title) Missing for Guest -- ", E_USER_NOTICE);
					if(!$guest[$new]["guestImage"] = $this->get_event($last_Index)->get_guest($count + 1)->get_image())
						trigger_error("(Image) Missing for Guest -- ", E_USER_WARNING);
				$new++;
				}

				$count++;
			}

				if($error != 0 ) {
					return false;
				} else {

						try {
								$guests = json_encode($guest);
								$sql = "CALL addEventGuest(".$this->get_event($last_Index)->get_id().",".json_encode($guests).")";
								$statement = $this->DB_Driver->prepare_query($sql);
								$statement->execute();
								return true;
						} catch (Exception $e) {
							trigger_error($e->getMessage(), E_USER_ERROR);
							return false;
						}
				}


		}

		public function delete_event_guest(Event $event){


			$lastIndex = $this->set_event($event);

			$count = 0;
			$guest = null;
			$error = 0;
			$deleted = 0;
			while($count < $this->get_event($lastIndex)->get_guest_count() ){

				if( $this->get_event($lastIndex)->get_guest($count + 1 )->get_status() == "deleted" ){

					if((!$guest[$deleted]["guestId"] = $this->get_event($lastIndex)->get_guest($count + 1 )->get_id()) && $error = 1  ) {
						trigger_error('guest ID not set for one of guests, ID is required for deleted ' ,E_USER_ERROR);
					} else {
						$deleted++;
					}



				}

				$count++;
			}


			if($error == 0) {

					try {

					$guests = json_encode($guest);

					$sql = "CALL deleteEventGuest(".$this->get_event($lastIndex)->get_id().",".json_encode($guests).")";

							$statement = $this->DB_Driver->prepare_query($sql);
							$statement->execute();

					} catch (Exception $e) {
						trigger_error($e->getMessage(), E_USER_ERROR);
						$error = 1;
					}
			}

			return ($error == 0 ) ? true : false;

		 }


		public  function update_event_guest(Event  $event){

		 	$last_index = $this->set_event($event);



			$count = 0;
			$guest = null;
			$error = 0;
			$updated = 0;
			while($count < $this->get_event($last_index)->get_guest_count() ){

				if( $this->get_event($last_index)->get_guest($count + 1 )->get_status() == "updated" ){


					if((!$guest[$updated]["guestId"] = $this->get_event($last_index)->get_guest($count + 1)->get_id()) && $error = 1 )
						trigger_error("REQUIRED, Event GUEST ID name not specified", E_USER_ERROR);
					if(!$guest[$updated]["firstName"] = $this->get_event($last_index)->get_guest($count + 1)->get_first_name())
						trigger_error("Guest First Name not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$guest[$updated]["lastName"] = $this->get_event($last_index)->get_guest($count + 1)->get_last_name())
						trigger_error("Guest Last Name not specified, the default value will be the one set before ", E_USER_WARNING);
					if(! $guest[$updated]["akaName"] = $this->get_event($last_index)->get_guest($count + 1)->get_aka_name())
						trigger_error("Guest Stage Name not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$guest[$updated]["aboutGuest"] = $this->get_event($last_index)->get_guest($count + 1)->get_bio())
						trigger_error("Guest Bio not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$guest[$updated]["title"] = $this->get_event($last_index)->get_guest($count + 1)->get_title())
						trigger_error("Guest Title not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$guest[$updated]["guestImage"] = $this->get_event($last_index)->get_guest($count + 1)->get_image())
							trigger_error("Guest Image not specified, the default value will be the one set before ", E_USER_WARNING);
					$updated++;
				}

				$count++;
			}

			if($error != 0 ) {
				return false;
			} else {


					try {
							$guests= json_encode($guest);

							$sql = "CALL updateEventGuest(". $this->get_event($last_index)->get_id().",".json_encode($guests).")";

							$statement = $this->DB_Driver->prepare_query($sql);
							$statement->execute();

							return true;
					} catch (Exception $e) {

						trigger_error($e->getMessage(), E_USER_ERROR);
						return false;
					}

			}


		 }

		public function add_event_sponsor(Event  $event){


			$last_index = $this->set_event($event);
			$error = 0;
			$count = 0;
			$sponsor = null;
			$new = 0;

			while($count < $this->get_event($last_index)->get_sponsor_count() ){


				if( $this->get_event($last_index)->get_sponsor($count + 1 )->get_status() == "new" ){

					if((!$sponsor[$new]["sponsorName"] = $this->get_event($last_index)->get_sponsor($count + 1)->get_name()) && $error = 1 )
						trigger_error("REQUIRED value Sponsor (Name) Missing for Sponsor -- ". $this->get_event($last_index)->get_sponsor($count + 1)->get_name(), E_USER_ERROR);
					if(!$sponsor[$new]["sponsorImage"] = $this->get_event($last_index)->get_sponsor($count + 1)->get_image())
						trigger_error("Sponsor (Image) Not specified for Sponsor -- ". $this->get_event($last_index)->get_sponsor($count + 1)->get_name(), E_USER_WARNING);
					if(!$sponsor[$new]["aboutSponsor"] = $this->get_event($last_index)->get_sponsor($count + 1)->get_bio())
						trigger_error("Sponsor (Discription) Not specified for Sponsor -- ". $this->get_event($last_index)->get_sponsor($count + 1)->get_name(), E_USER_WARNING);

					$new++;
				}

					$count++;
			}

			if($error != 0) {
				return false;
			} else {

					try {
							$sponsors = json_encode($sponsor);
							$sql = "CALL addEventSponsor(".$this->get_event($last_index)->get_id().",".json_encode($sponsors).")";
							$statement = $this->DB_Driver->prepare_query($sql);
							$statement->execute();
							return true;
					} catch (Exception $e) {
						trigger_error($e->getMessage(), E_USER_ERROR);
						return false;
					}
			}

		}


		public function delete_event_sponsor(Event  $event){

		 			$lastIndex = $this->set_event($event);
		 			$error = 0;
			$count = 0;
			$sponsor = null;

			while($count < $this->get_event($lastIndex)->get_sponsor_count() ){


				if( $this->get_event($lastIndex)->get_sponsor($count + 1 )->get_status() == "deleted" ){

					if($this->get_event($lastIndex)->get_sponsor($count + 1 )->get_id() == null && $error = 1 ) {
						trigger_error('sponsor id not set , id is required for deleting sponsor ',E_USER_ERROR);
						exit;
					}
					$sponsor[$count]["sponsorId"] = $this->get_event($lastIndex)->get_sponsor($count + 1 )->get_id();
				}

				$count++;
			}

			if($error == 0 ) {

				try {
						$sponsors = json_encode($sponsor);

						$sql = "CALL deleteEventSponsor(".$this->get_event($lastIndex)->get_id().",".json_encode($sponsors).")";


						$statement = $this->DB_Driver->prepare_query($sql);
						$statement->execute();
					} catch (Exception $e) {
						$error = 1;
						trigger_error($e->getMessage(), E_USER_ERROR);

				}
			}

			return ($error == 0) ? true : false;
		 }

		public function change_event_status(Event $event) {

			$error = 0;

			$event_index = $this->set_event($event);
					$new_status = '';
				if((!$new_status = $this->get_event($event_index)->get_status() ) && $error = 1 )
					trigger_error("REQUIRED, Event Status is not provided ",E_USER_ERROR);


				if($error == 0 ) {
					try{
						$sql = "CALL changeEventStatus(".$this->get_event($event_index)->get_id().",".$new_status.")";

						$statement = $this->DB_Driver->prepare_query($sql);
						$statement->execute();
					}catch(Exception $e){
						$error = 1;
						trigger_error($e->getMessage, E_USER_ERROR);
					}

				}

				return ($error == 0) ? true : false;
		}

		public function update_event_picture(Event $event) {

			$error = 0;

			$event_index = $this->set_event($event);
					$image;
				if((!$image = $this->get_event($event_index)->get_picture() ) && $error = 1 )
					trigger_error("REQUIRED, Event Image is not provided ",E_USER_ERROR);


				if($error == 0 ) {
					try{
						$sql = "CALL updateEventPicture(".$this->get_event($event_index)->get_id().",".$image.")";

						$statement = $this->DB_Driver->prepare_query($sql);
						$statement->execute();
					}catch(Exception $e){
						$error = 1;
						trigger_error($e->getMessage, E_USER_ERROR);
					}

				}

				return ($error == 0) ? true : false;
		}

		public function update_event_sponsor(Event  $event){

			$count = 0;
			$sponsor = null;
			$error = 0;

				 	$eventIndex = $this->set_event($event);

			$updated = 0;
					while($count < $this->get_event($eventIndex)->get_sponsor_count() ){

						if( $this->get_event($eventIndex)->get_sponsor($count + 1)->get_status() == "updated" ){

							if((!$sponsor[$updated]["sponsorId"] = $this->get_event($eventIndex)->get_sponsor($count + 1 )->get_id())&& $error = 1 ) {
								trigger_error('Sponsor ID not set , id is required for update ',E_USER_ERROR);
								exit;
							}

							if(!$sponsor[$updated]["sponsorName"] = $this->get_event($eventIndex)->get_sponsor($count + 1)->get_name())
								trigger_error("Sponsor Name not specified, the default value will be the one set before ", E_USER_WARNING);
							if(!$sponsor[$updated]["sponsorImage"] = $this->get_event($eventIndex)->get_sponsor($count + 1)->get_image())
								trigger_error("Sponsor Image not specified, the default value will be the one set before ", E_USER_WARNING);
							if(!$sponsor[$updated]["aboutSponsor"] = $this->get_event($eventIndex)->get_sponsor($count + 1)->get_bio())
								trigger_error("Sponsor Bio not specified, the default value will be the one set before ", E_USER_WARNING);
							$updated++;
						}

						$count++;
					}


					if($error == 0) {


						try{

							$sponsors = json_encode($sponsor);
							$sql = "CALL updateEventSponsor(".$this->get_event($eventIndex)->get_id().",".json_encode($sponsors).")";

							$statement = $this->DB_Driver->prepare_query($sql);
							$statement->execute();

						} catch (Exception $e) {
						$error = 1;
						trigger_error($e->getMessage(), E_USER_ERROR);

						}
					}

				return ($error == 0) ? true : false;

		 }

		public function add_event_ticket(Event  $event){

		 	$count = 0;
			$ticket = null;
			$error = 0;
			$last_index = $this->set_event($event);

			$new = 0;
				while($count < $this->get_event($last_index)->get_ticket_count() ){


					if( $this->get_event($last_index)->get_ticket($count + 1 )->get_status() == "new" ){

						if((!$ticket[$new]["ticketName"] = $this->get_event($last_index)->get_ticket($count + 1)->get_name()) && $error = 1 )
								trigger_error("REQUIRED value Ticket (Name) Missing !!!", E_USER_ERROR);
						if((!$ticket[$new]["ticketType"] = $this->get_event($last_index)->get_ticket($count + 1)->get_type()) && $error = 1 )
								trigger_error("REQUIRED value Ticket (Type) Missing !!!", E_USER_ERROR);
						if((!$ticket[$new]["aboutTicket"] = $this->get_event($last_index)->get_ticket($count + 1)->get_discription()) && $error = 1 )
								trigger_error("REQUIRED value Ticket (Discription) Missing !!!", E_USER_ERROR);
						if((is_null($ticket[$new]["ticketPrice"] =  $this->get_event($last_index)->get_ticket($count + 1)->get_price())) && $error = 1 )
								trigger_error("REQUIRED value Ticket (Price) Missing !!!", E_USER_ERROR);
						if((!$ticket[$new]["quantity"] = $this->get_event($last_index)->get_ticket($count + 1)->get_quantity()) && $error = 1 )
								trigger_error("REQUIRED value Ticket (Quantity) Missing !!!", E_USER_ERROR);
						if((!$ticket[$new]["saleStart"] = $this->get_event($last_index)->get_ticket($count + 1)->get_sale_start()) && $error = 1 )
								trigger_error("REQUIRED value Ticket (Sale Starting Date ) Missing !!!", E_USER_ERROR);
						if((!$ticket[$new]["saleEnd"] = $this->get_event($last_index)->get_ticket($count + 1)->get_sale_end()) && $error = 1 )
								trigger_error("REQUIRED value Ticket (Sale Ending Date) Missing !!!", E_USER_ERROR);

						$new++;
					}

				$count++;
				}

				if($error == 0 ) {
						try {

							$tickets = json_encode($ticket);
							$sql = "CALL addEventticket(".$this->get_event($last_index)->get_id().",".json_encode($tickets).")";

							$statement = $this->DB_Driver->prepare_query($sql);
							$statement->execute();

							} catch (Exception $e) {

							$error = 1;
							trigger_error($e->getMessage(), E_USER_ERROR);

						}
				}

			return ($error == 0) ? true : false;
		 }


		 public function delete_event_ticket(Event  $event){

		 		$lastIndex = $this->set_event($event);
		 	$error = 0;
			$count = 0;
			$ticket = null;

			while($count < $this->get_event($lastIndex)->get_ticket_count() ){



				if( $this->get_event($lastIndex)->get_ticket($count + 1 )->get_status() == "deleted" ){

					if($this->get_event($lastIndex)->get_ticket($count + 1 )->get_id() == null && $error = 1 ) {
						trigger_error('ticket id not set , id is required for Deleting ticket', E_USER_ERROR);
						exit;
					}

					$ticket[$count]["ticketId"] = $this->get_event($lastIndex)->get_ticket($count + 1 )->get_id();

				}

				$count++;
			}

				if($error == 0 ) {

					try {
							$tickets = json_encode($ticket);

							$sql = "CALL deleteEventTicket(".$this->get_event($lastIndex)->get_id().",".json_encode($tickets).")";


							$statement = $this->DB_Driver->prepare_query($sql);
							$statement->execute();
						} catch (Exception $e) {
							$error = 1;
							trigger_error($e->getMessage(), E_USER_ERROR);

					}
				}

			return ($error == 0) ? true : false;

		}


		 public function update_event_ticket(Event  $event){

		 		$last_index = $this->set_event($event);
		 		$error = 0;
				$count = 0;
				$ticket = null;
				$updated = 0;

				while($count < $this->get_event($last_index)->get_ticket_count() ){

					if( $this->get_event($last_index)->get_ticket($count + 1 )->get_status() == "updated" ){

						if((!$ticket[$updated]["ticketId"] = $this->get_event($last_index)->get_ticket($count + 1)->get_id()) && $error = 1 )
								trigger_error("REQUIRED, Ticket ID not specified, the default value will be the one set before ", E_USER_ERROR);

							if((!$ticket[$updated]["ticketName"] = $this->get_event($last_index)->get_ticket($count + 1)->get_name()))
								trigger_error("Ticket name not specified, the default value will be the one set before ", E_USER_WARNING);
							if((!$ticket[$updated]["ticketType"] = $this->get_event($last_index)->get_ticket($count + 1)->get_type()))
								trigger_error("Ticket Type not specified, the default value will be the one set before ", E_USER_WARNING);
							if((!$ticket[$updated]["aboutTicket"] = $this->get_event($last_index)->get_ticket($count + 1)->get_discription()))
								trigger_error("Ticket Discription not specified, the default value will be the one set before ", E_USER_WARNING);
							if((is_null($ticket[$updated]["ticketPrice"] = $this->get_event($last_index)->get_ticket($count + 1)->get_price())))
								trigger_error("Ticket Price not specified, the default value will be the one set before ", E_USER_WARNING);
							if((!$ticket[$updated]["quantity"] = $this->get_event($last_index)->get_ticket($count + 1)->get_quantity()))
								trigger_error("Ticket quantity not specified, the default value will be the one set before ", E_USER_WARNING);
							if((!$ticket[$updated]["saleStart"] = $this->get_event($last_index)->get_ticket($count + 1)->get_sale_start()))
								trigger_error("Ticket Sale Start date not specified, the default value will be the one set before ", E_USER_WARNING);
							if((!$ticket[$updated]["saleEnd"] = $this->get_event($last_index)->get_ticket($count + 1)->get_sale_end()))
								trigger_error("Ticket Sale End date not specified, the default value will be the one set before ", E_USER_WARNING);
						$updated++;
					}

				$count++;

				}

				if($error == 0 ) {

					try {
							$tickets = json_encode($ticket);

							$sql = "CALL updateEventTicket(".$this->get_event($last_index)->get_id().",".json_encode($tickets).")";

							$statement = $this->DB_Driver->prepare_query($sql);
							$statement->execute();

					} catch (Exception $e) {
						$error = 1;
						trigger_error($e->getMessage(), E_USER_ERROR);

					}
				}

			return ($error == 0) ? true : false;


		 }



			public function set_event_count($new_count) {
				return (($this->eventCount = VALIDATOR::is_positive_int($new_count)) >= 0 ) ? $this->eventCount : trigger_error("INVALID event count value. valid count must be a positive integer");
			}

			public function get_event_count() {
				return $this->eventCount;
			}

			public function get_event($index){


						return $this->EVENTS[$index];

			}

			public static function log_in($userMail, $password, SESSION $session) {

        		try {



        				$connection = new DB_CONNECTION();

        				$log["email"] = $userMail;
        	        	$log["password"] = $password;

	       				$log = json_encode($log);

        	         	$sql = "CALL logIn(".json_encode($log).")";

        	      		$statement = $connection->prepare_query( $sql );
            	    	$statement->execute();

            	    	$result = $statement->fetch();

	            	    if($result["organizerId"] && $result["firstName"]) {
	            	    		$session->set_session($result["organizerId"], $result["firstName"]);
	            	    	return $result;

	            	    } else {
	            	    		$session->set_session(null, null);
	            	   		return null;
	            	    }

		        	} catch (Exception $e) {
        				trigger_error($e->getMessage(), E_USER_ERROR);
        				return false;
        			}

    		 }

			public  function set_event($value){
				$this->set_event_count($this->get_event_count() + 1 );
				$this->EVENTS[$this->get_event_count()] = $value;
				return $this->get_event_count();
			}

			public static function get_organizer($id){

				try {

				$connection = new DB_CONNECTION();

				 $sql = "CALL getOrganizer(".$id.") ";

              			$statement = $connection->prepare_query( $sql );
                		$statement->execute();

							if($statement->rowCount() == 1 ) {
								$result = $statement->fetch();

				    		$organizer = new Organizer();
				    		$organizer->set_id($result["organizerId"]);
				    		$organizer->set_first_name($result["firstName"]);
				    		$organizer->set_last_name($result["lastName"]);
				    		$organizer->set_bio($result["aboutOrganizer"]);
				    		$organizer->set_organization_id($result["organizationId"]);
				    		$organizer->set_email($result["email"]);
				    		$organizer->set_picture($result["organizerImage"]);
				    		$organizer->set_birthdate($result["birthdate"]);
				    		$organizer->set_gender($result["gender"]);
				    		$organizer->set_title($result["title"]);


				    		return $organizer;

				    	} else {
				    		return null;
				    	}

			    	 } catch (Exception $e) {
        				trigger_error($e->getMessage(), E_ERROR);
        				return false;
        			}

			}

			public static function sign_up($fname, $lname, $mail, $password, $session){


							$success = false;
								$newOrganizer["firstName"] = $fname;
								$newOrganizer["lastName"] = $lname;
								$newOrganizer["email"] = $mail;
								$newOrganizer["password"] = $password;

							$result = null;

							$newOrganizer = json_encode($newOrganizer) ;

						try {


							$sql = "CALL createAccount(". json_encode($newOrganizer).") ";
						 	$connection = new DB_CONNECTION();
						 	$statement = $connection->prepare_query($sql);

			 			 	$statement->execute();
			 			 	if($row = $statement->fetch()) {
         				 		$session->set_session($row['organizerId'],ucfirst($fname));
         				 		$success = $row;
			 			 	} else {
			 			 		$session->set_session(null, null);
			 			 		$success = null;
			 			 	}

			          } catch (Exception $e) {
			          	trigger_error($e->getMessage(), E_ERROR);
						$success = false;

					}


					return $success;
			}



			public function add_event(Event $new_event){

					$last_index = $this->set_event_count($this->get_event_count() + 1);
					$this->EVENTS[$last_index] = $new_event;

					$error = 0;

					$this->EVENTS[$this->get_event_count()] = $new_event;
					$i = 1;
					if((! $event["eventName"] = $this->get_event($last_index)->get_name() ) &&  $error = 1 )
						trigger_error("Event Name is not Specified ", E_USER_ERROR);

					if((!$event["aboutEvent"] = $this->get_event($last_index)->get_discription() ) && $error = 1 )
						trigger_error("REQUIRED, Event (Discription) is not specified!!!", E_USER_ERROR);
					if((! $event["eventCategory"] =  1 ) && $error = 1 )
						trigger_error("REQUIRED, Event (Category) is not specified!!!", E_USER_ERROR);
					if((! $event["startTime"] = $this->get_event($last_index)->get_start_time() ) && $error = 1 )
						trigger_error("REQUIRED, Event (Starting Date) is not specified!!!", E_USER_ERROR);
					if((! $event["startDate"] = $this->get_event($last_index)->get_start_date()) && $error = 1 )
						trigger_error("REQUIRED, Event (Starting Time) is not specified!!!", E_USER_ERROR);
					if((! $event["endTime"] = $this->get_event($last_index)->get_end_time() ) && $error = 1 )
						trigger_error("REQUIRED, Event (Ending time) is not specified!!!", E_USER_ERROR);
					if((! $event["endDate"] = $this->get_event($last_index)->get_end_date() ) && $error = 1 )
						trigger_error("REQUIRED, Event (Ending Date) is not specified!!!", E_USER_ERROR);
					if((! $event["eventStatus"] = $this->get_event($last_index)->get_status() ) && $error = 1 )
						trigger_error("REQUIRED, Event (Status) is not specified!!!", E_USER_ERROR);
					if(!$this->get_event($last_index)->get_picture() ){
						trigger_error("Event doesnt have a Poster ", E_USER_WARNING);
					}	else {
						$event["eventImage"] = $this->get_event($last_index)->get_picture();
					}
					if((! $event["city"] = $this->get_event($last_index)->get_address(1)->get_city() ) && $error = 1 )
						trigger_error("REQUIRED, Event (City) is not specified!!!", E_USER_ERROR);
					if((!$event["subCity"] = $this->get_event($last_index)->get_address(1)->get_sub_city() ) && $error = 1 )
							trigger_error("REQUIRED, Event (Sub-City) is not specified!!!", E_USER_ERROR);

					if((!$event["country"] = $this->get_event($last_index)->get_address(1)->get_country()) && $error = 1 )
							trigger_error("REQUIRED, Event (Country) is not specified!!!", E_USER_ERROR);
					if((!$event["location"] = $this->get_event($last_index)->get_address(1)->get_location()) && $error = 1 )
							trigger_error("REQUIRED, Event (location) is not specified!!!", E_USER_ERROR);
					if((!$event["venue"] = $this->get_event($last_index)->get_venue()) && $error = 1 )
						trigger_error("REQUIRED, Event (Venue) is not specified!!!", E_USER_ERROR);


					if(!$event["longitude"] = $this->get_event($last_index)->get_address(1)->get_longitude() &&
						!$event["latitude"] = $this->get_event($last_index)->get_address(1)->get_latitude()
					  )
						trigger_error("event longitude and latitude coordinates are not set required to show location of event on a map", E_USER_WARNING);



					$ticket = null;
					$count = 0;
					if($this->get_event($last_index)->get_ticket_count() > 0 ) {

						while($count < $this->get_event($last_index)->get_ticket_count()) {

								if((!$ticket[$count]["ticketName"] = $this->get_event($last_index)->get_ticket($count + 1)->get_name()) && $error = 1 )
										trigger_error("REQUIRED value Ticket (Name) Missing !!!", E_USER_ERROR);
								if((!$ticket[$count]["ticketType"] = $this->get_event($last_index)->get_ticket($count + 1)->get_type()) && $error = 1 )
										trigger_error("REQUIRED value Ticket (Type) Missing !!!", E_USER_ERROR);
								if((!$ticket[$count]["aboutTicket"] = $this->get_event($last_index)->get_ticket($count + 1)->get_discription()) && $error = 1 )
										trigger_error("REQUIRED value Ticket (Discription) Missing !!!", E_USER_ERROR);
								if((is_null($ticket[$count]["ticketPrice"] =  $this->get_event($last_index)->get_ticket($count + 1)->get_price())) && $error = 1 )
										trigger_error("REQUIRED value Ticket (Price) Missing !!!", E_USER_ERROR);
								if((!$ticket[$count]["quantity"] = $this->get_event($last_index)->get_ticket($count + 1)->get_quantity()) && $error = 1 )
										trigger_error("REQUIRED value Ticket (Quantity) Missing !!!", E_USER_ERROR);
								if((!$ticket[$count]["saleStart"] = $this->get_event($last_index)->get_ticket($count + 1)->get_sale_start()) && $error = 1 )
										trigger_error("REQUIRED value Ticket (Sale Starting Date ) Missing !!!", E_USER_ERROR);
								if((!$ticket[$count]["saleEnd"] = $this->get_event($last_index)->get_ticket($count + 1)->get_sale_end()) && $error = 1 )
										trigger_error("REQUIRED value Ticket (Sale Ending Date) Missing !!!", E_USER_ERROR);
							$count++;

						}

						$event["tickets"] = $ticket;
					} else {
						$error = 1;
						trigger_error("No Ticket Created!!!, Event created Should have atleast One ticket type Associated with it!!!", E_USER_ERROR);
					}



						$guest = null;
					$count = 0;

					if($this->get_event($last_index)->get_guest_count() > 0) {

							while($count < $this->get_event($last_index)->get_guest_count()) {

								if((!$guest[$count]["firstName"] = $this->get_event($last_index)->get_guest($count + 1)->get_first_name()) && $error = 1 )
									trigger_error("REQUIRED value Event Special Guest (First Name) Missing !!!", E_USER_ERROR);
								if((!$guest[$count]["lastName"] = $this->get_event($last_index)->get_guest($count + 1)->get_last_name()) && $error = 1 )
									trigger_error("REQUIRED value Event Special Guest (Last Name) Missing !!!", E_USER_ERROR);
								if(!$guest[$count]["akaName"] = $this->get_event($last_index)->get_guest($count + 1)->get_aka_name())
									trigger_error("Notice: No nick name saved for Guest -- ". $this->get_event($last_index)->get_guest($count + 1)->get_first_name(), E_USER_NOTICE);
								if(!$guest[$count]["aboutGuest"] = $this->get_event($last_index)->get_guest($count + 1)->get_bio())
									trigger_error("Notice: Discription Missing for Guest -- ". $this->get_event($last_index)->get_guest($count + 1)->get_first_name(), E_USER_NOTICE);
								if(!$guest[$count]["title"] = $this->get_event($last_index)->get_guest($count + 1)->get_title())
									trigger_error("Notice: (Title) Missing for Guest -- ". $this->get_event($last_index)->get_guest($count + 1)->get_first_name(), E_USER_NOTICE);
								if(!$guest[$count]["guestImage"] = $this->get_event($last_index)->get_guest($count + 1)->get_image())
									trigger_error("(Image) Missing for Guest -- ". $this->get_event($last_index)->get_guest($count + 1)->get_first_name(), E_USER_WARNING);


								$count++;
							}

						$event["guests"] = $guest;

					}


					$sponsor = null;
					$count = 0;

					if($this->get_event($last_index)->get_sponsor_count() > 0 ) {

						while($count < $this->get_event($last_index)->get_sponsor_count()) {

							if((!$sponsor[$count]["sponsorName"] = $this->get_event($last_index)->get_sponsor($count + 1)->get_name()) && $error = 1 )
								trigger_error("REQUIRED value Sponsor (Name) Missing for Sponsor -- ". $this->get_event($last_index)->get_sponsor($count + 1)->get_name(), E_USER_ERROR);

							if(!$sponsor[$count]["sponsorImage"] = $this->get_event($last_index)->get_sponsor($count + 1)->get_image())
								trigger_error("Sponsor (Image) Not specified for Sponsor -- ". $this->get_event($last_index)->get_sponsor($count + 1)->get_name(), E_USER_WARNING);
							if(!$sponsor[$count]["aboutSponsor"] = $this->get_event($last_index)->get_sponsor($count + 1)->get_bio())
								trigger_error("Sponsor (Discription) Not specified for Sponsor -- ". $this->get_event($last_index)->get_sponsor($count + 1)->get_name(), E_USER_WARNING);
							$count++;

						}
				$event["sponsors"] = $sponsor;

					}


			$event = json_encode($event);

			if($error == 0 ) {

				try {

						$id = self::get_id();
						$sql = 'CALL addEvent( '.self::get_id().','. json_encode($event).')';

						$statement = $this->DB_Driver->prepare_query($sql);
						$statement->execute();

					$result = $statement->fetch();

					$this->EVENTS[$this->get_event_count()]->set_id($result["eventId"]);

				} catch (Exception $e) {
					$error = 1;
					trigger_error($e->getMessage(), E_USER_ERROR);

				}
			}

			return ($error == 0) ? true : false;

		}

			public function has_billing_address() {
				$connection = new DB_CONNECTION();

				$sql = "SELECT * ";
				$sql .= "FROM `billing_address` ";
				$sql .= " WHERE `ORGANIZATION_ID` = :id ";

				$placeholder = array(':id' => self::get_organization_id() );

				$statement = $connection->prepare_query($sql);
				$statement->execute($placeholder);

						if($statement->rowCount() >= 1 ) {
							return true;
						} else {
							return false;
						}
			}


			public function update_event(Event $updated_event){

					$eventIndex = self::set_event($updated_event);
					$error = 0;

					if(!$event["eventId"] = $this->get_event($eventIndex)->get_id() && $error = 1 )
						trigger_error("REQUIRED event Id name not specified", E_USER_ERROR);

					if(!$event["eventName"] = $this->get_event($eventIndex)->get_name())
						trigger_error("Event name not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["aboutEvent"] = $this->get_event($eventIndex)->get_discription())
						trigger_error("Event discription not specified, the default value will be the one set before ", E_USER_WARNING);

					if(!$event["eventCategory"] =  1)
						trigger_error("Event category not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["startTime"] = $this->get_event($eventIndex)->get_start_time())
						trigger_error("Event start time not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["startDate"] = $this->get_event($eventIndex)->get_start_date())
						trigger_error("Event start date not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["endTime"] = $this->get_event($eventIndex)->get_end_time())
						trigger_error("Event end time not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["endDate"] = $this->get_event($eventIndex)->get_end_date())
						trigger_error("Event end date not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["eventImage"] = $this->get_event($eventIndex)->get_picture())
						trigger_error("Event Image not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["city"] = $this->get_event($eventIndex)->get_address(1)->get_city())
						trigger_error("Event City not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["subCity"] = $this->get_event($eventIndex)->get_address(1)->get_sub_city())
						trigger_error("Event Sub-city not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["country"] = $this->get_event($eventIndex)->get_address(1)->get_country())
						trigger_error("Event Country not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["location"] = $this->get_event($eventIndex)->get_address(1)->get_location())
						trigger_error("Event location not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["venue"] = $this->get_event($eventIndex)->get_venue())
						trigger_error("Event Venue not specified, the default value will be the one set before ", E_USER_WARNING);


					$ticket = null;
					$count = 0;
						while($count < $this->get_event($eventIndex)->get_ticket_count()) {

							if(!$ticket[$count]["ticketId"] = $this->get_event($eventIndex)->get_ticket($count + 1)->get_id() && $error = 1 )
								trigger_error("REQUIRED, Ticket ID not specified, the default value will be the one set before ", E_USER_ERROR);
							if(!$ticket[$count]["ticketName"] = $this->get_event($eventIndex)->get_ticket($count + 1)->get_name())
								trigger_error("Ticket name not specified, the default value will be the one set before ", E_USER_WARNING);
							if(!$ticket[$count]["ticketType"] = $this->get_event($eventIndex)->get_ticket($count + 1)->get_type())
								trigger_error("Ticket Type not specified, the default value will be the one set before ", E_USER_WARNING);
							if(!$ticket[$count]["aboutTicket"] = $this->get_event($eventIndex)->get_ticket($count + 1)->get_discription())
								trigger_error("Ticket Discription not specified, the default value will be the one set before ", E_USER_WARNING);
							if(!$ticket[$count]["ticketPrice"] = $this->get_event($eventIndex)->get_ticket($count + 1)->get_price())
								trigger_error("Ticket Price not specified, the default value will be the one set before ", E_USER_WARNING);
							if(!$ticket[$count]["quantity"] = $this->get_event($eventIndex)->get_ticket($count + 1)->get_quantity())
								trigger_error("Ticket Price not specified, the default value will be the one set before ", E_USER_WARNING);
							if(!$ticket[$count]["saleStart"] = $this->get_event($eventIndex)->get_ticket($count + 1)->get_sale_start())
								trigger_error("Ticket Sale Start date not specified, the default value will be the one set before ", E_USER_WARNING);
							if(!$ticket[$count]["saleEnd"] = $this->get_event($eventIndex)->get_ticket($count + 1)->get_sale_end())
								trigger_error("Ticket Sale End date not specified, the default value will be the one set before ", E_USER_WARNING);

							$count++;

						}

						$event["tickets"] = $ticket;

						$guest = null;
					$count = 0;

						while($count < $this->get_event($eventIndex)->get_guest_count()) {

							if(!$guest[$count]["guestId"] = $this->get_event($eventIndex)->get_guest($count + 1)->get_id() && $error = 1 )
								trigger_error("REQUIRED, Event GUEST ID name not specified", E_USER_ERROR);
							if(!$guest[$count]["firstName"] = $this->get_event($eventIndex)->get_guest($count + 1)->get_first_name())
								trigger_error("Guest First Name not specified, the default value will be the one set before ", E_USER_WARNING);
							if(!$guest[$count]["lastName"] = $this->get_event($eventIndex)->get_guest($count + 1)->get_last_name())
								trigger_error("Guest Last Name not specified, the default value will be the one set before ", E_USER_WARNING);
							if(!$guest[$count]["akaName"] = $this->get_event($eventIndex)->get_guest($count + 1)->get_aka_name())
								trigger_error("Guest Stage Name not specified, the default value will be the one set before ", E_USER_WARNING);
							if(!$guest[$count]["aboutGuest"] = $this->get_event($eventIndex)->get_guest($count + 1)->get_bio())
								trigger_error("Guest Bio not specified, the default value will be the one set before ", E_USER_WARNING);
							if(!$guest[$count]["title"] = $this->get_event($eventIndex)->get_guest($count + 1)->get_title())
								trigger_error("Guest Title not specified, the default value will be the one set before ", E_USER_WARNING);
							if(!$guest[$count]["guestImage"] = $this->get_event($eventIndex)->get_guest($count + 1)->get_image())
									trigger_error("Guest Image not specified, the default value will be the one set before ", E_USER_WARNING);

							$count++;

						}

					$event["guests"] = $guest;
					$sponsor = null;
					$count = 0;

						while($count < $this->get_event($eventIndex)->get_sponsor_count()) {

								if(!$sponsor[$count]["sponsorId"] = $this->get_event($eventIndex)->get_sponsor($count + 1)->get_id() && $error = 1 )
									trigger_error("REQUIRED, Sponsor ID not specified ", E_USER_ERROR);
								if(!$sponsor[$count]["sponsorName"] = $this->get_event($eventIndex)->get_sponsor($count + 1)->get_name())
									trigger_error("Sponsor Name not specified, the default value will be the one set before ", E_USER_WARNING);
								if(!$sponsor[$count]["sponsorImage"] = $this->get_event($eventIndex)->get_sponsor($count + 1)->get_image())
									trigger_error("Sponsor Image not specified, the default value will be the one set before ", E_USER_WARNING);
								if(!$sponsor[$count]["aboutSponsor"] = $this->get_event($eventIndex)->get_ssonsor($count + 1)->get_bio())
									trigger_error("Sponsor Bio not specified, the default value will be the one set before ", E_USER_WARNING);

							$count++;

						}


						$event["sponsors"] = $sponsor;

						$event = json_encode($event);
						if($error != 0 ) {
							return false;
						} else {

								try {

									$sql = 'CALL updateEvent( '.self::get_id().','. json_encode($event).')';

									$statement = $this->DB_Driver->prepare_query($sql);

									$statement->execute();
									return true;

								}catch(Exception $e) {
									trigger_error($e->getMessage(), E_USER_ERROR);
									return false;
								}
						}


			}

			public function update_event_information(Event $updated_event) {

				$eventIndex = $this->set_event($updated_event);
				$error = 0;
				$event = null;
					if((!$event["eventId"] = $this->get_event($eventIndex)->get_id()) && $error = 1 )
						trigger_error("REQUIRED event Id name not specified", E_USER_ERROR);

					if(!$event["eventName"] = $this->get_event($eventIndex)->get_name())
						trigger_error("Event name not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["aboutEvent"] = $this->get_event($eventIndex)->get_discription())
						trigger_error("Event discription not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["eventCategory"] =  1)
						trigger_error("Event category not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["startTime"] = $this->get_event($eventIndex)->get_start_time())
						trigger_error("Event start time not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["startDate"] = $this->get_event($eventIndex)->get_start_date())
						trigger_error("Event start date not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["endTime"] = $this->get_event($eventIndex)->get_end_time())
						trigger_error("Event end time not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["endDate"] = $this->get_event($eventIndex)->get_end_date())
						trigger_error("Event end date not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["eventImage"] = $this->get_event($eventIndex)->get_picture())
						trigger_error("Event Image not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["city"] = $this->get_event($eventIndex)->get_address(1)->get_city())
						trigger_error("Event City not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["subCity"] = $this->get_event($eventIndex)->get_address(1)->get_sub_city())
						trigger_error("Event Sub-city not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["country"] = $this->get_event($eventIndex)->get_address(1)->get_country())
						trigger_error("Event Country not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["location"] = $this->get_event($eventIndex)->get_address(1)->get_location())
						trigger_error("Event location not specified, the default value will be the one set before ", E_USER_WARNING);
					if(!$event["venue"] = $this->get_event($eventIndex)->get_venue())
						trigger_error("Event Venue not specified, the default value will be the one set before ", E_USER_WARNING);

					if($error == 0) {
						try {
							$event = json_encode($event);

							$sql = "CALL updateEventInfo(".$this->get_id().", ".json_encode($event).")";
							$statement = $this->DB_Driver->prepare_query($sql);
							$statement->execute();

						} catch(Exception $e ) {
							$error = 1;
							trigger_error($e->getMessage(), E_USER_ERROR);
						}
					}

					return ($error == 0) ? true : false;


			}


			public function delete_event(Event $event){
				$error = 0;
					if(!$event->get_id() && $error = 1 )
						trigger_error("REQUIRED, Event ID Not Set", E_USER_ERROR);

					if($error != 0 ) {
							return false;

					} else {
								try {

									$sql = "CALL deleteEvent(".self::get_id().", ".$event->get_id().")";
									$statement = $this->DB_Driver->prepare_query($sql);
									$statement->execute();

								return true;

								} catch (Exception $e) {
									trigger_error($e->getMessage(), E_USER_ERROR);
									return false;
								}
					}

			}




			public function set_id($new_id) {
				return (VALIDATOR::validate_integer($new_id) > 0 )? $this->ORGANIZER_ID = VALIDATOR::validate_integer($new_id) : trigger_error("INVALID organizer ID Value or trying to change an exsisting organizer id value. valid id value should be a positive integer", E_USER_ERROR);
			}



			public function set_event_status($bool) {
				$validated = VALIDATOR::is_valid_event_status($bool);
				return ($validated) ? $this->active = $validated : trigger_error("INVALID boolean value", E_USER_ERROR);

			}

			public function get_image_upload_location($image) {
				return $this->organizerPictureLocation.basename($image['name']);
			}

			public function set_picture($image) {
				if (VALIDATOR::validate_image($image)){
					if (VALIDATOR::validate_image_size($image, 5000000)){
						if(move_uploaded_file($image["tmp_name"], self::get_image_upload_location($image))) {
						return $this->picture = basename($image["name"]);
						} else {
							trigger_error(" Profile Picture Upload failed ", E_USER_ERROR );
						}
					} else {
						trigger_error("invalid Profile picture Image Size, image size should be less than or equal to 5 mb  ", E_USER_ERROR );
					}

				} else {
					trigger_error("Invalid Profile Picture", E_USER_ERROR);
				}

			}



			public function set_first_name($value) {
				 return ($this->first_name = ucfirst( VALIDATOR::validate_name($value)))? $this->first_name : trigger_error("INVALID organizer first name. valid name should only contain alphabetic characters", E_USER_ERROR);
			}

			public function set_last_name($value) {
			return ($this->last_name = ucfirst( VALIDATOR::validate_name($value))) ? $this->last_name : trigger_error("INVALID organizer last name. valid name should only contain alphabetic characters", E_USER_ERROR);
			}

			public function set_title($value) {
				 return ($this->title = ucfirst(VALIDATOR::validate_regExp($value, '/[a-zA-Z]+[.]?/'))) ? $this->title : trigger_error("INVALID title. valid title should only contain alphabetic characters and optional suffix . ", E_USER_ERROR);
			}

			public function set_gender($value) {
			return ($this->gender = ucfirst( VALIDATOR::validate_name($value))) ? $this->gender : trigger_error("INVALID gender. valid gender should only contain alphabetic characters ", E_USER_ERROR);
			}

			public function set_birthdate($value) {
				return ($this->birthdate = VALIDATOR::validate_date($value)) ? $this->birthdate : trigger_error("INVALID birthdate value. valid date should be in the format YYYY-MM-DD . ", E_USER_ERROR);
			}

			public function set_bio($value) {
				 return ($this->bio = ucfirst(VALIDATOR::validate_string($value))) ? $this->title : trigger_error("INVALID bio. valid bio should contain atleast one character ", E_USER_ERROR);
			}

			public function set_email($value) {
			 return ($this->e_mail = VALIDATOR::validate_email($value)) ? $this->e_mail : trigger_error("INVALID email address. valid email address should be in the  format something@emailprovider.domain ", E_USER_ERROR);
			}

			public function set_password($value) {
				 $this->password = password_encrypt($value);

			}
			public function set_position($value) {
			return ($this->position = ucfirst(VALIDATOR::validate_regExp($value, '/^[a-zA-Z ]+$/'))) ? $this->position : trigger_error("INVALID organizer position value . valid position value should only contain alphabetic characters and optionaly space separated ", E_USER_ERROR);
		}

			public function get_position() {
				return $this->position;
			}

			public function get_id() {
				 return $this->ORGANIZER_ID;
			}

			public function get_first_name() {
				 return $this->first_name;
			}

			public function get_last_name() {
				 return $this->last_name;
			}

			public function get_gender() {
				 return $this->gender;
			}

			public function get_title() {
				 return $this->title;
			}

			public function get_picture() {
				 return $this->picture;
			}
			public function get_birthdate() {
				 return $this->birthdate;
			}

			public function get_bio() {
				 return $this->bio;
			}

			public function get_email() {
				 return $this->e_mail;
			}
			public function get_password() {
				 return $this->password;
			}

			public function get_registration_date() {
				 return $this->registered_on;
			}

			public function update_event_schedule(Event $event) {
				$eventIndex = $this->set_event($event);
				$error = 0;
				$schedule = null;
				if((! $schedule['startDate'] = $this->get_event($eventIndex)->get_start_date()) && $error = 1 )
					trigger_error("REQUIRED Event (Start date) can not be null", E_USER_ERROR);
				if((! $schedule['startTime'] = $this->get_event($eventIndex)->get_start_time()) && $error = 1 )
					trigger_error("REQUIRED Event (Start time) can not be null", E_USER_ERROR);
				if((! $schedule['endDate'] = $this->get_event($eventIndex)->get_end_date()) && $error = 1 )
					trigger_error("REQUIRED Event (End date) can not be null", E_USER_ERROR);
				if((! $schedule['endTime'] =  $this->get_event($eventIndex)->get_end_time()) && $error = 1 )
					trigger_error("REQUIRED Event (End Time) can not be null", E_USER_ERROR);


					if($error = 0) {
						try {
							$sql = 'CALL updateEventTime('.$this->get_id().', '.json_encode($schedule).')';
							$statement = $this->DB_Driver->prepare_query($sql);
							$statement->execute();

						} catch(Exception $e) {
							$error = 1;
							trigger_error($e->getMessage(), E_USER_ERROR);

						}
					}

				return ($error == 0) ? true : false;


			}

			public function change_password($current_password, $new_password){

				if(password_check($current_password , self::get_password() )  ) {
					self::set_password($new_password);

						$sql = "CALL changeAccountPassword(".self::get_id().",".self::get_password().")	";


						$statement = $this->DB_Driver->prepare_query($sql);
						$statement->execute();

								if($statement->rowCount() == 1 ){
									return true;
								} else {
									return false;
								}

		        		}else{
		        			   return null;
		        		}
			}


			public function update_picture($img) {
					self::set_picture($img);


						  $sql = " CALL updateOrganizerPicture(".self::get_id()."".self::get_picture().") ";


						$statement = $this->DB_Driver->prepare_query($sql);
					  	$statement->execute();

					  	if($statement->rowCount() == 1){
					  		return true;
					  	} else {
					  		return false;
					  	}

			}


			public function change_email($new_mail) {
					$error = 0;

					self::set_email($new_mail);
						if($error == 0) {

							try {

								 $sql = "CALL updateOrganizerEmail (".$this->get_id().", '". $this->get_email()."')";

								  $statement = $this->DB_Driver->prepare_query($sql);
								  $statement->execute();
							} catch (Exception $e) {
								$error= 1;
								trigger_error($e->getMessage(), E_USER_ERROR);

							}
						}

							return ($error == 0) ? true : false;

			}


			public function update_profile() {
				$profile = null;
				$error = 0;

					if((!$profile["firstName"] = self::get_first_name()) && $error = 1)
						trigger_error("Organizer (first name) Can not Be empty", E_USER_ERROR);
					if((!$profile["lastName"] = self::get_last_name()) && $error = 1)
						trigger_error("Organizer (last name) Can not Be empty", E_USER_ERROR);
					if(!$profile["aboutOrganizer"] = self::get_bio())
						trigger_error("Organizer (Bio) empty, previous value will be deleted if it exists", E_USER_NOTICE);

					if(!$profile["gender"] = self::get_gender())
						trigger_error("Organizer (Gender) empty, previous value will be deleted if it exists", E_USER_NOTICE);
					if(!$profile["birthdate"] = self::get_birthdate())
						trigger_error("Organizer (Birthdate) empty, previous value will be deleted if it exists", E_USER_NOTICE);
					if(!$profile["organizerPosition"] = self::get_position())
						trigger_error("Organizer (Position) empty, previous value will be deleted if it exists", E_USER_NOTICE);
					if(!$profile["title"] = self::get_title())
						trigger_error("Organizer (Title) empty, previous value will be deleted if it exists", E_USER_NOTICE);
					if(!$profile["organizerImage"] = self::get_picture())
						trigger_error("Organizer (Profile) empty, previous value will be deleted if it exists", E_USER_NOTICE);

					if($error == 0) {
						try {
								$profile = json_encode($profile);
								$sql = "CALL updateOrganizerProfile(".self::get_id().",".json_encode($profile).")";
								$statement = $this->DB_Driver->prepare_query($sql);
								 $statement->execute();
							} catch (Exception $e) {
								$error = 1;
								trigger_error($e->getMessage(), E_USER_ERROR);

							}
					}


				  return ($error == 0) ? true : false;


			}

			public function remove(){


			}


			public function update_organization(){

			  $error = 0;

			  if((!$this->get_id()) && $error = 1 )
			  	trigger_error("REQUIRED, Organizer Id not Profivded!! ", E_USER_ERROR);
			  if((!$this->get_organization_id()) && $error = 1 )
			  	trigger_error("REQUIRED, Organization Id not Profivded!! ", E_USER_ERROR);


			  							$profile['organizationName'] = $this->get_organization_name();
			  							$profile['officeNumber'] = [$this->get_office_number()];
			  							$profile['mobileNumber'] = [$this->get_mobile_number()];
			  							$profile['aboutOrganization'] = $this->get_bio();
			  							$profile['postNumber'] = $this->get_po_num();
			  							$profile['website'] = $this->get_website();
			  							$profile['organizationLogo'] = $this->get_organization_logo();

			  							$profile = json_encode($profile);


			  if($error == 0) {
			  	try {

			  		$sql = "CALL updateOrganizationProfile(".$this->get_id().", ".$this->get_organization_id().",".json_encode($profile).")";
						$statement = $this->DB_Driver->prepare_query($sql);
			  	  		$statement->execute();

			  	} catch (Exception $e) {
			  		$error = 1;
			  		trigger_error($e->getMessage(), E_USER_ERROR);
			  	}

			  }

			  return ($error == 0) ? true : false;
		}


			function close_organization(Organizer $updated_organizer) {

				 		$sql = "CALL closeAccount(".self::get_id()."".self::get_password().") ";


							$statement = $this->DB_driver->prepare_query($sql);
							$statement->execute();

				return ($statement->rowCount() == 1 ) ? true : false ;

			}







  	}


?>
