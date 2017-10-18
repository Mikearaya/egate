-- phpMyAdmin SQL Dump
-- version 4.6.4
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 03, 2017 at 04:07 PM
-- Server version: 5.7.14
-- PHP Version: 5.6.25

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `egate_db`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `addComment` (IN `in_eventId` INT, IN `in_comment` JSON)  MODIFIES SQL DATA
BEGIN
		
	DECLARE errorCount INT DEFAULT 0;
    DECLARE NESTED BOOLEAN DEFAULT true;    
      
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN ROLLBACK; END IF;
            RESIGNAL;                    
        END;
        
				IF transactionCount() = 0 THEN
					START TRANSACTION;
                    SET NESTED = false;
				END IF;
                IF NOT ISNULL(in_eventId) AND 
				NOT ISNULL(	in_comment)
				
				THEN
                PREPARE comment_statement FROM 
                ' INSERT INTO `eventComment` ( `EVENT_ID`, `name`, `comment` )  VALUES(?, ?, ?) ';
				
                SET @eventId = in_eventId;
                SET @counter = 0;
                
					
                
						SET @commenter = in_comment->>'$.commenter';
						SET @content = in_comment->>'$.comment';
                		EXECUTE comment_statement USING @eventId, @commenter, @content;
                        
                    SET @commentId = LAST_INSERT_ID();
					
                    IF NESTED = false AND errorCount = 0 THEN
                    
                    COMMIT; 
                    SELECT @commentId AS 'commentId';
                    END IF;
                    
					DEALLOCATE PREPARE comment_statement;
						
				ELSE 
					SIGNAL SQLSTATE '45000'
						SET MYSQL_ERRNO = 5,
							MESSAGE_TEXT = 'JSON OBJECT passed for comment missing required field EVENT_ID , name and comment';
				END IF;
                                
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `addEvent` (IN `in_organizerId` INT, IN `in_event` JSON)  MODIFIES SQL DATA
BEGIN
	DECLARE errorCount INT DEFAULT  0;
    
		DECLARE CONTINUE HANDLER FOR SQLEXCEPTION, 1265
		BEGIN        					
		
        ROLLBACK;
        RESIGNAL;
    SET errorCount = 1;
		
		END;

#check if their is atleast one ticket type associated with the event
#since bussiness rule requires events to have atleast 1 ticket type
IF JSON_CONTAINS_PATH(in_event, "all", '$.tickets[*].ticketName' ,'$.tickets[*].ticketType', '$.tickets[*].quantity',
                                        '$.tickets[*].aboutTicket', '$.tickets[*].ticketPrice') 
									THEN

    START TRANSACTION;
 
	PREPARE add_event_statement 
		FROM 'INSERT INTO `event` (
			`ORGANIZER_ID`, `name`, `venue`, `discription`, `start_time`, `start_date`, `end_time`, 
			`end_date`,  `CATEGORY_ID`, `sub_city`, `city`, `country`, `location`, `picture`, `longitude`, `latitude` , `status`
			) VALUES ( ?, ?, ?, ?, ? ,?, ?, ?, ?, ?, ?, ? ,?, ?, ?, ?, ?)';
    SET @organizer = in_organizerId;
    SET @eventName =  in_event->>'$.eventName';
    SET @venue = in_event->>'$.venue';
    SET @discription = in_event->>'$.aboutEvent';
    SET @startTime = in_event->>'$.startTime';
    SET @startDate =  in_event->>'$.startDate';
    SET @endTime =in_event->>'$.endTime';
    SET @endDate = in_event->>'$.endDate';
    SET @category = in_event->>'$.eventCategory';
    SET @subCity = in_event->>'$.subCity';
    SET @city = in_event->>'$.city';
    SET @country = in_event->>'$.country';
    SET @location = in_event->>'$.location';
    SET @latitude = in_event->>'$.latitude';
    SET @longitude = in_event->>'$.longitude';
    SET @image = in_event->>'$.eventImage';
    SET @eventStatus = in_event->>'$.eventStatus';
    
    EXECUTE add_event_statement USING @organizer, @eventName, @venue, @discription, @startTime, @startDate,
                                      @endTime, @endDate, @category, @subCity, @city, @country, @location, @image,
                                      @latitude, @longitude, @eventStatus;



     SET @new_event_id = LAST_INSERT_ID();
    
    IF @new_event_id IS NOT NULL THEN
    
		
        CALL addEventTicket(@new_event_id, in_event->>'$.tickets');
        
       	IF (NOT ISNULL(in_event->>'$.guests') ) AND JSON_LENGTH(in_event->>'$.guests') > 0 THEN            
        CALL addEventGuest(@new_event_id, in_event->>'$.guests');
		END IF;
    

		IF (NOT ISNULL(in_event->>'$.sponsors') ) AND JSON_LENGTH(in_event->>'$.sponsors') > 0 THEN 
			CALL addEventSponsor(@new_event_id, in_event->>'$.sponsors');
		END IF;
	
        ELSE 		
          ROLLBACK;
     END IF;
    
    

    
    IF errorCount = 0 THEN 
		COMMIT;
	SELECT @new_event_id AS 'eventId';
	ELSE 
		ROLLBACK; 
     
	END IF; 
 
    
		ELSE 
			SIGNAL SQLSTATE '45000' 
			SET MESSAGE_TEXT = 'json data passed for ticket missing required keys 
								check the manual for required keys and try again',
		MYSQL_ERRNO = 1;	
END IF;




END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `addEventAttendee` (IN `in_eventId` INT, IN `in_attendee` JSON, OUT `out_newAttendeeId` INT)  MODIFIES SQL DATA
BEGIN

		DECLARE NESTED BOOLEAN DEFAULT true;
        DECLARE errorCount INT DEFAULT 0;
        
        DECLARE email_exists CONDITION FOR 1062;
        
        DECLARE invalid_foreign_key CONDITION FOR 1452;
        
        DECLARE EXIT HANDLER FOR invalid_foreign_key
        BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN ROLLBACK; END IF;
            RESIGNAL SQLSTATE '45100' SET MESSAGE_TEXT = 'Service Provider Doesnt Exists';
        END;
        
        DECLARE EXIT HANDLER FOR SQLEXCEPTION, email_exists
        BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN ROLLBACK; END IF;
            RESIGNAL;						
        END;
						
			IF JSON_CONTAINS_PATH(in_attendee, 'all', '$.firstName', '$.lastName', '$.phoneNumber') THEN
SELECT `ATTENDEE_ID` FROM eventAttendee 
          WHERE EVENT_ID = in_eventId AND phone = in_attendee->>'$.phoneNumber' INTO out_newAttendeeId;            
		IF NOT out_newAttendeeId THEN
                        IF transactionCount() = 0 THEN
							START TRANSACTION;
                            SET NESTED = false;
						END IF;
                        
            	PREPARE attendee_registeration_statement FROM
							'INSERT INTO `eventAttendee` (
								`EVENT_ID`, `first_name`, `last_name`,`phone`, `PROVIDER_ID`, `email`
								) VALUES (?, ?, ?, ? ,?, ? ) 
                                ON DUPLICATE KEY UPDATE `first_name` = ?, `last_name` = ?,
                                `email` = ?, `PROVIDER_ID` = ? ';
                                
            SET @eventId = in_eventId;
            SET @fname = in_attendee->>'$.firstName';
            SET @lname = in_attendee->>'$.lastName';
            SET @phone = in_attendee->>'$.phoneNumber';
            SET @email = in_attendee->>'$.email';
            SET @serviceProvider = in_attendee->>'$.serviceProvider';
            
            EXECUTE attendee_registeration_statement USING @eventId, @fname, @lname, @phone, @serviceProvider,
						@email, @fname, @lname, @email, @serviceProvider;
            
        SET out_newAttendeeId = LAST_INSERT_ID();
       
            IF ISNULL(out_newAttendeeId) THEN
				
					SIGNAL SQLSTATE '45000'
						SET MYSQL_ERRNO = 22,
                        MESSAGE_TEXT = 'ERROR Occured While registering event Attendee ';								
			END IF;
	
            
            IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
     
     
            DEALLOCATE PREPARE attendee_registeration_statement;
            
     END IF;       
            
		ELSE
				SIGNAL SQLSTATE '45000' 
            SET MYSQL_ERRNO = 1,	
			MESSAGE_TEXT = 'json data passed for event attendee missing one of the required keys required keys 
								eventId, firstName, lastName, phoneNumber ';
        
        END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `addEventBooking` (IN `in_reservationId` INT, IN `in_ticket` JSON)  MODIFIES SQL DATA
BEGIN

		DECLARE NESTED BOOLEAN DEFAULT true;
        DECLARE errorCount INT DEFAULT 0;
        
       
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN 
				ROLLBACK; 
		
			END IF;
            RESIGNAL;						
        END;
        
					
				IF JSON_CONTAINS_PATH(in_ticket, 'one', '$[*].ticketId', '$[*].ticketQuantity') AND 	(NOT ISNULL(in_reservationId))
				THEN
            
                        IF transactionCount() = 0 THEN
							START TRANSACTION;
                            SET NESTED = false;
						END IF;
				
			SET @attendeeId = in_reservationId;
            
			PREPARE add_booking_statement FROM 
					'INSERT INTO `eventBooking` ( `ATTENDEE_ID`, `TICKET_ID`  )
												VALUES (?, ? )';
					SET @counter = 0;
                    
				WHILE @counter < JSON_LENGTH(in_ticket) DO
				
					SET @ticketId = JSON_UNQUOTE(JSON_EXTRACT(in_ticket, CONCAT('$[', @counter, '].ticketId')));
                    SET @quantity = JSON_UNQUOTE(JSON_EXTRACT(in_ticket, CONCAT('$[', @counter, '].ticketQuantity')));
							
                       IF (availableTicket(@ticketId) >= @quantity ) THEN     
							
                            SET @booked = 0;
								WHILE @booked < @quantity DO
							
									EXECUTE add_booking_statement USING @attendeeId, @ticketId;
												
									SET @booked = @booked + 1;
								END WHILE;
                    
						ELSE
							SIGNAL SQLSTATE '45000'
								SET MYSQL_ERRNO = 25,
									MESSAGE_TEXT = "error Trying to book ticket more than the available amount";
						END IF;
					
                    SET @counter = @counter + 1;
				
                END WHILE;
                DEALLOCATE PREPARE add_booking_statement;
                
				IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
               
		ELSE 
        SIGNAL SQLSTATE '45000'
			SET MYSQL_ERRNO = 102,
				MESSAGE_TEXT = 'JSON array for booking id missing required key ticketId and quantity ';
	END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `addEventCategory` (IN `in_category` JSON)  MODIFIES SQL DATA
BEGIN
	DECLARE NESTED BOOLEAN DEFAULT true;
    DECLARE errorCount INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		GET DIAGNOSTICS errorCount = NUMBER;
        IF NESTED = false THEN ROLLBACK; END IF;
        RESIGNAL;
        
    END;
    
				IF transactionCount() = 0 THEN
					START TRANSACTION;
                    SET NESTED = false;
				END IF;
                
                
			IF JSON_CONTAINS_PATH(in_category, 'all', '$[*].category') THEN
            
				SET @counter = 0;
                
                PREPARE add_category_prepare FROM 
                'INSERT INTO `egat_db`.`eventCategory`(`category_name`) VALUES(?)';
                
                WHILE @counter < JSON_LENGTH(in_category) DO
                
					SET @category = JSON_EXTRACT(in_category, CONCAT('$[', @counter, '].category'));
					
					EXECUTE add_category_prepare USING @category;
					
					SET @counter = @counter + 1;
				
                END WHILE;
                
                
                IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
               
               DEALLOCATE PREPARE add_category_prepare;
		ELSE
			SIGNAL SQLSTATE '45000' 
				SET MYSQL_ERRNO = 1,	
					MESSAGE_TEXT = 'json data passed for event category missing required  
								field (category) ';
        
        
        END IF;
                
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `addEventGuest` (IN `in_eventID` INT, IN `in_guest` JSON)  MODIFIES SQL DATA
BEGIN

	DECLARE eventGuest JSON;
	DECLARE NESTED BOOLEAN DEFAULT true;
	DECLARE errorCount INT DEFAULT 0;

		DECLARE EXIT  HANDLER FOR SQLEXCEPTION, SQLSTATE '45000'
		BEGIN 
		GET DIAGNOSTICS errorCount = NUMBER;		
		 IF NESTED = false THEN ROLLBACK; END IF;
        
        RESIGNAL;
  
		END;
    
		 IF transactionCount() = 0 THEN 
         SET @tran = transactionCount();
		 START TRANSACTION; 
		 SET NESTED = false;
		 END IF;

IF JSON_CONTAINS_PATH(in_guest, 'all', '$[*].firstName' ,'$[*].lastName') THEN
        
         PREPARE   add_guest_statement FROM 'INSERT INTO `eventGuest` (
				`EVENT_ID`, `first_name`, `last_name`, `aka_name` , `bio`, `title`, `image` 
				) VALUES ( ?, ?, ?, ?, ?, ?, ?	)';
                SET @counter = 0;
                SET @event_id = in_eventId;
                
			WHILE @counter < JSON_LENGTH(in_guest) DO
          
          SET eventGuest = JSON_EXTRACT(in_guest, CONCAT('$[', @counter, ']'));
		
            SET @fname = eventGuest->>'$.firstName';
            SET @lname = eventGuest->>'$.lastName';
            SET @akaName = eventGuest->>'$.akaName';
            SET @bio = eventGuest->>'$.aboutGuest';
            SET @title = eventGuest->>'$.title';
            SET @image = eventGuest->>'$.guestImage';
            
            EXECUTE add_guest_statement USING @event_id, @fname, @lname, @akaName, @bio, @title, @image;
            SET @counter = @counter + 1;
            
            END WHILE;
            DEALLOCATE PREPARE add_guest_statement;
            
            IF NESTED = false AND errorCount = 0 THEN 
					COMMIT; 
            END IF;
           
		ELSE
        	SIGNAL SQLSTATE '45000' 
            SET MYSQL_ERRNO = 1,	
			MESSAGE_TEXT = 'json data passed for event guest missing required keys 
								check the manual for required keys and try again';
            				
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `addEventSponsor` (IN `in_eventID` INT, IN `in_sponsor` JSON)  MODIFIES SQL DATA
BEGIN
     DECLARE eventSponsor JSON;
     DECLARE NESTED BOOLEAN DEFAULT true;
	DECLARE errorCount INT DEFAULT 0;
	
		DECLARE EXIT  HANDLER FOR SQLEXCEPTION
		BEGIN 
		GET DIAGNOSTICS errorCount = NUMBER;		
		 IF NESTED = false THEN ROLLBACK; END IF;
         RESIGNAL;
         
		END;
    
		 IF transactionCount() = 0 THEN 
		 START TRANSACTION; 
		 SET NESTED = false;
		 END IF;
		
	
	IF JSON_CONTAINS_PATH(in_sponsor, "all", '$[*].sponsorName' ) THEN
    
         PREPARE   add_sponsor_statement FROM 'INSERT INTO `eventSponsor` (
				`EVENT_ID`, `name`, `image`, `aboutSponsor`
				) VALUES ( ?, ?, ?, ? )';
            
            SET @counter = 0;
                SET @event_id = in_eventID;
                
			WHILE @counter < JSON_LENGTH(in_sponsor) DO
            
            SET eventSponsor = JSON_EXTRACT(in_sponsor, CONCAT('$[', @counter, ']'));		
            SET @name = eventSponsor->>'$.sponsorName';           
            SET @image = eventSponsor->>'$.sponsorImage';
            SET @about = eventSponsor->>'$.aboutSponsor';
            
            EXECUTE add_sponsor_statement USING @event_id, @name, @image, @about;
            
            SET @counter = @counter + 1;
            
            END WHILE;
            
            DEALLOCATE PREPARE add_sponsor_statement;
           IF NESTED = false AND errorCount = 0 THEN
				   COMMIT; 
           END IF;
           
           
		ELSE
        	SIGNAL SQLSTATE '45000' 
            SET MYSQL_ERRNO = 1,	
			MESSAGE_TEXT = 'json data passed for event sponsor missing required keys 
								sponsorName';
            				
    END IF;
    
    
		

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `addEventTicket` (IN `in_eventId` INT, IN `in_ticket` JSON)  MODIFIES SQL DATA
BEGIN

	DECLARE eventTicket JSON;
	DECLARE NESTED BOOLEAN DEFAULT true;
	DECLARE errorCount INT DEFAULT 0;

		DECLARE EXIT  HANDLER FOR SQLEXCEPTION, 1265
		BEGIN 
		GET DIAGNOSTICS errorCount = NUMBER;
		IF NESTED = false THEN ROLLBACK; END IF;
        RESIGNAL;
        
		 
		END;
    
		 IF transactionCount() = 0 THEN 
		 START TRANSACTION;          
		 SET NESTED = false;
		 END IF;
         
         
    

PREPARE add_ticket_statement FROM 'INSERT INTO `eventTicket` (
				`EVENT_ID`, `name`, `type`, `price` , `quantity`, `available`, `discription`,
                `sale_start`, `sale_end`
				) VALUES ( ?, ?, ?, ?, ?, ?,?, ?, ?	)';
			SET @counter = 0;
		WHILE (@counter < JSON_LENGTH(in_ticket)) DO
       
         
			 SET eventTicket = JSON_EXTRACT(in_ticket, CONCAT('$[', @counter, ']'));
				SET @eventId = in_eventId;
				SET @name = eventTicket->>'$.ticketName';
				SET @type =  eventTicket->>'$.ticketType';
				SET @price =  eventTicket->>'$.ticketPrice';
				SET @quantity =  eventTicket->>'$.quantity';
				SET @available =  eventTicket->>'$.quantity';
				SET @discription =  eventTicket->>'$.aboutTicket';
				SET @saleStart =  eventTicket->>'$.saleStart';
				SET @saleEnd =  eventTicket->>'$.saleEnd';
        
		 EXECUTE add_ticket_statement USING   @eventId, @name , @type , @price, @quantity, @available, @discription,
         @saleStart, @saleEnd;
         
			SET @counter = @counter + 1;
			            
        END WHILE;
		DEALLOCATE PREPARE add_ticket_statement;
        
      IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
      
       
        
       
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `addOrganizationAddress` (IN `in_organizerId` INT, IN `in_address` JSON)  MODIFIES SQL DATA
BEGIN
	
		DECLARE errorCount INT DEFAULT 0;
        DECLARE NESTED BOOLEAN DEFAULT true;
        DECLARE address JSON;
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN 
			GET DIAGNOSTICS errorCount = NUMBER;
			IF NESTED = false THEN ROLLBACK; END IF;
            RESIGNAL;
		END;
        		
		SET @organizationId = getOrganizationId(in_organizerId);
        
        IF JSON_CONTAINS_PATH(in_address,'all', '$[*].country','$[*].city', '$[*].subCity', '$[*].location' ) 
			AND  @organizationId THEN
					IF transactionCount() = 0 THEN
						START TRANSACTION;
                        SET NESTED = false;
					END IF;

        
        
        PREPARE add_organizationAddress_prepare FROM 
			'INSERT INTO  `egate_db`.`organization_address` ( 
				`ORGANIZATION_ID`, `country` , `city` , `sub_city`, `location`, `longitude`, `latitude`
                ) VALUES (?, ?, ?,?, ?, ?, ?) ';
				
                SET @counter = 0;
                    
				WHILE @counter  < JSON_LENGTH(in_address)DO
					SET address = JSON_EXTRACT(in_address, CONCAT('$[',@counter ,']'));
            
            SET @country = address->>'$.country';
            SET @city = address->>'$.city';
            SET @subCity = address->>'$.subCity';
            SET @location = address->>'$.location';
            SET @latitude = address->>'$.latitude';
            SET @longitude = address->>'$.longitude';
                      
				EXECUTE add_organizationAddress_prepare USING  @organizationId, @country , @city, @subCity, @location, @latitude, @longitude;
				SET @counter = @counter + 1;
			END WHILE;
			
            IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
        
        DEALLOCATE PREPARE add_organizationAddress_prepare;
        
	ELSE	
		SIGNAL SQLSTATE '45100'
			SET MESSAGE_TEXT = 'JSON data passed for address missing required key (country, city, subCity, location) ';
	END IF;
					
 END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `addSubscription` (IN `in_subscription` JSON, OUT `out_subscriptionId` INT)  MODIFIES SQL DATA
BEGIN
		DECLARE NESTED BOOLEAN DEFAULT true;
        DECLARE errorCount INT DEFAULT 0;
        DECLARE subscriptions JSON;
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN ROLLBACK; END IF;
            RESIGNAL;
        END;
        
				IF transactionCount() = 0 THEN
					START TRANSACTION;
                    SET NESTED = false;
				END IF;
                
                
			IF JSON_CONTAINS_PATH(in_subscription, 'all', '$[*].email', '$[*].subscription') THEN
            
				PREPARE add_subscriber_prepare FROM 'INSERT INTO `subscriber`(`e_mail`) VALUE(?)';
                
                SET @email = in_subscription->>'$[0].email';
                
                EXECUTE add_subscriber_prepare USING @email;
                
                
                IF ROW_COUNT() = 1 THEN 
                 
					SET @newId = LAST_INSERT_ID();
                    
                    PREPARE add_subscription_prepare FROM 
                    'INSERT INTO subscription(`SUBSCRIBER_ID`, `CATEGORY_ID` )
					VALUE(?, ?)';
						SET @counter = 0;
						SET subscriptions = in_subscription->>'$[0].subscription';
                        
                        WHILE @counter < JSON_LENGTH( subscriptions ) DO
							
							SET @categoryId = JSON_EXTRACT(subscriptions, CONCAT('$[',@counter,']'));
                            
                            EXECUTE add_subscription_prepare USING @newId, @categoryId;
                            
                            SET @counter = @counter + 1;
					END WHILE;
                    SET out_subscriptionId = @newId;
						IF errorCount = 0 AND NESTED = false THEN COMMIT; END IF;
                                                
				ELSE
					SIGNAL SQLSTATE '45000'
						SET MYSQL_ERRNO = 70,
							MESSAGE_TEXT = 'ERROR occured while creating subscriber account.';
					
                END IF;
			ELSE
            SIGNAL SQLSTATE '45000'
						SET MYSQL_ERRNO = 50,
							MESSAGE_TEXT = 'json parameter expected email and subscription array containing category IDs';
			END IF;
                
            
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `attendeeCheckIn` (IN `in_eventId` INT, IN `in_recieptId` INT)  MODIFIES SQL DATA
BEGIN
	
    DECLARE NESTED BOOLEAN DEFAULT true;
    DECLARE errorCount INT DEFAULT 0;
    DECLARE reciept_used CONDITION FOR 1062;
    DECLARE invalid_reciept CONDITION FOR 1452;
	
    
	   DECLARE EXIT HANDLER FOR invalid_reciept
			BEGIN
				SIGNAL SQLSTATE '45000'
					SET	MESSAGE_TEXT = "invalid reciept";
            END;
            
        DECLARE EXIT HANDLER FOR reciept_used
			BEGIN
				SIGNAL SQLSTATE '45000'
					SET	MESSAGE_TEXT = "the reciept has been used";
            END;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		GET DIAGNOSTICS errorCount = NUMBER;
        IF NESTED = false THEN ROLLBACK; END IF;
        RESIGNAL;
	END;
				
		IF isValidReciept(in_eventId, in_recieptId) = true THEN
        
                IF transactionCount() = 0 THEN
					START TRANSACTION;
                    SET NESTED = false;
				END IF;
    
    
			PREPARE check_in_prepare FROM
				'INSERT INTO `egate_db`.`checkIns`(`RECIEPT_ID`, `EVENT_ID`) VALUE(?, ?) 
                  ON DUPLICATE KEY UPDATE `status` = 1 ';
            
            SET @recieptId = in_recieptId;
            SET @eventId = in_eventId;
            
			EXECUTE check_in_prepare USING @recieptId, @eventId;
            
            IF errorCount = 0 AND NESTED = false THEN 
				COMMIT; 
                CALL getCheckin(in_eventId, in_recieptId);
			END IF;
	ELSE
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'provided reciept id doesnt belong to event ';
	END IF;
            
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `attendeeCheckOut` (IN `in_eventId` INT, IN `in_recieptId` INT)  MODIFIES SQL DATA
BEGIN
	
    DECLARE NESTED BOOLEAN DEFAULT true;
    DECLARE errorCount INT DEFAULT 0;
    DECLARE reciept_used CONDITION FOR 90;
    DECLARE invalid_reciept CONDITION FOR 1452;
	
    
	   DECLARE EXIT HANDLER FOR invalid_reciept
			BEGIN
				SIGNAL SQLSTATE '45000'
					SET MYSQL_ERRNO = 90,
						MESSAGE_TEXT = "invalid reciept";
            END;
            
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		GET DIAGNOSTICS errorCount = NUMBER;
        IF NESTED = false THEN ROLLBACK; END IF;
        RESIGNAL;
	END;
    
		IF isValidReciept(in_eventId, in_recieptId) = true THEN
				
			IF(SELECT COUNT(*) FROM checkIns WHERE RECIEPT_ID = in_recieptId ) != 1 THEN
			    SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 90,
					MESSAGE_TEXT = "invalid reciept id ";
			END IF;
                IF transactionCount() = 0 THEN
					START TRANSACTION;
                    SET NESTED = false;
				END IF;
    
    
			PREPARE check_out_prepare FROM
            'UPDATE `egate_db`.`checkIns` SET `status` = 0 , `last_check_out` = ? WHERE `RECIEPT_ID` = ?  AND `EVENT_ID` = ? ';
            
            SET @lastCheckOut = CURRENT_TIMESTAMP;
            SET @recieptId = in_recieptId;
            SET @eventId = in_eventId;
            
			EXECUTE check_out_prepare USING @lastCheckOut, @recieptId, @eventId;
            
            IF errorCount = 0 AND NESTED = false THEN COMMIT; END IF;
            CALL getCheckin(in_eventId, in_recieptId);
			ELSE
		SIGNAL SQLSTATE '45000'
			SET MYSQL_ERRNO = 45,
				MESSAGE_TEXT = 'provided reciept id doesnt belong to event ';
	END IF;
            
            
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `bookEvent` (IN `in_eventId` INT, IN `in_attendee` JSON, IN `in_ticket` JSON)  MODIFIES SQL DATA
BEGIN
	
		DECLARE NESTED BOOLEAN DEFAULT true;
        DECLARE errorCount INT DEFAULT 0;
        
       
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN 
				ROLLBACK; 
		
			END IF;
            RESIGNAL;						
        END;
        SELECT eventStatus(in_eventId) INTO @eventStatus;
        
			IF @eventStatus = 'OPEN'  OR @eventStatus = 'ACTIVE' THEN
						
				IF JSON_CONTAINS_PATH(in_attendee, 'all', '$.firstName', '$.lastName', '$.phoneNumber') AND 
						((NOT ISNULL(in_eventId)) AND (NOT ISNULL(in_ticket)))
				THEN
            
                        IF transactionCount() = 0 THEN
							START TRANSACTION;
                            SET NESTED = false;
						END IF;                  					
			CALL addEventAttendee(in_eventId, in_attendee, @attendeeId);
			
           SELECT @attendeeId;
            IF @attendeeId IS NOT NULL THEN
				CALL addEventBooking(@attendeeId, in_ticket);
			ELSE 
				SIGNAL SQLSTATE '45000'
					SET MYSQL_ERRNO = 3,
						MESSAGE_TEXT = 'error occured while creating event attendee';
			END IF;
            
                
                IF NESTED = false AND errorCount = 0 THEN				
                  SELECT @attendeeId AS 'reservationId';
                  COMMIT; 
                   
				END IF;
                
			ELSE
				SIGNAL SQLSTATE '45000'
					SET MYSQL_ERRNO = 3,
						MESSAGE_TEXT = 'json data missing required field values';
			END IF;
		ELSE 
        	SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = 50,
					MESSAGE_TEXT = 'Error trying to book event that is not open for booking';
        END IF;
            
          
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `cancelSubscription` (IN `in_subscription` JSON, OUT `out_result` BOOLEAN)  MODIFIES SQL DATA
BEGIN
		DECLARE NESTED BOOLEAN DEFAULT true;
        DECLARE errorCount INT DEFAULT 0;
        DECLARE subscriptions JSON;
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN ROLLBACK; END IF;
            RESIGNAL;
        END;
                
				IF transactionCount() = 0 THEN
					START TRANSACTION;
                    SET NESTED = false;
				END IF;
                
                
			IF JSON_CONTAINS_PATH(in_subscription, 'one', '$.email', '$.id')   THEN
            
				
                
                
                    PREPARE cancel_subscription_prepare FROM 
							'DELETE FROM `egate_db`.`subscriber` WHERE `e_mail` = ? OR `SUBSCRIBER_ID` = ? ';
					                     					
					SET @id = in_subscription->>'$.id';
					SET @email = in_subscription->>'$.email';
							
                            
					EXECUTE cancel_subscription_prepare USING @email, @id;
								IF ROW_COUNT() = 1 THEN
									SET out_result = true;
								ELSE
									SET out_result = false;
								END IF;
                                
                    DEALLOCATE PREPARE cancel_subscription_prepare;
                    
					IF errorCount = 0 AND NESTED = false THEN COMMIT; END IF;
             
			ELSE
            SIGNAL SQLSTATE '45000'
						SET MYSQL_ERRNO = 50,
							MESSAGE_TEXT = 'json parameter expected email or ID of subscription ';
			END IF;
                
            
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `changeEventStatus` (IN `in_eventId` INT, IN `in_status` VARCHAR(30))  MODIFIES SQL DATA
BEGIN
	DECLARE NESTED BOOLEAN DEFAULT true;
    DECLARE errorCount INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		GET DIAGNOSTICS errorCount = NUMBER;
        IF NESTED = false THEN ROLLBACK; END IF;
        RESIGNAL;
        
    END;
    
				IF transactionCount() = 0 THEN
					START TRANSACTION;
                    SET NESTED = false;
				END IF;
                
           
                PREPARE update_status_prepare FROM 
                'UPDATE `egat_db`.`event` SET `status` = ?
					WHERE `EVENT_ID` = ?';
                
            
					SET @newStatus = in_status;
                    SET @eventId = in_eventId;
					
					EXECUTE update_status_prepare USING @newStatus, @eventId;
					
					               
                
                IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
               
               DEALLOCATE PREPARE update_status_prepare;

                
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `changeSubscriptionMail` (IN `in_subscription` JSON, OUT `out_result` BOOLEAN)  MODIFIES SQL DATA
BEGIN
		DECLARE NESTED BOOLEAN DEFAULT true;
        DECLARE errorCount INT DEFAULT 0;
        DECLARE subscriptions JSON;
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN ROLLBACK; END IF;
            RESIGNAL;
        END;
                
				IF transactionCount() = 0 THEN
					START TRANSACTION;
                    SET NESTED = false;
				END IF;
                
                
			IF JSON_CONTAINS_PATH(in_subscription, 'one', '$.email', '$.id', '$.newMail')   THEN
            
				
                
                
                    PREPARE change_subscription_prepare FROM 
							'UPDATE `egate_db`.`subscriber` SET `e_mail` = ? WHERE `e_mail` = ? OR `SUBSCRIBER_ID` = ? ';
					                     					
					SET @id = in_subscription->>'$.id';
					SET @email = in_subscription->>'$.email';
                    SET @newMail = in_subscription->>'$.newMail';
							
                            
					EXECUTE change_subscription_prepare USING @newMail, @email, @id;
								IF ROW_COUNT() = 1 THEN
									SET out_result = true;
								ELSE
									SET out_result = false;
								END IF;
                                
                    DEALLOCATE PREPARE change_subscription_prepare;
                    
					IF errorCount = 0 AND NESTED = false THEN COMMIT; END IF;
             
			ELSE
            SIGNAL SQLSTATE '45000'
						SET MYSQL_ERRNO = 50,
							MESSAGE_TEXT = 'json parameter expected new email and (old email or ID of subscription) ';
			END IF;
                
            
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `createAccount` (IN `in_organizer` JSON)  MODIFIES SQL DATA
BEGIN
		
        DECLARE errorCount INT DEFAULT 0;
        DECLARE NESTED BOOLEAN DEFAULT true;
        
		DECLARE email_exists CONDITION FOR 1062;
        DECLARE EXIT HANDLER FOR email_exists
        BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN 
				ROLLBACK; 
                RESIGNAL SQLSTATE '45000'
					SET MESSAGE_TEXT = 'account already exists with this E-Mail address, please give another email address';
            END IF;
                   
        END;
        
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN ROLLBACK; END IF;
            RESIGNAL;
            
        END;
   
            IF transactionCount() = 0 THEN
				START TRANSACTION;
                SET NESTED = false;
			END IF;
            
            
            
				PREPARE organizer_registration_statement FROM	
								'INSERT INTO `egate_db`.`organizer` ( 
									`ORGANIZATION_ID`, `first_name`, `last_name`, `e_mail`, `password`
								) VALUES ( ?, ? , ? , ? , ?)'; 
		SET @organizerId = 0;
        SET @fname = in_organizer->>'$.firstName';
        SET @lname = in_organizer->>'$.lastName';
        SET @mail = in_organizer->>'$.email';
        SET @pass = in_organizer->>'$.password';
        
				EXECUTE organizer_registration_statement USING @organizerId, @fname, @lname, @mail, @pass;
			
            
				                  SET @newId = LAST_INSERT_ID();
            DEALLOCATE PREPARE organizer_registration_statement;
			
           IF NESTED = false AND errorCount = 0 THEN  
           SELECT @newId AS 'result';
           COMMIT; END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteBillingAddress` (IN `in_organizerId` INT, IN `in_accountInfo` JSON)  MODIFIES SQL DATA
BEGIN
	
		DECLARE errorCount INT DEFAULT 0;
        DECLARE NESTED BOOLEAN DEFAULT true;
      
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN 
			GET DIAGNOSTICS errorCount = NUMBER;
			IF NESTED = false THEN ROLLBACK; END IF;
            RESIGNAL;
		END;
        		
		SET @organizationId = getOrganizationId(in_organizerId);
        
        IF JSON_CONTAINS_PATH(in_accountInfo,'one', '$[*].billingId' ) 
			AND  @organizationId THEN
					IF transactionCount() = 0 THEN
						START TRANSACTION;
                        SET NESTED = false;
					END IF;

        
        
        PREPARE delete_billingAddress_prepare FROM 
			'DELETE FROM  `egate_db`.`billingaddress` 
            WHERE `BILLING_ID` = ? AND `ORGANIZATION_ID` = ? ';
				SET @counter = 0;
                
                WHILE @counter < JSON_LENGTH(in_accountInfo) DO
					SET @billingId = JSON_EXTRACT(in_accountInfo, CONCAT('$[', @counter , '].billingId'));					
					EXECUTE delete_billingAddress_prepare USING @billingId, @organizationId;
                    SET @counter = @counter + 1;
                END WHILE;
				
                
			IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
        
        DEALLOCATE PREPARE delete_billingAddress_prepare;
        
	ELSE	
		SIGNAL SQLSTATE '45100'
			SET MESSAGE_TEXT = 'JSON data passed for billing address missing required key (billingId) ';
	END IF;
					
 END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteComment` (IN `in_eventId` INT, IN `in_commentId` JSON)  MODIFIES SQL DATA
