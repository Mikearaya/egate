USE egate;


DELIMITER $$
CREATE TRIGGER `AI_checkIn_validator` AFTER INSERT ON `checkins` FOR EACH ROW BEGIN

        UPDATE `egate_db`.`reciept` SET `status` = 'USED' WHERE `RECIEPT_ID` = NEW.RECIEPT_ID;

END $$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER `BU_checkIn_validator` BEFORE UPDATE ON `checkins` FOR EACH ROW BEGIN


		IF  NEW.status = OLD.status AND NEW.status = 1 THEN

            SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 90,
					MESSAGE_TEXT = "ticket already used for checking in";
		END IF;
		IF  NEW.status = OLD.status AND NEW.status = 0 THEN
			  SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 90,
					MESSAGE_TEXT = "ticket already checked out";
		END IF;


END $$
DELIMITER ;


DELIMITER $$

CREATE TRIGGER `BI_eventValidator` BEFORE INSERT ON `event` FOR EACH ROW BEGIN

		IF	LENGTH(TRIM(NEW.name)) = 0  OR
			LENGTH(TRIM(NEW.venue)) = 0  OR
            LENGTH(TRIM(NEW.discription)) = 0  OR
            LENGTH(TRIM(NEW.start_time)) = 0  OR
            LENGTH(TRIM(NEW.start_date)) = 0  OR
            LENGTH(TRIM(NEW.end_time)) = 0  OR
            LENGTH(TRIM(NEW.end_date)) = 0  OR
            LENGTH(TRIM(NEW.country)) = 0  OR
            LENGTH(TRIM(NEW.city)) = 0  OR
            LENGTH(TRIM(NEW.sub_city)) = 0  OR
            LENGTH(TRIM(NEW.location)) = 0
        THEN
			SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 3,
					MESSAGE_TEXT =  'mising required value,  name, venue, category, discription,
							start time, start date, end time, end date, country, city, sub city, location
						are required fields and can not be null or empty';
		ELSEIF ISNULL(NEW.picture) THEN
				SIGNAL SQLSTATE '01000'
				SET MYSQL_ERRNO = 120,
					MESSAGE_TEXT =  'WARNING, the event picture was not provided and was not saved.';

        END IF;
		  IF (DATEDIFF(NEW.start_date, CURDATE()) < 2 ) THEN
			 SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 7,
					MESSAGE_TEXT = "INVALID DATE event start date should be grater than a minimum of 2 date from current date";
		 END IF;

         IF (DATEDIFF(NEW.end_date, NEW.start_date) < 0 ) THEN
			SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 9,
				MESSAGE_TEXT = "INVALID DATE RANGE, event start date can not be greater than ending date";
		END IF;

        IF (DATEDIFF(NEW.end_date, NEW.start_date) = 0 ) AND
           (TIMEDIFF(NEW.end_time, NEW.start_time) <= 0 )
		THEN
			SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 8,
					MESSAGE_TEXT = "INVALID TIME RANGE, event  start time can not be greater than ending time when ends on the same date";
		END IF;



    END $$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER `BU_eventValidator` BEFORE UPDATE ON `event` FOR EACH ROW BEGIN

		IF NEW.name IS NULL OR LENGTH(TRIM(NEW.name)) = 0 THEN	SET NEW.name = OLD.name;    END IF;

        IF NEW.discription IS NULL THEN	SET NEW.discription = OLD.discription;  END IF;

        IF NEW.venue IS NULL THEN	SET NEW.venue = OLD.venue;     END IF;

        IF NEW.CATEGORY_ID IS NULL THEN SET NEW.CATEGORY_ID = OLD.CATEGORY_ID;     END IF;

        IF NEW.country IS NULL THEN SET NEW.country = OLD.country;    END IF;

        IF NEW.city IS NULL THEN  SET NEW.city = OLD.city;    END IF;

        IF NEW.sub_city IS NULL THEN  SET NEW.sub_city = OLD.sub_city;    END IF;

        IF NEW.location IS NULL THEN  SET NEW.location = OLD.location;    END IF;

        IF NEW.start_time IS NULL THEN  SET NEW.start_time = OLD.start_time;    END IF;

        IF NEW.start_date IS NULL THEN  SET NEW.start_date = OLD.start_date;    END IF;

        IF NEW.end_time IS NULL THEN  SET NEW.end_time = OLD.end_time;    END IF;

        IF NEW.end_date IS NULL THEN  SET NEW.end_date = OLD.end_date;    END IF;

          IF (NEW.start_date != OLD.start_date) AND (DATEDIFF(NEW.start_date, CURDATE()) < 0 ) THEN
			 SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 7,
					MESSAGE_TEXT = "INVALID DATE event start date should be grater than a minimum of 2 date from current date";
		 END IF;

         IF (DATEDIFF(NEW.end_date, NEW.start_date) < 0 ) THEN
			SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 9,
				MESSAGE_TEXT = "INVALID DATE RANGE, event start date can not be greater than ending date";
		END IF;

        IF (DATEDIFF(NEW.end_date, NEW.start_date) = 0 ) AND
           (TIMEDIFF(NEW.end_time, NEW.start_time) <= 0 )
		THEN
			SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 8,
					MESSAGE_TEXT = "INVALID TIME RANGE, event  start time can not be greater than ending time when ends on the same date";
		END IF;

        IF (NEW.status != OLD.status) AND NEW.status = 'ACTIVE' AND (NEW.start_date > CURRENT_DATE() OR NEW.end_date < CURRENT_DATE()) THEN
				SIGNAL SQLSTATE '45000'
				SET	MESSAGE_TEXT = "Event Status Can Not be active";
        END IF;

        IF (NEW.status != OLD.status) AND NEW.status = 'OPEN' AND (NEW.start_date < CURRENT_DATE() OR NEW.end_date < CURRENT_DATE()) THEN
				SIGNAL SQLSTATE '45000'
				SET	MESSAGE_TEXT = "Event Status Can Not be Open";
        END IF;

