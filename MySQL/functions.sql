USE `egate`;


DELIMITER $$
CREATE  FUNCTION `availableTicket`(`in_ticketId` INT) RETURNS int(11)
    READS SQL DATA
BEGIN
		SET @total = 0;
        
        SELECT `available` FROM `eventTicket` 
			WHERE `TICKET_ID` = in_ticketId  INTO @total;
        

	RETURN(@total);
END $$
DELIMITER ;

DELIMITER $$
CREATE  FUNCTION `email_exists`(`email_address` VARCHAR(50)) RETURNS tinyint(1)
    READS SQL DATA
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

END $$
DELIMITER ;


DELIMITER $$
CREATE  FUNCTION `eventStatus`(`in_eventId` INT) RETURNS varchar(20) CHARSET latin1
    READS SQL DATA
BEGIN

	DECLARE eventStatus VARCHAR(20) DEFAULT NULL;
    
		
        
        SELECT `status` FROM `event` 
			WHERE `EVENT_ID` = in_eventId  INTO eventStatus;
		
	RETURN(eventStatus);
END $$
DELIMITER ;

DELIMITER $$
CREATE  FUNCTION `eventTicketCount`(`in_eventId` INT) RETURNS int(11)
    READS SQL DATA
BEGIN
		SET @total = 0;
        
        SELECT COUNT(*) AS `count` FROM `eventTicket` WHERE `EVENT_ID` = in_eventId INTO @total;
        

	RETURN(@total);
END $$
DELIMITER ;


DELIMITER $$
CREATE  FUNCTION `getEventAttendeeId`(`in_eventId` INT, `in_attendeePhone` INT) RETURNS int(11)
    READS SQL DATA
BEGIN
	DECLARE idNumber INT DEFAULT NULL;
    
			
				SELECT `ATTENDEE_ID` 
                FROM `eventAttendee`
                WHERE `EVENT_ID`  = in_eventId AND `phone` = in_attendeePhone INTO idNumber;
                
	RETURN idNumber;
END $$
DELIMITER ;


DELIMITER $$
CREATE  FUNCTION `getOrganizationId`(`in_organizerId` INT) RETURNS int(11)
    READS SQL DATA
BEGIN
	DECLARE ID INT DEFAULT NULL;
		SELECT `ORGANIZATION_ID` from `organization` 
        LEFT JOIN `organizer` USING(`ORGANIZATION_ID`)
        WHERE `ORGANIZER_ID` = in_organizerId INTO ID;
        
	RETURN ID;
 END $$
DELIMITER ;


DELIMITER $$
CREATE  FUNCTION `isValidEmail`(`in_value` VARCHAR(50)) RETURNS tinyint(1)
    NO SQL
BEGIN

	DECLARE result BOOLEAN DEFAULT false;
    
		IF in_value REGEXP '^[A-Za-z0-9._%-]+@[A-z0-9.-]+\\.[A-Z]{2,4}$'	THEN
			SET result = true;
		ELSE
			SET result = false;
		END IF;
	
    RETURN(result);

END $$
DELIMITER ;


DELIMITER $$
CREATE  FUNCTION `isValidEventStatus`(`in_value` VARCHAR(50)) RETURNS tinyint(1)
    NO SQL
BEGIN

	DECLARE result BOOLEAN DEFAULT false;
    
		IF in_value REGEXP '^(OPEN|CLOSED|DRAFT)$'	THEN
			SET result = true;
		ELSE
			SET result = false;
		END IF;
	
    RETURN(result);

END $$
DELIMITER ;

DELIMITER $$
CREATE  FUNCTION `isValidFloat`(`in_value` VARCHAR(20)) RETURNS tinyint(1)
    NO SQL
BEGIN

	DECLARE result BOOLEAN DEFAULT false;
    
		IF in_value REGEXP '^[0-9]+[\.]?[0-9]*$'	THEN
			SET result = true;
		ELSE
			SET result = false;
		END IF;
	
    RETURN(result);

END $$
DELIMITER ;

DELIMITER $$
CREATE  FUNCTION `isValidInt`(`in_value` VARCHAR(20)) RETURNS tinyint(1)
    NO SQL
BEGIN

	DECLARE result BOOLEAN DEFAULT false;
    
		IF in_value REGEXP '^[0-9]+$'	THEN
			SET result = true;
		ELSE
			SET result = false;
		END IF;
	
    RETURN(result);

END $$
DELIMITER ;

DELIMITER $$
CREATE  FUNCTION `isValidName`(`in_value` VARCHAR(30)) RETURNS tinyint(1)
    NO SQL