BEGIN
		
	DECLARE errorCount INT DEFAULT 0;
    DECLARE NESTED BOOLEAN DEFAULT false;    
      
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN ROLLBACK; END IF;
            RESIGNAL;                    
        END;
        
				IF transactionCount() = 0 THEN
					START TRANSACTION;
                    SET NESTED = true;
				END IF;
                
                IF NOT ISNULL(in_eventId) AND 
				NOT ISNULL(	in_commentId) 
				THEN
                
					PREPARE delete_comment_statement FROM 
                ' 	DELETE FROM `eventComments` WHERE COMMENT_ID = ? AND EVENT_ID = ? ';
				
					SET @eventId = in_eventId;
					SET @counter = 0;
                    WHILE @counter < JSON_LENGTH(in_commentId) DO
						
						SET @commentId = JSON_EXTRACT(in_commentId, CONCAT('$[', @counter, '].id'));
						
						EXECUTE delete_comment_statement USING @commentId,  @eventId;
							
						
                            SET @counter  = @counter + 1;
					
                    END WHILE;
					
                    IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
                    
						DEALLOCATE PREPARE delete_comment_statement;
						
				ELSE 
					SIGNAL SQLSTATE '45000'
						SET MYSQL_ERRNO = 5,
							MESSAGE_TEXT = 'JSON OBJECT passed or event id can not be null';
				END IF;
                                
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteEvent` (IN `in_organizerId` INT, IN `in_eventId` INT)  MODIFIES SQL DATA
BEGIN
	
    DECLARE errorCount INT DEFAULT 0;
    DECLARE NESTED BOOLEAN DEFAULT true;
    
    DECLARE CONTINUE HANDLER FOR SQLWARNING  BEGIN END;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		GET DIAGNOSTICS errorCount = NUMBER;
        IF NESTED = false THEN ROLLBACK; END IF;
        RESIGNAL;
    END;
    
	IF organizerEventExist(in_organizerId, in_eventId) = true THEN
			
            IF transactionCount() = 0  THEN
				START TRANSACTION;
                SET NESTED = false;
			END IF;            
		
			PREPARE delete_event_statement FROM 'DELETE FROM `event`  
												WHERE `EVENT_ID` = ? AND `ORGANIZER_ID` = ?';
				SET @counter = 0;
                SET @eventId = in_eventId;
                SET @organizerId = in_organizerId;
                
			EXECUTE delete_event_statement USING @eventId, @organizerId;
				
                    IF ROW_COUNT() != 1	THEN 
                    SET @message = CONCAT(' Sponsor with id ', @sponsorId ,  ' not deleted successfully');
						SIGNAL SQLSTATE '01000'
							SET MYSQL_ERRNO = 15,
								MESSAGE_TEXT = @message;
					END IF;
		
            
            IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;		
            
            		DEALLOCATE PREPARE delete_event_statement;
    ELSE
		SET @message = CONCAT("event with id ", in_eventId, " and organizer id ", in_organizerId , "does not exist ");
		SIGNAL SQLSTATE '45000' 
			SET MYSQL_ERRNO = 11,	
				MESSAGE_TEXT = @message;
    END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteEventAttendee` (IN `in_attendee` JSON, OUT `out_result` INT)  MODIFIES SQL DATA
BEGIN

		DECLARE NESTED BOOLEAN DEFAULT true;
        DECLARE errorCount INT DEFAULT 0;
        
       
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN 
				ROLLBACK; 
				SET out_result = false; 
			END IF;
            RESIGNAL;						
        END;
						
			IF JSON_CONTAINS_PATH(in_attendee, 'all', '$.eventId', '$.id') THEN
            
                        IF transactionCount() = 0 THEN
							START TRANSACTION;
                            SET NESTED = false;
						END IF;
                        
            	PREPARE attendee_delete_statement FROM
							'DELETE FROM `eventAttendee`
						     WHERE `EVENT_ID` = ? AND ATTENDEE_ID = ? ';
								                     
	        SET @guestId = in_attendee->>'$.id';
            SET @eventId = in_attendee->>'$.eventId';
            SET @serviceProvider = in_attendee->>'$.serviceProvider';
            
            EXECUTE attendee_delete_statement USING  @eventId, @guestId;
                   
            IF NESTED = false AND errorCount = 0 THEN 
				COMMIT; 
				SET out_result = true;
             END IF;
            
            DEALLOCATE PREPARE attendee_delete_statement;
            
            
            
		ELSE
				SIGNAL SQLSTATE '45000' 
            SET MYSQL_ERRNO = 1,	
			MESSAGE_TEXT = 'json data passed for event attendee missing one of the required keys required keys 
								eventId, id for delete ';
        
        END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteEventBooking` (IN `in_reservationId` INT, IN `in_bookingId` JSON)  MODIFIES SQL DATA
BEGIN

		DECLARE NESTED BOOLEAN DEFAULT true;
        DECLARE errorCount INT DEFAULT 0;
        
       
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN 
				ROLLBACK; 
		
			END IF;
            RESIGNAL;						
        END;
        
					
				IF JSON_CONTAINS_PATH(in_bookingId, 'one', '$[*].bookingId') AND 	(NOT ISNULL(in_reservationId))
				THEN
            
                        IF transactionCount() = 0 THEN
							START TRANSACTION;
                            SET NESTED = false;
						END IF;
				
                PREPARE delete_booking_prepare FROM
                'DELETE FROM `egate_db`.`eventBooking` WHERE `BOOKING_ID` = ? AND `ATTENDEE_ID` = ? ';
                
                SET @attendeeId = in_reservationId;
				SET @counter = 0;
				WHILE @counter < JSON_LENGTH(in_bookingId) DO
                
					SET @bookingId = JSON_UNQUOTE(JSON_EXTRACT(in_bookingId, CONCAT('$[', @counter, '].bookingId')));
                    
                    EXECUTE delete_booking_prepare USING @bookingId, @attendeeId;
					
                    SET @counter = @counter + 1;
                    
                END WHILE;

				IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
                DEALLOCATE PREPARE delete_booking_prepare;
		ELSE 
        SIGNAL SQLSTATE '45000'
			SET MYSQL_ERRNO = 102,
				MESSAGE_TEXT = 'JSON array for booking id missing required key bookingId ';
	END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteEventCategory` (IN `in_category` JSON)  MODIFIES SQL DATA
BEGIN
	DECLARE NESTED BOOLEAN DEFAULT true;
    DECLARE errorCount INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		GET DIAGNOSTICS errorCount = NUMBER;
        IF NESTED = false THEN ROLLBACK; END IF;
        RESIGNAL;
        
    END;
    
				IF transactionCount() = 0 THEN
					START TRANSACTION;
                    SET NESTED = false;
				END IF;
                
                
			IF JSON_CONTAINS_PATH(in_category, 'one', '$[*].category' , '$[*].id') THEN
            
				SET @counter = 0;
                
                PREPARE delete_category_prepare FROM 
                'DELETE FROM `egat_db`.`eventCategory`
					WHERE `CATEGORY_ID` = ? OR `category_name` = ?';
                
                WHILE @counter < JSON_LENGTH(in_category) DO
                
					SET @category = JSON_EXTRACT(in_category, CONCAT('$[', @counter, '].category'));
                    SET @id = JSON_EXTRACT(in_category, CONCAT('$[', @counter, '].id'));
					
					EXECUTE delete_category_prepare USING  @id, @category;
					
					SET @counter = @counter + 1;
				
                END WHILE;
                
                
                IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
               
               DEALLOCATE PREPARE delete_category_prepare;
		ELSE
			SIGNAL SQLSTATE '45000' 
				SET MYSQL_ERRNO = 1,	
					MESSAGE_TEXT = 'json data passed for event category missing required  
								field (category or id) ';
        
        
        END IF;
                
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteEventGuest` (IN `in_eventId` INT, IN `in_guest` JSON)  MODIFIES SQL DATA
BEGIN
	
    
    DECLARE errorCount INT DEFAULT 0;
    DECLARE NESTED BOOLEAN DEFAULT true;
    
     DECLARE CONTINUE HANDLER FOR SQLWARNING
     BEGIN END;
     
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		GET DIAGNOSTICS errorCount = NUMBER;
        IF NESTED = false THEN ROLLBACK; END IF;
        RESIGNAL;
    END;
    			
            
	IF JSON_CONTAINS_PATH(in_guest, 'all',  '$[*].guestId') THEN
            
            IF transactionCount() = 0  THEN
				START TRANSACTION;
                SET NESTED = false;
			END IF;
            
			
            
			PREPARE delete_guest_statement FROM 'DELETE FROM `eventGuest`  
												WHERE `EVENT_ID` = ? AND `GUEST_ID` = ?';
				SET @counter = 0;
                SET @eventId = in_eventId;
                
            WHILE @counter  < JSON_LENGTH(in_guest)	DO
				SET @guestId = JSON_EXTRACT(in_guest, CONCAT('$[', @counter, '].guestId'));
				
                    EXECUTE delete_guest_statement USING @eventId, @guestId;
                                  												
                SET @counter = @counter + 1;
                IF @guestId IS NULL THEN
						SIGNAL SQLSTATE '45000' 
							SET MYSQL_ERRNO = 11,	
								MESSAGE_TEXT =  " id value can not be null ";
				END IF;
			
            END WHILE;
            
			DEALLOCATE PREPARE delete_guest_statement;
            
            IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
            
            
		
            
    ELSE
		SIGNAL SQLSTATE '45000' 
			SET MYSQL_ERRNO = 11,	
				MESSAGE_TEXT =  "JSON array missing required id key ";
    END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteEventSponsor` (IN `in_eventId` INT, IN `in_sponsor` JSON)  MODIFIES SQL DATA
BEGIN
	
    DECLARE errorCount INT DEFAULT 0;
    DECLARE NESTED BOOLEAN DEFAULT true;
    
    DECLARE CONTINUE HANDLER FOR SQLWARNING  BEGIN END;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		GET DIAGNOSTICS errorCount = NUMBER;
        IF NESTED = false THEN ROLLBACK; END IF;
        RESIGNAL;
    END;
    
	IF JSON_CONTAINS_PATH(in_sponsor, 'all', '$[*].sponsorId') THEN
			
            IF transactionCount() = 0  THEN
				START TRANSACTION;
                SET NESTED = false;
			END IF;
            
	
			PREPARE delete_sponsor_statement FROM 'DELETE FROM `eventSponsor`  
												WHERE `EVENT_ID` = ? AND `sponsor_ID` = ?';
				SET @counter = 0;
                SET @eventId = in_eventId;
                
            WHILE @counter < JSON_LENGTH(in_sponsor)	DO
				SET @sponsorId = JSON_EXTRACT(in_sponsor, CONCAT('$[', @counter, '].sponsorId'));
					
                    IF @sponsorId IS NULL	THEN 
                    
						SIGNAL SQLSTATE '01000'
							SET MYSQL_ERRNO = 15,
								MESSAGE_TEXT = "one of the sponsorId values are null ";
					END IF;												
                    EXECUTE delete_sponsor_statement USING @eventId, @sponsorId;
                    
                    		
                SET @counter = @counter + 1;
			END WHILE;
            
			DEALLOCATE PREPARE delete_sponsor_statement;
            
            IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
	
            
    ELSE
	
		SIGNAL SQLSTATE '45000' 
			SET MYSQL_ERRNO = 11,	
				MESSAGE_TEXT = "JSON array passed required sponsorId key missing ";
    END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteEventTicket` (IN `in_organizerId` INT, IN `in_eventId` INT, IN `in_ticketId` JSON)  MODIFIES SQL DATA
BEGIN

    DECLARE errorCount INT DEFAULT 0;
    DECLARE NESTED BOOLEAN DEFAULT true;
    
    DECLARE CONTINUE HANDLER FOR SQLWARNING  BEGIN END;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		GET DIAGNOSTICS errorCount = NUMBER;
        IF NESTED = false THEN ROLLBACK; END IF;
        RESIGNAL;
    END;
    
	IF organizerEventExist(in_organizerId, in_eventId) = true THEN
		
        IF  eventTicketCount(in_eventId) <= JSON_LENGTH(in_ticketId)	THEN
			            
            IF transactionCount() = 0  THEN
				START TRANSACTION;
                SET NESTED = false;
			END IF;            
		
			PREPARE delete_ticket_statement FROM 'DELETE FROM `eventTicket`  
												WHERE `EVENT_ID` = ? AND `TICKET_ID` = ? ';
				SET @counter = 0;
                SET @eventId = 0;
                SET @eventId = in_eventId;
				
                WHILE ( @counter < JSON_LENGTH(in_ticketId ))	DO
                
					SET @ticketId = JSON_EXTRACT(in_ticketId, CONCAT('$[', @counter, '].ticketId'));
                    
					EXECUTE delete_ticket_statement USING @eventId, @ticketId;
						
                        SET @counter = @counter + 1;
						
                        
				END WHILE;
		
            
            IF NESTED = false AND errorCount = 0 THEN 	COMMIT; 	END IF;		
            
            		DEALLOCATE PREPARE delete_ticket_statement;
		ELSE 		
			SIGNAL SQLSTATE '45000' 
			SET MYSQL_ERRNO = 11,	
				MESSAGE_TEXT = 'attempting to delete all tickets of event, event should have 
								atleast one ticket at all time.';
        END IF;
    ELSE
		SET @message = CONCAT("event with id ", in_eventId, " and organizer id ", in_organizerId , "does not exist ");
		SIGNAL SQLSTATE '45000' 
			SET MYSQL_ERRNO = 11,	
				MESSAGE_TEXT = @message;
    END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteOrganization` (IN `in_organization` JSON)  MODIFIES SQL DATA
BEGIN
		
	DECLARE errorCount INT DEFAULT 0;
    DECLARE NESTED BOOLEAN DEFAULT true;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		GET DIAGNOSTICS errorCount = NUMBER;
        IF NESTED = false THEN ROLLBACK; END IF;
        
        RESIGNAL;
    END;
    
	IF JSON_CONTAINS_PATH(in_organization, 'all', in_organization->>'$.organizationId', in_organization->>'$.organizerId') THEN
    
    IF ( isValidInt(in_organization->>'$.organizerId') AND isValidInt(in_organization->>'$.organizationId') ) AND 
		organizationExist(in_organization->>'$.organizerId' , in_organization->>'$.organizerId') = true
		 
	THEN
			
							
                            IF transactionCount() = 0 THEN
								START TRANSACTION;
                                SET NESTED = false;
							END IF;
                            
                            PREPARE organization_delete_statement FROM
                            'DELETE FROM `organization`  
							  WHERE `ORGANIZATION_ID` = ? ';
                            
                            SET @organizationId =  in_organization->>'$.organizationId';
                            
                            
                            EXECUTE organization_delete_statement USING 	@organizationId;
							
                            IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
                            
                            DEALLOCATE PREPARE organization_delete_statement;
		
		ELSE
        	SIGNAL SQLSTATE '45000' 
			SET MESSAGE_TEXT = 'organization by the provided orgnizer id and organization id does not exist  ',
			MYSQL_ERRNO = 1;
	
        END IF;
		ELSE
			SIGNAL SQLSTATE '45000' 
			SET MESSAGE_TEXT = ' JSON data missing required key name pair (organizerId and organizationId) ',
			MYSQL_ERRNO = 1;
	
	
    END IF;
	
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteOrganizationAddress` (IN `in_organizerId` INT, IN `in_address` JSON)  MODIFIES SQL DATA
BEGIN
	
		DECLARE errorCount INT DEFAULT 0;
        DECLARE NESTED BOOLEAN DEFAULT true;
        DECLARE address JSON;
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN 
			GET DIAGNOSTICS errorCount = NUMBER;
			IF NESTED = false THEN ROLLBACK; END IF;
            RESIGNAL;
		END;
		
		SET @organizationId = getOrganizationId(in_organizerId);
		
        IF JSON_CONTAINS_PATH(in_address,'one','$[*].addressId' ) 
			AND NOT ISNULL(@organizationId) THEN
					IF transactionCount() = 0 THEN
						START TRANSACTION;
                        SET NESTED = false;
					END IF;

        
        
        PREPARE delete_organizationAddress_prepare FROM 
			'DELETE FROM `egate_db`.`organization_address`  				
                WHERE `ORG_ADD_ID` = ? AND `ORGANIZATION_ID` = ?';
                
				
                SET @counter = 0;
                    
				WHILE @counter  < JSON_LENGTH(in_address)DO
					SET address = JSON_EXTRACT(in_address, CONCAT('$[',@counter ,']'));
				SET @id = address->>'$.addressId';
		
                      
				EXECUTE delete_organizationAddress_prepare USING   @id, @organizationId;
				SET @counter = @counter + 1;
			END WHILE;
			
            IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
        
        DEALLOCATE PREPARE delete_organizationAddress_prepare;
        
	ELSE	
		SIGNAL SQLSTATE '45100'
			SET MESSAGE_TEXT = 'JSON data passed for address delete missing required key (addressId) ';
	END IF;
					
 END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteSubscription` (IN `in_subscription` JSON, OUT `out_subscriptionId` INT)  MODIFIES SQL DATA
BEGIN
		DECLARE NESTED BOOLEAN DEFAULT true;
        DECLARE errorCount INT DEFAULT 0;
        DECLARE subscriptions JSON;
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN ROLLBACK; END IF;
            RESIGNAL;
        END;
                
				IF transactionCount() = 0 THEN
					START TRANSACTION;
                    SET NESTED = false;
				END IF;
                
                
			IF JSON_CONTAINS_PATH(in_subscription, 'all', '$[*].subscriberId' ,'$[*].categoryId') OR JSON_CONTAINS_PATH(in_subscription, 'all', '$[*].subscrptionId')  THEN
            
				
                
                
                    PREPARE delete_subscription_prepare FROM 
                    'DELETE FROM subscription WHERE (`SUBSCRIBER_ID` = ? AND `CATEGORY_ID` = ?) OR SUBSCRIPTION_ID = ?';
						SET @counter = 0;
						
                        
                        WHILE @counter < JSON_LENGTH( in_subscription ) DO
							
							SET @categoryId = JSON_EXTRACT(in_subscription, CONCAT('$[',@counter,'].categoryId'));
                            SET @subscriberId = JSON_EXTRACT(in_subscription, CONCAT('$[',@counter,'].subscriberId'));
							SET @subscriptionId = JSON_EXTRACT(in_subscription, CONCAT('$[',@counter,'].subscriptionId'));
                            
                            EXECUTE delete_subscription_prepare USING @subscriberId, @categoryId, @subscriptionId;
                            
                            SET @counter = @counter + 1;
					END WHILE;
                    DEALLOCATE PREPARE delete_subscription_prepare;
                    
						IF errorCount = 0 AND NESTED = false THEN COMMIT; END IF;
             
			ELSE
            SIGNAL SQLSTATE '45000'
						SET MYSQL_ERRNO = 50,
							MESSAGE_TEXT = 'json parameter expected email and subscription array containing category IDs';
			END IF;
                
            
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getActiveEvents` (IN `in_limit` INT)  MODIFIES SQL DATA
BEGIN
	
		PREPARE get_activeEvent_statement FROM
			"SELECT `event`.`EVENT_ID` AS 'eventId', `event`.`ORGANIZER_ID` AS 'organizerId',  `event`.`name` AS 'eventName',`venue`, `event`.`discription` AS 'adoutEvent', 
				`eventcategory`.`category_name` AS 'eventCategory', `event`.`start_date` AS 'startDate', `event`.`start_time` AS 'startTime',
                `event`.`end_date` AS 'endDate', `event`.`end_time` AS 'endTime', `longitude`, `latitude`,  `location`,
                CONCAT(`event`.`sub_city`,', ', `event`.`city`, ' ', `event`.`country`) AS 'address', `event`.`picture` AS 'eventImage',
                `event`.`status`, `event`.`created_on` AS 'createdOn', `event`.`last_updated` AS 'lastUpdated'
		FROM `event`
        LEFT JOIN `eventCategory` USING(`CATEGORY_ID`)
        WHERE `status` = 'OPEN'
        LIMIT ?";
			
            SET @getLimit = in_limit;
		
		EXECUTE get_activeEvent_statement USING @getLimit ;
        
        DEALLOCATE PREPARE get_activeEvent_statement;
        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getAttendeeReservation` (IN `in_reservationId` INT)  READS SQL DATA
BEGIN
		
        PREPARE get_reservation_prepare FROM		
        "SELECT `eventBooking`.`ATTENDEE_ID` AS 'reservationId', `eventbooking`.`BOOKING_ID` AS 'bookingId', `eventBooking`.`TICKET_ID` AS 'ticketId',
			(CASE WHEN `eventTicket`.`price` = 0 THEN 'FREE' ELSE `eventTicket`.`price` END) AS 'ticketPrice',  `eventBooking`.`status`, 
            `eventBooking`.`booked_on` AS 'bookedOn'
		FROM `egate_db`.`eventBooking`
        LEFT JOIN `egate_db`.`eventTicket` USING(`TICKET_ID`)
        WHERE `eventBooking`.`ATTENDEE_ID` = ? ";
        
        SET @attendeeId = in_reservationId;
        
        EXECUTE get_reservation_prepare USING @attendeeId;
        
        DEALLOCATE PREPARE get_reservation_prepare;
        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getCheckIn` (IN `in_eventId` INT, IN `in_recieptId` INT)  READS SQL DATA
BEGIN
		SELECT * FROM `egate_db`.`eventCheckIns`
        WHERE `eventId` = in_eventId AND `recieptId` = in_recieptId;
        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getClosedEvents` (IN `in_limit` INT)  MODIFIES SQL DATA
