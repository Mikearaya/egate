<?php

class VALIDATOR {

	public static function password_check($password, $existing_hash){

		$hash = crypt($password, $existing_hash);

		if($hash === $existing_hash){
			return true;
		} else {
			
			 return false;
		}
	}

	public static function is_positive_int($value) {
 			$value = self::validate_integer($value) ;
 			if($value >= 0 ) {
 				return $value;
 			} else {
 				return false;
 			}
 	}

 

		public static function mail_exists($mail) {
		
			if(self::validate_email($mail)){
		$DB_driver = new DB_CONNECTION();

		$sql = "SELECT emailAddressUsed(".$email.")";
		$connection = new DB_CONNECTION();

		$statement = $connection->set_query($sql);
		$result = $statement->fetch();

	return ($result['result'] == '1' ) ? true : false;
	}else{
		trigger_error("invalid email format", E_USER_ERROR);
		return false;
	}

}


	public static function sanitize_string($input) {
		$sanitized = filter_var($input, FILTER_SANITIZE_STRING);
  		$sanitized = trim($sanitized);
  		$sanitized = stripslashes($sanitized);
  		$sanitized = htmlspecialchars($sanitized);
 	 return $sanitized;
	}

	public static function validate_name($input){
		
			$string = self::sanitize_string($input);
	if(filter_var($string, FILTER_VALIDATE_REGEXP, array("options"=>array("regexp"=>"/^[a-zA-Z]*$/")))) {
  			return  $string = ucfirst($string);
		} else {
			return false;
		}

	}

	public static function validate_string($input){
		
			$string = self::sanitize_string($input);
	if(filter_var($string, FILTER_VALIDATE_REGEXP, array("options"=>array("regexp"=>"/.+/")))) {
  			return  $string;
		} else {
			return false;
		}

	}

	public static function validate_regExp($input, $regex){
		
			$string = self::sanitize_string($input);
	if(filter_var($string, FILTER_VALIDATE_REGEXP, array("options"=>array("regexp"=>$regex )))) {
  			return  $string;
		} else {
			return false;
		}

	}


	public static function validate_float($input) {
		$sanitized = filter_var($input, FILTER_SANITIZE_NUMBER_FLOAT, FILTER_FLAG_ALLOW_FRACTION);
		
		return (filter_var($sanitized, FILTER_VALIDATE_FLOAT) >= 0) ?$sanitized : false;
	}


	public static function validate_int_range($input, $min, $max) {
		$sanitized = filter_var($input, FILTER_SANITIZE_NUMBER_INT);
		
		return (filter_var($sanitized, FILTER_VALIDATE_INT, array("options" => array("min_range"=>$min, "max_range"=>$max)) === false)) ? $sanitized : false;
	}

	public static function is_valid_event_status($input) {
		$sanitized = strtoupper( self::sanitize_string($input));
		if(filter_var($sanitized, FILTER_VALIDATE_REGEXP,array('options' => array("regexp" => "/^(DRAFT|OPEN|CLOSED|ACTIVE){1}$/") ))) {
			return $sanitized;
		}else {
			return false;
		}
	
	}

	public static function validate_date($value) {
		return $value;
	}

	public static function validate_time($value) {
		return $value;
	}
	public static function validate_text($input, $min = 144) {
		$sanitized = filter_var($input, FILTER_SANITIZE_MAGIC_QUOTES);
		$sanitized = filter_var($sanitized, FILTER_SANITIZE_SPECIAL_CHARS);

		return (filter_var($sanitized, FILTER_VALIDATE_REGEXP, array("options"=>array("regexp"=>"/[.]{".$min.",}/")))) ? $sanitized : false;

		 
	} 

	public static function validate_email($input){

		$input = filter_var($input, FILTER_SANITIZE_EMAIL);

		return (filter_var($input, FILTER_VALIDATE_EMAIL)) ? $input : false;
  		
	}

	public static function validate_url($input){

		 $input = filter_var($input, FILTER_SANITIZE_URL);
		
		if (filter_var($input,FILTER_VALIDATE_URL) ){
	  			return  $input;
		} else {
			return false;
		}
		
}

	public static function validate_image($input){
	// Check if image file is a actual image or fake image
	  		$check = getimagesize($input["tmp_name"]);
			    if($check !== false) {
			        return $input;
			        
			    } else {
			        return false;
			        
			    }
	
	}