END $$
DELIMITER ;


DELIMITER $$

CREATE TRIGGER `BI_eventAttendeeValidator` BEFORE INSERT ON `event_attendees` FOR EACH ROW BEGIN

            IF isValidName(NEW.first_name) = false THEN
				SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 27,
					MESSAGE_TEXT = "error, invalid attendee first name provided!";
            END IF;
            IF isValidName(NEW.last_name) = false THEN
				SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 27,
					MESSAGE_TEXT = "error, invalid attendee last name provided!";
            END IF;

            IF isValidphone(NEW.phone) = false THEN
				SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 27,
					MESSAGE_TEXT = "error, invalid attendee phone number provided!";
            END IF;

            IF (NOT ISNULL(NEW.email) ) AND isValidEmail(NEW.email) = false THEN
				SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 27,
					MESSAGE_TEXT = "error, invalid attendee email address format provided!";
            END IF;


 END $$
DELIMITER ;

DELIMITER $$

CREATE TRIGGER `BU_eventAttendeeValidator` BEFORE UPDATE ON `event_attendees` FOR EACH ROW BEGIN

            IF isValidName(NEW.first_name) = false THEN
				SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 27,
					MESSAGE_TEXT = "error, invalid attendee first name provided!";
            END IF;
            IF isValidName(NEW.last_name) = false THEN
				SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 27,
					MESSAGE_TEXT = "error, invalid attendee last name provided!";
            END IF;

            IF isValidphone(NEW.phone) = false THEN
				SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 27,
					MESSAGE_TEXT = "error, invalid attendee phone number provided!";
            END IF;

            IF (NOT ISNULL(NEW.email) ) AND isValidEmail(NEW.email) = false THEN
				SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 27,
					MESSAGE_TEXT = "error, invalid attendee email address format provided!";
            END IF;


     IF NOT ISNULL(NEW.PROVIDER_ID) AND NOT is_events_billingAddress(NEW.EVENT_ID, NEW.PROVIDER_ID) THEN
     SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = "NEW payment provider is not registered for the event!";
      END IF;

  SET NEW.ATTENDEE_ID = OLD.ATTENDEE_ID;
 END $$
DELIMITER ;



