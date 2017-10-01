select `egate_db`.`event`.`EVNT_ID` AS `EVNT_ID`,
		`egate_db`.`event`.`name` AS  `event_name`,
		`egate_db`.`event`.`discription` AS `event_discription`,
		`egate_db`.`event`.`start_datetime` AS `event_start`,
		`egate_db`.`event`.`venue` AS `venue`,
		`egate_db`.`event_tickets`.`TIK_ID` AS `TIK_ID`,
		`egate_db`.`event_tickets`.`type` AS `ticket_type`,
		`egate_db`.`event_tickets`.`quantity` AS `ticket_quantity`,
		`egate_db`.`event_tickets`.`price` AS `ticket_price`,
		`egate_db`.`event_tickets`.`discription` AS `ticket_discription`,
		`egate_db`.`guests`.`GUEST_ID` AS `GUEST_ID`,
		`egate_db`.`guests`.`first_name` AS `guest_first_name`,
		`egate_db`.`guests`.`last_name` AS `guest_last_name`,
		`egate_db`.`guests`.`aka_name` AS `guest_aka_name`,
		`egate_db`.`guests`.`image` AS `guest_image`,
		`egate_db`.`guests`.`bio` AS `guest_bio`,
		`egate_db`.`guests`.`title` AS `title`

		 from `egate_db`.`event` join 
		 `egate_db`.`organizer` join 
		 `egate_db`.`event_tickets` join 
		 `egate_db`.`guests` join 
		 `egate_db`.`comments` join 
		 `egate_db`.`sponsor` 

		 where ((`egate_db`.`event`.`ORGANIZER_ID` = `egate_db`.`organizer`.`ORGANIZER_ID`) and 
		 	((`egate_db`.`event`.`EVNT_ID` = `egate_db`.`event_tickets`.`EVNT_ID`) or (`egate_db`.`event_tickets`.`EVNT_ID` = NULL)) and 
		 	((`egate_db`.`event`.`EVNT_ID` = `egate_db`.`guests`.`EVNT_ID`) or (`egate_db`.`guests`.`EVNT_ID` = NULL )) and 
		 	((`egate_db`.`event`.`EVNT_ID` = `egate_db`.`comments`.`EVNT_ID`) or (`egate_db`.`comments`.`EVNT_ID` = NULL )) and 
		 	((`egate_db`.`event`.`EVNT_ID` = `egate_db`.`sponsor`.`EVNT_ID`) or (`egate_db`.`sponsor`.`EVNT_ID` = NULL)) and 		 	
		 	(`egate_db`.`event`.`EVNT_ID` = 126))