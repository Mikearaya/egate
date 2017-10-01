<?php



	include('classes.php');
	include('session.php');

	$SESSION = new SESSION();

		$connection  = new DB_CONNECTION();

		$result = new stdclass();

$allowed = array('png', 'jpg', 'gif','zip');



	$submitted_form  = '';
if(isset($_POST['form'])) {

	$submitted_form =	$_POST['form'];

}



      		
      	

      if($submitted_form === 'contact_organizer') {

      			$organizer = $connection->fetch_organizer(165);

      			$fname = $_POST['contact-org-firstname'];
      			$lname = $_POST['contact-org-lastname'];
      			$email = $_POST['contact-org-email'];
      			$mail = $_POST['contact-org-message'];
      			$subject = $_POST['contact-org-subject'];


      			$sender = new Viewer();

      			$sender->set_first_name($fname);
      			$sender->set_last_name($lname);
      			$sender->set_mail_address($email);
      			$sender->set_mail($mail);
      			$sender->set_subject($subject);

      			$sender->send_mail($organizer);

      			echo "<h1> success </h1>"; 
      }





      if(isset($_POST['get_ticket'])) {
      		$event_id =  $_POST['get_ticket'];
      			$ticket['ticket'] = $connection->get_event_ticket($event_id);

      			echo json_encode($ticket);
      }


      if($submitted_form === 'order_form') {


      			
      			$fname = $_POST['att-first-name'];
      			$lname = $_POST['att-last-name'];
      			$subscriber= $_POST['att-subscription'];
      			$phone = $_POST['att-telephone'];
      			$attendee = new Attendee(150, $fname, $lname, $phone, $subscriber);

      			
      	$i = 0;	$result->message = '';
      			while($i < count($_POST['ticket-id'])) {
      				$ticket = $connection->get_ticket_by_id($_POST['ticket-id'][$i]);
      				$event = $ticket->EVNT_ID;
      				$quantity = $_POST['orderQuantity'][$i];
      				$booking = new Booking($ticket, $quantity);

      					$result->message += $attendee->add_booking($booking);
      					$i++;
      			}
      		
      		var_dump( $result->message);

      }


      	


?>