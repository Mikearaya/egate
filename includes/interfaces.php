<?php
interface Event_interface {

		function add_event(Event $event);
		function update_event(Event $event);
		function delete_event(Event $event);
		function add_event_sponsor(Event $sponsor);
		function update_event_sponsor(Event $sponsor);
		function delete_event_sponsor(Event $sponsor);
		function add_event_guest(Event $guest);
		function update_event_guest(Event $guest);
		function delete_event_guest(Event $event);
		function add_event_ticket(Event $ticket);
		function update_event_ticket(Event $ticket);
		function delete_event_ticket(Event $ticket);
		
		function set_event_count($new_count);
		function get_event_count();
		function get_event($index);	
		
}


interface Booking_Listener {
	function onBooked($quantity);
	function onBookingPaid($quantity);
	function onBookingCancel($quantity);
}


interface Location_interface {
			
			
			function set_address(Address $Address);
			function update_address();
			function get_address($index);
			
		
}

interface Guest_interface {
        
        function set_guest(Guest $guest);
      
      	function set_guest_count($newValue);
        function get_guest_count();
       	function get_guest($index);
                
           
  }


  interface Sponsor_interface {
        
        function set_sponsor(Sponsor $sponsor);
  
        function get_sponsor_count();
       	function get_sponsor($index);
        function set_sponsor_count($newValue);
   


}



interface Comment_interface {
        
        function add_comment(Comment $comment);
        function remove_comment(Comment $comment);
        function get_comment_count();
        function get_comment($index);
        function set_comment_count($newValue);

}


interface Subscription_Model {

		function add_subscription(Subscriber $subscriber, $subscription);
		function remove_subscription(Subscriber $subscriber);
		function get_subscriber_count();
		function set_subscriber_count($new_count);
		function get_subscription($index);
		function update_subscription(Subscriber $subscriber, $new_subscription);
			

}

interface Ticket_interface {
        
	        function set_ticket(Ticket $ticket);
	        function get_ticket_count();
	       	function get_ticket($index);
	        function set_ticket_count($newValue);

}

?>