<?php
require('FPDF/fpdf.php');


class PDF extends FPDF
{
// Page header
function Header()
{
    // Logo
    $this->Image('Egate.png',10,10,20);
    // Arial bold 15
    $this->SetFont('Arial','B',15);
    // Move to the right

    // Title
    $this->Cell(null,20,'Egate',1,1,'C');
    // Line break
    $this->Ln(20);
}

// Page footer
function Footer()
{
    // Position at 1.5 cm from bottom
    $this->SetY(-15);
    // Arial italic 8
    $this->SetFont('Arial','I',8);
    // Page number
    $this->Cell(0,10,'Page '.$this->PageNo().'/{nb}',0,0,'C');
}

public function print_reciept(){
// Instanciation of inherited class
$pdf = new PDF();
$pdf->AliasNbPages();
$pdf->SetFillColor(230,230,0);
$pdf->SetTextColor(220,50,50);
$pdf->AddPage();
$pdf->SetFont('Times','',12);

$pdf->SetLineWidth(1);
$y=30;

$txt = file_get_contents("my.txt");

for($i=1;$i<=40;$i++) {
   
       $pdf->Image('Egate.png', 10,$pdf->GetY(), 30 );
    $pdf->Cell(25);

$x = "RECIEPT ID : 300 ";
$x .= "Reservation Code: 10  \n ";
$x .= "EVENT: Logic Concert  \n";
$x .= "Venu: Bole Millenium Hall \n";
$x .= "Addres: Friendship, Bole, Addis Ababa Ethiopia \n";                            
$x .= "Event Start Date ".date("yyyy-mm-dd")." Time: ".date('h:i:s')."\n";
$x .= "Event End Date ".date("yyyy-mm-dd")." Time: ".date('h:i:s')."\n";                            
$x .= "Ticket Type: VIP  \n";
$x .= "Booked By: Mikael Araya  \n ";
$x .= "Price: Free  \n  ".$pdf->GetY()."";
$x .= "Organizer: WAFA Promotion \n";
    $pdf->MultiCell(null,5,$x, null,'L', true);
    $y = $y + 45 ;
    $pdf->Ln();
}

$pdf->Output();    
}
}

$pd = new PDF();

$pd->print_reciept();

?>