BEGIN
	
		PREPARE get_closedEvent_statement FROM
			"SELECT `event`.`EVENT_ID` AS 'eventId', `event`.`ORGANIZER_ID` AS 'organizerId',  `event`.`name` AS 'eventName',`venue`, `event`.`discription` AS 'adoutEvent', 
				`eventcategory`.`category_name` AS 'eventCategory', `event`.`start_date` AS 'startDate', `event`.`start_time` AS 'startTime',
                `event`.`end_date` AS 'endDate', `event`.`end_time` AS 'endTime', `longitude`, `latitude`,  `location`,
                CONCAT(`event`.`sub_city`,', ', `event`.`city`, ' ', `event`.`country`) AS 'address', `event`.`picture` AS 'eventImage',
                `event`.`status`, `event`.`created_on` AS 'createdOn', `event`.`last_updated` AS 'lastUpdated'
		FROM `event`
        LEFT JOIN `eventCategory` USIN(`CATEGORY_ID`)
        WHERE `status` = 'CLOSED'
        
        LIMIT ?";
			
            SET @getLimit = in_limit;
		
		EXECUTE get_closedEvent_statement USING @getLimit ;
        
        DEALLOCATE PREPARE get_closedEvent_statement;
        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getComment` (IN `in_commentId` INT)  READS SQL DATA
BEGIN
	
		PREPARE get_comment_statement FROM
			"SELECT `eventComment`.`EVENT_ID` AS 'eventId', `eventComment`.`COMMENT_ID` AS 'commentId', 
            `eventComment`.`name` AS `commenter`, `eventComment`.`comment`, `eventComment`.`commented_on` AS 'commentedOn'                
					FROM `egate_db`.`eventComment`
					WHERE `eventComment`.`COMMENT_ID` = ?";
			SET @commentId = in_commentId;
		EXECUTE get_comment_statement USING @commentId ;
        
        DEALLOCATE PREPARE get_comment_statement;
        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getDraftEvents` (IN `in_limit` INT)  MODIFIES SQL DATA
BEGIN
	
		PREPARE get_draftEvent_statement FROM
			"SELECT `event`.`EVENT_ID` AS 'eventId', `event`.`ORGANIZER_ID` AS 'organizerId',  `event`.`name` AS 'eventName',`venue`, `event`.`discription` AS 'adoutEvent', 
				`eventcategory`.`category_name` AS 'eventCategory', `event`.`start_date` AS 'startDate', `event`.`start_time` AS 'startTime',
                `event`.`end_date` AS 'endDate', `event`.`end_time` AS 'endTime', `longitude`, `latitude`,  `location`,
                CONCAT(`event`.`sub_city`,', ', `event`.`city`, ' ', `event`.`country`) AS 'address', `event`.`picture` AS 'eventImage',
                `event`.`status`, `event`.`created_on` AS 'createdOn', `event`.`last_updated` AS 'lastUpdated'
		FROM `event`
        LEFT JOIN `eventCategory` USING(`CATEGORY_ID`)        
        WHERE `status` = 'DRAFT'
        LIMIT ?";
			
            SET @getLimit = in_limit;
		
		EXECUTE get_draftEvent_statement USING @getLimit ;
        
        DEALLOCATE PREPARE get_draftEvent_statement;
        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getEventBookings` (IN `in_eventId` INT)  READS SQL DATA
BEGIN
	
		PREPARE get_eventBookings_statement FROM
			"SELECT ANY_VALUE(eventAttendee.EVENT_ID) AS 'eventId', ANY_VALUE(eventBooking.ATTENDEE_ID) AS 'reservationId', 
				ANY_VALUE(eventBooking.BOOKING_ID) AS 'bookingId', ANY_VALUE(eventBooking.TICKET_ID) AS ticketId,
				ANY_VALUE(eventAttendee.first_name) AS 'firstName', ANY_VALUE(eventAttendee.last_name) AS 'lastName',
				ANY_VALUE(eventAttendee.phone) AS 'phoneNumber',ANY_VALUE(eventAttendee.service_provider) AS 'serviceProvider', 
				SUM(ANY_VALUE(eventTicket.price)) AS 'totalPrice', ANY_VALUE(eventBooking.booked_on) AS 'bookedOn'
			FROM `egate_db`.`eventBooking`
				LEFT JOIN `egate_db`.`eventAttendee` ON eventBooking.ATTENDEE_ID = eventAttendee.ATTENDEE_ID 
				LEFT JOIN `egate_db`.eventTicket ON  eventBooking.TICKET_ID = eventTicket.TICKET_ID 
			WHERE `eventAttendee`.`EVENT_ID` = ?
			GROUP BY eventBooking.ATTENDEE_ID,  eventBooking.TICKET_ID  ";
			
		SET @eventId = in_eventId;
		EXECUTE get_eventBookings_statement USING @eventId ;
        
        DEALLOCATE PREPARE get_eventBookings_statement;
        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getEventBookingStat` (IN `in_organizerId` INT, IN `in_eventId` INT)  BEGIN
		SELECT * 
        FROM `egate_db`.`eventticketstatstics`
        WHERE `eventId` = in_eventId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getEventCategory` (`in_category` INT, `in_limit` INT)  READS SQL DATA
BEGIN
		SELECT `EVENT_ID` AS 'eventId' , `ORGANIZER_ID` AS 'organizerId', `event`.`name` AS 'eventName' , `venue`,
				`eventCategory`.`category_name` AS 'category', `event`.`discription` AS 'aboutEvent', `event`.`picture` AS 'eventImage', `start_date` AS 'startDate', 
                `start_time` AS 'startTime', `end_date` AS 'endDate', `end_time` AS 'endTime' , `location`, CONCAT(`sub_city`, ", ", `city`, " ", `country`) AS 'address',
                COUNT(`TICKET_ID`) AS 'totalTicket', MAX(`price`) AS 'maxPrice', MIN(`price`) AS 'minPrice', `event`.`status`
                
		FROM `event`
        LEFT JOIN `eventCategory` USING(`CATEGORY_ID`)
        LEFT JOIN `eventTicket` USING(`EVENT_ID`)
        WHERE `CATEGORY_ID` = in_category AND (`event`.`status` = 'OPEN' OR `event`.`status` = 'ACTIVE')
        GROUP BY `EVENT_ID`
        LIMIT in_limit;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getEventCheckIns` (IN `in_eventId` INT)  READS SQL DATA
BEGIN
		SELECT * FROM `egate_db`.`eventCheckIns`
        WHERE `eventId` = in_eventId;
        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getEventComments` (IN `in_eventId` INT)  READS SQL DATA
BEGIN
	
		PREPARE get_eventComment_statement FROM
			"SELECT `eventComment`.`EVENT_ID` AS 'eventId', `eventComment`.`COMMENT_ID` AS 'commentId', 
            `eventComment`.`name` AS `commenter`, `eventComment`.`comment`, `eventComment`.`commented_on` AS 'commentedOn'                
					FROM `egate_db`.`eventComment`
					WHERE `eventComment`.`EVENT_ID` = ?";
			SET @eventId = in_eventId;
		EXECUTE get_eventComment_statement USING @eventId ;
        
        DEALLOCATE PREPARE get_eventComment_statement;
        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getEventDetail` (IN `in_eventId` INT)  READS SQL DATA
BEGIN

	UPDATE `egate_db`.`event` SET `total_view` = `total_view` + 1 WHERE `EVENT_ID` = in_eventId;
	SELECT  `event`.`EVENT_ID` AS 'eventId' , `organizer`.`ORGANIZER_ID` AS 'organizerId', `organization`.`name` AS 'organizationName',
			`social`, 	`mobile_number` AS 'mobileNumber', `office_number` AS 'officeNumber',  `po_num` AS 'postAddress', 
			`organization`.`logo` AS 'organizationLogo', `organization`.`info` AS 'aboutOrganization',	CONCAT(`organizer`.`first_name`, " ", 
            `organizer`.`last_name` ) AS 'organizerName',  `eventCategory`.`category_name` AS 'eventCategory',
            `e_mail` AS 'organizerEmail',  `organizer`.`picture` AS 'organizerImage', `organizer`.`bio` AS 'aboutOrganizer',`event`.`name` AS 'eventName' , `venue`,	
            `event`.`discription` AS 'aboutEvent', `event`.`picture` AS 'eventImage', `start_date` AS 'startDate', `start_time` AS 'startTime', 
            `end_date` AS 'endDate', `end_time` AS 'endTime' , `location`, CONCAT(`sub_city`, ", ", `city`, " ", `country`) AS 'address', `event`.`longitude`, `event`.`latitude`, `event`.`status`AS 'eventStatus'
			
          
		FROM `egate_db`.`event`
			LEFT JOIN `egate_db`.`organizer` USING(`ORGANIZER_ID`)
			LEFT JOIN  `egate_db`.`organization` USING(`ORGANIZATION_ID`)        
			LEFT JOIN `egate_db`.`eventCategory` USING(`CATEGORY_ID`)
        WHERE `event`.`EVENT_ID` = in_eventId;       
        
       SELECT `TICKET_ID` AS 'ticketId', `eventTicket`.`name` AS 'ticketName',  `eventTicket`.`type` AS 'ticketType', `price` AS 'ticketPrice', `quantity` AS 'ticketQuantity', `available` AS 'availableTicket', 
            `eventTicket`.`discription` AS 'aboutTicket', `sale_start` AS 'saleStart', `sale_end` AS 'saleEnd' , `eventTicket`.`status` AS 'ticketStatus',
		(COUNT(eventBooking.BOOKING_ID) - COUNT(reciept.RECIEPT_ID))  AS 'pendingBooking' , COUNT(reciept.RECIEPT_ID) AS 'confirmedBooking'
		FROM `egate_db`.`eventTicket`
        LEFT JOIN `eventBooking` USING(`TICKET_ID`) 
        LEFT JOIN `reciept` USING(`BOOKING_ID`) 
        WHERE `eventTicket`.`EVENT_ID` = in_eventId
        GROUP BY TICKET_ID ;
		
		
        SELECT `eventGuest`.`GUEST_ID` AS 'guestId', 
				CONCAT(`eventGuest`.`first_name`, " ", `eventGuest`.`last_name`) AS 'guestName',  `eventGuest`.`aka_name` AS 'akaName',
                    `eventGuest`.`title` AS 'guestTitle', `eventGuest`.`bio` AS 'aboutGuest', `eventGuest`.`image` AS 'guestImage'				
		FROM `egate_db`.`eventGuest`
        WHERE `eventGuest`.`EVENT_ID` = in_eventId;
        
        SELECT `eventSponsor`.`SPONSOR_ID` AS 'sponsorId',
			`eventSponsor`.`name` AS 'sponsorName', `eventSponsor`.`image` AS 'sponsorImage', `eventSponsor`.`aboutSponsor` 
		FROM `egate_db`.`eventSponsor`
        WHERE `eventSponsor`.`EVENT_ID` = in_eventId;
        
        SELECT `eventComment`.`COMMENT_ID` AS 'commentId', `eventComment`.`name` AS 'commenter', `eventComment`.`comment` AS 'comment',
				`eventComment`.`commented_on` AS 'commentedOn', `eventComment`.`last_updated` AS 'updatedOn'
		FROM `egate_db`.`eventComment`
        WHERE `eventComment`.`EVENT_ID` = in_eventId;  
        
        
        
        
        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getEventEndDateTime` (IN `in_eventId` INT)  READS SQL DATA
BEGIN
	
		PREPARE get_eventEndDateTime_statement FROM
			"SELECT `event`.`EVENT_ID` AS 'eventId', `event`.`end_date` AS 'endDate', `event`.`end_Time` AS 'endTime'                
					FROM `egate_db`.`event`
					WHERE `event`.`EVENT_ID` = ?";
			SET @eventId = in_eventId;
		EXECUTE get_eventEndDateTime_statement USING @eventId ;
        
        DEALLOCATE PREPARE get_eventEndDateTime_statement;
        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getEventGeneralInfo` (IN `in_eventId` INT)  BEGIN		
        SELECT `event`.`EVENT_ID` AS 'eventId', `event`.`ORGANIZER_ID` AS 'organizerId',  `event`.`name` AS 'eventName',`venue`, `event`.`discription` AS 'adoutEvent', 
				`eventcategory`.`category_name` AS 'eventCategory', `event`.`start_date` AS 'startDate', `event`.`start_time` AS 'startTime',
                `event`.`end_date` AS 'endDate', `event`.`end_time` AS 'endTime', `longitude`, `latitude`,  `location`,
			`event`.`sub_city` AS 'subCity', `event`.`city`,  `event`.`country` , `event`.`picture` AS 'eventImage',
                `event`.`status`, `event`.`created_on` AS 'createdOn', `event`.`last_updated` AS 'lastUpdated'
		FROM `event`
        LEFT JOIN `eventCategory` USING(`CATEGORY_ID`)
        WHERE `EVENT_ID` = in_eventId;
       

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getEventGuest` (IN `in_eventId` INT)  READS SQL DATA
BEGIN
       PREPARE get_eventGuest_statement FROM
       "SELECT `eventGuest`.`GUEST_ID` AS 'guestId', `eventGuest`.`first_name` AS 'firstName', `eventGuest`.`last_name` AS 'lastName',
       `eventGuest`.`aka_name` AS 'nickName' , `eventGuest`.`title`, `eventGuest`.`bio` AS 'aboutGuest',`eventGuest`.`image` AS 'guestImage', 
       `eventGuest`.`date_added` AS 'dateAdded', `eventGuest`.`last_updated` AS 'lastUpdated'
				FROM `egate_db`.`eventGuest`
				WHERE `eventGuest`.`EVENT_ID` = ?";
       
       SET @eventId = in_eventId;
       
       EXECUTE get_eventGuest_statement USING @eventId;
       
       DEALLOCATE PREPARE get_eventGuest_statement;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getEventOrganizerId` (IN `in_eventId` INT)  READS SQL DATA
BEGIN
	
		PREPARE get_organizerId_statement FROM
			"SELECT `ORGANIZER_ID` AS 'organizerId'                
					FROM `event`
					WHERE `EVENT_ID` = ?";
			SET @eventId = in_eventId;
		EXECUTE get_organizerId_statement USING @eventId ;
        
        DEALLOCATE PREPARE get_organizer_statement;
        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getEventsBasic` (IN `in_limit` INT)  READS SQL DATA
BEGIN

		SELECT `EVENT_ID` AS 'eventId' , `ORGANIZER_ID` AS 'organizerId', `event`.`name` AS 'eventName' , `venue`,
				`eventCategory`.`category_name` AS 'category', `event`.`discription` AS 'aboutEvent', `event`.`picture` AS 'eventImage', `start_date` AS 'startDate', 
                `start_time` AS 'startTime', `end_date` AS 'endDate', `end_time` AS 'endTime' , `location`, CONCAT(`sub_city`, ", ", `city`, " ", `country`) AS 'address',
                COUNT(`TICKET_ID`) AS 'totalTicket', MAX(`price`) AS 'maxPrice', MIN(`price`) AS 'minPrice', `event`.`status`
                
		FROM `event`
        LEFT JOIN `eventCategory` USING(`CATEGORY_ID`)
        LEFT JOIN `eventTicket` USING(`EVENT_ID`)
        WHERE `event`.`status` = 'OPEN' OR `event`.`status` = 'ACTIVE'
        GROUP BY `EVENT_ID`
        LIMIT in_limit;
        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getEventSchedule` (IN `in_eventId` INT)  READS SQL DATA
BEGIN
	
		PREPARE get_eventSchedule_statement FROM
			"SELECT `EVENT_ID` AS 'eventId', `start_date` AS 'startDate', `start_time` AS `startTime`, `end_date` AS 'endDate', `end_Time` AS 'endTime'                
					FROM `event`
					WHERE `EVENT_ID` = ?";
			SET @eventId = in_eventId;
		EXECUTE get_eventSchedule_statement USING @eventId ;
        
        DEALLOCATE PREPARE get_eventSchedule_statement;
        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getEventSponsor` (IN `in_eventId` INT)  READS SQL DATA
BEGIN
       PREPARE get_eventSponsor_statement FROM
       "SELECT `eventSponsor`.`SPONSOR_ID` AS 'sponsorId', `eventSponsor`.`name` AS 'sponsorName', `eventSponsor`.`image` AS 'sponsorImage', 
       `eventSponsor`.`aboutSponsor`, 	`eventSponsor`.`date_added` AS 'dateAdded', `eventSponsor`.`last_updated` AS 'lastUpdated'
				FROM `egate_db`.`eventSponsor`
				WHERE `eventSponsor`.`EVENT_ID` = ?";
       
       SET @eventId = in_eventId;
	
       EXECUTE get_eventSponsor_statement USING @eventId;
       
       DEALLOCATE PREPARE get_eventSponsor_statement;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getEventStartDateTime` (IN `in_eventId` INT)  READS SQL DATA
BEGIN
	
		PREPARE get_eventStartDatetime_statement FROM
			"SELECT `EVENT_ID` AS 'eventId', `start_date` AS 'startDate', `start_time` AS `startTime`
					FROM `event`
					WHERE `EVENT_ID` = ?";
			SET @eventId = in_eventId;
		EXECUTE get_eventStartDatetime_statement USING @eventId ;
        
        DEALLOCATE PREPARE get_eventStartDatetime_statement;
        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getEventTicket` (IN `in_eventId` INT)  READS SQL DATA
BEGIN
       PREPARE get_eventTicket_statement FROM
       "SELECT `eventTicket`.`TICKET_ID` AS 'ticketId', `eventTicket`.`name` AS 'ticketName', `eventTicket`.`type` AS 'ticketType' , 
       `eventTicket`.`price` AS 'ticketPrice', `eventTicket`.`discription` AS 'aboutTicket', `eventTicket`.`quantity` AS 'ticketQuantity' , 
       `eventTicket`.`available` AS 'availableTicket' , `eventTicket`.`sale_start` AS 'saleStart', `eventTicket`.`sale_end` AS 'saleEnd',
       `eventTicket`.`status` AS 'ticketStatus',  `eventTicket`.`date_added` AS 'dateAdded', `eventTicket`.`last_updated` AS 'lastUpdated'
				FROM `egate_db`.`eventTicket`
				WHERE `eventTicket`.`EVENT_ID` = ?";
       
       SET @eventId = in_eventId;
	
       EXECUTE get_eventTicket_statement USING @eventId;
       
       DEALLOCATE PREPARE get_eventTicket_statement;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getEventTime` (IN `in_eventId` INT, OUT `out_startDate` DATE, OUT `out_startTime` TIME, OUT `out_endDate` DATE, OUT `out_endTime` TIME)  READS SQL DATA
BEGIN
		SET @total = 0;
        
        SELECT `start_date`, `start_time`, `end_date`, `end_time`  FROM `event` 
			WHERE `EVENT_ID` = in_eventId  INTO out_startDate, out_startTime, out_endDate, out_endTime;
        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getGuest` (IN `in_guestId` INT)  READS SQL DATA
BEGIN
       PREPARE get_guest_statement FROM
       "SELECT `eventGuest`.`GUEST_ID` AS 'guestId', `eventGuest`.`EVENT_ID` AS 'eventId', `eventGuest`.`first_name` AS 'firstName', `eventGuest`.`last_name` AS 'lastName',
       `eventGuest`.`aka_name` AS 'nickName' , `eventGuest`.`title`, `eventGuest`.`bio` AS 'aboutGuest',`eventGuest`.`image` AS 'guestImage', 
       `eventGuest`.`date_added` AS 'dateAdded', `eventGuest`.`last_updated` AS 'lastUpdated'
				FROM `egate_db`.`eventGuest`
				WHERE `eventGuest`.`GUEST_ID` = ?";
       
       SET @guestId = in_guestId;
       
       EXECUTE get_guest_statement USING @guestId;
       
       DEALLOCATE PREPARE get_guest_statement;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getOrganizationAddress` (IN `in_organizerId` INT)  MODIFIES SQL DATA
BEGIN
		
        PREPARE get_address_prepare FROM "SELECT `ORG_ADD_ID` AS 'addressId',`sub_city` AS 'subCity' , `city`, `country`, 
			`location`,`longitude`, `latitude`
			FROM `egate_db`.`organization_address`
            LEFT JOIN `egate_db`.`organizer` USING(`ORGANIZATION_ID`)
			WHERE  `ORGANIZER_ID` = ?";
        SET @organizationId = in_organizerId;
        
        EXECUTE get_address_prepare USING @organizationId;
        
        DEALLOCATE PREPARE get_address_prepare; 

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getOrganizationSocials` (IN `in_organizerId` INT)  READS SQL DATA
BEGIN
			
            SELECT  `ORGANIZATION_ID` AS 'organizationId', `social` , `website`
			FROM `egate_db`.`organization`
            LEFT JOIN `egate_db`.`organizer` USING(`ORGANIZATION_ID`)
            WHERE `ORGANIZER_ID` = in_organizerId;
            
            
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getOrganizer` (IN `in_organizerId` INT)  READS SQL DATA
BEGIN

		PREPARE get_organizer_prepare FROM 
       " SELECT `ORGANIZER_ID` AS 'organizerId', `ORGANIZATION_ID` AS 'organizationId', `first_name` AS 'firstName' ,
       `last_name` AS 'lastName', `e_mail` AS 'email',
			`gender`, `bio` AS 'aboutOrganizer', `birthdate`, `title` , `position` , `picture` AS 'organizerImage' 
		FROM `egate_db`.`organizer`
		WHERE `ORGANIZER_ID` = ? " ;
        
        SET @organizerId = in_organizerId;
        
        EXECUTE get_organizer_prepare USING @organizerId;
        
        DEALLOCATE PREPARE get_organizer_prepare;


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getOrganizerAddress` (IN `in_organizationId` INT)  MODIFIES SQL DATA
BEGIN
		
        PREPARE get_address_prepare FROM "SELECT `ORG_ADD_ID` AS 'addressId',`sub_city` AS 'subCity' , `city`, `country`, 
			`location`,`longitude`, `latitude`
			FROM `egate_db`.`organization_address`
			WHERE  `ORGANIZATION_ID` = ?";
        SET @organizationId = in_organizationId;
        
        EXECUTE get_address_prepare USING @organizationId;
        
        DEALLOCATE PREPARE get_address_prepare; 

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getOrganizerEvent` (IN `in_eventId` INT, IN `in_organizerId` INT)  BEGIN		
        SELECT `event`.`EVENT_ID` AS 'eventId', `event`.`ORGANIZER_ID` AS 'organizerId',  `event`.`name` AS 'eventName',`venue`, `event`.`discription` AS 'aboutEvent', 
				`eventcategory`.`category_name` AS 'eventCategory', `event`.`start_date` AS 'startDate', `event`.`start_time` AS 'startTime',
                `event`.`end_date` AS 'endDate', `event`.`end_time` AS 'endTime', `longitude`, `latitude`,  `location`,
                `event`.`sub_city` AS 'subCity', `event`.`city`, `event`.`country`, `event`.`picture` AS 'eventImage',
                `event`.`status`, `event`.`created_on` AS 'createdOn', `event`.`last_updated` AS 'lastUpdated'
		FROM `event`
        RIGHT JOIN `eventCategory` USING(`CATEGORY_ID`)
        WHERE `ORGANIZER_ID` = in_organizerId AND `EVENT_ID` = in_eventId;
       

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getOrganizerEvents` (IN `in_organizerId` INT)  BEGIN		
        SELECT `event`.`EVENT_ID` AS 'eventId', `event`.`ORGANIZER_ID` AS 'organizerId',  `event`.`name` AS 'eventName',`venue`, `event`.`discription` AS 'adoutEvent', 
				`eventcategory`.`category_name` AS 'eventCategory', `event`.`start_date` AS 'startDate', `event`.`start_time` AS 'startTime',
                `event`.`end_date` AS 'endDate', `event`.`end_time` AS 'endTime', `longitude`, `latitude`,  `location`,
                CONCAT(`event`.`sub_city`,', ', `event`.`city`, ' ', `event`.`country`) AS 'address', `event`.`picture` AS 'eventImage',
                `event`.`status`, `event`.`created_on` AS 'createdOn', `event`.`last_updated` AS 'lastUpdated'
		FROM `event`
        LEFT JOIN `eventCategory` USING(`CATEGORY_ID`)
        WHERE `ORGANIZER_ID` = in_organizerId;
       

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getOrganizerInformation` (IN `in_organizerId` INT)  READS SQL DATA
BEGIN

		PREPARE get_organizer_prepare FROM 
	"SELECT `ORGANIZER_ID` AS 'organizerId', `ORGANIZATION_ID` AS 'organizationId', `first_name` AS 'firstName' ,
       `last_name` AS 'lastName', `e_mail` AS 'email',
			`gender`, `bio` AS 'aboutOrganizer', `birthdate`, `title` , `position` AS 'organizerPosition' , `picture` AS 'organizerImage' ,
            `organization`.`name` AS 'organizationName', `organization`.`po_num` AS 'postalAddress', `organization`.`logo` AS 'organizationLogo',
            `organization`.`info` AS 'aboutOrganization', `organization`.`registered_on` AS 'registeredOn', JSON_UNQUOTE(`organization`.`social`) AS 'social', 
            `organization`.`mobile_number` AS 'mobileNumber', `organization`.`office_number` AS 'officeNumber', `organization`.`website`
		FROM `egate_db`.`organizer`
        LEFT JOIN `egate_db`.`organization` USING(`ORGANIZATION_ID`)
		WHERE `ORGANIZER_ID` = ? " ;
        
        SET @organizerId = in_organizerId;
        
        EXECUTE get_organizer_prepare USING @organizerId;
        
        DEALLOCATE PREPARE get_organizer_prepare;


END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getReciept` (IN `in_reservationId` INT)  READS SQL DATA
BEGIN
		
       PREPARE get_reciept_prepare FROM		
        'SELECT * FROM `egate_db`.`recieptdetails`
        WHERE `reservationId` = ? ';
        
        SET @attendeeId = in_reservationId;
        
       EXECUTE get_reciept_prepare USING @attendeeId;
        
        DEALLOCATE PREPARE get_reciept_prepare;
        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getSponsor` (IN `in_sponsorId` INT)  READS SQL DATA
BEGIN
       PREPARE get_sponsor_statement FROM
       "SELECT `eventSponsor`.`SPONSOR_ID` AS 'sponsorId', `eventSponsor`.`EVENT_ID` AS 'eventId',  `eventSponsor`.`name` AS 'sponsorName', `eventSponsor`.`image` AS 'sponsorImage', 
       `eventSponsor`.`aboutSponor`, 	`eventSponsor`.`date_added` AS 'dateAdded', `eventSponsor`.`last_updated` AS 'lastUpdated'
				FROM `egate_db`.`eventSponsor`
				WHERE `eventSponsor`.`SPONSOR_ID` = ?";
       
       SET @sponsorId = in_sponsorId;
	
       EXECUTE get_sponsor_statement USING @sponsorId;
       
       DEALLOCATE PREPARE get_sponsor_statement;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getSubscription` (IN `in_subscriber` JSON)  MODIFIES SQL DATA
BEGIN
	
    
	PREPARE get_subscription_prepare  FROM  "SELECT  `subscription`.`SUBSCRIPTION_ID` AS 'subscriptionId', `subscriber`.`SUBSCRIBER_ID` AS 'subscriberId', 
		`subscriber`.`e_mail` AS 'Email' , `eventCategory`.`category_name` AS `subscription`, `subscriber`.`added_on` AS 'subscribedOn' ,
		`subscription`.`updated_on` AS 'lastUpdated' 
		FROM `egate_db`.`subscriber`
		LEFT JOIN `egate_db`.`subscription` USING(`SUBSCRIBER_ID`)
		LEFT JOIN `egate_db`.`eventCategory` USING(`CATEGORY_ID`)
		WHERE `subscriber`.`e_mail` = ? OR `subscriber`.`SUBSCRIBER_ID` = ? ";
        
        SET @email = in_subscriber->>'$.email';
        SET @id = in_subscriber->>'$.id';
                
		EXECUTE get_subscription_prepare USING @email, @id;
        
        DEALLOCATE PREPARE get_subscription_prepare;
        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getTicket` (IN `in_ticketId` INT)  READS SQL DATA
BEGIN
       PREPARE get_ticket_statement FROM
       "SELECT `eventTicket`.`TICKET_ID` AS 'ticketId', `eventTicket`.`EVENT_ID` AS 'eventId', `eventTicket`.`name` AS 'ticketName', `eventTicket`.`type` AS 'ticketType' , 
       `eventTicket`.`price` AS 'ticketPrice', `eventTicket`.`discription` AS 'aboutTicket', `eventTicket`.`quantity` , 
       `eventTicket`.`available` AS 'availableTickets' , `eventTicket`.`sale_start` AS 'saleStart', `eventTicket`.`sale_end` AS 'saleEnd',
       `eventTicket`.`status` AS 'ticketStatus',  `eventTicket`.`date_added` AS 'dateAdded', `eventTicket`.`last_updated` AS 'lastUpdated'
				FROM `egate_db`.`eventTicket`
				WHERE `eventTicket`.`TICKET_ID` = ?";
       
       SET @ticketId = in_ticketId;
	
       EXECUTE get_ticket_statement USING @ticketId;
       
       DEALLOCATE PREPARE get_ticket_statement;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `logIn` (IN `in_organizer` JSON)  READS SQL DATA
