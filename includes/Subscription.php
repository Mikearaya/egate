<?php
//include('DB_CONNECTION.php');


class Subscriber {
			

		private $email;
		private $SUBSCRIBER_ID;
		private $subscription = array();
		private $total_subscription;
		private $DB_Driver;

				function __construct($mail = null)	{
					
					if($mail != null ) {
				
						$this->DB_Driver = new DB_CONNECTION();

						
						self::set_mail($mail); 
						
							

						
						$sql = "INSERT INTO `subscribers` ( ";
						$sql .= " `email`, `subscribed_on` ";
						$sql .= " ) VALUES( :email , NOW() )";
						$placeholder = array(':email' => self::get_mail() );
									


								 $statement =	$this->DB_Driver->prepare_query($sql);

								


									$statement->execute($placeholder);
									

									if($statement->rowCount() == 1 ){
										$new_id =  $this->DB_Driver->get_last_inserted_id();

										self::set_id($new_id);
										return true;
									}	else {
										return null;
									}
				}

			}

			public static function get_subscriber($id) {
				$connection = new DB_CONNECTION();
				$sql = "SELECT * ";
				$sql .= "FROM `subscribers` ";
				$sql .= "WHERE `SUBSCRIBER_ID` = :id ";

				$placeholder = array(':id' => $id );
				$statement = $connection->prepare_query($sql);

				$statement->execute($placeholder);

						if($statement->rowCount() == 1){
							return	$statement->fetchObject('Subscriber');
						} else {
							return null;
						}

			}


			public static function get_subscriber_by_email($id) {
				$connection = new DB_CONNECTION();
				$sql = "SELECT * ";
				$sql .= "FROM `subscribers` ";
				$sql .= "WHERE `email` = :email ";

				$placeholder = array(':email' => $id );
				$statement = $connection->prepare_query($sql);

				$statement->execute($placeholder);

						if($statement->rowCount() == 1){
							return	$statement->fetchObject('Subscriber');
						} else {
							return null;
						}

			}

			public function get_total_subscriptions(){
				return $this->total_subscription;
			}

			public function set_total_subscription($value){
				 $this->total_subscription = $value;
			}

			public function get_id(){
				return (isset($this->SUBSCRIBER_ID )) ? $this->SUBSCRIBER_ID : false;
			}
			
			public function set_id($value){
				return (!isset($this->SUBSCRIBER_ID) ) ? $this->SUBSCRIBER_ID = $value : false;
			}

			public function set_subscription($value) {
					return (isset($value)) ? $this->subscription = $value : false;
			}

			public function get_subscriptions() {
				return $this->subscription;
			}
			public function set_mail($value) {
				 $this->email = $value;
			}
			public function get_mail() {
				return $this->email;
			}

			
}

		
class Subscription implements Subscription_Model {
		
		private $subscriptions = array();
		private $subscriber_count;
		private $DB_Driver;
			
				function __construct()	{	
						
					$this->set_subscriber_count(0);
					$this->DB_Driver = new DB_CONNECTION();
						
				}

			public function set_subscriber_count($new_count) {
					$this->subscriber_count = $new_count;
			}
				
			public function get_subscriber_count() {
				return $this->subscriber_count;
			}

			public function get_subscription($index){
				return $this->subscriptions[$index];
			}

			public function add_subscription(Subscriber $subscriber, $subscription) {

					$this->set_subscriber_count($this->get_subscriber_count() + 1 );
					$this->subscriptions[$this->get_subscriber_count()] = $subscriber;
													
									 
					 	$sql = "INSERT INTO `subscriptions` ( ";
						$sql .= " `SUBSCRIBER_ID`, `content` ";
						$sql .= " ) VALUES ";


						unset($placeholder);
						$insertData = '';
						$x = 0;
						

							while ($x < count($subscription)) {
			 				   $placeholder[] = '(? , ?)';
			    				$insertData[] = $subscriber->get_id();
			    				$insertData[] = $subscription[$x];
			    					
			    					$x++;
			    			}

	    			
				    			if (!empty($placeholder)) {
				    				$sql .= implode(', ', $placeholder);
				    				
				    				$statement =	$this->DB_Driver->prepare_query($sql);
				    				$statement->execute($insertData);
								}
									
									
								

							if($statement->rowCount() === count($subscription)){
								return true;
							} else {
								return false;
							}
								
								 
			
			}

		

			public function remove_subscription(Subscriber $subscriber) {
					
					$counter = 0;

					while(++$counter <= $this->get_subscriber_count() ) {

							if($this->subscriptions[$counter] == $subscriber ){

									for($x = $counter ; $x < $this->get_subscriber_count() ; $x++ ) {
										$this->subscriptions[$x] = $this->subscriptions[$x + 1];
									}

								$this->set_subscriber_count($this->get_subscriber_count() - 1 );

								echo $this->get_subscriber_count();
							}
					}


					$sql = "DELETE FROM `subscriptions` ";
					$sql .= "WHERE `SUBSCRIBER_ID` = :id ";

					$placeholder = array(':id' => $subscriber->get_id() );

					$statement = $this->DB_Driver->prepare_query($sql);

					$statement->execute($placeholder);


					if($statement->rowCount() >= 1 ){
						return true;
					} else {
						return false;
					}


				}
				
					
			public function update_subscription(Subscriber $subscriber, $new_subscription) {
					
					$counter = 0;

						while(++$counter <= $this->get_subscriber_count()){
							if(
								$this->subscriptions[$counter]->get_subscriber_id() 
								== 
								$new_subscription->get_subscriber_id() ) {
								$this->subscriptions[$counter] = $new_subscription;
								

							}
						}


						self::remove_subscription($subscriber);
						self::add_subscription($subscriber, $new_subscription );


			}
			
}



?>