DELIMITER $$
CREATE TRIGGER `BI_bookingValidator` BEFORE INSERT ON `event_bookings` FOR EACH ROW BEGIN


			IF isValidInt(NEW.TICKET_ID) AND ticketStatus(NEW.TICKET_ID) = 'ACTIVE' THEN
				UPDATE `eventTicket` SET `available` = `available` - 1
                WHERE `TICKET_ID` = NEW.TICKET_ID;

            ELSE
					SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 25,
					MESSAGE_TEXT = "error, the ticket you are trying to book is not in active state";

			END IF;

            IF ticketType(NEW.TICKET_ID) != 'PAID' THEN
				SET NEW.`status` = 'CONFIRMED';
			END IF;

 END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER `AI_bookingValidator` AFTER INSERT ON `event_bookings` FOR EACH ROW BEGIN


            IF NEW.`status` = 'CONFIRMED' THEN

                INSERT INTO `egate_db`.`reciept`(`BOOKING_ID`, `status`)
					VALUE(NEW.BOOKING_ID, 'ACTIVE');
			END IF;


 END $$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER `BI_guestValidator` BEFORE INSERT ON `event_guests` FOR EACH ROW BEGIN

    IF 	(ISNULL(NEW.first_name) OR LENGTH(TRIM(NEW.first_name)) = 0 ) OR
		(ISNULL(NEW.last_name) OR LENGTH(TRIM(NEW.last_name)) = 0 )
	THEN
		SIGNAL SQLSTATE '45000'
			SET MYSQL_ERRNO = 3,
				MESSAGE_TEXT =  'mising required value, guest first name & last name are required fields and
						can not be null or empty';
	END IF;

END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER `BU_guestValidator` BEFORE UPDATE ON `event_guests` FOR EACH ROW BEGIN

	IF (ISNULL(NEW.first_name) OR LENGTH(TRIM(NEW.first_name)) = 0 ) THEN	SET NEW.first_name = OLD.first_name;	END IF;

	IF (ISNULL(NEW.last_name) OR LENGTH(TRIM(NEW.last_name))  =  0 )  THEN	SET NEW.last_name = OLD.last_name;	END IF;


END $$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER `BI_sponsorValidator` BEFORE INSERT ON `event_sponsors` FOR EACH ROW BEGIN
			IF (ISNULL(NEW.name) OR LENGTH(TRIM(NEW.name) ) = 0) THEN
				SIGNAL SQLSTATE '45000'
					SET MYSQL_ERRNO = 3,
						MESSAGE_TEXT =  'mising required value, sponsor  name is a required fields and
						can not be null or empty';
			END IF;


END $$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER `BU_sponsorValidator` BEFORE UPDATE ON `event_sponsors` FOR EACH ROW BEGIN


    IF (ISNULL(NEW.name) OR LENGTH(TRIM(NEW.name)) = 0 ) THEN   SET NEW.name = OLD.name; END IF;

END $$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER `BI_ticketValidator` BEFORE INSERT ON `event_tickets` FOR EACH ROW BEGIN



    IF	LENGTH(TRIM(NEW.name))= 0  OR
		LENGTH(TRIM(NEW.type)) = 0   OR
		LENGTH(TRIM(NEW.discription)) = 0  OR
        LENGTH(TRIM(NEW.price)) = 0   OR
		LENGTH(TRIM(NEW.quantity)) = 0   OR
        LENGTH(TRIM(NEW.sale_start)) = 0  OR
		LENGTH(TRIM(NEW.sale_end)) = 0
	THEN
		SIGNAL SQLSTATE '45000'
			SET MYSQL_ERRNO = 3,
			MESSAGE_TEXT =  'null or empty value, Ticket name, type, price, discription, quantity, sale start & sale end
						are required fields and can not be null or empty';
     ELSE
			SET NEW.type = UPPER(NEW.type);

	END IF;



		CALL getEventTime(NEW.EVENT_ID, @startDate, @startTime, @endDate, @endTime );

			IF DATEDIFF(@startDate , NEW.sale_start  ) < 2 THEN
				SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 30,
					MESSAGE_TEXT = "Ticket sale start date should be less than or equal to 2 days before event start time";
			ELSEIF DATEDIFF(NEW.sale_end,  @endDate) > 0 THEN
					SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 30,
					MESSAGE_TEXT = "Ticket sale end date can not be greater than event end date";
            END IF;
	    IF (DATEDIFF(NEW.sale_start, CURDATE() ) < 0 ) THEN

        SIGNAL SQLSTATE '45000'
        SET MYSQL_ERRNO = 7,
			MESSAGE_TEXT = "Ticket sale start date should be grater than or equal to from current date";
		END IF;

	IF DATEDIFF(NEW.sale_end, NEW.sale_start) < 2 THEN
		 SIGNAL SQLSTATE '45000'
			SET MYSQL_ERRNO = 2,
				MESSAGE_TEXT = 'Ticket sale ending date should be 2 or more days greater than sales starting date';
	END IF;


    IF NEW.price < 0 THEN
		SIGNAL SQLSTATE '45000'
			SET MYSQL_ERRNO = 4,
				MESSAGE_TEXT = 'Ticket price can not have value of less than 0. ';

	END IF;

    IF isValidFloat(NEW.price) = false THEN
		SIGNAL SQLSTATE '45100'
			SET MYSQL_ERRNO = 4,
				MESSAGE_TEXT = 'Ticket price should be a valid integer. ';

	END IF;

    IF NEW.price > 0 AND UPPER(NEW.type) = "FREE" THEN
		SIGNAL SQLSTATE '45100'
		SET MESSAGE_TEXT = 'Ticket type that have value of FREE can not have price greater than 0.',
	 MYSQL_ERRNO = 5;
     END IF;
	IF NEW.price <= 0 AND UPPER(NEW.type) = "PAID" THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Ticket type that have value of PAID can not have price of 0.',
	 MYSQL_ERRNO = 6;
    END IF;

    IF NEW.available > NEW.quantity THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'available ticket can not be greater than provided ticktet quantty.',
	 MYSQL_ERRNO = 40;
    END IF;


