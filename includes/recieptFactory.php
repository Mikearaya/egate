<?php
require('FPDF/fpdf.php');

class RecieptFactory extends FPDF {

	private $DB_Driver;
	private $RECIEPT_ID;
	private $BOOKING_ID;
	private $reservation_code;
	private $event_name;
	private $event_venue;
	
	private $organization;
	private $start_date;
	private $start_time;
	private $end_date;
	private $end_time;
	private $ticket_id;
	private $EVNT_ID;
	private $country;
	private $city;
	private $sub_city;
	private $reciept_status;
	private $picture;
	
	private $ticket_name;
	private $ticket_type;
	private $ticket_price;
	private $first_name;
	private $last_name;

	public function get_reciept_id(){
			return $this->RECIEPT_ID;
	}

	function Header() {
		$this->SetFillColor(0,0,0);
	$this->SetTextColor(255,255,255);
    // Logo
    $this->Image('Egate.png',10,10,20);
    // Arial bold 15
    $this->SetFont('Arial','B',15);
    // Move to the right
    $this->Cell(22);
    // Title
    $this->Cell(null,20,'Egate.com 						 Addis Ababa, Ethiopia',1,1,'C', true);
    // Line break
    $this->Ln(15);
	}

// Page footer
function Footer() {
    // Position at 1.5 cm from bottom
    $this->SetY(-15);
    // Arial italic 8
    $this->SetFont('Arial','I',8);
    // Page number
    $this->Cell(0,10,'Page '.$this->PageNo().'/{nb}',0,0,'C');
}

		
		public function get_event_poster(){
				return $this->picture;
		}
		public  static function print_reciept($reservation_code){
	
				$reciept = self::get_reciept_detail($reservation_code);
				
				
					$pdf = new RecieptFactory();

					$pdf->AliasNbPages();
					$pdf->SetFillColor(141,201,233);
					$pdf->SetTextColor(42,42,42);
					$pdf->AddPage();
					$pdf->SetFont('Times','',12);

					$pdf->SetLineWidth(1);
						
						$y=30;

						for($i=0 ; $i < count($reciept) ; $i++) {
				   
				   if($reciept[$i]->get_event_poster() != null){
				       $pdf->Image('../uploads/eventImages/'.$reciept[$i]->get_event_poster().'', 10,$pdf->GetY(), 30 );
						 $pdf->Cell(25);
				   } else {
				   	   $pdf->Image('../img/placeholder.jpg', 10,$pdf->GetY(), 30 );
				   }

				$x = "RECIEPT ID :".$reciept[$i]->get_reciept_id()." \t  Booking Id : ".$reciept[$i]->get_booking_id()." ";
				$x .= "Reservation Code  :  ".$reciept[$i]->get_reservation_code()." \n ";
				$x .= "EVENT : ".$reciept[$i]->get_event_name()." \n";
				$x .= "Venu : ".$reciept[$i]->get_event_venue()." \n";
				$x .= "Addres : ".$reciept[$i]->get_event_location()." \n";                            
				$x .= "Event Start Date ".$reciept[$i]->get_start_date()." Time: ".$reciept[$i]->get_start_time()."\n";
				$x .= "Event End Date ".$reciept[$i]->get_end_date()." Time: ".$reciept[$i]->get_end_time()."\n";                            
				$x .= "Ticket name: ".$reciept[$i]->get_ticket_name()." Type ".$reciept[$i]->get_ticket_type()." \n";
				$x .= "Booked By: Mikael Araya  \n ";
				$x .= "Price: ".$reciept[$i]->get_ticket_price()." ETB \n";
				$x .= "Organizer: ".$reciept[$i]->get_organizer_name()." \n";

				    $pdf->MultiCell(null,5,$x, null,'L', true);
				    $y = $y + 45 ;
				    $pdf->Ln();
				}

				$pdf->Output();    

				

		}

			public function get_ticket_name(){
				return $this->ticket_name;
			}

			public function get_ticket_type(){
				return $this->ticket_type;
			}
	public function get_start_date(){
		return $this->start_date;
	}

	public function get_start_time(){
		return $this->start_time;
	}

	public function get_end_date(){
		return $this->end_date;
	}

	public function get_end_time(){
		return $this->end_time;
	}

	public function get_organization_name(){
		return $this->organization;
	}

	public function get_organizer_name() {
		return $this->first_name.' '.$this->last_name;
	}

	public function get_event_venue(){
		return $this->event_venue;
	}
	public function get_booking_id(){
		return $this->BOOKING_ID;
	}

	public function get_event_id(){
		return $this->EVNT_ID;
	}

	public function get_ticket_id(){
		return $this->ticket_id;
	}

	public function get_ticket_price(){
		return $this->ticket_price;
	}

	public function get_event_location(){
		return $this->sub_city.' '.$this->city.' '.$this->country;
	}

	public function get_event_name(){
		return $this->event_name;
	}

	public function get_reservation_code(){
		return $this->reservation_code;
	}

		
	

		function create_reciept($booking = null){
			$this->DB_Driver = new DB_CONNECTION();
			if($booking != null && $booking->get_status() != 'PAID' ){

		

				$attendee = Attendee::get_attendee($booking->get_attendee_id());
				$ticket = Ticket::get_ticket($booking->get_ticket_id());

				$event = Event::get_event($attendee->get_event_id());

			$sql = "INSERT INTO `reciept` ( ";
			$sql .= " `BOOKING_ID`, `ATTENDEE_ID`,  `issued_on`  ";
			$sql .= " ) VALUES ( :booking, :attendee, NOW() )  ";
		for($i = 0; $i < $booking->get_quantity(); $i++ ) {	
						
			$placeholder = array(':attendee' => $attendee->get_id(), 
									':booking' => $booking->get_id() );

			$statement = $this->DB_Driver->prepare_query($sql);
			$statement->execute($placeholder);

			}

				if($statement->rowCount() == 1) {
					$booking->set_paid();
					return true;
					
				} else {
					return false;
				}
		} else {
			return false;
		}
		
		}

	public static function get_reciept_detail($reservation_ID){
		$connection = new DB_CONNECTION();

		$sql ="SELECT * ";
		$sql .= "FROM `reciept_details` ";
		$sql .= "WHERE `reservation_code` = :id AND `reciept_status` = 'ACTIVE' ";

		$placeholder = array(':id' =>  $reservation_ID );

		

		$statement = $connection->prepare_query($sql);
		$statement->execute($placeholder);

			if($statement->rowCount() >= 1 ){
				return $statement->fetchAll(PDO::FETCH_CLASS, 'RecieptFactory');
			}else{
				return null;
			}



	}


}


?>