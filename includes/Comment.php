<?php

//include('DB_CONNECTION.php');

   


class Comment {

			      
      	private $name;
     	private $content;
     	private $commented_on;
     	private $CMT_ID;
	      

			    function __construct($commenter, $comment) {   
			    	self::set_commenter($commenter);
			    	self::set_comment($comment);
			    }

			  
		    
	       	public function set_id($new_id) {
	       		return (!isset($this->CMT_ID)) ? $this->CMT_ID = $new_id : false;
	       	}

		    
		    public function set_commenter($value) {
	    		return ($this->name = VALIDATOR::validate_string($value)) ? $this->name : trigger_error("INVALID commenter name value. valid name should contain atleast one or more characters ", E_USER_ERROR);
		    		
		    }
			
			public function set_comment($value) {

		    		return ($this->content = VALIDATOR::validate_text($value)) ? $this->containt : trigger_error("INVALID commenter name value. valid name should contain atleast one or more characters ", E_USER_ERROR);
		    }  

		    public function get_commenter(){
		     	return $this->name;
		    }

		    public function get_time(){
		     	return $this->commented_on;
		    }

		    public function get_comment(){
		     	return  $this->content;
		    }

		    public function get_id(){
		      	return (isset($this->CMT_ID)) ? $this->CMT_ID : false;
		    }
 

}


?>