BEGIN
		
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
        RESIGNAL;
        END;
        
        IF JSON_CONTAINS_PATH(in_organizer, 'all', '$[0].email', '$[0].password') THEN 
        PREPARE log_in_statement FROM 
				"SELECT SQL_CALC_FOUND_ROWS `ORGANIZER_ID` AS organizerId, `first_name` AS 'firstName',  `last_name` AS lastName 
					FROM `egate_db`.`organizer` WHERE `e_mail` = ? AND `password` = ? ";
		SET @email = in_organizer->>'$[0].email';
        SET @pass = in_organizer->>'$[0].password';
        
        EXECUTE log_in_statement USING @email, @pass;
		
			IF found_rows() != 1 THEN 
					SIGNAL SQLSTATE '45000'
					SET MYSQL_ERRNO = 21,
						MESSAGE_TEXT = 'acount not found, email address or password is not correct ';					
				
			END IF;
            			
		ELSE
        SIGNAL SQLSTATE '45000'
					SET MYSQL_ERRNO = 21,
						MESSAGE_TEXT = 'json array missing on or all required keys to log in (email, password) ';					
		END IF;
            
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ticketStatusAndType` (IN `in_ticketId` INT, OUT `out_status` VARCHAR(15), OUT `out_type` VARCHAR(15))  READS SQL DATA
BEGIN
       SELECT `status`, `type`
       FROM `eventTicket`
       WHERE `TICKET_ID` = in_ticketId INTO out_status, out_type;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateBillingAddress` (IN `in_organizerId` INT, IN `in_accountInfo` JSON)  MODIFIES SQL DATA
BEGIN
	
		DECLARE errorCount INT DEFAULT 0;
        DECLARE NESTED BOOLEAN DEFAULT true;        
        DECLARE EXIT HANDLER FOR 1062
        BEGIN
        	GET DIAGNOSTICS errorCount = NUMBER;
			IF NESTED = false THEN ROLLBACK; END IF;
            RESIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Account already Exists under the specified service provider.';
		END;
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN 
			GET DIAGNOSTICS errorCount = NUMBER;
			IF NESTED = false THEN ROLLBACK; END IF;
            RESIGNAL;
		END;
        		
		SET @organizationId = getOrganizationId(in_organizerId);
        
        IF JSON_CONTAINS_PATH(in_accountInfo,'all', '$[*].serviceProvider','$[*].phoneNumber' ) 
			AND  @organizationId THEN
					IF transactionCount() = 0 THEN
						START TRANSACTION;
                        SET NESTED = false;
					END IF;

        
        
        PREPARE update_billingAddress_prepare FROM 
			'INSERT INTO  `egate_db`.`billingaddress` ( 
				`ORGANIZATION_ID`, `PROVIDER_ID` , `phone_number` 
                ) VALUES (?, ?, ?)  ON DUPLICATE KEY UPDATE `phone_number` = ? ';
				
                SET @counter = 0;
                WHILE @counter < JSON_LENGTH(in_accountInfo) DO    
				
					SET @serviceProvider = JSON_EXTRACT(in_accountInfo, CONCAT('$[',@counter,'].serviceProvider'));
					SET @phone = JSON_EXTRACT(in_accountInfo, CONCAT('$[',@counter,'].phoneNumber'));
    
				EXECUTE update_billingAddress_prepare USING  @organizationId, @serviceProvider , @phone, @phone;
                SET @counter = @counter + 1;
                
                END WHILE;
			
            IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
        
        DEALLOCATE PREPARE update_billingAddress_prepare;
        
	ELSE	
		SIGNAL SQLSTATE '45100'
			SET MESSAGE_TEXT = 'JSON data passed for billing address missing required key (serviceProvider, phoneNumber) ';
	END IF;
					
 END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateComment` (IN `in_eventId` INT, IN `in_comment` JSON)  MODIFIES SQL DATA
BEGIN
		
	DECLARE errorCount INT DEFAULT 0;
    DECLARE NESTED BOOLEAN DEFAULT false;    
      
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN ROLLBACK; END IF;
            RESIGNAL;                    
        END;
        
				IF transactionCount() = 0 THEN
					START TRANSACTION;
                    SET NESTED = true;
				END IF;
                
                IF NOT ISNULL(in_eventId) AND 
				NOT ISNULL(	in_comment) 
				THEN
                
					PREPARE update_comment_statement FROM 
                ' 	UPDATE `eventComments` 
							SET `name` = ? , `comment` = ?  
                            WHERE COMMENT_ID = ? AND EVENT_ID = ? ';
				
					SET @eventId = in_eventId;
					SET @counter = 0;
                    WHILE @counter < JSON_LENGTH(in_comment) DO
						
						SET @commentId = JSON_EXTRACT(in_comment, CONCAT('$[', @counter, '].id'));
                        SET @commenter = JSON_EXTRACT(in_comment, CONCAT('$[', @counter, '].name'));
                        SET @content = JSON_EXTRACT(in_comment, CONCAT('$[', @counter, '].comment'));
						
						EXECUTE update_comment_statement USING @commenter, @content, @commentId,  @eventId;
							
						
                            SET @counter  = @counter + 1;
					
                    END WHILE;
					
                    IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
                    
						DEALLOCATE PREPARE upate_comment_statement;
						
				ELSE 
					SIGNAL SQLSTATE '45000'
						SET MYSQL_ERRNO = 5,
							MESSAGE_TEXT = 'JSON OBJECT passed  or event id can not be null';
				END IF;
                                
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateEvent` (IN `in_organizerId` INT, IN `in_event` JSON)  MODIFIES SQL DATA
BEGIN
	DECLARE NESTED BOOLEAN DEFAULT true;
    DECLARE errorCount INT DEFAULT 0;
    
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
        GET DIAGNOSTICS errorCount = NUMBER;
        IF NESTED = false THEN ROLLBACK; END IF;
        RESIGNAL;
        END;
			
        
		IF organizerEventExist(in_organizerId, in_event->>'$.eventId') = true THEN
			IF transactionCount() = 0 THEN
				START TRANSACTION;
                SET NESTED = false;
			END IF;
            
				PREPARE update_event_statement FROM
                'UPDATE `event` 
                SET `name` = ?, `venue` = ? , `discription` = ?, `start_time` = ? , `start_date` = ?, 
                `end_time` = ?, `end_date` = ?,  `CATEGORY_ID` = ?, `sub_city` = ?, `city` = ? , 
                `country` = ?, `location` = ?, `picture` = ?, `longitude` = ?, `latitude` = ?
                WHERE `ORGANIZER_ID` = ? AND `EVENT_ID` = ?';
			SET @organizerId = in_organizerId;
            SET @eventId =  in_event->>'$.eventId';
			SET @eventName =  in_event->>'$.eventName';
			SET @venue = in_event->>'$.venue';
			SET @discription = in_event->>'$.aboutEvent';
			SET @startTime =  in_event->>'$.startTime';
			SET @startDate = in_event->>'$.startDate';
			SET @endTime = in_event->>'$.endTime';
			SET @endDate = in_event->>'$.endDate';
			SET @category = in_event->>'$.eventCategory';
			SET @subCity = in_event->>'$.subCity';
			SET @city = in_event->>'$.city';
			SET @country = in_event->>'$.country';
			SET @location = in_event->>'$.location';
			SET @latitude = in_event->>'$.latitude';
			SET @longitude = in_event->>'$.longitude';
			SET @image = in_event->>'$.image';
    
			EXECUTE update_event_statement USING @eventName, @venue, @discription, @startTime, @startDate,
                                      @endTime, @endDate, @category, @subCity, @city, @country, @location, @image,
                                      @latitude, @longitude,  @organizerId, @eventId;
            
            IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
            DEALLOCATE PREPARE update_event_statement;
            ELSE
				
				SIGNAL SQLSTATE '45000' 
						SET MYSQL_ERRNO = 11,	
						MESSAGE_TEXT = 'Event Undder the specidied organizer Doesnt Exist';
            END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateEventAddress` (IN `in_organizerId` INT, IN `in_eventAddress` JSON)  MODIFIES SQL DATA
BEGIN
	DECLARE NESTED BOOLEAN DEFAULT true;
    DECLARE errorCount INT DEFAULT 0;
    
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
        GET DIAGNOSTICS errorCount = NUMBER;
        IF NESTED = false THEN ROLLBACK; END IF;
        RESIGNAL;
        END;
			
        
		IF organizerEventExist(in_organizerId, in_eventAddress->>'$.id') = true THEN
			IF transactionCount() = 0 THEN
				START TRANSACTION;
                SET NESTED = false;
			END IF;
            
				PREPARE update_event_address_statement FROM
                'UPDATE `event` 
					SET `sub_city` = ?, `city` = ? , `country` = ?, `location` = ?, `longitude` = ?, `latitude` = ?
                WHERE `ORGANIZER_ID` = ? AND `EVENT_ID` = ?';
			SET @organizerId = in_organizerId;
            SET @eventId =  in_eventAddress->>'$.id';						
			SET @subCity = in_eventAddress->>'$.subCity';
			SET @city = in_eventAddress->>'$.city';
			SET @country = in_eventAddress->>'$.country';
			SET @location = in_eventAddress->>'$.location';
			SET @latitude = in_eventAddress->>'$.latitude';
			SET @longitude = in_eventAddress->>'$.longitude';
			
    
			EXECUTE update_event_address_statement USING  @subCity, @city, @country, @location, @latitude, @longitude, 
													@organizerId, @eventId;
            
            IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
            DEALLOCATE PREPARE update_event_address_statement;
            ELSE
				SET @message = CONCAT("event with id ", in_event->>'$.id', " and organizer id ", in_organizerId , "does not exist ");
				SIGNAL SQLSTATE '45000' 
						SET MYSQL_ERRNO = 11,	
						MESSAGE_TEXT = @message;
            END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateEventAttendee` (IN `in_attendee` JSON, OUT `out_result` INT)  MODIFIES SQL DATA
BEGIN

		DECLARE NESTED BOOLEAN DEFAULT true;
        DECLARE errorCount INT DEFAULT 0;
        
        DECLARE email_exists CONDITION FOR 1062;
        
        
        DECLARE EXIT HANDLER FOR SQLEXCEPTION, email_exists
        BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN 
				ROLLBACK; 
				SET out_result = false; 
			END IF;
            RESIGNAL;						
        END;
						
			IF JSON_CONTAINS_PATH(in_attendee, 'all', '$.eventId', '$.id', '$.firstName', '$.lastName', '$.phoneNumber') THEN
            
                        IF transactionCount() = 0 THEN
							START TRANSACTION;
                            SET NESTED = false;
						END IF;
                        
            	PREPARE attendee_update_statement FROM
							'UPDATE `eventAttendee`
								SET `first_name` =  ? , `last_name` = ? , `phone` = ? , `service_provider`= ? , `email` = ?
                                WHERE `EVENT_ID` = ? AND ATTENDEE_ID = ? ';
								                     
	        SET @guestId = in_attendee->>'$.id';
            SET @eventId = in_attendee->>'$.eventId';
            SET @fname = in_attendee->>'$.firstName';
            SET @lname = in_attendee->>'$.lastName';
            SET @phone = in_attendee->>'$.phoneNumber';
            SET @email = in_attendee->>'$.email';
            SET @serviceProvider = in_attendee->>'$.serviceProvider';
            
            EXECUTE attendee_update_statement USING  @fname, @lname, @phone, @serivceProvider, @email, @eventId, @guestId;
                   
            IF NESTED = false AND errorCount = 0 THEN 
              COMMIT; 
			SET out_result = true;
             END IF;
            
            DEALLOCATE PREPARE attendee_update_statement;
            
            
            
		ELSE
				SIGNAL SQLSTATE '45000' 
            SET MYSQL_ERRNO = 1,	
			MESSAGE_TEXT = 'json data passed for event attendee missing one of the required keys required keys 
								eventId, id firstName, lastName, phoneNumber ';
        
        END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateEventCategory` (IN `in_category` JSON)  MODIFIES SQL DATA
BEGIN
	DECLARE NESTED BOOLEAN DEFAULT true;
    DECLARE errorCount INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		GET DIAGNOSTICS errorCount = NUMBER;
        IF NESTED = false THEN ROLLBACK; END IF;
        RESIGNAL;
        
    END;
    
				IF transactionCount() = 0 THEN
					START TRANSACTION;
                    SET NESTED = false;
				END IF;
                
                
			IF JSON_CONTAINS_PATH(in_category, 'all', '$[*].category' , '$[*].id') THEN
            
				SET @counter = 0;
                
                PREPARE update_category_prepare FROM 
                'UPDATE `egat_db`.`eventCategory` SET `category_name` = ?
					WHERE `CATEGORY_ID` = ?';
                
                WHILE @counter < JSON_LENGTH(in_category) DO
                
					SET @category = JSON_EXTRACT(in_category, CONCAT('$[', @counter, '].category'));
                    SET @id = JSON_EXTRACT(in_category, CONCAT('$[', @counter, '].id'));
					
					EXECUTE update_category_prepare USING @category, @id;
					
					SET @counter = @counter + 1;
				
                END WHILE;
                
                
                IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
               
               DEALLOCATE PREPARE update_category_prepare;
		ELSE
			SIGNAL SQLSTATE '45000' 
				SET MYSQL_ERRNO = 1,	
					MESSAGE_TEXT = 'json data passed for event category missing required  
								field (category & id) ';
        
        
        END IF;
                
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateEventGuest` (IN `in_eventID` INT, IN `in_guest` JSON)  MODIFIES SQL DATA
BEGIN

	DECLARE eventGuest JSON;
	DECLARE NESTED BOOLEAN DEFAULT true;
	DECLARE errorCount INT DEFAULT 0;

		DECLARE EXIT  HANDLER FOR SQLEXCEPTION, SQLSTATE '45000'
		BEGIN 
		GET DIAGNOSTICS errorCount = NUMBER;		
		 IF NESTED = false THEN ROLLBACK; END IF;
         RESIGNAL;
		END;
    
		IF JSON_CONTAINS_PATH(in_guest, 'all', '$[*].guestId', '$[*].firstName', '$[*].lastName' )THEN

			 IF transactionCount() = 0 THEN 
			 SET @tran = transactionCount();
			 START TRANSACTION; 
			 SET NESTED = false;
			 END IF;

			
			
			
			 PREPARE   update_guest_statement FROM 
			 'UPDATE `eventGuest`	SET `first_name` = ? , `last_name` = ?, `aka_name` = ? , 
							`bio` = ? , `title` = ? , `image` = ?
								WHERE `EVENT_ID` = ? AND `GUEST_ID` = ?';

                SET @counter = 0;
                SET @eventId = in_eventId;
                
			WHILE @counter < JSON_LENGTH(in_guest) DO
			
				SET eventGuest = JSON_EXTRACT(in_guest, CONCAT('$[', @counter,']'));
               
                IF eventGuest->>'$.guestId' IS NULL THEN
					SIGNAL SQLSTATE '45000' 
						SET MYSQL_ERRNO = 9,	
							MESSAGE_TEXT = 'JSON data for guest missing id or value is null  field';
				END IF;
                
				SET @guestId = eventGuest->>'$.guestId';
				SET @fname = eventGuest->>'$.firstName';
				SET @lname = eventGuest->>'$.lastName';
				SET @akaName = eventGuest->>'$.akaName';
				SET @bio = eventGuest->>'$.aboutGuest';
				SET @title = eventGuest->>'$.title';
				SET @image = eventGuest->>'$.guestImage';
                
                IF
					(SELECT COUNT(*) FROM `eventGuest`
						WHERE `EVENT_ID` = @eventId AND `GUEST_ID` = @guestId )  = 1 
				THEN					
                    EXECUTE update_guest_statement USING @fname, @lname, @akaName, @bio, @title, @image, @eventId, @guestId;
                 ELSE
						SET @message = CONCAT("record not found. event guest with id ",@guestId, " & event id of ", @eventId);
						SIGNAL SQLSTATE '45000' 
						SET MYSQL_ERRNO = 11,	
						MESSAGE_TEXT = @message;
                 END IF;
				SET @counter = @counter + 1;
				
            END WHILE;
            DEALLOCATE PREPARE update_guest_statement;
            
            IF NESTED = false AND errorCount = 0 THEN 
					COMMIT; 
            END IF;
		ELSE
			SIGNAL SQLSTATE '45000' 
            SET MYSQL_ERRNO = 9,	
			MESSAGE_TEXT = 'JSON data missing one or more required key values(id, firstName, lastName ) ';
            				
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateEventInfo` (IN `in_organizerId` INT, IN `in_event` JSON)  MODIFIES SQL DATA
BEGIN
	DECLARE NESTED BOOLEAN DEFAULT true;
    DECLARE errorCount INT DEFAULT 0;
    
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
        GET DIAGNOSTICS errorCount = NUMBER;
        IF NESTED = false THEN ROLLBACK; END IF;
        RESIGNAL;
        END;
			
        
		IF organizerEventExist(in_organizerId, in_event->>'$.eventId') = true THEN
			IF transactionCount() = 0 THEN
				START TRANSACTION;
                SET NESTED = false;
			END IF;
            
				PREPARE update_event_statement FROM
                'UPDATE `event` 
                SET `name` = ?, `venue` = ? , `discription` = ?,  `CATEGORY_ID` = ?, `sub_city` = ?, `city` = ? , 
                `country` = ?, `location` = ?, `picture` = ?, `longitude` = ?, `latitude` = ?
                WHERE `ORGANIZER_ID` = ? AND `EVENT_ID` = ?';
			SET @organizerId = in_organizerId;
            SET @eventId =  in_event->>'$.eventId';
			SET @eventName =  in_event->>'$.eventName';
			SET @venue = in_event->>'$.venue';
			SET @discription = in_event->>'$.aboutEvent';
		
			SET @category = in_event->>'$.eventCategory';
			SET @subCity = in_event->>'$.subCity';
			SET @city = in_event->>'$.city';
			SET @country = in_event->>'$.country';
			SET @location = in_event->>'$.location';
			SET @latitude = in_event->>'$.latitude';
			SET @longitude = in_event->>'$.longitude';
			SET @image = in_event->>'$.image';
    
			EXECUTE update_event_statement USING @eventName, @venue, @discription, @category, @subCity, @city, @country, @location, @image,
                                      @latitude, @longitude,  @organizerId, @eventId;
            
            IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
            DEALLOCATE PREPARE update_event_statement;
            ELSE
				
				SIGNAL SQLSTATE '45000' 
						SET MYSQL_ERRNO = 11,	
						MESSAGE_TEXT = 'Event Undder the specidied organizer Doesnt Exist';
            END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateEventPicture` (IN `in_eventId` INT, IN `in_picture` VARCHAR(50))  MODIFIES SQL DATA