END $$
DELIMITER ;



DELIMITER $$
CREATE TRIGGER `BU_ticketValidator` BEFORE UPDATE ON `event_tickets` FOR EACH ROW BEGIN

	IF	(ISNULL(NEW.name) OR LENGTH(TRIM(NEW.name)) = 0 )  THEN SET NEW.name = OLD.name;	END IF;

	IF (ISNULL(NEW.type) AND LENGTH(TRIM(NEW.type)) = 0 )  THEN	SET NEW.type = OLD.type;	END IF;

    IF	(ISNULL(NEW.discription) OR LENGTH(TRIM(NEW.discription)) = 0 )  THEN	SET NEW.discription = OLD.discription;	END IF;

    IF	(ISNULL(NEW.price) AND LENGTH(TRIM(NEW.price)) = 0 )  THEN	SET NEW.price = OLD.price;	END IF;

    IF 	(ISNULL(NEW.quantity) OR LENGTH(TRIM(NEW.quantity)) = 0 )  THEN	SET NEW.quantity = OLD.quantity;	END IF;

    IF	(ISNULL(NEW.sale_start) OR LENGTH(TRIM(NEW.sale_start)) = 0 )  THEN	SET NEW.sale_start = OLD.sale_start;	END IF;

    IF 	(ISNULL(NEW.sale_end) OR LENGTH(TRIM(NEW.sale_end)) = 0 ) THEN SET NEW.sale_end = OLD.sale_end; END IF;

    IF (NEW.sale_start <> OLD.sale_start AND DATEDIFF(NEW.sale_start, CURDATE() ) < 0 ) THEN
		SIGNAL SQLSTATE '45000'
			SET MYSQL_ERRNO = 7,
				MESSAGE_TEXT = "event ticket  sale start date can not be greater than current date";
	END IF;

    IF (DATEDIFF(NEW.sale_end, NEW.sale_start) < 0 ) THEN
		SIGNAL SQLSTATE '45000'
			SET MYSQL_ERRNO = 9,
				MESSAGE_TEXT = "event ticket  sale start date can not be greater than sale ending date";
	END IF;

    IF(NEW.quantity < 0) THEN
		SIGNAL SQLSTATE '45000'
            SET MYSQL_ERRNO = 13,
				MESSAGE_TEXT = "value not allowed. Ticket quantity can not have value less than 0 ";
	END IF;

	IF(NEW.price < 0) THEN
		SIGNAL SQLSTATE '45000'
            SET MYSQL_ERRNO = 13,
				MESSAGE_TEXT = "value not allowed. Ticket price can not have value less than 0 ";
	END IF;



	IF NEW.price > 0 AND UPPER(NEW.type) = "FREE" THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Ticket type that have value of FREE can not have price greater than 0.',
				MYSQL_ERRNO = 5;
	ELSEIF NEW.price = 0 AND UPPER(NEW.type) = "PAID" THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Ticket type that have value of PAID can not have price of 0.',
			MYSQL_ERRNO = 6;
	ELSE
		SET NEW.type = UPPER(NEW.type);
	END IF;

    IF ((NEW.quantity IS NOT NULL AND NEW.quantity > OLD.quantity)) THEN
		SET NEW.available = (NEW.quantity - OLD.quantity);
	END IF;
	IF	((NEW.quantity IS NOT NULL AND NEW.quantity < OLD.available))	THEN
		SET NEW.available = NEW.quantity;
     END IF;

		IF NEW.available < 0 THEN
			SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 25,
				MESSAGE_TEXT = "error Trying to book ticket more than the available amount";

            END IF;


