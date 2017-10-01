  <?php


/*
echo $_SERVER['PHP_SELF'];
echo "<br>";
echo $_SERVER['SERVER_NAME'];
echo "<br>";
echo $_SERVER['HTTP_HOST'];
echo "<br>";
echo $_SERVER['SERVER_ADDR'];
echo "<br>";
//echo $_SERVER['HTTP_REFERER'];
echo "<br>";
echo $_SERVER['HTTP_USER_AGENT'];
echo "<br>";
echo $_SERVER['SCRIPT_NAME'];

  */

$ERROR_HANDLER = new ErrorHandle();
  
$errors = 0;
$message = '';

error_reporting(E_ALL);

class ErrorHandle {

   private $errorCount;
   private $warningCount;
   private $noticeCount;
   private $errorMessage = array();
   private $noticeMessage = array();
   private $warningMessage = array();

      
       function __construct() {
         $this->errorCount = 0;
          $this->warningCount = 0;
           $this->noticeCount = 0;
      }
   
   public function get_notice_count() {
      return $this->noticeCount;
   }

    public function get_error_count() {
      return $this->errorCount;
   }

    public function get_warning_count() {
      return $this->warningCount;
   }
   public function set_warning($message) {
      $this->warningMessage[$this->warningCount] = $message;
      $this->warningCount++;
   }

   public function set_error($message) {
         $this->errorMessage[$this->errorCount] = $message;
         $this->errorCount++;
   }

   public function set_notice($message) {
         $this->noticeMessage[$this->noticeCount] = $message;
         $this->noticeCount++;
   }

   public function get_all_notices() {
         return $this->noticeMessage;
  }


   public function get_all_warnings() {
      return $this->warningMessage;
   }

   public function get_all_errors() {
        return  $this->errorMessage;
    }

     public function get_warning($index) {
      return (self::get_warning_count() > $index ) ? $this->warningMessage[$index] : null;
   }

   public function get_error($index) {
       return (self::get_error_count() > $index ) ? $this->errorMessage[$index] : null;
         
   }

   public function get_notice($index) {
           return (self::get_notice_count() > $index ) ? $this->noticeMessage[$index] : null;
   }

}




   function errorhandler($errno, $errstr,$error_file,$error_line) {
      
         if($errno == 1024) {

            $GLOBALS['ERROR_HANDLER']->set_notice($errstr);
         } elseif ($errno == 512 ) {
            
            $GLOBALS['ERROR_HANDLER']->set_warning($errstr);
         }elseif ($errno == 256) {
             $GLOBALS['ERROR_HANDLER']->set_error($errstr);
         } else {

          $err = "error number[".$errno."]  error ".$errstr. "|  file ".$error_file. "|   line ".$error_line;
          error_log($err, 3, "C://Users/Mikael/Desktop/PRACTICE/Errorlog/error.txt");
        
         }
  
      
   }

   


   set_error_handler("errorhandler");

/*
class MyException extends Exception
{
    // Redefine the exception so message isn't optional
    public function __construct($message, $code = 0, Exception $previous = null) {
        // some code
    
        // make sure everything is assigned properly
        parent::__construct($message, $code, $previous);
    }

    // custom string representation of object
    public function __toString() {
        return  " {$this->message}\n";
    }

    public function customFunction() {
        echo "A custom function for this type of exception\n";
    }
}



 

    function exception_handler($exception) {
      echo json_encode( $exception->getMessage(), "\n");

   
   }  
   

   set_exception_handler('exception_handler');

*/
  
   //set error handler
   
//set error handler


//trigger error


   ?>