BEGIN
	DECLARE NESTED BOOLEAN DEFAULT true;
    DECLARE errorCount INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		GET DIAGNOSTICS errorCount = NUMBER;
        IF NESTED = false THEN ROLLBACK; END IF;
        RESIGNAL;
        
    END;
    
				IF transactionCount() = 0 THEN
					START TRANSACTION;
                    SET NESTED = false;
				END IF;
                
           
                PREPARE update_picture_prepare FROM 
                'UPDATE `egat_db`.`event` SET `picture` = ?
					WHERE `EVENT_ID` = ?';
                
            
					SET @newImage = in_picture;
                    SET @eventId = in_eventId;
					
					EXECUTE update_picture_prepare USING @newImage, @eventId;
					
					               
                
                IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
               
               DEALLOCATE PREPARE update_picture_prepare;

                
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateEventSponsor` (IN `in_eventID` INT, IN `in_sponsor` JSON)  MODIFIES SQL DATA
BEGIN
     DECLARE eventSponsor JSON;
     DECLARE NESTED BOOLEAN DEFAULT true;
	DECLARE errorCount INT DEFAULT 0;

		DECLARE EXIT  HANDLER FOR SQLEXCEPTION
		BEGIN 
		GET DIAGNOSTICS errorCount = NUMBER;		
		 IF NESTED = false THEN ROLLBACK; END IF;
         RESIGNAL;
		END;
    
		 IF transactionCount() = 0 THEN 
		 START TRANSACTION; 
		 SET NESTED = false;
		 END IF;

	IF JSON_CONTAINS_PATH(in_sponsor, 'all', '$[*].sponsorId') THEN
    
         PREPARE   update_sponsor_statement FROM 'UPDATE `eventSponsor`
													SET  `name` = ?, 
														`image` = ?, 
                                                        `aboutSponsor` = ?
													WHERE SPONSOR_ID = ? AND EVENT_ID = ? ';
            
            SET @counter = 0;
			SET @event_id = in_eventID;
                
			WHILE @counter < JSON_LENGTH(in_sponsor) DO
            
            SET eventSponsor = JSON_EXTRACT(in_sponsor, CONCAT('$[', @counter, ']'));		
            SET @name = eventSponsor->>'$.sponsorName';           
            SET @image = eventSponsor->>'$.sponsorImage';
            SET @about = eventSponsor->>'$.aboutSponsor';
            SET @sponsorId = eventSponsor->>'$.sponsorId';
            
					IF @sponsorId IS NULL THEN 
                    
            		SIGNAL SQLSTATE '45000'
						SET MYSQL_ERRNO = 11,
							MESSAGE_TEXT = "sponsorId can not be null";
					END IF;
			
                       
				EXECUTE update_sponsor_statement USING @name, @image, @about, @sponsorId, @event_id;
				
				
				SET @counter = @counter + 1;
				
				END WHILE;
            
            DEALLOCATE PREPARE update_sponsor_statement;
           IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
           
		ELSE
        	SIGNAL SQLSTATE '45000' 
            SET MYSQL_ERRNO = 9,	
			MESSAGE_TEXT = 'JSON array missing sponsorId required key  ';
            				
    END IF;
    
    
		

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateEventStatus` (IN `in_organizerId` INT, IN `in_eventId` INT, IN `in_eventStatus` VARCHAR(20), OUT `out_result` BOOLEAN)  MODIFIES SQL DATA
BEGIN		
	
	DECLARE NESTED BOOLEAN DEFAULT true;
	DECLARE errorCount INT DEFAULT 0;

		DECLARE EXIT  HANDLER FOR SQLEXCEPTION
		BEGIN 
		GET DIAGNOSTICS errorCount = NUMBER;
			IF NESTED = false THEN 
				ROLLBACK;
				SET out_result = false;
			END IF;
		RESIGNAL;
              	 
		END;
    
         
        IF isValidEventStatus(UPPER(in_eventStatus)) = true THEN
					
                    
			 IF transactionCount() = 0 THEN 
			 START TRANSACTION;          
			 SET NESTED = false;
			 END IF;

                PREPARE status_update_statement FROM 
					'UPDATE `event` 
						SET status = ?
                        WHERE EVENT_ID = ? AND ORGANIZER_ID = ? ';
                        
                        SET @newStatus = UPPER(in_eventStatus);
                        SET @organizerId = in_organizerId;
                        SET @eventId = in_eventId;
                        
				EXECUTE status_update_statement USING @newStatus, @eventId, @organizerId;
                
                IF errorCount = 0 AND NESTED = false THEN COMMIT; END IF;
                SET out_result = true;
        ELSE
			SIGNAL SQLSTATE '45000'
				SET MYSQL_ERRNO = '60',
					MESSAGE_TEXT = 'invalid event Status event status should only be ("OPEN", "CLOSED", "DRAFT" ) ';
			
        END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateEventTicket` (IN `in_eventId` INT, IN `in_ticket` JSON)  MODIFIES SQL DATA
BEGIN

	DECLARE eventTicket JSON;
	DECLARE NESTED BOOLEAN DEFAULT true;
	DECLARE errorCount INT DEFAULT 0;

		DECLARE EXIT  HANDLER FOR SQLEXCEPTION, 1265
		BEGIN 
		GET DIAGNOSTICS errorCount = NUMBER;
		IF NESTED = false THEN ROLLBACK; END IF;
        RESIGNAL;
		
		END;
    
		 IF JSON_CONTAINS_PATH(in_ticket, 'all', '$[*].ticketId' ) THEN
         
		 IF transactionCount() = 0 THEN 
		 START TRANSACTION;          
		 SET NESTED = false;
		 END IF;
   

			PREPARE update_ticket_statement FROM 
            'UPDATE `eventTicket` 
					SET `name` = ?,	`type` = ?,  `price` = ? , `quantity` = ?,  
						`discription` = ?,  `sale_start` = ?,  `sale_end`= ?
                        WHERE `EVENT_ID` = ? AND TICKET_ID = ?';
				
			SET @counter = 0;
            SET @eventId = in_eventId;
            
		WHILE (@counter < JSON_LENGTH(in_ticket)) DO
       
         
			 SET eventTicket = JSON_EXTRACT(in_ticket, CONCAT('$[', @counter, ']'));
				SET @ticketId = eventTicket->>'$.ticketId';
                SET @tname = eventTicket->>'$.ticketName';
				
				SET @ttype =  eventTicket->>'$.ticketType';
				SET @price =  eventTicket->>'$.ticketPrice';
				SET @quantity =  eventTicket->>'$.quantity';
				SET @available =  eventTicket->>'$.quantity';
				SET @discription =  eventTicket->>'$.aboutTicket';
				SET @saleStart = eventTicket->>'$.saleStart';
				SET @saleEnd = eventTicket->>'$.saleEnd';

						EXECUTE update_ticket_statement USING  @tname , @ttype , @price,
								@quantity, @discription,   @saleStart, @saleEnd,  @eventId, @ticketId;
			
			SET @counter = @counter + 1;
			            
        END WHILE;
		DEALLOCATE PREPARE update_ticket_statement;
        
      IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
       
	ELSE
        	SIGNAL SQLSTATE '45000' 
            SET MYSQL_ERRNO = 9,	
			MESSAGE_TEXT = 'JSON Array missing required ticketId key for update';
            				
    END IF;
       
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateEventTime` (IN `in_organizerId` INT, IN `in_eventTime` JSON)  MODIFIES SQL DATA
BEGIN
	DECLARE NESTED BOOLEAN DEFAULT true;
    DECLARE errorCount INT DEFAULT 0;
    
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
        GET DIAGNOSTICS errorCount = NUMBER;
        IF NESTED = false THEN ROLLBACK; END IF;
        RESIGNAL;
        END;
			
        
		IF organizerEventExist(in_organizerId, in_eventTime->>'$.id') = true THEN
			IF transactionCount() = 0 THEN
				START TRANSACTION;
                SET NESTED = false;
			END IF;
            
				PREPARE update_event_time_statement FROM
                'UPDATE `event` 
						SET `start_time` = ? , `start_date` = ?, `end_time` = ?, `end_date` = ?
						WHERE `ORGANIZER_ID` = ? AND `EVENT_ID` = ?';
			SET @organizerId = in_organizerId;
            SET @eventId =  in_eventTime->>'$.id';		
			SET @startTime =  in_eventTime->>'$.startTime';
			SET @startDate = in_eventTime->>'$.startDate';
			SET @endTime = in_eventTime->>'$.endTime';
			SET @endDate = in_eventTime->>'$.endDate';
			
    
			EXECUTE update_event_time_statement USING @startTime, @startDate,  @endTime, @endDate,  @organizerId, @eventId;
            
            IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
            DEALLOCATE PREPARE update_event_time_statement;
            ELSE
				SET @message = CONCAT("event with id ", in_event->>'$.id', " and organizer id ", in_organizerId , "does not exist ");
				SIGNAL SQLSTATE '45000' 
						SET MYSQL_ERRNO = 11,	
						MESSAGE_TEXT = @message;
            END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateOrganization` (IN `in_organization` JSON)  MODIFIES SQL DATA
BEGIN
		
	DECLARE errorCount INT DEFAULT 0;
    DECLARE NESTED BOOLEAN DEFAULT true;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		GET DIAGNOSTICS errorCount = NUMBER;
        IF NESTED = false THEN ROLLBACK; END IF;
        
        RESIGNAL;
    END;
    
	IF JSON_CONTAINS_PATH(in_organization, 'all', '$.organizationId', '$.organizerId') THEN
    
    IF ( isValidInt(in_organization->>'$.organizerId') AND isValidInt(in_organization->>'$.organizationId') ) AND 
		organizationExist(in_organization->>'$.organizationId' , in_organization->>'$.organizerId') = true
		 
	THEN
    
							
                            IF transactionCount() = 0 THEN
								START TRANSACTION;
                                SET NESTED = false;
							END IF;
                            
                            PREPARE organization_update_statement FROM
                            'UPDATE `organization`  
								SET `name` = ? , `social` = ? ,  `website` = ? ,  `phone_number` = ? ,  `po_num` = ? ,  `logo` = ? , `info` = ? 
                                WHERE `ORGANIZATION_ID` = ? ';
                            
                            SET @organizationId =  in_organization->>'$.organizationId';
                            SET @organizerId =  in_organization->>'$.organizerId';
                            SET @name = in_organization->>'$.name';
                            SET @socialMedia = in_organization->>'$.socialMedia';
                            SET @telephone = in_organization->>'$.phoneNumber';
                            SET @website =	in_organization->>'$.website';
                            SET @postNum = in_organization->>'$.postNumber';
                            SET @logo = in_organization->>'$.logo';
                            SET @info = in_organization->>'$.info';
                            
                            
                            EXECUTE organization_update_statement USING 
									@name,  @socialMedia, @website, @telephone, @postNum, @logo, @info, @organizationId;
							IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
                            
                            DEALLOCATE PREPARE organization_update_statement;
			ELSE
        	SIGNAL SQLSTATE '45000' 
			SET MESSAGE_TEXT = 'organization by the provided orgnizer id and organization id does not exist  ',
			MYSQL_ERRNO = 1;
	
        END IF;
	
		ELSE
			SIGNAL SQLSTATE '45000' 
			SET MESSAGE_TEXT = ' JSON data missing required key name pair (organizerId and organizationId) ',
			MYSQL_ERRNO = 1;
	
	
    END IF;
	
	
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateOrganizationAddress` (IN `in_organizerId` INT, IN `in_address` JSON)  MODIFIES SQL DATA
BEGIN
	
		DECLARE errorCount INT DEFAULT 0;
        DECLARE NESTED BOOLEAN DEFAULT true;
        DECLARE address JSON;
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN 
			GET DIAGNOSTICS errorCount = NUMBER;
			IF NESTED = false THEN ROLLBACK; END IF;
            RESIGNAL;
		END;
		
		SET @organizationId = getOrganizationId(in_organizerId);
		
        IF JSON_CONTAINS_PATH(in_address,'one','$[*].addressId' ) 
			AND NOT ISNULL(@organizationId) THEN
					IF transactionCount() = 0 THEN
						START TRANSACTION;
                        SET NESTED = false;
					END IF;

        
        
        PREPARE update_organizationAddress_prepare FROM 
			'UPDATE `egate_db`.`organization_address`  
				SET `country` = ? , `city` = ?, `sub_city` = ?, `location` = ?, `longitude` = ?, `latitude` = ?
                WHERE `ORG_ADD_ID` = ? AND `ORGANIZATION_ID` = ?';
                
				
                SET @counter = 0;
                    
				WHILE @counter  < JSON_LENGTH(in_address)DO
					SET address = JSON_EXTRACT(in_address, CONCAT('$[',@counter ,']'));
				SET @id = address->>'$.addressId';
				SET @country = address->>'$.country';
				SET @city = address->>'$.city';
				SET @subCity = address->>'$.subCity';
				SET @location = address->>'$.location';
				SET @latitude = address->>'$.latitude';
				SET @longitude = address->>'$.longitude';
                      
				EXECUTE update_organizationAddress_prepare USING   @country , @city, @subCity, @location, @latitude, @longitude, @id, @organizationId;
				SET @counter = @counter + 1;
			END WHILE;
			
            IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
        
        DEALLOCATE PREPARE update_organizationAddress_prepare;
        
	ELSE	
		SIGNAL SQLSTATE '45100'
			SET MESSAGE_TEXT = 'JSON data passed for address update missing required key (addressId) ';
	END IF;
					
 END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateOrganizationProfile` (IN `in_organizerId` INT, IN `in_organizationId` INT, IN `in_organizationInfo` JSON)  MODIFIES SQL DATA
BEGIN
		
	DECLARE errorCount INT DEFAULT 0;
    DECLARE NESTED BOOLEAN DEFAULT true;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		GET DIAGNOSTICS errorCount = NUMBER;
        IF NESTED = false THEN ROLLBACK; END IF;
		RESIGNAL;
    END;
    

    
    IF organizationExist(in_organizationId, in_organizerId) = true	THEN
    
							
                            IF transactionCount() = 0 THEN
								START TRANSACTION;
                                SET NESTED = false;
							END IF;
                            
                            PREPARE organization_update_statement FROM
                            'UPDATE `organization`  
								SET `name` = ? ,  `website` = ? ,  `mobile_number` = ? , `office_number` = ?,
                                `po_num` = ? ,  `logo` = ? , `info` = ? 
                                WHERE `ORGANIZATION_ID` = ? ';
                            
                            SET @organizationId =  in_organizationId;
                            SET @organizerId =  in_organizerId;
                            SET @name = in_organizationInfo->>'$.organizationName';
                            
                            SET @mobileNum = in_organizationInfo->>'$.mobileNumber';
                            SET @officeNum = in_organizationInfo->>'$.officeNumber';
                            SET @website =	in_organizationInfo->>'$.website';
                            SET @postNum = in_organizationInfo->>'$.postNumber';
                            SET @logo = in_organizationInfo->>'$.organizationLogo';
                            SET @info = in_organizationInfo->>'$.aboutOrganization';
                            
                            
                            EXECUTE organization_update_statement USING 
									@name,  @website, @mobileNum, @officeNum, @postNum, @logo, @info, @organizationId;
							IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
                            
                            DEALLOCATE PREPARE organization_update_statement;
			ELSE
        	SIGNAL SQLSTATE '45000' 
			SET MESSAGE_TEXT = 'organization by the provided orgnizer id and organization id does not exist  ';
			
	
        END IF;
	
		
	
	
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateOrganizationSocialAddress` (IN `in_organizerId` INT, IN `in_socialAddress` JSON)  MODIFIES SQL DATA
BEGIN
	
		DECLARE errorCount INT DEFAULT 0;
        DECLARE NESTED BOOLEAN DEFAULT true;
        
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN 
			GET DIAGNOSTICS errorCount = NUMBER;
			IF NESTED = false THEN ROLLBACK; END IF;
            RESIGNAL;
		END;
        
        IF JSON_CONTAINS_PATH(in_socialAddress,'one', '$.socialMedia') THEN
					IF transactionCount() = 0 THEN
						START TRANSACTION;
                        SET NESTED = false;
					END IF;
		
		
        
        PREPARE update_socialAddress_prepare FROM 
			'UPDATE `egate_db`.`organization` 
						SET social = ? 
					WHERE `ORGANIZATION_ID` = ?	';
                    
			SET @organizationId = getOrganizationId(in_organizerId);
            SET @socialAddress = in_socialAddress->>'$.socialMedia';
            
		EXECUTE update_socialAddress_prepare USING @socialAddress , @organizationId;
        
        IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
        
        DEALLOCATE PREPARE update_socialAddress_prepare;
        
	ELSE	
		SIGNAL SQLSTATE '45100'
			SET MESSAGE_TEXT = 'JSON data passed for social media missing required key (socialMedia) ';
	END IF;
					
 END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateOrganizer` (IN `in_organizerId` INT, IN `in_newEmail` VARCHAR(50))  MODIFIES SQL DATA
BEGIN
		DECLARE errorCount INT DEFAULT 0;
        DECLARE NESTED BOOLEAN DEFAULT true;
        
		DECLARE email_exists CONDITION FOR 1062;
        
        DECLARE EXIT HANDLER FOR  email_exists
         BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN 
            
            ROLLBACK; 
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Email address already used!!!';
            ELSE 
            RESIGNAL SET MESSAGE_TEXT = 'Email address already used';
            END IF;
        END;
     
        
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN ROLLBACK; END IF;
            RESIGNAL;
            
        END;
     
            IF transactionCount() = 0 THEN
				START TRANSACTION;
                SET NESTED = false;
			END IF;
            
                  
				PREPARE email_update_prepare FROM
                'UPDATE `egate_db`.`organizer` 
					SET `e_mail` = ?
                    WHERE `ORGANIZER_ID` = ? ';
				SET @organizerId = in_organizerId;
				SET @email = in_newEmail;
                
                EXECUTE email_update_prepare USING @email,@organizerId;
                
                IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
                
                DEALLOCATE PREPARE email_update_prepare;
	
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateOrganizerEmail` (IN `in_organizerId` INT, IN `in_newEmail` VARCHAR(50))  MODIFIES SQL DATA
BEGIN
		DECLARE errorCount INT DEFAULT 0;
        DECLARE NESTED BOOLEAN DEFAULT true;
        
		DECLARE email_exists CONDITION FOR 1062;
        
        DECLARE EXIT HANDLER FOR  email_exists
         BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN 
            
            ROLLBACK; 
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Email address already used!!!';
            ELSE 
            RESIGNAL SET MESSAGE_TEXT = 'Email address already used';
            END IF;
        END;
     
        
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN ROLLBACK; END IF;
            RESIGNAL;
            
        END;
     
            IF transactionCount() = 0 THEN
				START TRANSACTION;
                SET NESTED = false;
			END IF;
            
                  
				PREPARE email_update_prepare FROM
                'UPDATE `egate_db`.`organizer` 
					SET `e_mail`= ?
                    WHERE `ORGANIZER_ID` = ? ';
                    
				SET @organizerId = in_organizerId;
				SET @email = in_newEmail;
                
                EXECUTE email_update_prepare USING @email, @organizerId;
                
                IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
                
                DEALLOCATE PREPARE email_update_prepare;
	
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateOrganizerPassword` (IN `in_organizerId` INT, IN `in_oldPassword` VARCHAR(100), IN `in_newPassword` VARCHAR(100))  MODIFIES SQL DATA
BEGIN
		DECLARE errorCount INT DEFAULT 0;
        DECLARE NESTED BOOLEAN DEFAULT true;
        
		
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN ROLLBACK; END IF;
            RESIGNAL;
            
        END;
     
            IF transactionCount() = 0 THEN
				START TRANSACTION;
                SET NESTED = false;
			END IF;
		IF (SELECT COUNT(*) 
			FROM `egate_db`.`organizer` 
			WHERE `ORGANIZER_ID` = in_organizerId AND `password` = in_oldPassword) = 1 
		THEN
			
				PREPARE password_update_prepare FROM
                'UPDATE `egate_db`.`organizer` 
					SET `password`= ?
                    WHERE `ORGANIZER_ID` = ? ';
                    
				SET @organizerId = in_organizerId;
				SET @newPassword = in_newPassword;
                
                EXECUTE password_update_prepare USING @newPassword, @organizerId;
                
                IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
                
                DEALLOCATE PREPARE password_update_prepare;
                
		ELSE 
			SIGNAL SQLSTATE '45000'
				SET MESSAGE_TEXT = 'Incorrect Old Password, Try Again!';
		END IF;
	
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateOrganizerProfile` (IN `in_organizerId` INT, IN `in_profileInfo` JSON)  MODIFIES SQL DATA
BEGIN
		DECLARE errorCount INT DEFAULT 0;
        DECLARE NESTED BOOLEAN DEFAULT true;
        
		DECLARE email_exists CONDITION FOR 1062;
        
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN ROLLBACK; END IF;
            RESIGNAL;
            
        END;
     
            IF transactionCount() = 0 THEN
				START TRANSACTION;
                SET NESTED = false;
			END IF;
            
            IF JSON_CONTAINS_PATH(in_profileInfo, 'all', '$.firstName', '$.lastName') THEN
            
				PREPARE organizer_update_prepare FROM
                'UPDATE `egate_db`.`organizer` 
					SET `first_name` = ?, `last_name` = ?, `gender` = ? , `title` = ? , `position`= ?,`birthdate` = ?, `picture` = ?, `bio` = ?
                    WHERE `ORGANIZER_ID` = ? ';
				SET @organizerId = in_organizerId;
				SET @fname = in_profileInfo->>'$.firstName';
                SET @lname = in_profileInfo->>'$.lastName';
                SET @gender = in_profileInfo->>'$.gender';
                SET @title = in_profileInfo->>'$.title';
                SET @pos  = in_profileInfo->>'$.organizerPosition';
                SET @bday = in_profileInfo->>'$.birthdate';
                SET @image = in_profileInfo->>'$.organizerImage';
                SET @bio = in_profileInfo->>'$.aboutOrganizer';
                
                EXECUTE organizer_update_prepare USING @fname,@lname, @gender, @title, @pos, @bday, @image, @bio, @organizerId;
                
                IF NESTED = false AND errorCount = 0 THEN COMMIT; END IF;
                
                DEALLOCATE PREPARE organizer_update_prepare;
		ELSE 
			SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'required first name and last name not provided ';
		END IF;
        
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `updateSubscription` (IN `in_subscription` JSON, OUT `out_subscriptionId` INT)  MODIFIES SQL DATA
BEGIN
		DECLARE NESTED BOOLEAN DEFAULT true;
        DECLARE errorCount INT DEFAULT 0;
        DECLARE subscriptions JSON;
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
			GET DIAGNOSTICS errorCount = NUMBER;
            IF NESTED = false THEN ROLLBACK; END IF;
            RESIGNAL;
        END;
        
				IF transactionCount() = 0 THEN
					START TRANSACTION;
                    SET NESTED = false;
				END IF;
                
                
			IF JSON_CONTAINS_PATH(in_subscription, 'all', '$[*].subscriberId' ,'$[*].categoryId') OR JSON_CONTAINS_PATH(in_subscription, 'all', '$[*].subscrptionId')  THEN
            
				
                
                
                    PREPARE delete_subscription_prepare FROM 
                    'DELETE FROM subscription WHERE `SUBSCRIBER_ID` = ? AND `CATEGORY_ID` = ? OR SUBSCRIPTION_ID = ?';
						SET @counter = 0;
						SET subscriptions = in_subscription->>'$[0].subscription';
                        
                        WHILE @counter < JSON_LENGTH( subscriptions ) DO
							
							SET @categoryId = JSON_EXTRACT(subscriptions, CONCAT('$[',@counter,'].categoryId'));
                            SET @subscriberId = JSON_EXTRACT(subscriptions, CONCAT('$[',@counter,'].subscriberId'));
							SET @subscriptionId = JSON_EXTRACT(subscriptions, CONCAT('$[',@counter,'].subscriptionId'));
                            
                            EXECUTE delete_subscription_prepare USING @subscriberId, @categoryId, @subscriptionId;
                            
                            SET @counter = @counter + 1;
					END WHILE;
                    DEALLOCATE PREPARE delete_subscription_prepare;
                    
						IF errorCount = 0 AND NESTED = false THEN COMMIT; END IF;
             
			ELSE
            SIGNAL SQLSTATE '45000'
						SET MYSQL_ERRNO = 50,
							MESSAGE_TEXT = 'json parameter expected email and subscription array containing category IDs';
			END IF;
                
            
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `availableTicket` (`in_ticketId` INT) RETURNS INT(11) READS SQL DATA
BEGIN
		SET @total = 0;
        
        SELECT `available` FROM `eventTicket` 
			WHERE `TICKET_ID` = in_ticketId  INTO @total;
        

	RETURN(@total);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `email_exists` (`email_address` VARCHAR(50)) RETURNS TINYINT(1) READS SQL DATA
BEGIN
DECLARE id INT DEFAULT 0;
DECLARE email_count INT DEFAULT 0;
DECLARE email_exists BOOLEAN;

SELECT COUNT(*) INTO email_count 
FROM organizer
WHERE LOWER(e_mail) = LOWER(email_address);

   IF email_count > 0 THEN 
		SET email_exists = TRUE;
   ELSE
   SET email_exists = FALSE;
END IF;
   
RETURN(email_exists);

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `eventStatus` (`in_eventId` INT) RETURNS VARCHAR(20) CHARSET latin1 READS SQL DATA
BEGIN

	DECLARE eventStatus VARCHAR(20) DEFAULT NULL;
    
		
        
        SELECT `status` FROM `event` 
			WHERE `EVENT_ID` = in_eventId  INTO eventStatus;
		
	RETURN(eventStatus);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `eventTicketCount` (`in_eventId` INT) RETURNS INT(11) READS SQL DATA
BEGIN
		SET @total = 0;
        
        SELECT COUNT(*) AS `count` FROM `eventTicket` WHERE `EVENT_ID` = in_eventId INTO @total;
        

	RETURN(@total);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `getEventAttendeeId` (`in_eventId` INT, `in_attendeePhone` INT) RETURNS INT(11) READS SQL DATA
BEGIN
	DECLARE idNumber INT DEFAULT NULL;
    
			
				SELECT `ATTENDEE_ID` 
                FROM `eventAttendee`
                WHERE `EVENT_ID`  = in_eventId AND `phone` = in_attendeePhone INTO idNumber;
                
	RETURN idNumber;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `getOrganizationId` (`in_organizerId` INT) RETURNS INT(11) READS SQL DATA
BEGIN
	DECLARE ID INT DEFAULT NULL;
		SELECT `ORGANIZATION_ID` from `organization` 
        LEFT JOIN `organizer` USING(`ORGANIZATION_ID`)
        WHERE `ORGANIZER_ID` = in_organizerId INTO ID;
        
	RETURN ID;
 END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `isValidEmail` (`in_value` VARCHAR(50)) RETURNS TINYINT(1) NO SQL
BEGIN

	DECLARE result BOOLEAN DEFAULT false;
    
		IF in_value REGEXP '^[A-Za-z0-9._%-]+@[A-z0-9.-]+\\.[A-Z]{2,4}$'	THEN
			SET result = true;
		ELSE
			SET result = false;
		END IF;
	
    RETURN(result);

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `isValidEventStatus` (`in_value` VARCHAR(50)) RETURNS TINYINT(1) NO SQL
BEGIN

	DECLARE result BOOLEAN DEFAULT false;
    
		IF in_value REGEXP '^(OPEN|CLOSED|DRAFT)$'	THEN
			SET result = true;
		ELSE
			SET result = false;
		END IF;
	
    RETURN(result);

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `isValidFloat` (`in_value` VARCHAR(20)) RETURNS TINYINT(1) NO SQL
BEGIN

	DECLARE result BOOLEAN DEFAULT false;
    
		IF in_value REGEXP '^[0-9]+[\.]?[0-9]*$'	THEN
			SET result = true;
		ELSE
			SET result = false;
		END IF;
	
    RETURN(result);

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `isValidInt` (`in_value` VARCHAR(20)) RETURNS TINYINT(1) NO SQL
BEGIN

	DECLARE result BOOLEAN DEFAULT false;
    
		IF in_value REGEXP '^[0-9]+$'	THEN
			SET result = true;
		ELSE
			SET result = false;
		END IF;
	
    RETURN(result);

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `isValidName` (`in_value` VARCHAR(30)) RETURNS TINYINT(1) NO SQL
BEGIN

	DECLARE result BOOLEAN DEFAULT false;
    
		IF in_value REGEXP '^[A-Za-z]+$' THEN
			SET result = true;
		ELSE
			SET result = false;
		END IF;
	
    RETURN(result);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `isValidPhone` (`in_value` VARCHAR(15)) RETURNS TINYINT(1) NO SQL
BEGIN

	DECLARE result BOOLEAN DEFAULT false;
    
		IF in_value REGEXP '^[+]?([0-9][0-9])?[0-9]{3,4}[0-9]{6}$'	THEN
			SET result = true;
		ELSE
			SET result = false;
		END IF;
	
    RETURN(result);

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `isValidReciept` (`in_eventId` INT, `in_recieptId` INT) RETURNS TINYINT(1) READS SQL DATA
BEGIN
		DECLARE result BOOLEAN DEFAULT false;
        
        IF (SELECT COUNT(*) FROM `egate_db`.`eventReciepts` WHERE `eventId` = in_eventId AND `recieptId` = in_recieptId) = 1 THEN
			SET result = true;
		ELSE	
			SET result = false;
		END IF;
        
	RETURN result;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `isValidText` (`in_value` TEXT) RETURNS TINYINT(1) NO SQL
BEGIN

	DECLARE result BOOLEAN DEFAULT false;
    
		IF in_value REGEXP '.+'	THEN
			SET result = true;
		ELSE
			SET result = false;
		END IF;
	
    RETURN(result);

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `isValidTicketType` (`in_value` VARCHAR(50)) RETURNS TINYINT(1) NO SQL
BEGIN

	DECLARE result BOOLEAN DEFAULT false;
    
		IF in_value REGEXP '[FREE|PAID]'	THEN
			SET result = true;
		ELSE
			SET result = false;
		END IF;
	
    RETURN(result);

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `isValidTime` (`in_value` VARCHAR(15)) RETURNS TINYINT(1) NO SQL
BEGIN

	DECLARE result BOOLEAN DEFAULT false;
    
		IF in_value REGEXP '^[0-9]{2}:[0-9]{2}:[0-9]{2}$' OR in_value REGEXP '^[0-9]{2}:[0-9]{2}$' THEN
			SET result = true;
		ELSE
			SET result = false;
		END IF;
	
    RETURN(result);

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `is_events_billingAddress` (`in_eventId` INT, `in_providerId` INT) RETURNS TINYINT(1) BEGIN
	DECLARE result BOOLEAN DEFAULT false;
    
	IF (
			SELECT COUNT(*)
			FROM serviceprovider
				LEFT JOIN billingaddress USING(PROVIDER_ID)
				LEFT JOIN organizer USING(ORGANIZATION_ID)
				LEFT JOIN event USING (ORGANIZER_ID)
			WHERE EVENT_ID = in_eventId AND PROVIDER_ID = in_providerId 
	) >= 1 THEN
            
            SET result = true;
	ELSE           SET result = false;
            
            END IF;
            
    RETURN result;        
            
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `organizationExist` (`in_organizationId` INT, `in_organizerId` INT) RETURNS TINYINT(1) READS SQL DATA
BEGIN
		SET @result = 0;
        
        IF (SELECT COUNT(*) FROM `organizer`
			WHERE `ORGANIZATION_ID` = in_organizationId AND `ORGANIZER_ID` = in_organizerId = 1)
		THEN
				SET @result = true;
		ELSE 
			SET @result = false;
		END IF;
        
        

	RETURN(@result);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `organizerEventExist` (`in_organizerId` INT, `in_eventId` INT) RETURNS TINYINT(1) READS SQL DATA
BEGIN
DECLARE result BOOLEAN DEFAULT false;

		IF (SELECT COUNT(*) FROM `event` 
			WHERE `ORGANIZER_ID` = in_organizerId AND `EVENT_ID` = in_eventId) = 1
		THEN
				SET result = true;
		ELSE
				SET result = false;
		END IF;
	RETURN(result);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `ticketStatus` (`in_ticketId` INT) RETURNS VARCHAR(15) CHARSET latin1 READS SQL DATA
BEGIN
		DECLARE ticketStatus VARCHAR(15) DEFAULT '';
       
       SELECT `status`
       FROM `eventTicket`
       WHERE `TICKET_ID` = in_ticketId INTO ticketStatus;

RETURN ticketStatus;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `ticketType` (`in_ticketId` INT) RETURNS VARCHAR(15) CHARSET latin1 READS SQL DATA
BEGIN
		DECLARE ticketType VARCHAR(15) DEFAULT '';
       
       SELECT `type`
       FROM `eventTicket`
       WHERE `TICKET_ID` = in_ticketId INTO ticketType;

RETURN ticketType;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `transactionCount` () RETURNS INT(11) READS SQL DATA
BEGIN
DECLARE trans INT DEFAULT 0;

SELECT count(1)  FROM information_schema.innodb_trx 
    WHERE trx_mysql_thread_id = CONNECTION_ID() INTO trans;
RETURN trans;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `billingaddress`
--