END $$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER `BU_organizerAddress_trigger` BEFORE UPDATE ON `organization_address` FOR EACH ROW BEGIN
		IF ISNULL(NEW.country)THEN
          SET NEW.country = OLD.country;
		END IF;

        IF ISNULL(NEW.city) THEN
			SET NEW.city = OLD.city;
		END IF;

        IF ISNULL(NEW.sub_city) THEN
			SET NEW.sub_city = OLD.sub_city;
		END IF;
        IF isnull(NEW.location) THEN
			SET NEW.location = OLD.location;
		END IF;

END $$
DELIMITER ;



DELIMITER $$
CREATE TRIGGER `BI_organizerValidator` BEFORE INSERT ON `organizer` FOR EACH ROW BEGIN


        IF (isValidName(NEW.first_name) = false) THEN
			SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 19,
					MESSAGE_TEXT = 'TRIGGERED invalid organizer first name ,
									valid name should only containnot more than 20  alphabetic characters only ';
        END IF;

        IF (isValidName(NEW.last_Name) = false) THEN
			SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 19,
					MESSAGE_TEXT = 'TRIGGERED invalid organizer last name ,
									valid name should only containnot more than 20  alphabetic characters only ';
        END IF;

        IF (isValidText(NEW.password) = false) THEN
			SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 19,
					MESSAGE_TEXT = 'TRIGGERED invalid organizer password  ';

        END IF;

        IF (isValidEmail(NEW.e_mail) = false) THEN
			SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 19,
					MESSAGE_TEXT = 'TRIGGERED invalid Email format given for email';

        END IF;

        	INSERT INTO organization() VALUE();

            IF ROW_COUNT() = 1 THEN
				SET NEW.ORGANIZATION_ID = LAST_INSERT_ID();
            ELSE
				SIGNAL SQLSTATE '45000'
					SET MYSQL_ERRNO = 18,
						MESSAGE_TEXT = 'TRIGGERED Unkown Error Occured While Creating Organization check if
										all input are valid and try Again';
			END IF;

 END $$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER `BU_organizerValidator` BEFORE UPDATE ON `organizer` FOR EACH ROW BEGIN


        IF (isValidName(NEW.first_name) = false) THEN
        SET NEW.first_name = OLD.first_name;
			SIGNAL SQLSTATE '01000'
				SET MYSQL_ERRNO = 19,
					MESSAGE_TEXT = 'TRIGGERED invalid organizer first name ,
									valid name should only containnot more than 20  alphabetic characters only ';
        END IF;

        IF (isValidName(NEW.last_Name) = false) THEN
        SET NEW.last_name = OLD.last_name;
			SIGNAL SQLSTATE '01000'
				SET MYSQL_ERRNO = 19,
					MESSAGE_TEXT = 'TRIGGERED invalid organizer last name ,
									valid name should only containnot more than 20  alphabetic characters only ';
        END IF;

        IF (isValidText(NEW.password) = false) THEN
        SET NEW.password = OLD.password;
			SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 19,
					MESSAGE_TEXT = 'TRIGGERED invalid organizer password  ';

        END IF;

        IF (isValidEmail(NEW.e_mail) = false) THEN
        SET NEW.e_mail = OLD.e_mail;
			SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 19,
					MESSAGE_TEXT = 'TRIGGERED invalid Email ,
									valid Email should only any alphabetic character followed by @ symbole and any number of char and optionally . followed by 2 to 4 chars for domain ';
        END IF;


 END $$
DELIMITER ;