	public static function image_exists($target_file){
		// Check if file already exists
	if (file_exists($target_file)) {
    	return $target_file;
  
		} else {
			return true;
		}
	}

	public static function validate_image_size($input, $size) {
		 // Check file size
		return ($input["size"] < $size) ? $input: false;
	}

	public static function image_format($input){
		// Allow certain file formats
		if($input != "jpg" || $input != "png" || $input != "jpeg"  ) {
    		return false;
		} else {
			return $input;
		}
	
	}

	public static function validate_integer($input){
		if (filter_var($input, FILTER_VALIDATE_INT) >= 0 ) {
 			   return $input;
		} else {
    		return  false;
		}
	}


		public static function validate_phone_number($input){
		$sanitized = filter_var($input, FILTER_SANITIZE_NUMBER_INT);
		
		if(filter_var($sanitized, FILTER_VALIDATE_REGEXP, array("options"=>array("regexp"=>"/^(([0-9][0-9]([0-9]9|[0-9]1)|(09|01)))?[0-9]{8}$/")))) {
	
 			   return $sanitized;
		} else {
    		return  false;
		}
	}

	public static function valid_ip($input){	
		if (filter_var($input, FILTER_VALIDATE_IP) === true) {
		    return true;
		} else {
		    return false;
		}
	}

	public function validate_boolean($value) {
		if(filter_var($value, FILTER_VALIDATE_BOOLEAN)) {
			return $value;
		} else {
			return false;
		}
	}


}
/*

if (filter_var($url, FILTER_VALIDATE_URL)) {
    echo("$url is a valid URL");
} else {
    echo("$url is not a valid URL");
}

var_dump(filter_var($var, FILTER_VALIDATE_BOOLEAN));

if (filter_var($email, FILTER_VALIDATE_EMAIL)) {
  echo("$email is a valid email address");
} else {
  echo("$email is not a valid email address");
}

$var = a;
var_dump(filter_var($var, FILTER_VALIDATE_FLOAT));

$int = 100.1;

if (filter_var($int, FILTER_VALIDATE_INT)) {
    echo("Variable is an integer");
} else {
    echo("Variable is not an integer");
}


$int = 122;
$min = 1;
$max = 200;



if (filter_var($int, FILTER_VALIDATE_INT, array("options" => array("min_range"=>$min, "max_range"=>$max))) === false) {
    echo("Variable value is not within the legal range");
} else {
    echo("Variable value is within the legal range");
}
$email = "john(.doe)@exa//mple.com";
if(
$email = filter_var($email, FILTER_SANITIZE_EMAIL)) {
   echo "sanitized email";
} else {
   echo 'error email';
}

if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
    echo("$ip is a valid IP address");
} else {
    echo("$ip is not a valid IP address");
}




$url="https://www.w3schoolsÅÅ.com";

$url = filter_var($url, FILTER_SANITIZE_ENCODED, FILTER_FLAG_STRIP_HIGH);
echo $url;

$var="Peter's here!";

var_dump(filter_var($var, FILTER_SANITIZE_MAGIC_QUOTES));

$number="5-2f+3.3pp";

var_dump(filter_var($number, FILTER_SANITIZE_NUMBER_FLOAT,
FILTER_FLAG_ALLOW_FRACTION));

$number="5-2+3pp";

var_dump(filter_var($number, FILTER_SANITIZE_NUMBER_INT));

$url="Is Peter <smart> & funny?";

var_dump(filter_var($url,FILTER_SANITIZE_SPECIAL_CHARS));

$str = "<h1>Hello World!</h1>";

$newstr = filter_var($str, FILTER_SANITIZE_STRING);
echo $newstr;

$var="https://www.w3schoo��ls.co�m";

var_dump(filter_var($var, FILTER_SANITIZE_URL));

function convertSpace($string)
  {
  return str_replace(" ", "_", $string);
  }

$string = "Peter is a great guy!";

echo filter_var($string, FILTER_CALLBACK,
array("options"=>"convertSpace"));


$string = "Match this string";

var_dump(filter_var($string, FILTER_VALIDATE_REGEXP,
array("options"=>array("regexp"=>"/^M(.*)/"))))


*/

?>