CREATE TABLE `billingaddress` (
  `BILLING_ID` int(11) NOT NULL,
  `ORGANIZATION_ID` int(11) NOT NULL,
  `PROVIDER_ID` int(11) NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `added_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_updated` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `billingaddress`
--

INSERT INTO `billingaddress` (`BILLING_ID`, `ORGANIZATION_ID`, `PROVIDER_ID`, `phone_number`, `added_on`, `last_updated`) VALUES
(3, 173, 1, '234982394', '2017-08-28 19:50:36', '2017-08-28 19:50:36');

-- --------------------------------------------------------

--
-- Stand-in structure for view `bookingdetails`
-- (See below for the actual view)
--
CREATE TABLE `bookingdetails` (
`eventId` bigint(11)
,`attendeeId` bigint(11)
,`bookingId` bigint(11)
,`ticketId` bigint(11)
,`firstName` varchar(20)
,`lastName` varchar(20)
,`billingAddress` varchar(15)
,`serviceProvider` varchar(10)
,`paymentAddress` varchar(15)
,`totalPrice` double
,`bookedOn` datetime
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `bookingstatus`
-- (See below for the actual view)
--
CREATE TABLE `bookingstatus` (
`BOOKING_ID` int(11)
,`RECIEPT_ID` int(11)
,`status` varchar(7)
);

-- --------------------------------------------------------

--
-- Table structure for table `checkins`
--

CREATE TABLE `checkins` (
  `CHECK_IN_ID` int(11) NOT NULL,
  `RECIEPT_ID` int(11) NOT NULL,
  `status` tinyint(1) NOT NULL DEFAULT '1',
  `first_check_in` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_check_in` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_check_out` datetime DEFAULT NULL,
  `updated_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `EVENT_ID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `checkins`
--

INSERT INTO `checkins` (`CHECK_IN_ID`, `RECIEPT_ID`, `status`, `first_check_in`, `last_check_in`, `last_check_out`, `updated_on`, `EVENT_ID`) VALUES
(1, 10, 0, '2017-09-21 17:11:36', '2017-09-21 17:11:36', '2017-09-21 18:33:22', '2017-09-21 18:33:22', 798),
(2, 12, 1, '2017-09-21 17:49:23', '2017-09-21 17:49:23', NULL, '2017-09-21 17:49:23', 798),
(4, 11, 0, '2017-09-21 17:50:05', '2017-09-21 17:50:05', '2017-09-21 18:47:46', '2017-09-21 18:47:46', 798);

--
-- Triggers `checkins`
--
DELIMITER $$
CREATE TRIGGER `AI_checkIn_validator` AFTER INSERT ON `checkins` FOR EACH ROW BEGIN
		
        UPDATE `egate_db`.`reciept` SET `status` = 'USED' WHERE `RECIEPT_ID` = NEW.RECIEPT_ID;
		
END
$$
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
            
		
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `confirmerdbookings`
-- (See below for the actual view)
--
CREATE TABLE `confirmerdbookings` (
`eventId` int(11)
,`reservationId` int(11)
,`bookingId` int(11)
,`RECIEPT_ID` int(11)
,`firstName` varchar(20)
,`lastName` varchar(20)
,`email` varchar(30)
,`phoneNumber` varchar(15)
,`paymentProvider` enum('HELLO CASH','MBIRR')
,`bookedOn` datetime
,`bookingStatus` enum('PENDING','CONFIRMED','CANCELED')
,`ticketId` int(11)
,`recieptStatus` enum('ACTIVE','USED')
,`recieptIssued` datetime
);

-- --------------------------------------------------------

--
-- Table structure for table `deactivated`
--

CREATE TABLE `deactivated` (
  `DEACTIVATION_ID` int(11) NOT NULL,
  `registered_on` date NOT NULL,
  `deactivated_on` date NOT NULL,
  `ORGANIZATION_ID` int(11) NOT NULL,
  `organizer_name` varchar(30) DEFAULT NULL,
  `email_address` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `deactivated`
--

INSERT INTO `deactivated` (`DEACTIVATION_ID`, `registered_on`, `deactivated_on`, `ORGANIZATION_ID`, `organizer_name`, `email_address`) VALUES
(9, '2017-04-18', '2017-05-13', 85, 'mike12 araya', 'vaaatfgasaanasssnnncavwkim'),
(10, '2017-04-18', '2017-05-13', 86, 'mike1 araya', 'vaaatfgasanasssnnncavwkim'),
(11, '2017-04-25', '2017-05-13', 90, 'jsakdhkjah dshfksdhfk', 'mike8@gmail.com'),
(12, '2017-04-25', '2017-05-13', 91, 'ejrhwekjrh djksfhskjdfh', 'sjakhdaksdh@gmila.vom'),
(13, '2017-04-25', '2017-05-13', 92, 'Mikael Araya', 'admin@events.com'),
(14, '2017-05-03', '2017-06-05', 146, 'Mikael Araya', 'admin@account.com');

-- --------------------------------------------------------

--
-- Table structure for table `deactivation_reasons`
--

CREATE TABLE `deactivation_reasons` (
  `REASON_ID` int(11) NOT NULL,
  `DEACTIVATION_ID` int(11) NOT NULL,
  `reason` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `deactivation_reasons`
--

INSERT INTO `deactivation_reasons` (`REASON_ID`, `DEACTIVATION_ID`, `reason`) VALUES
(5, 9, '0'),
(6, 9, '0'),
(7, 10, '0'),
(8, 10, '0'),
(9, 11, 'i hate it'),
(10, 11, 'found different solution'),
(11, 12, 'i'),
(12, 12, 'found different solution'),
(13, 13, 'just want out'),
(14, 13, 'f'),
(15, 14, ''),
(16, 14, 'f');

-- --------------------------------------------------------

--
-- Table structure for table `event`
--

CREATE TABLE `event` (
  `EVENT_ID` int(11) NOT NULL,
  `ORGANIZER_ID` int(11) NOT NULL,
  `name` varchar(30) NOT NULL,
  `discription` text NOT NULL,
  `picture` varchar(100) DEFAULT NULL,
  `venue` varchar(30) NOT NULL,
  `country` varchar(30) NOT NULL DEFAULT 'Ethiopia',
  `city` varchar(30) NOT NULL,
  `sub_city` varchar(50) NOT NULL,
  `location` varchar(50) NOT NULL,
  `longitude` varchar(30) DEFAULT NULL,
  `latitude` varchar(30) DEFAULT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `status` enum('OPEN','DRAFT','ACTIVE','CLOSED') NOT NULL DEFAULT 'DRAFT',
  `created_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `CATEGORY_ID` int(11) DEFAULT NULL,
  `total_view` int(11) DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `event`
--

INSERT INTO `event` (`EVENT_ID`, `ORGANIZER_ID`, `name`, `discription`, `picture`, `venue`, `country`, `city`, `sub_city`, `location`, `longitude`, `latitude`, `start_date`, `end_date`, `start_time`, `end_time`, `status`, `created_on`, `last_updated`, `CATEGORY_ID`, `total_view`) VALUES
(794, 166, 'Event', 'Hfgdsjgfsd', NULL, 'Sundayt', 'Ethiopia', 'Addis Ababa', 'Bole', 'Bole Mikael', NULL, NULL, '2017-09-27', '2017-09-28', '17:45:00', '10:50:00', 'OPEN', '2017-09-17 16:49:52', '2017-10-01 15:14:17', 1, 4),
(795, 166, 'Event', 'Sdfsdfjh fsdfhgdsjf', '00 - Logic_Young_Broke_Infamous-front-large.jpg', 'sundayt', 'Ethiopia', 'Addis Ababa', 'Bole', 'Bole Mikael', NULL, 'false', '2017-09-22', '2017-09-23', '17:45:00', '10:50:00', 'DRAFT', '2017-09-17 16:50:02', '2017-09-23 19:29:22', 1, 2),
(796, 166, 'Event', 'Sdfsdfjh fsdfhgdsjf', '00 - Logic_Young_Broke_Infamous-front-large.jpg', 'sundayt', 'Ethiopia', 'Addis Ababa', 'Bole', 'Bole Mikael', NULL, 'false', '2017-09-22', '2017-09-23', '17:45:00', '10:50:00', 'DRAFT', '2017-09-17 16:50:48', '2017-09-17 16:50:48', 1, 0),
(797, 166, 'Event', 'Event discription', '00 Cover.jpg', 'Venuw', 'Country', 'City', 'Sub City', 'Location', NULL, 'false', '2017-09-22', '2017-09-23', '09:45:00', '09:45:00', 'ACTIVE', '2017-09-17 17:20:43', '2017-09-24 20:14:35', 1, 65),
(798, 166, 'booked', 'Dsfsjdfhkjsd fsdfjkdshfkj', '00 Cover.jpg', 'Jdsfkjsdh', 'Dsfs', 'Sddfsdjkjfh', 'Dfjdfhkgj', 'Dsfkjdsflk', NULL, 'false', '2017-09-22', '2017-09-23', '14:50:00', '17:29:00', 'ACTIVE', '2017-09-17 17:29:57', '2017-09-24 19:53:59', 1, 186),
(799, 166, 'Dsfsdhfjk', 'Dsfsjdfhkjsd fsdfjkdshfkj', '00 Cover.jpg', 'Jdsfkjsdh', 'Dsfs', 'Sddfsdjkjfh', 'Dfjdfhkgj', 'Dsfkjdsflk', NULL, 'false', '2017-09-22', '2017-09-23', '14:50:00', '17:29:00', 'DRAFT', '2017-09-17 17:30:03', '2017-09-17 17:30:03', 1, 0),
(801, 166, 'Tester', 'Lupe fiasco album cover art', 'Folder.jpg', 'Millenium Hall', 'Ethiopia', 'Addis Ababa', 'Bole', 'Bole Mikael', NULL, 'false', '2017-09-26', '2017-09-27', '13:25:00', '10:50:00', 'OPEN', '2017-09-20 20:30:19', '2017-09-22 18:10:20', 1, 8),
(802, 166, 'Dsfhsd', 'Sdfsdfh', 'null', 'Hgdsfj', 'Ethiopia', 'Addis Ababa', 'Bole', 'Dskfjsd', NULL, 'false', '2017-09-28', '2017-09-29', '01:05:00', '10:50:00', 'OPEN', '2017-09-25 20:33:32', '2017-09-25 20:33:32', 1, 0),
(803, 166, 'Fdgdfgj', 'Dfgdf', 'null', 'Jhdfsjdfh', 'Dsfkjsdf', 'Dfgdf', 'Dfg', 'Dfg', NULL, 'false', '2017-09-27', '2017-09-28', '13:45:00', '10:50:00', 'OPEN', '2017-09-25 20:40:21', '2017-09-25 20:40:21', 1, 0),
(804, 166, 'Dfs', 'Dfg', 'null', 'Fdgdfg', 'Fdg', 'Fdg', 'Fdg', 'Dfg', NULL, 'false', '2017-09-27', '2017-09-29', '09:45:00', '10:50:00', 'OPEN', '2017-09-25 20:43:57', '2017-09-25 20:43:57', 1, 0),
(805, 166, 'Sdsd', 'Dfjkfhg', 'null', 'Hjg', 'Cvbq', 'Gjg', 'Jg', 'Jg', NULL, 'false', '2017-09-27', '2017-09-29', '06:30:00', '09:45:00', 'OPEN', '2017-09-25 20:46:29', '2017-09-25 20:46:29', 1, 0),
(806, 166, 'Fdshjk', 'Vcbkjcvkbj', 'null', 'Kjfhgkdfj', 'Sdfsdf', 'Fgdjh', 'Jhkjh', 'Jkhk', NULL, 'false', '2017-09-27', '2017-09-28', '21:25:00', '09:45:00', 'OPEN', '2017-09-25 20:50:12', '2017-09-25 20:50:12', 1, 0),
(807, 166, 'Dgfdfh', 'Dsfjhsdjk', 'null', 'Hjkdfk', 'Dfj', 'Hjkhk', 'Hkhk', 'Hk', NULL, 'false', '2017-09-28', '2017-09-29', '05:25:00', '14:45:00', 'OPEN', '2017-09-25 20:56:27', '2017-09-25 20:56:27', 1, 0),
(808, 166, 'Sdfshkj', 'Dsfhksjdfh', 'null', 'Hkjhkj', 'Cvbcv', 'Hjgjhg', 'Jggj', 'Jgg', NULL, 'false', '2017-09-28', '2017-09-29', '06:30:00', '09:45:00', 'OPEN', '2017-09-25 20:59:07', '2017-09-25 20:59:07', 1, 0),
(809, 166, 'Dfjgdh', 'Dshgjhgf', 'null', 'Hgfggh', 'Ethiopia', 'Addis Ababa', 'Bole', 'Bole Mikael', NULL, 'false', '2017-09-30', '2017-10-01', '05:25:00', '10:50:00', 'OPEN', '2017-09-27 15:49:20', '2017-09-27 15:49:20', 1, 0),
(810, 166, 'Jrhrterjkh', 'Dsjfgsdkfjh', 'null', 'Fdgbdfm', 'Ethiopia', 'Addis Ababa', 'Bole', 'Bole Mikael', NULL, 'false', '2017-09-30', '2017-10-01', '10:50:00', '14:25:00', 'OPEN', '2017-09-27 15:53:31', '2017-09-27 15:53:31', 1, 0),
(811, 166, 'Yjgjhgj', 'Hfjhgjhdgfjdg', 'null', 'Hjkhkj', 'Ethiopia', 'Addis Ababa', 'Bole', 'Bole Mikael', NULL, 'false', '2017-09-30', '2017-10-01', '14:30:00', '10:50:00', 'OPEN', '2017-09-27 15:56:47', '2017-09-27 15:56:47', 1, 0),
(812, 166, 'Hsdgjhgjh', 'Hfghfhgf', 'null', 'Dhsgdsjh', 'Ethiopia', 'Addis Ababa', 'Adklasjdlkasjd', 'Ddjdj', NULL, 'false', '2017-09-29', '2017-09-30', '14:50:00', '05:25:00', 'OPEN', '2017-09-27 15:59:42', '2017-09-27 15:59:42', 1, 0),
(813, 166, 'Hgjhg', 'Sdjfhkjsdfhkdsj', 'null', 'Gjhgjh', 'Ethiopia', 'Addis Ababa', 'Bole', 'Bole Mikael', NULL, 'false', '2017-09-29', '2017-09-30', '10:50:00', '14:50:00', 'OPEN', '2017-09-27 16:05:39', '2017-09-27 16:05:39', 1, 0),
(814, 166, 'Test', 'Sdfhdskjfhsjd', 'null', 'Hhha', 'Ethiopia', 'A', 'A', 'A', NULL, 'false', '2017-09-29', '2017-09-30', '10:50:00', '10:50:00', 'OPEN', '2017-09-27 18:01:13', '2017-09-27 18:01:13', 1, 0),
(815, 166, 'Test', 'Sdfhdskjfhsjd', 'null', 'Hhha', 'Ethiopia', 'A', 'A', 'A', NULL, 'false', '2017-09-29', '2017-09-30', '10:50:00', '10:50:00', 'OPEN', '2017-09-27 18:01:29', '2017-09-27 18:01:29', 1, 0),
(816, 166, 'Test', 'Sdfhdskjfhsjd', 'null', 'Hhha', 'Ethiopia', 'A', 'A', 'A', NULL, 'false', '2017-09-29', '2017-09-30', '10:50:00', '10:50:00', 'OPEN', '2017-09-27 18:01:44', '2017-09-27 18:01:44', 1, 0),
(817, 166, 'Gg', 'Dskjlksdjlks', 'null', 'Gg', 'Ethe', 'Ajhjk', 'Jhkjh', 'Jhkhkj', NULL, 'false', '2017-09-29', '2017-09-30', '18:30:00', '09:45:00', 'OPEN', '2017-09-27 18:05:34', '2017-09-27 18:05:34', 1, 0),
(818, 166, 'Jhjh', 'Dsfkjsdlkf', 'null', 'Jhgjhg', 'Fdgdf', 'Dfsjdh', 'Dfsdjkfhkj', 'Dsfjfk', NULL, 'false', '2017-09-29', '2017-09-30', '09:45:00', '10:50:00', 'OPEN', '2017-09-27 18:13:03', '2017-09-27 18:13:03', 1, 0),
(819, 166, 'Sdfkjdsk', 'Dsfksdjflk', 'null', 'Sdhfgdsf', 'Asdjsahdkj', 'Asdkjaskl', 'Ksaljdlk', 'Ksdjflksdf', NULL, 'false', '2017-09-29', '2017-09-30', '18:50:00', '09:45:00', 'OPEN', '2017-09-27 18:15:23', '2017-09-27 18:15:23', 1, 0);

--
-- Triggers `event`
--
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
		
       
	
    END
$$
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
        
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `eventattendee`
--

CREATE TABLE `eventattendee` (
  `ATTENDEE_ID` int(11) NOT NULL,
  `EVENT_ID` int(11) NOT NULL,
  `phone` varchar(15) NOT NULL,
  `first_name` varchar(20) NOT NULL,
  `last_name` varchar(20) NOT NULL,
  `email` varchar(30) DEFAULT NULL,
  `registered_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `PROVIDER_ID` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `eventattendee`
--

INSERT INTO `eventattendee` (`ATTENDEE_ID`, `EVENT_ID`, `phone`, `first_name`, `last_name`, `email`, `registered_on`, `last_updated`, `PROVIDER_ID`) VALUES
(2, 798, '0191998877', 'djjd', 'jdjd', NULL, '2017-09-18 17:36:51', '2017-09-18 17:36:51', NULL),
(3, 798, '0912669988', 'Araya', 'Mikael', NULL, '2017-09-21 14:35:12', '2017-09-21 16:03:26', 1),
(13, 798, '0912669989', 'Araya', 'Mikael', NULL, '2017-09-21 14:44:32', '2017-09-21 15:16:57', 2),
(28, 798, '0912669977', 'Araya', 'Mikael', NULL, '2017-09-21 16:31:17', '2017-09-21 16:31:17', 1);

--
-- Triggers `eventattendee`
--
DELIMITER $$
CREATE TRIGGER `BI_eventAttendeeValidator` BEFORE INSERT ON `eventattendee` FOR EACH ROW BEGIN
			
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
            
           
 END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `BU_eventAttendeeValidator` BEFORE UPDATE ON `eventattendee` FOR EACH ROW BEGIN
			
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
 END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `eventbooking`
--

CREATE TABLE `eventbooking` (
  `BOOKING_ID` int(11) NOT NULL,
  `TICKET_ID` int(11) NOT NULL,
  `ATTENDEE_ID` int(11) NOT NULL,
  `booked_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status` enum('PENDING','CONFIRMED','CANCELED') NOT NULL DEFAULT 'PENDING',
  `last_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `eventbooking`
--

INSERT INTO `eventbooking` (`BOOKING_ID`, `TICKET_ID`, `ATTENDEE_ID`, `booked_on`, `status`, `last_updated`) VALUES
(7, 320, 28, '2017-09-21 16:31:17', 'CONFIRMED', '2017-09-21 16:31:17'),
(8, 320, 28, '2017-09-21 16:31:17', 'CONFIRMED', '2017-09-21 16:31:17'),
(9, 320, 28, '2017-09-21 16:31:17', 'CONFIRMED', '2017-09-21 16:31:17'),
(10, 320, 28, '2017-09-21 16:31:17', 'CONFIRMED', '2017-09-21 16:31:17'),
(11, 320, 28, '2017-09-21 16:36:30', 'CONFIRMED', '2017-09-21 16:36:30'),
(12, 320, 28, '2017-09-21 16:36:30', 'CONFIRMED', '2017-09-21 16:36:30'),
(13, 320, 28, '2017-09-21 16:36:30', 'CONFIRMED', '2017-09-21 16:36:30'),
(14, 320, 28, '2017-09-21 16:36:30', 'CONFIRMED', '2017-09-21 16:36:30'),
(15, 320, 28, '2017-09-21 16:36:33', 'CONFIRMED', '2017-09-21 16:36:33'),
(16, 320, 28, '2017-09-21 16:36:33', 'CONFIRMED', '2017-09-21 16:36:33'),
(17, 320, 28, '2017-09-21 16:36:33', 'CONFIRMED', '2017-09-21 16:36:33'),
(18, 320, 28, '2017-09-21 16:36:33', 'CONFIRMED', '2017-09-21 16:36:33'),
(19, 320, 3, '2017-09-21 18:52:38', 'CONFIRMED', '2017-09-21 18:52:38'),
(20, 320, 3, '2017-09-21 18:52:38', 'CONFIRMED', '2017-09-21 18:52:38'),
(21, 320, 3, '2017-09-21 18:52:38', 'CONFIRMED', '2017-09-21 18:52:38'),
(22, 320, 3, '2017-09-21 18:52:38', 'CONFIRMED', '2017-09-21 18:52:38'),
(23, 320, 3, '2017-09-21 18:52:38', 'CONFIRMED', '2017-09-21 18:52:38'),
(24, 320, 3, '2017-09-21 18:52:38', 'CONFIRMED', '2017-09-21 18:52:38'),
(25, 320, 3, '2017-09-21 18:52:38', 'CONFIRMED', '2017-09-21 18:52:38'),
(26, 320, 3, '2017-09-21 18:52:38', 'CONFIRMED', '2017-09-21 18:52:38'),
(27, 320, 3, '2017-09-21 18:52:38', 'CONFIRMED', '2017-09-21 18:52:38'),
(28, 320, 3, '2017-09-21 18:52:38', 'CONFIRMED', '2017-09-21 18:52:38'),
(29, 320, 3, '2017-09-21 18:52:38', 'CONFIRMED', '2017-09-21 18:52:38'),
(30, 320, 3, '2017-09-21 18:52:38', 'CONFIRMED', '2017-09-21 18:52:38'),
(31, 320, 3, '2017-09-21 18:52:38', 'CONFIRMED', '2017-09-21 18:52:38'),
(32, 320, 3, '2017-09-21 18:52:38', 'CONFIRMED', '2017-09-21 18:52:38'),
(33, 320, 3, '2017-09-21 18:52:38', 'CONFIRMED', '2017-09-21 18:52:38'),
(34, 320, 3, '2017-09-21 18:52:38', 'CONFIRMED', '2017-09-21 18:52:38');

--
-- Triggers `eventbooking`
--
DELIMITER $$
CREATE TRIGGER `AI_bookingValidator` AFTER INSERT ON `eventbooking` FOR EACH ROW BEGIN
 

            IF NEW.`status` = 'CONFIRMED' THEN
				
                INSERT INTO `egate_db`.`reciept`(`BOOKING_ID`, `status`)
					VALUE(NEW.BOOKING_ID, 'ACTIVE');
			END IF;
        
 
 END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `BI_bookingValidator` BEFORE INSERT ON `eventbooking` FOR EACH ROW BEGIN
 

		
			
            
				
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
 
 END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `eventcategory`
--

CREATE TABLE `eventcategory` (
  `CATEGORY_ID` int(11) NOT NULL,
  `category_name` varchar(30) NOT NULL,
  `date_added` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `eventcategory`
--

INSERT INTO `eventcategory` (`CATEGORY_ID`, `category_name`, `date_added`, `last_updated`) VALUES
(1, 'ART', '2017-08-29 17:21:51', '2017-08-29 17:21:51'),
(2, 'SPORT', '2017-08-29 17:21:51', '2017-08-29 17:21:51'),
(3, 'MUSIC', '2017-08-29 17:21:51', '2017-08-29 17:21:51'),
(4, 'CONFERENCE', '2017-08-29 17:21:51', '2017-08-29 17:21:51'),
(5, 'SOCIAL GROUP', '2017-08-29 17:21:51', '2017-08-29 17:21:51');

-- --------------------------------------------------------

--
-- Stand-in structure for view `eventcheckins`
-- (See below for the actual view)
--
CREATE TABLE `eventcheckins` (
`checkInId` int(11)
,`bookingId` int(11)
,`recieptId` int(11)
,`eventId` int(11)
,`status` varchar(3)
,`firstCheckIn` datetime
,`lastCheckout` datetime
,`lastCheckIn` datetime
);

-- --------------------------------------------------------

--
-- Table structure for table `eventcomment`
--

CREATE TABLE `eventcomment` (
  `COMMENT_ID` int(11) NOT NULL,
  `EVENT_ID` int(11) NOT NULL,
  `name` varchar(30) NOT NULL,
  `comment` varchar(255) NOT NULL,
  `commented_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `eventguest`
--

CREATE TABLE `eventguest` (
  `GUEST_ID` int(11) NOT NULL,
  `EVENT_ID` int(11) NOT NULL,
  `first_name` varchar(30) NOT NULL,
  `last_name` varchar(20) NOT NULL,
  `aka_name` varchar(50) DEFAULT NULL,
  `title` varchar(50) DEFAULT NULL,
  `bio` text,
  `image` varchar(100) DEFAULT NULL,
  `date_added` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `eventguest`
--

INSERT INTO `eventguest` (`GUEST_ID`, `EVENT_ID`, `first_name`, `last_name`, `aka_name`, `title`, `bio`, `image`, `date_added`, `last_updated`) VALUES
(83, 794, 'Mikaeldfdg', 'Arayadfgdfg', 'null', 'null', 'null', 'null', '2017-09-17 16:49:52', '2017-09-17 19:18:47'),
(84, 795, 'Mikaeldf', 'Arayasdf', 'dsfsdf', 'null', 'null', 'null', '2017-09-17 16:50:02', '2017-09-17 18:49:58'),
(85, 796, 'Mikael', 'Araya', 'null', 'null', NULL, NULL, '2017-09-17 16:50:48', '2017-09-17 16:50:48'),
(86, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', NULL, NULL, '2017-09-17 18:58:25', '2017-09-17 18:58:25'),
(87, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', NULL, NULL, '2017-09-17 18:58:25', '2017-09-17 18:58:25'),
(88, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:00:29', '2017-09-17 19:00:29'),
(89, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:00:29', '2017-09-17 19:00:29'),
(90, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:00:53', '2017-09-17 19:00:53'),
(91, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:00:54', '2017-09-17 19:00:54'),
(92, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:01:21', '2017-09-17 19:01:21'),
(93, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:01:21', '2017-09-17 19:01:21'),
(94, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:02:05', '2017-09-17 19:02:05'),
(95, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:02:05', '2017-09-17 19:02:05'),
(96, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:03:09', '2017-09-17 19:03:09'),
(97, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:03:09', '2017-09-17 19:03:09'),
(98, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:04:21', '2017-09-17 19:04:21'),
(99, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:04:21', '2017-09-17 19:04:21'),
(100, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:04:45', '2017-09-17 19:04:45'),
(101, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:04:45', '2017-09-17 19:04:45'),
(102, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:05:58', '2017-09-17 19:05:58'),
(103, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:05:58', '2017-09-17 19:05:58'),
(104, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:06:52', '2017-09-17 19:06:52'),
(105, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:06:52', '2017-09-17 19:06:52'),
(106, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:08:27', '2017-09-17 19:08:27'),
(107, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:08:27', '2017-09-17 19:08:27'),
(108, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:10:10', '2017-09-17 19:10:10'),
(109, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:10:10', '2017-09-17 19:10:10'),
(110, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:11:17', '2017-09-17 19:11:17'),
(111, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:11:17', '2017-09-17 19:11:17'),
(112, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:13:42', '2017-09-17 19:13:42'),
(113, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:13:43', '2017-09-17 19:13:43'),
(114, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:13:57', '2017-09-17 19:13:57'),
(115, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:13:57', '2017-09-17 19:13:57'),
(116, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:14:08', '2017-09-17 19:14:08'),
(117, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:14:08', '2017-09-17 19:14:08'),
(118, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:14:51', '2017-09-17 19:14:51'),
(119, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:14:51', '2017-09-17 19:14:51'),
(120, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:15:22', '2017-09-17 19:15:22'),
(121, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:15:22', '2017-09-17 19:15:22'),
(122, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:17:53', '2017-09-17 19:17:53'),
(123, 795, 'Dfsdfds', 'Sdfsdf', 'null', 'null', 'null', 'null', '2017-09-17 19:17:54', '2017-09-17 19:17:54'),
(124, 794, 'Sdfsdfhjk', 'Fdjkghdfkjg', 'fdgdfg', 'null', 'null', 'null', '2017-09-17 19:19:20', '2017-09-17 19:19:20'),
(125, 794, 'Sdfsdfhjk', 'Fdjkghdfkjg', 'fdgdfg', 'null', 'null', 'null', '2017-09-17 19:19:20', '2017-09-17 19:19:20'),
(126, 794, 'Sdfsdfhjk', 'Fdjkghdfkjg', 'fdgdfg', 'null', 'null', 'null', '2017-09-17 19:20:16', '2017-09-17 19:20:16'),
(127, 794, 'Sdfsdfhjk', 'Fdjkghdfkjg', 'fdgdfg', 'null', 'null', 'null', '2017-09-17 19:20:16', '2017-09-17 19:20:16'),
(128, 794, 'Sdfsdfjk', 'Fdjghfdjk', 'fkdgj', 'null', 'null', 'null', '2017-09-17 19:22:32', '2017-09-17 19:22:32'),
(129, 794, 'Sdfsdfjk', 'Fdjghfdjk', 'fkdgj', 'null', 'null', 'null', '2017-09-17 19:22:32', '2017-09-17 19:22:32'),
(130, 794, 'Sdfsdfjk', 'Fdjghfdjk', 'fkdgj', 'null', 'null', 'null', '2017-09-17 19:24:41', '2017-09-17 19:24:41'),
(131, 794, 'Sdfsdfjk', 'Fdjghfdjk', 'fkdgj', 'null', 'null', 'null', '2017-09-17 19:24:42', '2017-09-17 19:24:42'),
(132, 794, 'Sdfsdfjk', 'Fdjghfdjk', 'fkdgj', 'null', 'null', 'null', '2017-09-17 19:27:40', '2017-09-17 19:27:40'),
(133, 794, 'Sdfsdfjk', 'Fdjghfdjk', 'fkdgj', 'null', 'null', 'null', '2017-09-17 19:27:40', '2017-09-17 19:27:40'),
(134, 794, 'Sdfsdfjk', 'Fdjghfdjk', 'fkdgj', 'null', 'null', 'null', '2017-09-17 19:28:44', '2017-09-17 19:28:44'),
(135, 794, 'Sdfsdfjk', 'Fdjghfdjk', 'fkdgj', 'null', 'null', 'null', '2017-09-17 19:28:44', '2017-09-17 19:28:44'),
(136, 794, 'Sdfsdfjk', 'Fdjghfdjk', 'fkdgj', 'null', 'null', 'null', '2017-09-17 19:31:22', '2017-09-17 19:31:22'),
(137, 794, 'Sdfsdfjk', 'Fdjghfdjk', 'fkdgj', 'null', 'null', 'null', '2017-09-17 19:31:22', '2017-09-17 19:31:22'),
(138, 794, 'Sdfsdfjk', 'Fdjghfdjk', 'fkdgj', 'null', 'null', 'null', '2017-09-17 19:32:18', '2017-09-17 19:32:18'),
(139, 794, 'Sdfsdfjk', 'Fdjghfdjk', 'fkdgj', 'null', 'null', 'null', '2017-09-17 19:32:18', '2017-09-17 19:32:18'),
(140, 794, 'Sdfsdfjk', 'Fdjghfdjk', 'fkdgj', 'null', 'null', 'null', '2017-09-17 19:33:11', '2017-09-17 19:33:11'),
(141, 794, 'Sdfsdfjk', 'Fdjghfdjk', 'fkdgj', 'null', 'null', 'null', '2017-09-17 19:33:11', '2017-09-17 19:33:11'),
(142, 794, 'Sdfsdfjk', 'Fdjghfdjk', 'fkdgj', 'null', 'null', 'null', '2017-09-17 19:33:48', '2017-09-17 19:33:48'),
(143, 794, 'Sdfsdfjk', 'Fdjghfdjk', 'fkdgj', 'null', 'null', 'null', '2017-09-17 19:35:10', '2017-09-17 19:35:10'),
(144, 794, 'Sdfsdfjk', 'Fdjghfdjk', 'fkdgj', 'null', 'null', 'null', '2017-09-17 19:35:34', '2017-09-17 19:35:34'),
(145, 794, 'Sdfsdfjk', 'Fdjghfdjk', 'fkdgj', 'null', 'null', 'null', '2017-09-17 19:36:01', '2017-09-17 19:36:01'),
(146, 794, 'Sdfsdfjk', 'Fdjghfdjk', 'fkdgj', 'null', 'null', 'null', '2017-09-17 19:36:37', '2017-09-17 19:36:37'),
(147, 794, 'Sdfsdfjk', 'Fdjghfdjk', 'fkdgj', 'null', 'null', 'null', '2017-09-17 19:39:12', '2017-09-17 19:39:12'),
(148, 794, 'Sdfsdfjk', 'Fdjghfdjk', 'fkdgj', 'null', 'null', 'null', '2017-09-17 19:41:05', '2017-09-17 19:41:05'),
(149, 794, 'Sdfsdfjk', 'Fdjghfdjk', 'fkdgj', 'null', 'null', 'null', '2017-09-17 19:42:15', '2017-09-17 19:42:15'),
(150, 799, 'DFG', 'DFGDFG', 'null', 'null', 'null', 'null', '2017-09-17 20:10:07', '2017-09-17 20:10:07'),
(151, 799, 'Dsfsdsdf', 'Dsfdsf', 'null', 'null', 'null', 'null', '2017-09-17 20:12:20', '2017-09-17 20:12:20'),
(152, 799, 'Dsfsdsdfdsfdsdsfd', 'Dsfdsfdfsfxczxcdsf', 'null', 'null', 'null', 'null', '2017-09-17 20:18:58', '2017-09-17 20:39:56'),
(153, 799, 'Dfgdfgjh', 'Dfghdfjkgh', 'null', 'null', 'null', 'null', '2017-09-17 20:26:10', '2017-09-17 20:26:10'),
(154, 799, 'Dfgdfgjh', 'Dfghdfjkgh', 'null', 'null', 'null', 'null', '2017-09-17 20:27:30', '2017-09-17 20:27:30'),
(155, 799, 'Dfgdfgjh', 'Dfghdfjkgh', 'null', 'null', 'null', 'null', '2017-09-17 20:30:06', '2017-09-17 20:30:06'),
(156, 799, 'Dfgdfgjh', 'Dfghdfjkgh', 'null', 'null', 'null', 'null', '2017-09-17 20:30:36', '2017-09-17 20:30:36'),
(157, 799, 'Dfgdfgjh', 'Dfghdfjkgh', 'null', 'null', 'null', 'null', '2017-09-17 20:31:11', '2017-09-17 20:31:11'),
(158, 799, 'Dfgdfgjhfdg', 'Dfghdfjkgh', 'null', 'null', 'null', 'null', '2017-09-17 20:31:33', '2017-09-17 20:31:33'),
(159, 799, 'Dfgdfgjhfdg', 'Dfghdfjkgh', 'null', 'null', 'null', 'null', '2017-09-17 20:32:06', '2017-09-17 20:32:06'),
(160, 799, 'Dfgdfgjhfdg', 'Dfghdfjkgh', 'null', 'null', 'null', 'null', '2017-09-17 20:33:01', '2017-09-17 20:33:01'),
(161, 799, 'Dfgdfgjhfdg', 'Dfghdfjkgh', 'null', 'null', 'null', 'null', '2017-09-17 20:33:44', '2017-09-17 20:33:44'),
(162, 799, 'Dfgdfgjhfdg', 'Dfghdfjkgh', 'null', 'null', 'null', 'null', '2017-09-17 20:34:39', '2017-09-17 20:34:39'),
(163, 799, 'Dfgdfgjhfdg', 'Dfghdfjkgh', 'null', 'null', 'null', 'null', '2017-09-17 20:36:08', '2017-09-17 20:36:08'),
(164, 799, 'Dfgdfgjhfdg', 'Dfghdfjkgh', 'null', 'null', 'null', 'null', '2017-09-17 20:39:56', '2017-09-17 20:39:56'),
(165, 799, 'Dfgdfgjhfdg', 'Dfghdfjkgh', 'null', 'null', 'null', 'null', '2017-09-17 20:40:57', '2017-09-17 20:40:57'),
(166, 799, 'Dfgdfgjhfdg', 'Dfghdfjkgh', 'null', 'null', 'null', 'null', '2017-09-17 20:41:50', '2017-09-17 20:41:50'),
(167, 799, 'Dfgdfgjhfdg', 'Dfghdfjkgh', 'null', 'null', 'null', 'null', '2017-09-17 20:42:25', '2017-09-17 20:42:25'),
(168, 799, 'Dfgdfgjhfdg', 'Dfghdfjkgh', 'null', 'null', 'null', 'null', '2017-09-17 20:45:18', '2017-09-17 20:45:18'),
(169, 799, 'Dfgdfgjhfdg', 'Dfghdfjkgh', 'null', 'null', 'null', 'null', '2017-09-17 20:45:46', '2017-09-17 20:45:46'),
(170, 799, 'Dfgdfgjhfdg', 'Dfghdfjkgh', 'null', 'null', 'null', 'null', '2017-09-17 20:46:02', '2017-09-17 20:46:02'),
(171, 799, 'Sdfsdflkh', 'Dfjgkhdfjkgh', 'null', 'null', 'null', 'null', '2017-09-17 20:46:02', '2017-09-17 20:46:02'),
(172, 801, 'Mikael', 'Araya', 'StarBoy', 'null', 'null', 'Folder.jpg', '2017-09-20 20:30:19', '2017-09-20 20:30:19'),
(173, 798, 'Mikael', 'Araya', 'StarBoy', 'null', 'null', 'Cover.jpg', '2017-09-22 20:48:36', '2017-09-23 18:18:34'),
(174, 798, 'Mikael', 'Araya', 'Starboy', 'null', 'null', 'Cover.jpg', '2017-09-22 20:48:46', '2017-09-23 18:18:34'),
(175, 798, 'Meseret', 'Abebe', 'Tata', 'null', 'null', 'Cover.jpg', '2017-09-23 18:15:10', '2017-09-23 18:18:34');

--
-- Triggers `eventguest`
--
DELIMITER $$
CREATE TRIGGER `BI_guestValidator` BEFORE INSERT ON `eventguest` FOR EACH ROW BEGIN 
	
    IF 	(ISNULL(NEW.first_name) OR LENGTH(TRIM(NEW.first_name)) = 0 ) OR
		(ISNULL(NEW.last_name) OR LENGTH(TRIM(NEW.last_name)) = 0 )
	THEN
		SIGNAL SQLSTATE '45000' 
			SET MYSQL_ERRNO = 3,
				MESSAGE_TEXT =  'mising required value, guest first name & last name are required fields and 
						can not be null or empty';
	END IF;
			
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `BU_guestValidator` BEFORE UPDATE ON `eventguest` FOR EACH ROW BEGIN
				
	IF (ISNULL(NEW.first_name) OR LENGTH(TRIM(NEW.first_name)) = 0 ) THEN	SET NEW.first_name = OLD.first_name;	END IF;
                
	IF (ISNULL(NEW.last_name) OR LENGTH(TRIM(NEW.last_name))  =  0 )  THEN	SET NEW.last_name = OLD.last_name;	END IF;			
                
                
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `eventreciepts`
-- (See below for the actual view)
--
CREATE TABLE `eventreciepts` (
`eventId` int(11)
,`ticketId` int(11)
,`bookingId` int(11)
,`reservationId` int(11)
,`recieptId` int(11)
);

-- --------------------------------------------------------

--
-- Table structure for table `eventsponsor`
--

CREATE TABLE `eventsponsor` (
  `SPONSOR_ID` int(11) NOT NULL,
  `EVENT_ID` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `image` varchar(100) DEFAULT NULL,
  `date_added` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `aboutSponsor` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `eventsponsor`
--

INSERT INTO `eventsponsor` (`SPONSOR_ID`, `EVENT_ID`, `name`, `image`, `date_added`, `last_updated`, `aboutSponsor`) VALUES
(55, 794, 'Bionic Group', '00 Cover.jpg', '2017-09-17 16:49:52', '2017-09-17 16:49:52', 'null'),
(56, 795, 'B', 'null', '2017-09-17 16:50:02', '2017-09-18 14:30:18', 'null'),
(57, 796, 'Bionic Group', '00 Cover.jpg', '2017-09-17 16:50:48', '2017-09-17 16:50:48', 'null'),
(62, 795, 'Yyyyyyyy', 'null', '2017-09-18 14:25:14', '2017-09-18 14:30:18', 'null'),
(63, 795, 'Yyyyyyyyyyyy', 'null', '2017-09-18 14:26:36', '2017-09-18 14:30:18', 'null'),
(64, 795, 'Yyyyyyy', 'null', '2017-09-18 14:26:36', '2017-09-18 14:30:18', 'null'),
(65, 795, 'Yyyyy', 'null', '2017-09-18 14:27:40', '2017-09-18 14:30:18', 'null'),
(66, 795, 'Yyyyy', 'null', '2017-09-18 14:27:40', '2017-09-18 14:30:18', 'null'),
(67, 795, 'Yyyyy', 'null', '2017-09-18 14:27:40', '2017-09-18 14:30:18', 'null'),
(68, 795, 'New New', '00 - Logic_Young_Broke_Infamous-front-large.jpg', '2017-09-18 14:30:18', '2017-09-18 14:30:18', 'null'),
(69, 795, 'New New', '00 - Logic_Young_Broke_Infamous-back-large.jpg', '2017-09-18 14:30:18', '2017-09-18 14:30:18', 'null'),
(70, 801, 'Bionic Grop', 'Folder.jpg', '2017-09-20 20:30:19', '2017-09-20 20:30:19', 'null'),
(71, 798, 'Bionic Group', 'Cover.jpg', '2017-09-23 18:20:46', '2017-09-23 18:20:46', 'null'),
(72, 798, 'Idops Inc', 'Cover.jpg', '2017-09-23 18:20:46', '2017-09-23 18:20:46', 'null');

--
-- Triggers `eventsponsor`
--
DELIMITER $$
CREATE TRIGGER `BI_sponsorValidator` BEFORE INSERT ON `eventsponsor` FOR EACH ROW BEGIN
			IF (ISNULL(NEW.name) OR LENGTH(TRIM(NEW.name) ) = 0) THEN
				SIGNAL SQLSTATE '45000' 
					SET MYSQL_ERRNO = 3,
						MESSAGE_TEXT =  'mising required value, sponsor  name is a required fields and 
						can not be null or empty';
			END IF;
           
				
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `BU_sponsorValidator` BEFORE UPDATE ON `eventsponsor` FOR EACH ROW BEGIN	
   
	
    IF (ISNULL(NEW.name) OR LENGTH(TRIM(NEW.name)) = 0 ) THEN   SET NEW.name = OLD.name; END IF;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `eventticket`
--

CREATE TABLE `eventticket` (
  `TICKET_ID` int(11) NOT NULL,
  `EVENT_ID` int(11) NOT NULL,
  `type` enum('FREE','PAID','INVITATION','CHARITY') NOT NULL DEFAULT 'FREE',
  `name` varchar(30) NOT NULL DEFAULT 'Normal',
  `price` float NOT NULL,
  `quantity` int(4) NOT NULL,
  `available` int(11) NOT NULL,
  `discription` varchar(255) NOT NULL,
  `sale_start` datetime NOT NULL,
  `sale_end` datetime NOT NULL,
  `date_added` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `status` enum('ACTIVE','SOLD OUT','DRAFT','REMOVED') NOT NULL DEFAULT 'ACTIVE'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `eventticket`
--

INSERT INTO `eventticket` (`TICKET_ID`, `EVENT_ID`, `type`, `name`, `price`, `quantity`, `available`, `discription`, `sale_start`, `sale_end`, `date_added`, `last_updated`, `status`) VALUES
(316, 794, 'PAID', 'free', 120, 200, 198, 'dsgjhgds', '2017-09-18 00:00:00', '2017-09-21 00:00:00', '2017-09-17 16:49:52', '2017-09-18 18:40:52', 'ACTIVE'),
(317, 795, 'FREE', 'free ticket', 0, 200, 200, 'sdjkashdk', '2017-09-19 00:00:00', '2017-09-21 00:00:00', '2017-09-17 16:50:02', '2017-09-18 17:40:49', 'ACTIVE'),
(318, 796, 'FREE', 'free ticket', 0, 200, 200, 'basic features', '2017-09-17 00:00:00', '2017-09-21 00:00:00', '2017-09-17 16:50:48', '2017-09-17 16:50:48', 'ACTIVE'),
(319, 797, 'FREE', 'ticket name', 0, 200, 200, 'ticket discription', '2017-09-17 00:00:00', '2017-09-21 00:00:00', '2017-09-17 17:20:43', '2017-09-17 17:20:43', 'ACTIVE'),
(320, 798, 'FREE', 'dsfsdf', 0, 100, 70, 'fjgkghfd', '2017-09-17 00:00:00', '2017-09-21 00:00:00', '2017-09-17 17:29:57', '2017-09-21 18:52:38', 'ACTIVE'),
(321, 799, 'FREE', 'dsfsdf', 0, 100, 100, 'fjgkghfd', '2017-09-17 00:00:00', '2017-09-21 00:00:00', '2017-09-17 17:30:03', '2017-09-17 17:30:03', 'ACTIVE'),
(322, 794, 'FREE', 'hello', 0, 100, 100, 'added new', '2017-09-18 00:00:00', '2017-09-21 00:00:00', '2017-09-18 15:27:27', '2017-09-18 15:27:27', 'ACTIVE'),
(323, 794, 'FREE', 'hello', 0, 200, 200, 'hshs', '2017-09-18 00:00:00', '2017-09-21 00:00:00', '2017-09-18 15:27:27', '2017-09-18 15:27:27', 'ACTIVE'),
(324, 794, 'FREE', 'hello', 0, 100, 100, 'added new', '2017-09-18 00:00:00', '2017-09-21 00:00:00', '2017-09-18 15:28:24', '2017-09-18 15:28:24', 'ACTIVE'),
(325, 794, 'FREE', 'hello', 0, 200, 200, 'hshs', '2017-09-18 00:00:00', '2017-09-21 00:00:00', '2017-09-18 15:28:24', '2017-09-18 15:28:24', 'ACTIVE'),
(327, 801, 'FREE', 'Ticket', 0, 200, 200, 'Ticket 1', '2017-09-20 00:00:00', '2017-09-26 00:00:00', '2017-09-20 20:30:19', '2017-09-20 20:30:19', 'ACTIVE'),
(328, 801, 'FREE', 'Anouther', 0, 200, 200, 'Ticket 2', '2017-09-20 00:00:00', '2017-09-26 00:00:00', '2017-09-20 20:30:19', '2017-09-20 20:30:19', 'ACTIVE'),
(329, 802, 'FREE', 'sdf', 0, 23, 23, 'gdgdf', '2017-09-25 00:00:00', '2017-09-27 00:00:00', '2017-09-25 20:33:34', '2017-09-25 20:33:34', 'ACTIVE'),
(330, 803, 'FREE', 'dfgfdg', 0, 232, 232, 'sdfsdf', '2017-09-25 00:00:00', '2017-09-27 00:00:00', '2017-09-25 20:40:21', '2017-09-25 20:40:21', 'ACTIVE'),
(331, 804, 'FREE', 'dfgdf', 0, 34, 34, 'dfgdfg', '2017-09-25 00:00:00', '2017-09-28 00:00:00', '2017-09-25 20:43:57', '2017-09-25 20:43:57', 'ACTIVE'),
(332, 805, 'FREE', 'fdghdfjkh', 0, 34, 34, 'fdghjkdfgh', '2017-09-25 00:00:00', '2017-09-28 00:00:00', '2017-09-25 20:46:29', '2017-09-25 20:46:29', 'ACTIVE'),
(333, 806, 'FREE', 'fgdhfjkgh', 0, 22, 22, 'fgdfjgkh', '2017-09-25 00:00:00', '2017-09-27 00:00:00', '2017-09-25 20:50:13', '2017-09-25 20:50:13', 'ACTIVE'),
(334, 807, 'FREE', 'dsfjsdh', 0, 233, 233, 'sdfjhskjdfh', '2017-09-25 00:00:00', '2017-09-28 00:00:00', '2017-09-25 20:56:27', '2017-09-25 20:56:27', 'ACTIVE'),
(335, 808, 'FREE', 'sdfsdfhjhg', 0, 343, 343, 'jgjhg', '2017-09-25 00:00:00', '2017-09-28 00:00:00', '2017-09-25 20:59:07', '2017-09-25 20:59:07', 'ACTIVE'),
(336, 809, 'FREE', 'ghejfh', 0, 233, 233, 'dfjghdfjgh', '2017-09-27 00:00:00', '2017-09-30 00:00:00', '2017-09-27 15:49:20', '2017-09-27 15:49:20', 'ACTIVE'),
(337, 810, 'FREE', 'fdghdjk', 0, 336, 336, 'bjfgdfjkgh', '2017-09-27 00:00:00', '2017-09-29 00:00:00', '2017-09-27 15:53:31', '2017-09-27 15:53:31', 'ACTIVE'),
(338, 811, 'FREE', 'sjsdfhjk', 0, 299, 299, 'dsjfhsdjkfh', '2017-09-27 00:00:00', '2017-09-29 00:00:00', '2017-09-27 15:56:47', '2017-09-27 15:56:47', 'ACTIVE'),
(339, 812, 'FREE', 'fdjkhkj', 0, 366, 366, 'hgjhgjhgjh', '2017-09-27 00:00:00', '2017-09-29 00:00:00', '2017-09-27 15:59:42', '2017-09-27 15:59:42', 'ACTIVE'),
(340, 813, 'FREE', 'sdfjhsdkjfh', 0, 233, 233, 'fgjdfhkgj', '2017-09-27 00:00:00', '2017-09-29 00:00:00', '2017-09-27 16:05:39', '2017-09-27 16:05:39', 'ACTIVE'),
(341, 814, 'FREE', 'fdjghjk', 0, 34, 34, 'sdsd', '2017-09-27 00:00:00', '2017-09-29 00:00:00', '2017-09-27 18:01:13', '2017-09-27 18:01:13', 'ACTIVE'),
(342, 815, 'FREE', 'fdjghjk', 0, 34, 34, 'sdsd', '2017-09-27 00:00:00', '2017-09-29 00:00:00', '2017-09-27 18:01:29', '2017-09-27 18:01:29', 'ACTIVE'),
(343, 816, 'FREE', 'fdjghjk', 0, 34, 34, 'sdsd', '2017-09-27 00:00:00', '2017-09-29 00:00:00', '2017-09-27 18:01:44', '2017-09-27 18:01:44', 'ACTIVE'),
(344, 817, 'FREE', 'jjhkhk', 0, 12, 12, 'hkjhkjhk', '2017-09-27 00:00:00', '2017-09-29 00:00:00', '2017-09-27 18:05:34', '2017-09-27 18:05:34', 'ACTIVE'),
(345, 818, 'FREE', 'dsfsjdh', 0, 34, 34, 'fkdjgkldfjg', '2017-09-27 00:00:00', '2017-09-29 00:00:00', '2017-09-27 18:13:03', '2017-09-27 18:13:03', 'ACTIVE'),
(346, 819, 'FREE', 'sdfjshf', 0, 20, 20, 'djfhksjdfhdk', '2017-09-27 00:00:00', '2017-09-29 00:00:00', '2017-09-27 18:15:23', '2017-09-27 18:15:23', 'ACTIVE');

--
-- Triggers `eventticket`
--
DELIMITER $$
CREATE TRIGGER `BI_ticketValidator` BEFORE INSERT ON `eventticket` FOR EACH ROW BEGIN

	

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
    
    
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `BU_ticketValidator` BEFORE UPDATE ON `eventticket` FOR EACH ROW BEGIN
			
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
						

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `eventticketstatstics`
-- (See below for the actual view)
--
CREATE TABLE `eventticketstatstics` (
`eventId` int(11)
,`ticketId` int(11)
,`ticketPrice` float
,`quantity` int(4)
,`availableTicket` bigint(22)
,`totalBooking` bigint(21)
,`confirmedBooking` bigint(21)
,`pendingBooking` bigint(22)
,`pendingSale` double
,`confirmedSale` double
);

-- --------------------------------------------------------

--
-- Table structure for table `organization`
--

CREATE TABLE `organization` (
  `ORGANIZATION_ID` int(11) NOT NULL,
  `name` varchar(30) DEFAULT NULL,
  `po_num` varchar(10) DEFAULT NULL,
  `logo` varchar(100) DEFAULT NULL,
  `info` text,
  `registered_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `social` json DEFAULT NULL,
  `mobile_number` json DEFAULT NULL,
  `office_number` json DEFAULT NULL,
  `website` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `organization`
--

INSERT INTO `organization` (`ORGANIZATION_ID`, `name`, `po_num`, `logo`, `info`, `registered_on`, `last_updated`, `social`, `mobile_number`, `office_number`, `website`) VALUES
(173, 'Bionicsss', 'null', 'Egate.png', 'null', '2017-08-26 18:10:32', '2017-09-20 16:56:54', '{"twitter": "mike.twitter", "youtube": "mike.youtube", "facebook": "mike.facebook"}', '["0912669988"]', '["0116616278"]', 'https://www.egate.com'),
(174, NULL, NULL, NULL, NULL, '2017-08-27 16:41:41', '2017-08-27 16:41:41', NULL, NULL, 'null', NULL),
(175, NULL, NULL, NULL, NULL, '2017-08-30 18:51:00', '2017-08-30 18:51:00', NULL, NULL, 'null', NULL),
(176, NULL, NULL, NULL, NULL, '2017-08-30 19:06:55', '2017-08-30 19:06:55', NULL, NULL, 'null', NULL),
(178, NULL, NULL, NULL, NULL, '2017-08-30 19:11:57', '2017-08-30 19:11:57', NULL, NULL, 'null', NULL),
(179, NULL, NULL, NULL, NULL, '2017-08-30 19:12:30', '2017-08-30 19:12:30', NULL, NULL, 'null', NULL),
(181, NULL, NULL, NULL, NULL, '2017-08-30 19:20:41', '2017-08-30 19:20:41', NULL, NULL, 'null', NULL),
(182, NULL, NULL, NULL, NULL, '2017-08-30 20:02:14', '2017-08-30 20:02:14', NULL, NULL, 'null', NULL),
(185, NULL, NULL, NULL, NULL, '2017-08-30 20:03:17', '2017-08-30 20:03:17', NULL, NULL, 'null', NULL),
(187, NULL, NULL, NULL, NULL, '2017-08-30 20:04:52', '2017-08-30 20:04:52', NULL, NULL, 'null', NULL),
(189, NULL, NULL, NULL, NULL, '2017-08-30 20:27:05', '2017-08-30 20:27:05', NULL, NULL, 'null', NULL),
(191, NULL, NULL, NULL, NULL, '2017-08-31 18:56:29', '2017-08-31 18:56:29', NULL, NULL, 'null', NULL),
(192, NULL, NULL, NULL, NULL, '2017-08-31 18:57:12', '2017-08-31 18:57:12', NULL, NULL, 'null', NULL),
(193, NULL, NULL, NULL, NULL, '2017-10-01 19:59:00', '2017-10-01 19:59:00', NULL, NULL, NULL, NULL),
(194, NULL, NULL, NULL, NULL, '2017-10-01 20:00:54', '2017-10-01 20:00:54', NULL, NULL, NULL, NULL),
(195, NULL, NULL, NULL, NULL, '2017-10-01 20:01:50', '2017-10-01 20:01:50', NULL, NULL, NULL, NULL),
(196, NULL, NULL, NULL, NULL, '2017-10-01 20:02:57', '2017-10-01 20:02:57', NULL, NULL, NULL, NULL),
(197, NULL, NULL, NULL, NULL, '2017-10-01 20:06:14', '2017-10-01 20:06:14', NULL, NULL, NULL, NULL),
(198, NULL, NULL, NULL, NULL, '2017-10-01 20:06:51', '2017-10-01 20:06:51', NULL, NULL, NULL, NULL),
(199, NULL, NULL, NULL, NULL, '2017-10-01 20:08:48', '2017-10-01 20:08:48', NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `organization_address`
--

CREATE TABLE `organization_address` (
  `city` varchar(20) DEFAULT NULL,
  `sub_city` varchar(30) DEFAULT NULL,
  `country` varchar(20) DEFAULT NULL,
  `location` varchar(30) DEFAULT NULL,
  `longitude` varchar(20) DEFAULT NULL,
  `latitude` varchar(20) DEFAULT NULL,
  `ORG_ADD_ID` int(11) NOT NULL,
  `ORGANIZATION_ID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `organization_address`
--

INSERT INTO `organization_address` (`city`, `sub_city`, `country`, `location`, `longitude`, `latitude`, `ORG_ADD_ID`, `ORGANIZATION_ID`) VALUES
('Addis Ababa', 'Bole', 'Ethiopiagggg', 'Bole Mikael', 'null', 'null', 7, 173),
('Addis Ababa', 'Bole', 'EthiopiaGGGG', 'Bole Mikael', 'null', 'null', 8, 173);

--
-- Triggers `organization_address`
--
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
 
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `organizer`
--

CREATE TABLE `organizer` (
  `ORGANIZER_ID` int(11) NOT NULL,
  `ORGANIZATION_ID` int(11) NOT NULL,
  `first_name` varchar(15) NOT NULL,
  `last_name` varchar(15) NOT NULL,
  `e_mail` varchar(50) NOT NULL,
  `password` varchar(100) NOT NULL,
  `gender` varchar(10) DEFAULT NULL,
  `picture` varchar(100) DEFAULT NULL,
  `registered_on` date DEFAULT NULL,
  `position` varchar(50) DEFAULT NULL,
  `birthdate` date DEFAULT NULL,
  `title` varchar(10) DEFAULT NULL,
  `bio` text
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `organizer`
--

INSERT INTO `organizer` (`ORGANIZER_ID`, `ORGANIZATION_ID`, `first_name`, `last_name`, `e_mail`, `password`, `gender`, `picture`, `registered_on`, `position`, `birthdate`, `title`, `bio`) VALUES
(166, 173, 'Mikael', 'Araya', 'goldlilmike@yahoo.com', 'a', 'null', 'Folder.jpg', NULL, 'CEO', '1990-04-13', 'Mr.', 'Hello'),
(167, 175, 'msafas', 'dsfsdf', 'dsfsdf@gmail.com', 'adasdasd', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(168, 176, 'sdfsfs', 'hsadg', 'dsfsdf@dsf.com', 'dsfsdfsdf', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(170, 178, 'sdfsfs', 'hsadg', 'dsfdfsdf@dsf.com', 'dsfsdfsdf', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(171, 179, 'sdfsfs', 'hsadg', 'ddsfdfsdf@dsf.com', 'dsfsdfsdf', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(173, 181, 'msafas', 'dsfsdf', 'ddsfsfsdf@gmail.com', 'adasdasd', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(174, 182, 'sdfsfs', 'hsadg', 'dsfsdf@dsfs.com', 'dsfsdfsdf', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(177, 185, 'xxxxsdfsfs', 'hsadg', 'dsfdfsdf@dsfs.com', 'dsfsdfsdf', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(179, 187, 'sdfsfs', 'hsadg', 'dsfdsdsdf@dsfs.com', 'dsfsdfsdf', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(181, 189, 'shemsu', 'araya', 'admin@events.com', '$2y$10$YzBkMzhkNTcxZjg3YjNhMuAyA1kwfXFDxA8wtITjKOFRwj56AwMby', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(183, 191, 'mfdf', 'm', 'm@m.com', 'm', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(184, 192, 'A', 'a', 'a@a.com', 'a', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(185, 193, 'Mik', 'sd', 'g@f.com', 'a', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(186, 194, 'sdf', 'fdfs', 's@d.com', 'a', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(187, 195, 'df', 'df', 'as@dd.com', 'a', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(188, 196, 'fdg', 'hgf', 'sd@f.com', 'a', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(189, 197, 'dsf', 'jdfh', 'sds@dfd.com', 'a', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(190, 198, 'sdf', 'jkjdh', 'sd@dfd.vom', 's', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(191, 199, 'sdf', 'jkjdh', 'sd@dfdd.vom', 's', NULL, NULL, NULL, NULL, NULL, NULL, NULL);

--
-- Triggers `organizer`
--
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
	
 END
$$
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
                
        		
 END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `reciept`
--

CREATE TABLE `reciept` (
  `RECIEPT_ID` int(11) NOT NULL,
  `BOOKING_ID` int(11) NOT NULL,
  `status` enum('ACTIVE','USED') NOT NULL DEFAULT 'ACTIVE',
  `issued_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `reciept`
--

INSERT INTO `reciept` (`RECIEPT_ID`, `BOOKING_ID`, `status`, `issued_on`, `last_updated`) VALUES
(4, 7, 'ACTIVE', '2017-09-21 16:31:17', '2017-09-21 16:31:17'),
(5, 8, 'ACTIVE', '2017-09-21 16:31:17', '2017-09-21 16:31:17'),
(6, 9, 'ACTIVE', '2017-09-21 16:31:17', '2017-09-21 16:31:17'),
(7, 10, 'ACTIVE', '2017-09-21 16:31:17', '2017-09-21 16:31:17'),
(8, 11, 'ACTIVE', '2017-09-21 16:36:30', '2017-09-21 16:36:30'),
(9, 12, 'ACTIVE', '2017-09-21 16:36:30', '2017-09-21 16:36:30'),
(10, 13, 'USED', '2017-09-21 16:36:30', '2017-09-21 17:11:36'),
(11, 14, 'USED', '2017-09-21 16:36:30', '2017-09-21 17:50:05'),
(12, 15, 'USED', '2017-09-21 16:36:33', '2017-09-21 17:49:23'),
(13, 16, 'ACTIVE', '2017-09-21 16:36:33', '2017-09-21 16:36:33'),
(14, 17, 'ACTIVE', '2017-09-21 16:36:33', '2017-09-21 16:36:33'),
(15, 18, 'ACTIVE', '2017-09-21 16:36:33', '2017-09-21 16:36:33'),
(16, 19, 'ACTIVE', '2017-09-21 18:52:38', '2017-09-21 18:52:38'),
(17, 20, 'ACTIVE', '2017-09-21 18:52:38', '2017-09-21 18:52:38'),
(18, 21, 'ACTIVE', '2017-09-21 18:52:38', '2017-09-21 18:52:38'),
(19, 22, 'ACTIVE', '2017-09-21 18:52:38', '2017-09-21 18:52:38'),
(20, 23, 'ACTIVE', '2017-09-21 18:52:38', '2017-09-21 18:52:38'),
(21, 24, 'ACTIVE', '2017-09-21 18:52:38', '2017-09-21 18:52:38'),
(22, 25, 'ACTIVE', '2017-09-21 18:52:38', '2017-09-21 18:52:38'),
(23, 26, 'ACTIVE', '2017-09-21 18:52:38', '2017-09-21 18:52:38'),
(24, 27, 'ACTIVE', '2017-09-21 18:52:38', '2017-09-21 18:52:38'),
(25, 28, 'ACTIVE', '2017-09-21 18:52:38', '2017-09-21 18:52:38'),
(26, 29, 'ACTIVE', '2017-09-21 18:52:38', '2017-09-21 18:52:38'),
(27, 30, 'ACTIVE', '2017-09-21 18:52:38', '2017-09-21 18:52:38'),
(28, 31, 'ACTIVE', '2017-09-21 18:52:38', '2017-09-21 18:52:38'),
(29, 32, 'ACTIVE', '2017-09-21 18:52:38', '2017-09-21 18:52:38'),
(30, 33, 'ACTIVE', '2017-09-21 18:52:38', '2017-09-21 18:52:38'),
(31, 34, 'ACTIVE', '2017-09-21 18:52:38', '2017-09-21 18:52:38');

-- --------------------------------------------------------

--
-- Stand-in structure for view `recieptdetails`
-- (See below for the actual view)
--
CREATE TABLE `recieptdetails` (
`eventId` int(11)
,`eventName` varchar(30)
,`address` varchar(113)
,`location` varchar(50)
,`reservationId` int(11)
,`bookingId` int(11)
,`startDate` date
,`startTime` time
,`endDate` date
,`eventImage` varchar(100)
,`recieptId` int(11)
,`firstName` varchar(20)
,`lastName` varchar(20)
,`ticketName` varchar(30)
,`ticketType` enum('FREE','PAID','INVITATION','CHARITY')
,`ticketPrice` float
,`email` varchar(30)
,`phoneNumber` varchar(15)
,`paymentProvider` enum('HELLO CASH','MBIRR')
,`bookedOn` datetime
,`bookingStatus` enum('PENDING','CONFIRMED','CANCELED')
,`ticketId` int(11)
,`recieptStatus` enum('ACTIVE','USED')
,`recieptIssued` datetime
);

-- --------------------------------------------------------

--
-- Table structure for table `serviceprovider`
--

CREATE TABLE `serviceprovider` (
  `PROVIDER_ID` int(11) NOT NULL,
  `name` enum('HELLO CASH','MBIRR') NOT NULL,
  `added_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_updated` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `serviceprovider`
--

INSERT INTO `serviceprovider` (`PROVIDER_ID`, `name`, `added_on`, `last_updated`) VALUES
(1, 'HELLO CASH', '2017-08-28 18:54:23', '2017-08-28 18:54:23'),
(2, 'MBIRR', '2017-08-28 18:54:23', '2017-08-28 18:54:23');

-- --------------------------------------------------------

--
-- Table structure for table `subscriber`
--

CREATE TABLE `subscriber` (
  `SUBSCRIBER_ID` int(11) NOT NULL,
  `e_mail` varchar(50) NOT NULL,
  `added_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `subscriber`
--

INSERT INTO `subscriber` (`SUBSCRIBER_ID`, `e_mail`, `added_on`, `updated_on`) VALUES
(4, 'Mikael@yahoo.com', '2017-08-29 21:39:10', '2017-08-29 23:46:39');

-- --------------------------------------------------------

--
-- Table structure for table `subscription`
--

CREATE TABLE `subscription` (
  `SUBSCRIPTION_ID` int(11) NOT NULL,
  `CATEGORY_ID` int(11) DEFAULT NULL,
  `SUBSCRIBER_ID` int(11) NOT NULL,
  `added_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `subscription`
--

INSERT INTO `subscription` (`SUBSCRIPTION_ID`, `CATEGORY_ID`, `SUBSCRIBER_ID`, `added_on`, `updated_on`) VALUES
(2101, 1, 4, '2017-08-29 21:39:10', '2017-08-29 21:39:10');

-- --------------------------------------------------------

--
-- Stand-in structure for view `subscriptionlist`
-- (See below for the actual view)
--
CREATE TABLE `subscriptionlist` (
`subscriptionId` int(11)
,`subscriberId` int(11)
,`Email` varchar(50)
,`subscription` varchar(30)
,`subscribedOn` datetime
,`lastUpdated` datetime
);

-- --------------------------------------------------------

--
-- Table structure for table `viewers`
--

CREATE TABLE `viewers` (
  `VIEWER_ID` int(11) NOT NULL,
  `ORGANIZER_ID` int(11) NOT NULL,
  `sent_on` datetime DEFAULT NULL,
  `first_name` varchar(30) NOT NULL,
  `last_name` varchar(30) NOT NULL,
  `e_mail` varchar(50) NOT NULL,
  `subject` varchar(30) NOT NULL,
  `mail` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `viewers`
--

INSERT INTO `viewers` (`VIEWER_ID`, `ORGANIZER_ID`, `sent_on`, `first_name`, `last_name`, `e_mail`, `subject`, `mail`) VALUES
(1, 165, NULL, 'Mikael', 'Araya', 'michaelaraya@gmail.com', 'test7', 'seventh go'),
(2, 165, NULL, 'jerry', 'melaku', 'jerity@jj.com', 'test', 'melaky'),
(3, 165, NULL, 'Mikael', 'Araya', 'michaelaraya@gmail.com', 'hello', 'adin'),
(4, 165, NULL, 'hel', 'sakdj', 'jkh@gmail.com', 'djsfhk', 'sjadhjkasjf'),
(5, 165, NULL, 'Mikaek', 'Starboy', 'yupypu@yup.com', 'test2', 'hello mike whats goood'),
(6, 165, NULL, 'Mikael', 'shshd', 'shshs@sgsgs.co', 'shhshs', 'sajdhasjkdhkasjd'),
(7, 165, NULL, 'Mikael', 'Araya', 'kjhkjh@asdjkfhj.com', 'Majsdsashk', 'sadhgashgfasjf'),
(8, 165, NULL, 'Goodfd', 'Tsfsxvshf', 'miche@gmail.com', 'Xgdvd ', 'Gsgs. Fhdtfxs dhscd fhs dhshdj');

-- --------------------------------------------------------

--
-- Structure for view `bookingdetails`
--
DROP TABLE IF EXISTS `bookingdetails`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `bookingdetails`  AS  select any_value(`eventattendee`.`EVENT_ID`) AS `eventId`,any_value(`eventbooking`.`ATTENDEE_ID`) AS `attendeeId`,any_value(`eventbooking`.`BOOKING_ID`) AS `bookingId`,any_value(`eventbooking`.`TICKET_ID`) AS `ticketId`,any_value(`eventattendee`.`first_name`) AS `firstName`,any_value(`eventattendee`.`last_name`) AS `lastName`,any_value(`eventattendee`.`phone`) AS `billingAddress`,any_value(`serviceprovider`.`name`) AS `serviceProvider`,any_value(`billingaddress`.`phone_number`) AS `paymentAddress`,sum(any_value(`eventticket`.`price`)) AS `totalPrice`,any_value(`eventbooking`.`booked_on`) AS `bookedOn` from ((((((`eventbooking` left join `eventattendee` on((`eventbooking`.`ATTENDEE_ID` = `eventattendee`.`ATTENDEE_ID`))) left join `eventticket` on((`eventbooking`.`TICKET_ID` = `eventticket`.`TICKET_ID`))) left join `event` on((`eventattendee`.`EVENT_ID` = `event`.`EVENT_ID`))) left join `organizer` on((`event`.`ORGANIZER_ID` = `organizer`.`ORGANIZER_ID`))) left join `billingaddress` on((`organizer`.`ORGANIZATION_ID` = `billingaddress`.`ORGANIZATION_ID`))) left join `serviceprovider` on((`serviceprovider`.`PROVIDER_ID` = (case when (`billingaddress`.`PROVIDER_ID` = `eventattendee`.`PROVIDER_ID`) then `billingaddress`.`PROVIDER_ID` else NULL end)))) group by `eventbooking`.`ATTENDEE_ID`,`eventticket`.`TICKET_ID` ;

-- --------------------------------------------------------

--
-- Structure for view `bookingstatus`
--
DROP TABLE IF EXISTS `bookingstatus`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `bookingstatus`  AS  select `eventbooking`.`BOOKING_ID` AS `BOOKING_ID`,`reciept`.`RECIEPT_ID` AS `RECIEPT_ID`,(case when isnull(`reciept`.`RECIEPT_ID`) then 'PENDING' when (`reciept`.`RECIEPT_ID` is not null) then 'PAID' end) AS `status` from (`eventbooking` left join `reciept` on((`eventbooking`.`BOOKING_ID` = `reciept`.`BOOKING_ID`))) ;

-- --------------------------------------------------------

--
-- Structure for view `confirmerdbookings`
--
DROP TABLE IF EXISTS `confirmerdbookings`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `confirmerdbookings`  AS  select `eventattendee`.`EVENT_ID` AS `eventId`,`eventattendee`.`ATTENDEE_ID` AS `reservationId`,`eventbooking`.`BOOKING_ID` AS `bookingId`,`reciept`.`RECIEPT_ID` AS `RECIEPT_ID`,`eventattendee`.`first_name` AS `firstName`,`eventattendee`.`last_name` AS `lastName`,`eventattendee`.`email` AS `email`,`eventattendee`.`phone` AS `phoneNumber`,`serviceprovider`.`name` AS `paymentProvider`,`eventbooking`.`booked_on` AS `bookedOn`,`eventbooking`.`status` AS `bookingStatus`,`eventbooking`.`TICKET_ID` AS `ticketId`,`reciept`.`status` AS `recieptStatus`,`reciept`.`issued_on` AS `recieptIssued` from (`reciept` left join ((`eventattendee` left join `serviceprovider` on((`eventattendee`.`PROVIDER_ID` = `serviceprovider`.`PROVIDER_ID`))) left join `eventbooking` on((`eventattendee`.`ATTENDEE_ID` = `eventbooking`.`ATTENDEE_ID`))) on((`eventbooking`.`BOOKING_ID` = `reciept`.`BOOKING_ID`))) ;

-- --------------------------------------------------------

--
-- Structure for view `eventcheckins`
--
DROP TABLE IF EXISTS `eventcheckins`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `eventcheckins`  AS  select `checkins`.`CHECK_IN_ID` AS `checkInId`,`reciept`.`BOOKING_ID` AS `bookingId`,`checkins`.`RECIEPT_ID` AS `recieptId`,`checkins`.`EVENT_ID` AS `eventId`,(case when (`checkins`.`status` = 1) then 'IN' else 'OUT' end) AS `status`,`checkins`.`first_check_in` AS `firstCheckIn`,`checkins`.`last_check_out` AS `lastCheckout`,`checkins`.`last_check_in` AS `lastCheckIn` from (((`checkins` left join `reciept` on((`checkins`.`RECIEPT_ID` = `reciept`.`RECIEPT_ID`))) left join `eventbooking` on((`reciept`.`BOOKING_ID` = `eventbooking`.`BOOKING_ID`))) left join `eventticket` on((`checkins`.`EVENT_ID` = `eventticket`.`EVENT_ID`))) ;

-- --------------------------------------------------------

--
-- Structure for view `eventreciepts`
--
DROP TABLE IF EXISTS `eventreciepts`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `eventreciepts`  AS  select `eventticket`.`EVENT_ID` AS `eventId`,`eventbooking`.`TICKET_ID` AS `ticketId`,`reciept`.`BOOKING_ID` AS `bookingId`,`eventbooking`.`ATTENDEE_ID` AS `reservationId`,`reciept`.`RECIEPT_ID` AS `recieptId` from (`reciept` left join (`eventbooking` left join `eventticket` on((`eventbooking`.`TICKET_ID` = `eventticket`.`TICKET_ID`))) on((`eventbooking`.`BOOKING_ID` = `reciept`.`BOOKING_ID`))) ;

-- --------------------------------------------------------

--
-- Structure for view `eventticketstatstics`
--
DROP TABLE IF EXISTS `eventticketstatstics`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `eventticketstatstics`  AS  select `eventticket`.`EVENT_ID` AS `eventId`,`eventticket`.`TICKET_ID` AS `ticketId`,`eventticket`.`price` AS `ticketPrice`,`eventticket`.`quantity` AS `quantity`,(`eventticket`.`quantity` - count(`eventbooking`.`BOOKING_ID`)) AS `availableTicket`,count(`eventbooking`.`BOOKING_ID`) AS `totalBooking`,count(`reciept`.`RECIEPT_ID`) AS `confirmedBooking`,(count(`eventbooking`.`BOOKING_ID`) - count(`reciept`.`RECIEPT_ID`)) AS `pendingBooking`,(`eventticket`.`price` * (count(`eventbooking`.`BOOKING_ID`) - count(`reciept`.`RECIEPT_ID`))) AS `pendingSale`,(`eventticket`.`price` * count(`reciept`.`RECIEPT_ID`)) AS `confirmedSale` from ((`eventticket` left join `eventbooking` on((`eventticket`.`TICKET_ID` = `eventbooking`.`TICKET_ID`))) left join `reciept` on((`eventbooking`.`BOOKING_ID` = `reciept`.`BOOKING_ID`))) group by `eventticket`.`TICKET_ID` ;

-- --------------------------------------------------------

--
-- Structure for view `recieptdetails`
--
DROP TABLE IF EXISTS `recieptdetails`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `recieptdetails`  AS  select `eventattendee`.`EVENT_ID` AS `eventId`,`event`.`name` AS `eventName`,concat(`event`.`sub_city`,', ',`event`.`city`,' ',`event`.`country`) AS `address`,`event`.`location` AS `location`,`eventattendee`.`ATTENDEE_ID` AS `reservationId`,`eventbooking`.`BOOKING_ID` AS `bookingId`,`event`.`start_date` AS `startDate`,`event`.`start_time` AS `startTime`,`event`.`end_date` AS `endDate`,`event`.`picture` AS `eventImage`,`reciept`.`RECIEPT_ID` AS `recieptId`,`eventattendee`.`first_name` AS `firstName`,`eventattendee`.`last_name` AS `lastName`,`eventticket`.`name` AS `ticketName`,`eventticket`.`type` AS `ticketType`,`eventticket`.`price` AS `ticketPrice`,`eventattendee`.`email` AS `email`,`eventattendee`.`phone` AS `phoneNumber`,`serviceprovider`.`name` AS `paymentProvider`,`eventbooking`.`booked_on` AS `bookedOn`,`eventbooking`.`status` AS `bookingStatus`,`eventbooking`.`TICKET_ID` AS `ticketId`,`reciept`.`status` AS `recieptStatus`,`reciept`.`issued_on` AS `recieptIssued` from (`reciept` left join ((((`eventattendee` left join `event` on((`eventattendee`.`EVENT_ID` = `event`.`EVENT_ID`))) left join `serviceprovider` on((`eventattendee`.`PROVIDER_ID` = `serviceprovider`.`PROVIDER_ID`))) left join `eventbooking` on((`eventattendee`.`ATTENDEE_ID` = `eventbooking`.`ATTENDEE_ID`))) left join `eventticket` on((`eventbooking`.`TICKET_ID` = `eventticket`.`TICKET_ID`))) on((`eventbooking`.`BOOKING_ID` = `reciept`.`BOOKING_ID`))) ;

-- --------------------------------------------------------

--
-- Structure for view `subscriptionlist`
--
DROP TABLE IF EXISTS `subscriptionlist`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `subscriptionlist`  AS  select `subscription`.`SUBSCRIPTION_ID` AS `subscriptionId`,`subscriber`.`SUBSCRIBER_ID` AS `subscriberId`,`subscriber`.`e_mail` AS `Email`,`eventcategory`.`category_name` AS `subscription`,`subscriber`.`added_on` AS `subscribedOn`,`subscription`.`updated_on` AS `lastUpdated` from ((`subscriber` left join `subscription` on((`subscriber`.`SUBSCRIBER_ID` = `subscription`.`SUBSCRIBER_ID`))) left join `eventcategory` on((`subscription`.`CATEGORY_ID` = `eventcategory`.`CATEGORY_ID`))) group by `subscriber`.`SUBSCRIBER_ID`,`subscription`.`SUBSCRIPTION_ID` ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `billingaddress`
--
ALTER TABLE `billingaddress`
  ADD PRIMARY KEY (`BILLING_ID`),
  ADD UNIQUE KEY `organizer_billing_unq` (`ORGANIZATION_ID`,`PROVIDER_ID`),
  ADD KEY `ORGANIZATION_ID` (`ORGANIZATION_ID`),
  ADD KEY `PROVIDER_ID` (`PROVIDER_ID`);

--
-- Indexes for table `checkins`
--
ALTER TABLE `checkins`
  ADD PRIMARY KEY (`CHECK_IN_ID`),
  ADD UNIQUE KEY `RECIEPT_ID` (`RECIEPT_ID`),
  ADD UNIQUE KEY `RECIEPT_ID_3` (`RECIEPT_ID`),
  ADD KEY `RECIEPT_ID_2` (`RECIEPT_ID`),
  ADD KEY `event_checkin_idx` (`EVENT_ID`);

--
-- Indexes for table `deactivated`
--
ALTER TABLE `deactivated`
  ADD PRIMARY KEY (`DEACTIVATION_ID`),
  ADD UNIQUE KEY `ORGANIZATION_ID` (`ORGANIZATION_ID`);

--
-- Indexes for table `deactivation_reasons`
--
ALTER TABLE `deactivation_reasons`
  ADD PRIMARY KEY (`REASON_ID`),
  ADD KEY `DEACTIVATION_ID` (`DEACTIVATION_ID`);

--
-- Indexes for table `event`
--
ALTER TABLE `event`
  ADD PRIMARY KEY (`EVENT_ID`),
  ADD UNIQUE KEY `uq_event_organizer` (`EVENT_ID`,`ORGANIZER_ID`),
  ADD UNIQUE KEY `uq_event_category` (`EVENT_ID`,`CATEGORY_ID`),
  ADD UNIQUE KEY `uq_event_organizer_category` (`EVENT_ID`,`ORGANIZER_ID`,`CATEGORY_ID`),
  ADD KEY `ORGANIZER_ID` (`ORGANIZER_ID`) USING BTREE,
  ADD KEY `event_category_idx` (`CATEGORY_ID`);

--
-- Indexes for table `eventattendee`
--
ALTER TABLE `eventattendee`
  ADD PRIMARY KEY (`ATTENDEE_ID`),
  ADD UNIQUE KEY `eventattendee_billing_unq` (`EVENT_ID`,`phone`),
  ADD KEY `attendee_paymentAdd_fk` (`PROVIDER_ID`);

--
-- Indexes for table `eventbooking`
--
ALTER TABLE `eventbooking`
  ADD PRIMARY KEY (`BOOKING_ID`),
  ADD KEY `TIK_ID` (`TICKET_ID`),
  ADD KEY `TIK_ID_2` (`TICKET_ID`),
  ADD KEY `ATT_ID` (`ATTENDEE_ID`),
  ADD KEY `ATT_ID_2` (`ATTENDEE_ID`),
  ADD KEY `ATTENDEE_ID` (`ATTENDEE_ID`);

--
-- Indexes for table `eventcategory`
--
ALTER TABLE `eventcategory`
  ADD PRIMARY KEY (`CATEGORY_ID`),
  ADD UNIQUE KEY `category_name` (`category_name`);

--
-- Indexes for table `eventcomment`
--
ALTER TABLE `eventcomment`
  ADD PRIMARY KEY (`COMMENT_ID`),
  ADD KEY `EVNT_ID` (`EVENT_ID`);

--
-- Indexes for table `eventguest`
--
ALTER TABLE `eventguest`
  ADD PRIMARY KEY (`GUEST_ID`),
  ADD UNIQUE KEY `UQ_event_guest` (`GUEST_ID`,`EVENT_ID`),
  ADD KEY `EVNT_ID` (`EVENT_ID`);

--
-- Indexes for table `eventsponsor`
--
ALTER TABLE `eventsponsor`
  ADD PRIMARY KEY (`SPONSOR_ID`),
  ADD UNIQUE KEY `UQ_event_sponsor` (`SPONSOR_ID`,`EVENT_ID`),
  ADD KEY `EVT_ID` (`EVENT_ID`),
  ADD KEY `EVNT_ID` (`EVENT_ID`),
  ADD KEY `EVNT_ID_2` (`EVENT_ID`);

--
-- Indexes for table `eventticket`
--
ALTER TABLE `eventticket`
  ADD PRIMARY KEY (`TICKET_ID`),
  ADD UNIQUE KEY `UQ_event_ticket` (`TICKET_ID`,`EVENT_ID`),
  ADD KEY `EVNT_ID` (`EVENT_ID`);

--
-- Indexes for table `organization`
--
ALTER TABLE `organization`
  ADD PRIMARY KEY (`ORGANIZATION_ID`);

--
-- Indexes for table `organization_address`
--
ALTER TABLE `organization_address`
  ADD PRIMARY KEY (`ORG_ADD_ID`),
  ADD KEY `ORGANIZATION_ID` (`ORGANIZATION_ID`);

--
-- Indexes for table `organizer`
--
ALTER TABLE `organizer`
  ADD PRIMARY KEY (`ORGANIZER_ID`),
  ADD UNIQUE KEY `org_email` (`e_mail`),
  ADD UNIQUE KEY `ORGANIZATION_ID` (`ORGANIZATION_ID`);

--
-- Indexes for table `reciept`
--
ALTER TABLE `reciept`
  ADD PRIMARY KEY (`RECIEPT_ID`),
  ADD KEY `BOOKING_ID` (`BOOKING_ID`),
  ADD KEY `BOOKING_ID_2` (`BOOKING_ID`);

--
-- Indexes for table `serviceprovider`
--
ALTER TABLE `serviceprovider`
  ADD PRIMARY KEY (`PROVIDER_ID`);

--
-- Indexes for table `subscriber`
--
ALTER TABLE `subscriber`
  ADD PRIMARY KEY (`SUBSCRIBER_ID`),
  ADD UNIQUE KEY `e_mail` (`e_mail`),
  ADD UNIQUE KEY `uq_subscriber_email` (`SUBSCRIBER_ID`,`e_mail`);

--
-- Indexes for table `subscription`
--
ALTER TABLE `subscription`
  ADD PRIMARY KEY (`SUBSCRIPTION_ID`),
  ADD UNIQUE KEY `UQ_subscription` (`CATEGORY_ID`,`SUBSCRIBER_ID`),
  ADD KEY `subscribed_subscriber_fk` (`SUBSCRIBER_ID`);

--
-- Indexes for table `viewers`
--
ALTER TABLE `viewers`
  ADD PRIMARY KEY (`VIEWER_ID`),
  ADD KEY `ORGANIZER_ID` (`ORGANIZER_ID`),
  ADD KEY `ORGANIZER_ID_2` (`ORGANIZER_ID`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `billingaddress`
--
ALTER TABLE `billingaddress`
  MODIFY `BILLING_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;
--
-- AUTO_INCREMENT for table `checkins`
--
ALTER TABLE `checkins`
  MODIFY `CHECK_IN_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;
--
-- AUTO_INCREMENT for table `deactivated`
--
ALTER TABLE `deactivated`
  MODIFY `DEACTIVATION_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;
--
-- AUTO_INCREMENT for table `deactivation_reasons`
--
ALTER TABLE `deactivation_reasons`
  MODIFY `REASON_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;
--
-- AUTO_INCREMENT for table `event`
--
ALTER TABLE `event`
  MODIFY `EVENT_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=820;
--
-- AUTO_INCREMENT for table `eventattendee`
--
ALTER TABLE `eventattendee`
  MODIFY `ATTENDEE_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;
--
-- AUTO_INCREMENT for table `eventbooking`
--
ALTER TABLE `eventbooking`
  MODIFY `BOOKING_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;
--
-- AUTO_INCREMENT for table `eventcategory`
--
ALTER TABLE `eventcategory`
  MODIFY `CATEGORY_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;
--
-- AUTO_INCREMENT for table `eventcomment`
--
ALTER TABLE `eventcomment`
  MODIFY `COMMENT_ID` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `eventguest`
--
ALTER TABLE `eventguest`
  MODIFY `GUEST_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=176;
--
-- AUTO_INCREMENT for table `eventsponsor`
--
ALTER TABLE `eventsponsor`
  MODIFY `SPONSOR_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=73;
--
-- AUTO_INCREMENT for table `eventticket`
--
ALTER TABLE `eventticket`
  MODIFY `TICKET_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=347;
--
-- AUTO_INCREMENT for table `organization`
--
ALTER TABLE `organization`
  MODIFY `ORGANIZATION_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=200;
--
-- AUTO_INCREMENT for table `organization_address`
--
ALTER TABLE `organization_address`
  MODIFY `ORG_ADD_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;
--
-- AUTO_INCREMENT for table `organizer`
--
ALTER TABLE `organizer`
  MODIFY `ORGANIZER_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=192;
--
-- AUTO_INCREMENT for table `reciept`
--
ALTER TABLE `reciept`
  MODIFY `RECIEPT_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=32;
--
-- AUTO_INCREMENT for table `serviceprovider`
--
ALTER TABLE `serviceprovider`
  MODIFY `PROVIDER_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `subscriber`
--
ALTER TABLE `subscriber`
  MODIFY `SUBSCRIBER_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;
--
-- AUTO_INCREMENT for table `subscription`
--
ALTER TABLE `subscription`
  MODIFY `SUBSCRIPTION_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2102;
--
-- AUTO_INCREMENT for table `viewers`
--
ALTER TABLE `viewers`
  MODIFY `VIEWER_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;
--
-- Constraints for dumped tables
--

--
-- Constraints for table `billingaddress`
--
ALTER TABLE `billingaddress`
  ADD CONSTRAINT `event_billinaddress_fk` FOREIGN KEY (`ORGANIZATION_ID`) REFERENCES `organization` (`ORGANIZATION_ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `service_provider_fx` FOREIGN KEY (`PROVIDER_ID`) REFERENCES `serviceprovider` (`PROVIDER_ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `checkins`
--
ALTER TABLE `checkins`
  ADD CONSTRAINT `event_checkin_fk` FOREIGN KEY (`EVENT_ID`) REFERENCES `event` (`EVENT_ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `recipt_checkin_fk` FOREIGN KEY (`RECIEPT_ID`) REFERENCES `reciept` (`RECIEPT_ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `event`
--
ALTER TABLE `event`
  ADD CONSTRAINT `event_category_fk` FOREIGN KEY (`CATEGORY_ID`) REFERENCES `eventcategory` (`CATEGORY_ID`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `organizer_event` FOREIGN KEY (`ORGANIZER_ID`) REFERENCES `organizer` (`ORGANIZER_ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `eventattendee`
--
ALTER TABLE `eventattendee`
  ADD CONSTRAINT `attendee_paymentAddrss_fk` FOREIGN KEY (`PROVIDER_ID`) REFERENCES `serviceprovider` (`PROVIDER_ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `event_attendee_fk` FOREIGN KEY (`EVENT_ID`) REFERENCES `event` (`EVENT_ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `eventbooking`
--
ALTER TABLE `eventbooking`
  ADD CONSTRAINT `booked_attendee_fk` FOREIGN KEY (`ATTENDEE_ID`) REFERENCES `eventattendee` (`ATTENDEE_ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `booked_ticket_fk` FOREIGN KEY (`TICKET_ID`) REFERENCES `eventticket` (`TICKET_ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `eventcomment`
--
ALTER TABLE `eventcomment`
  ADD CONSTRAINT `event_comment_fk` FOREIGN KEY (`EVENT_ID`) REFERENCES `event` (`EVENT_ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `eventguest`
--
ALTER TABLE `eventguest`
  ADD CONSTRAINT `event_guest` FOREIGN KEY (`EVENT_ID`) REFERENCES `event` (`EVENT_ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `eventsponsor`
--
ALTER TABLE `eventsponsor`
  ADD CONSTRAINT `event_sponsor_fk` FOREIGN KEY (`EVENT_ID`) REFERENCES `event` (`EVENT_ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `eventticket`
--
ALTER TABLE `eventticket`
  ADD CONSTRAINT `event_ticket_fk` FOREIGN KEY (`EVENT_ID`) REFERENCES `event` (`EVENT_ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `organization_address`
--
ALTER TABLE `organization_address`
  ADD CONSTRAINT `organization_address_fk` FOREIGN KEY (`ORGANIZATION_ID`) REFERENCES `organization` (`ORGANIZATION_ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `organizer`
--
ALTER TABLE `organizer`
  ADD CONSTRAINT `organization_organizer_fk` FOREIGN KEY (`ORGANIZATION_ID`) REFERENCES `organization` (`ORGANIZATION_ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `reciept`
--
ALTER TABLE `reciept`
  ADD CONSTRAINT `bookin_reciept_fk` FOREIGN KEY (`BOOKING_ID`) REFERENCES `eventbooking` (`BOOKING_ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `subscription`
--
ALTER TABLE `subscription`
  ADD CONSTRAINT `subscribed_category_fk` FOREIGN KEY (`CATEGORY_ID`) REFERENCES `eventcategory` (`CATEGORY_ID`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `subscribed_subscriber_fk` FOREIGN KEY (`SUBSCRIBER_ID`) REFERENCES `subscriber` (`SUBSCRIBER_ID`) ON DELETE CASCADE ON UPDATE CASCADE;

DELIMITER $$
--
-- Events
--
CREATE DEFINER=`root`@`localhost` EVENT `event_status_updater` ON SCHEDULE EVERY 1 DAY STARTS '2017-08-21 18:17:51' ON COMPLETION PRESERVE ENABLE COMMENT ' changes status based on  start date value' DO BEGIN
		UPDATE `event` SET `status` = CASE 
					WHEN `start_date` > CURRENT_DATE() THEN 'OPEN'
                    WHEN `start_date` = CURRENT_DATE() THEN 'ACTIVE'
                    ELSE 'CLOSED'
                    END;
			
		UPDATE `eventticket` SET `active` = 1 WHERE sale_start >= CURRENT_DATE();
END$$

DELIMITER ;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
