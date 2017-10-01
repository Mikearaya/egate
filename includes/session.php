<?php


	class SESSION {
    
    function __construct(){
    	session_start();
        

    }
    
    
    function is_loged_in() {

        if (isset($_SESSION["user_id"])) {
            return true;
        } else {
            return false;
        }
    }


    function set_session($user_id, $name ) {
        $_SESSION["user_id"] = $user_id;
        $_SESSION['name'] = $name;
    }

    function get_session_id(){
        return  isset($_SESSION["user_id"]) ? $_SESSION["user_id"] : null;
    }

    function get_session_name() {
        return isset($_SESSION['name']) ? $_SESSION['name'] : null;
    }
    function close_session() {
         session_destroy();
    }

    function reset_session(){
    	$_SESSION['user_id'] = null;
        $_SESSION['name'] = null;
    } 

 


	}

    

?>