BEGIN

	DECLARE result BOOLEAN DEFAULT false;
    
		IF in_value REGEXP '^[A-Za-z]+$' THEN
			SET result = true;
		ELSE
			SET result = false;
		END IF;
	
    RETURN(result);
END $$
DELIMITER ;


DELIMITER $$
CREATE  FUNCTION `isValidPhone`(`in_value` VARCHAR(15)) RETURNS tinyint(1)
    NO SQL
BEGIN

	DECLARE result BOOLEAN DEFAULT false;
    
		IF in_value REGEXP '^[+]?([0-9][0-9])?[0-9]{3,4}[0-9]{6}$'	THEN
			SET result = true;
		ELSE
			SET result = false;
		END IF;
	
    RETURN(result);

END $$
DELIMITER ;


DELIMITER $$
CREATE  FUNCTION `isValidReciept`(`in_eventId` INT, `in_recieptId` INT) RETURNS tinyint(1)
    READS SQL DATA
BEGIN
		DECLARE result BOOLEAN DEFAULT false;
        
        IF (SELECT COUNT(*) FROM `egate_db`.`eventReciepts` WHERE `eventId` = in_eventId AND `recieptId` = in_recieptId) = 1 THEN
			SET result = true;
		ELSE	
			SET result = false;
		END IF;
        
	RETURN result;
END $$
DELIMITER ;

DELIMITER $$
CREATE  FUNCTION `isValidText`(`in_value` TEXT) RETURNS tinyint(1)
    NO SQL
BEGIN

	DECLARE result BOOLEAN DEFAULT false;
    
		IF in_value REGEXP '.+'	THEN
			SET result = true;
		ELSE
			SET result = false;
		END IF;
	
    RETURN(result);

END $$
DELIMITER ;


DELIMITER $$
CREATE  FUNCTION `isValidTicketType`(`in_value` VARCHAR(50)) RETURNS tinyint(1)
    NO SQL
BEGIN

	DECLARE result BOOLEAN DEFAULT false;
    
		IF in_value REGEXP '[FREE|PAID]'	THEN
			SET result = true;
		ELSE
			SET result = false;
		END IF;
	
    RETURN(result);

END $$
DELIMITER ;


DELIMITER $$
CREATE  FUNCTION `isValidTime`(`in_value` VARCHAR(15)) RETURNS tinyint(1)
    NO SQL
BEGIN

	DECLARE result BOOLEAN DEFAULT false;
    
		IF in_value REGEXP '^[0-9]{2}:[0-9]{2}:[0-9]{2}$' OR in_value REGEXP '^[0-9]{2}:[0-9]{2}$' THEN
			SET result = true;
		ELSE
			SET result = false;
		END IF;
	
    RETURN(result);

END $$
DELIMITER ;

DELIMITER $$
CREATE  FUNCTION `is_events_billingAddress`(`in_eventId` INT, `in_providerId` INT) RETURNS tinyint(1)
BEGIN
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
            
END $$
DELIMITER ;

DELIMITER $$
CREATE  FUNCTION `organizationExist`(`in_organizationId` INT, `in_organizerId` INT) RETURNS tinyint(1)
    READS SQL DATA
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
END $$
DELIMITER ;


DELIMITER $$
CREATE  FUNCTION `organizerEventExist`(`in_organizerId` INT, `in_eventId` INT) RETURNS tinyint(1)
    READS SQL DATA
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
END $$
DELIMITER ;


DELIMITER $$
CREATE  FUNCTION `ticketStatus`(`in_ticketId` INT) RETURNS varchar(15) CHARSET latin1
    READS SQL DATA
BEGIN
		DECLARE ticketStatus VARCHAR(15) DEFAULT '';
       
       SELECT `status`
       FROM `eventTicket`
       WHERE `TICKET_ID` = in_ticketId INTO ticketStatus;

RETURN ticketStatus;
END $$
DELIMITER ;


DELIMITER $$
CREATE  FUNCTION `ticketType`(`in_ticketId` INT) RETURNS varchar(15) CHARSET latin1
    READS SQL DATA
BEGIN
		DECLARE ticketType VARCHAR(15) DEFAULT '';
       
       SELECT `type`
       FROM `eventTicket`
       WHERE `TICKET_ID` = in_ticketId INTO ticketType;

RETURN ticketType;
END $$
DELIMITER ;


DELIMITER $$
CREATE  FUNCTION `transactionCount`() RETURNS int(11)
    READS SQL DATA
BEGIN
DECLARE trans INT DEFAULT 0;

SELECT count(1)  FROM information_schema.innodb_trx 
    WHERE trx_mysql_thread_id = CONNECTION_ID() INTO trans;
RETURN trans;
END $$
DELIMITER ;

