
USE `egate_db`;


DROP PROCEDURE IF EXISTS `addComment`;
DELIMITER $$
CREATE  PROCEDURE `addComment`(IN `in_eventId` INT, IN `in_comment` JSON)
    MODIFIES SQL DATA
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
                ' INSERT INTO `event_comments` ( `EVENT_ID`, `name`, `comment` )  VALUES(?, ?, ?) ';

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

END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `addEvent`;
DELIMITER $$
CREATE  PROCEDURE `addEvent`(IN `in_organizerId` INT, IN `in_event` JSON)
    MODIFIES SQL DATA
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




END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `addEventAttendee`;
DELIMITER $$
CREATE  PROCEDURE `addEventAttendee`(IN `in_eventId` INT, IN `in_attendee` JSON, OUT `out_newAttendeeId` INT)
    MODIFIES SQL DATA
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

                        IF transactionCount() = 0 THEN
							START TRANSACTION;
                            SET NESTED = false;
						END IF;

            	PREPARE attendee_registeration_statement FROM
							'INSERT INTO `event_attendees` (
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


		ELSE
				SIGNAL SQLSTATE '45000'
            SET MYSQL_ERRNO = 1,
			MESSAGE_TEXT = 'json data passed for event attendee missing one of the required keys required keys
								eventId, firstName, lastName, phoneNumber ';

        END IF;
END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `addEventBooking`;
DELIMITER $$
CREATE  PROCEDURE `addEventBooking`(IN `in_reservationId` INT, IN `in_ticket` JSON)
    MODIFIES SQL DATA
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
					'INSERT INTO `event_bookings` ( `ATTENDEE_ID`, `TICKET_ID`  )
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

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `addEventCategory`;
DELIMITER $$
CREATE  PROCEDURE `addEventCategory`(IN `in_category` JSON)
    MODIFIES SQL DATA
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
                'INSERT INTO `egate_db`.`event_category`(`category_name`) VALUES(?)';

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

END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `addEventGuest`;
DELIMITER $$
CREATE  PROCEDURE `addEventGuest`(IN `in_eventID` INT, IN `in_guest` JSON)
    MODIFIES SQL DATA
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

         PREPARE   add_guest_statement FROM 'INSERT INTO `event_guests` (
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

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `addEventSponsor`;
DELIMITER $$
CREATE  PROCEDURE `addEventSponsor`(IN `in_eventID` INT, IN `in_sponsor` JSON)
    MODIFIES SQL DATA
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

         PREPARE   add_sponsor_statement FROM 'INSERT INTO `event_sponsors` (
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




END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `addEventTicket`;
DELIMITER $$
CREATE  PROCEDURE `addEventTicket`(IN `in_eventId` INT, IN `in_ticket` JSON)
    MODIFIES SQL DATA
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




PREPARE add_ticket_statement FROM 'INSERT INTO `event_tickets` (
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




END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `addOrganizationAddress`;
DELIMITER $$
CREATE  PROCEDURE `addOrganizationAddress`(IN `in_organizerId` INT, IN `in_address` JSON)
    MODIFIES SQL DATA
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

 END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `addSubscription`;
DELIMITER $$
CREATE  PROCEDURE `addSubscription`(IN `in_subscription` JSON, OUT `out_subscriptionId` INT)
    MODIFIES SQL DATA
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


END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `attendeeCheckIn`;
DELIMITER $$
CREATE  PROCEDURE `attendeeCheckIn`(IN `in_eventId` INT, IN `in_recieptId` INT)
    MODIFIES SQL DATA
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


END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `attendeeCheckOut`;
DELIMITER $$
CREATE  PROCEDURE `attendeeCheckOut`(IN `in_eventId` INT, IN `in_recieptId` INT)
    MODIFIES SQL DATA
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



END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `bookEvent`;
DELIMITER $$
CREATE  PROCEDURE `bookEvent`(IN `in_eventId` INT, IN `in_attendee` JSON, IN `in_ticket` JSON)
    MODIFIES SQL DATA
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


END $$
DELIMITER ;




DROP PROCEDURE IF EXISTS `cancelSubscription`;
DELIMITER $$
CREATE  PROCEDURE `cancelSubscription`(IN `in_subscription` JSON, OUT `out_result` BOOLEAN)
    MODIFIES SQL DATA
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


END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `changeEventStatus`;
DELIMITER $$
CREATE  PROCEDURE `changeEventStatus`(IN `in_eventId` INT, IN `in_status` VARCHAR(30))
    MODIFIES SQL DATA
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


END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `changeSubscriptionMail`;
DELIMITER $$
CREATE  PROCEDURE `changeSubscriptionMail`(IN `in_subscription` JSON, OUT `out_result` BOOLEAN)
    MODIFIES SQL DATA
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


END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `createAccount`;
DELIMITER $$
CREATE  PROCEDURE `createAccount`(IN `in_organizer` JSON)
    MODIFIES SQL DATA
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
           SELECT @newId AS 'organizerId';
           COMMIT; END IF;

END $$
DELIMITER ;




DROP PROCEDURE IF EXISTS `deleteBillingAddress`;
DELIMITER $$
CREATE  PROCEDURE `deleteBillingAddress`(IN `in_organizerId` INT, IN `in_accountInfo` JSON)
    MODIFIES SQL DATA
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

 END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `deleteComment`;
DELIMITER $$
CREATE  PROCEDURE `deleteComment`(IN `in_eventId` INT, IN `in_commentId` JSON)
    MODIFIES SQL DATA
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
                ' 	DELETE FROM `event_comments` WHERE COMMENT_ID = ? AND EVENT_ID = ? ';

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

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `deleteEvent`;
DELIMITER $$
CREATE  PROCEDURE `deleteEvent`(IN `in_organizerId` INT, IN `in_eventId` INT)
    MODIFIES SQL DATA
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

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `deleteEventAttendee`;
DELIMITER $$
CREATE  PROCEDURE `deleteEventAttendee`(IN `in_attendee` JSON, OUT `out_result` INT)
    MODIFIES SQL DATA
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
							'DELETE FROM `event_attendees`
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
END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `deleteEventBooking`;
DELIMITER $$
CREATE  PROCEDURE `deleteEventBooking`(IN `in_reservationId` INT, IN `in_bookingId` JSON)
    MODIFIES SQL DATA
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
                'DELETE FROM `egate_db`.`event_bookings` WHERE `BOOKING_ID` = ? AND `ATTENDEE_ID` = ? ';

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

END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `deleteEventCategory`;
DELIMITER $$
CREATE  PROCEDURE `deleteEventCategory`(IN `in_category` JSON)
    MODIFIES SQL DATA
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
                'DELETE FROM `egat_db`.`event_category`
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

END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `deleteEventGuest`;
DELIMITER $$
CREATE  PROCEDURE `deleteEventGuest`(IN `in_eventId` INT, IN `in_guest` JSON)
    MODIFIES SQL DATA
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



			PREPARE delete_guest_statement FROM 'DELETE FROM `event_guests`
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

END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `deleteEventSponsor`;
DELIMITER $$
CREATE  PROCEDURE `deleteEventSponsor`(IN `in_eventId` INT, IN `in_sponsor` JSON)
    MODIFIES SQL DATA
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


			PREPARE delete_sponsor_statement FROM 'DELETE FROM `event_sponsors`
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

END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `deleteEventTicket`;
DELIMITER $$
CREATE  PROCEDURE `deleteEventTicket`(IN `in_organizerId` INT, IN `in_eventId` INT, IN `in_ticketId` JSON)
    MODIFIES SQL DATA
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

			PREPARE delete_ticket_statement FROM 'DELETE FROM `event_tickets`
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

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `deleteOrganization`;
DELIMITER $$
CREATE  PROCEDURE `deleteOrganization`(IN `in_organization` JSON)
    MODIFIES SQL DATA
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

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `deleteOrganizationAddress`;
DELIMITER $$
CREATE  PROCEDURE `deleteOrganizationAddress`(IN `in_organizerId` INT, IN `in_address` JSON)
    MODIFIES SQL DATA
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

 END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `deleteSubscription`;
DELIMITER $$
CREATE  PROCEDURE `deleteSubscription`(IN `in_subscription` JSON, OUT `out_subscriptionId` INT)
    MODIFIES SQL DATA
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


END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getActiveEvents`;
DELIMITER $$
CREATE  PROCEDURE `getActiveEvents`(IN `in_limit` INT)
    MODIFIES SQL DATA
BEGIN

		PREPARE get_activeEvent_statement FROM
			"SELECT `event`.`EVENT_ID` AS 'eventId', `event`.`ORGANIZER_ID` AS 'organizerId',  `event`.`name` AS 'eventName',`venue`, `event`.`discription` AS 'adoutEvent',
				`event_category`.`category_name` AS 'event_category', `event`.`start_date` AS 'startDate', `event`.`start_time` AS 'startTime',
                `event`.`end_date` AS 'endDate', `event`.`end_time` AS 'endTime', `longitude`, `latitude`,  `location`,
                CONCAT(`event`.`sub_city`,', ', `event`.`city`, ' ', `event`.`country`) AS 'address', `event`.`picture` AS 'eventImage',
                `event`.`status`, `event`.`created_on` AS 'createdOn', `event`.`last_updated` AS 'lastUpdated'
		FROM `event`
        LEFT JOIN `event_category` USING(`CATEGORY_ID`)
        WHERE `status` = 'OPEN'
        LIMIT ?";

            SET @getLimit = in_limit;

		EXECUTE get_activeEvent_statement USING @getLimit ;

        DEALLOCATE PREPARE get_activeEvent_statement;

END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `getAttendeeReservation`;
DELIMITER $$
CREATE  PROCEDURE `getAttendeeReservation`(IN `in_reservationId` INT)
    READS SQL DATA
BEGIN

        PREPARE get_reservation_prepare FROM
        "SELECT `event_bookings`.`ATTENDEE_ID` AS 'reservationId', `eventbooking`.`BOOKING_ID` AS 'bookingId', `event_bookings`.`TICKET_ID` AS 'ticketId',
			(CASE WHEN `event_tickets`.`price` = 0 THEN 'FREE' ELSE `event_tickets`.`price` END) AS 'ticketPrice',  `event_bookings`.`status`,
            `event_bookings`.`booked_on` AS 'bookedOn'
		FROM `event_bookings`
        LEFT JOIN `event_tickets` USING(`TICKET_ID`)
        WHERE `event_bookings`.`ATTENDEE_ID` = ? ";

        SET @attendeeId = in_reservationId;

        EXECUTE get_reservation_prepare USING @attendeeId;

        DEALLOCATE PREPARE get_reservation_prepare;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getCheckIn`;
DELIMITER $$
CREATE  PROCEDURE `getCheckIn`(IN `in_eventId` INT, IN `in_recieptId` INT)
    READS SQL DATA
BEGIN
		SELECT * FROM `egate_db`.`eventCheckIns`
        WHERE `eventId` = in_eventId AND `recieptId` = in_recieptId;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getClosedEvents`;
DELIMITER $$
CREATE  PROCEDURE `getClosedEvents`(IN `in_limit` INT)
    MODIFIES SQL DATA
BEGIN

		PREPARE get_closedEvent_statement FROM
			"SELECT `event`.`EVENT_ID` AS 'eventId', `event`.`ORGANIZER_ID` AS 'organizerId',  `event`.`name` AS 'eventName',`venue`, `event`.`discription` AS 'adoutEvent',
				`event_category`.`category_name` AS 'eventCategory', `event`.`start_date` AS 'startDate', `event`.`start_time` AS 'startTime',
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

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getComment`;
DELIMITER $$
CREATE  PROCEDURE `getComment`(IN `in_commentId` INT)
    READS SQL DATA
BEGIN

		PREPARE get_comment_statement FROM
			"SELECT `event_comments`.`EVENT_ID` AS 'eventId', `event_comments`.`COMMENT_ID` AS 'commentId',
            `event_comments`.`name` AS `commenter`, `event_comments`.`comment`, `event_comments`.`commented_on` AS 'commentedOn'
					FROM `event_comments`
					WHERE `event_comments`.`COMMENT_ID` = ?";
			SET @commentId = in_commentId;
		EXECUTE get_comment_statement USING @commentId ;

        DEALLOCATE PREPARE get_comment_statement;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getDraftEvents`;
DELIMITER $$
CREATE  PROCEDURE `getDraftEvents`(IN `in_limit` INT)
    MODIFIES SQL DATA
BEGIN

		PREPARE get_draftEvent_statement FROM
			"SELECT `event`.`EVENT_ID` AS 'eventId', `event`.`ORGANIZER_ID` AS 'organizerId',  `event`.`name` AS 'eventName',`venue`, `event`.`discription` AS 'adoutEvent',
				`event_category`.`category_name` AS 'event_category', `event`.`start_date` AS 'startDate', `event`.`start_time` AS 'startTime',
                `event`.`end_date` AS 'endDate', `event`.`end_time` AS 'endTime', `longitude`, `latitude`,  `location`,
                CONCAT(`event`.`sub_city`,', ', `event`.`city`, ' ', `event`.`country`) AS 'address', `event`.`picture` AS 'eventImage',
                `event`.`status`, `event`.`created_on` AS 'createdOn', `event`.`last_updated` AS 'lastUpdated'
		FROM `event`
        LEFT JOIN `event_category` USING(`CATEGORY_ID`)
        WHERE `status` = 'DRAFT'
        LIMIT ?";

            SET @getLimit = in_limit;

		EXECUTE get_draftEvent_statement USING @getLimit ;

        DEALLOCATE PREPARE get_draftEvent_statement;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getEventBookings`;
DELIMITER $$
CREATE  PROCEDURE `getEventBookings`(IN `in_eventId` INT)
    READS SQL DATA
BEGIN

		PREPARE get_event_bookings_statement FROM
			"SELECT ANY_VALUE(event_attendees.EVENT_ID) AS 'eventId', ANY_VALUE(event_bookings.ATTENDEE_ID) AS 'reservationId',
				ANY_VALUE(event_bookings.BOOKING_ID) AS 'bookingId', ANY_VALUE(event_bookings.TICKET_ID) AS ticketId,
				ANY_VALUE(event_attendees.first_name) AS 'firstName', ANY_VALUE(event_attendees.last_name) AS 'lastName',
				ANY_VALUE(event_attendees.phone) AS 'phoneNumber',ANY_VALUE(event_attendees.service_provider) AS 'serviceProvider',
				SUM(ANY_VALUE(event_tickets.price)) AS 'totalPrice', ANY_VALUE(event_bookings.booked_on) AS 'bookedOn'
			FROM `event_bookings`
				LEFT JOIN `event_attendees` ON event_bookings.ATTENDEE_ID = event_attendees.ATTENDEE_ID
				LEFT JOIN event_tickets ON  event_bookings.TICKET_ID = event_tickets.TICKET_ID
			WHERE `event_attendees`.`EVENT_ID` = ?
			GROUP BY event_bookings.ATTENDEE_ID,  event_bookings.TICKET_ID  ";

		SET @eventId = in_eventId;
		EXECUTE get_event_bookings_statement USING @eventId ;

        DEALLOCATE PREPARE get_event_bookings_statement;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getEventBookingStat`;
DELIMITER $$
CREATE  PROCEDURE `getEventBookingStat`(IN `in_organizerId` INT, IN `in_eventId` INT)
BEGIN
		SELECT *
        FROM `eventticketstatstics`
        WHERE `eventId` = in_eventId;
END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getEventCategory`;
DELIMITER $$
CREATE  PROCEDURE `getEventCategory`(`in_category` INT, `in_limit` INT)
    READS SQL DATA
BEGIN
		SELECT `EVENT_ID` AS 'eventId' , `ORGANIZER_ID` AS 'organizerId', `event`.`name` AS 'eventName' , `venue`,
				`event_category`.`category_name` AS 'category', `event`.`discription` AS 'aboutEvent', `event`.`picture` AS 'eventImage', `start_date` AS 'startDate',
                `start_time` AS 'startTime', `end_date` AS 'endDate', `end_time` AS 'endTime' , `location`, CONCAT(`sub_city`, ", ", `city`, " ", `country`) AS 'address',
                COUNT(`TICKET_ID`) AS 'totalTicket', MAX(`price`) AS 'maxPrice', MIN(`price`) AS 'minPrice', `event`.`status`

		FROM `event`
        LEFT JOIN `event_category` USING(`CATEGORY_ID`)
        LEFT JOIN `event_tickets` USING(`EVENT_ID`)
        WHERE `CATEGORY_ID` = in_category AND (`event`.`status` = 'OPEN' OR `event`.`status` = 'ACTIVE')
        GROUP BY `EVENT_ID`
        LIMIT in_limit;
END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getEventCheckIns`;
DELIMITER $$
CREATE  PROCEDURE `getEventCheckIns`(IN `in_eventId` INT)
    READS SQL DATA
BEGIN
		SELECT * FROM `egate_db`.`eventCheckIns`
        WHERE `eventId` = in_eventId;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getEventComments`;
DELIMITER $$
CREATE  PROCEDURE `getEventComments`(IN `in_eventId` INT)
    READS SQL DATA
BEGIN

		PREPARE get_event_comments_statement FROM
			"SELECT `event_comments`.`EVENT_ID` AS 'eventId', `event_comments`.`COMMENT_ID` AS 'commentId',
            `event_comments`.`name` AS `commenter`, `event_comments`.`comment`, `event_comments`.`commented_on` AS 'commentedOn'
					FROM `event_comments`
					WHERE `event_comments`.`EVENT_ID` = ?";
			SET @eventId = in_eventId;
		EXECUTE get_event_comments_statement USING @eventId ;

        DEALLOCATE PREPARE get_event_comments_statement;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getEventDetail`;
DELIMITER $$
CREATE  PROCEDURE `getEventDetail`(IN `in_eventId` INT)
    READS SQL DATA
BEGIN

	UPDATE `event` SET `total_view` = `total_view` + 1 WHERE `EVENT_ID` = in_eventId;
	SELECT  `event`.`EVENT_ID` AS 'eventId' , `organizer`.`ORGANIZER_ID` AS 'organizerId', `organization`.`name` AS 'organizationName',
			`social`, 	`mobile_number` AS 'mobileNumber', `office_number` AS 'officeNumber',  `po_num` AS 'postAddress',
			`organization`.`logo` AS 'organizationLogo', `organization`.`info` AS 'aboutOrganization',	CONCAT(`organizer`.`first_name`, " ",
            `organizer`.`last_name` ) AS 'organizerName',  `event_category`.`category_name` AS 'event_category',
            `e_mail` AS 'organizerEmail',  `organizer`.`picture` AS 'organizerImage', `organizer`.`bio` AS 'aboutOrganizer',`event`.`name` AS 'eventName' , `venue`,
            `event`.`discription` AS 'aboutEvent', `event`.`picture` AS 'eventImage', `start_date` AS 'startDate', `start_time` AS 'startTime',
            `end_date` AS 'endDate', `end_time` AS 'endTime' , `location`, CONCAT(`sub_city`, ", ", `city`, " ", `country`) AS 'address', `event`.`longitude`, `event`.`latitude`, `event`.`status`AS 'eventStatus'


		FROM `event`
			LEFT JOIN `organizer` USING(`ORGANIZER_ID`)
			LEFT JOIN  `organization` USING(`ORGANIZATION_ID`)
			LEFT JOIN `event_category` USING(`CATEGORY_ID`)
        WHERE `event`.`EVENT_ID` = in_eventId;

       SELECT `TICKET_ID` AS 'ticketId', `event_tickets`.`name` AS 'ticketName',  `event_tickets`.`type` AS 'ticketType', `price` AS 'ticketPrice', `quantity` AS 'ticketQuantity', `available` AS 'availableTicket',
            `event_tickets`.`discription` AS 'aboutTicket', `sale_start` AS 'saleStart', `sale_end` AS 'saleEnd' , `event_tickets`.`status` AS 'ticketStatus',
		(COUNT(event_bookings.BOOKING_ID) - COUNT(reciept.RECIEPT_ID))  AS 'pendingBooking' , COUNT(reciept.RECIEPT_ID) AS 'confirmedBooking'
		FROM `event_tickets`
        LEFT JOIN `event_bookings` USING(`TICKET_ID`)
        LEFT JOIN `reciept` USING(`BOOKING_ID`)
        WHERE `event_tickets`.`EVENT_ID` = in_eventId
        GROUP BY TICKET_ID ;


        SELECT `event_guests`.`GUEST_ID` AS 'guestId',
				CONCAT(`event_guests`.`first_name`, " ", `event_guests`.`last_name`) AS 'guestName',  `event_guests`.`aka_name` AS 'akaName',
                    `event_guests`.`title` AS 'guestTitle', `event_guests`.`bio` AS 'aboutGuest', `event_guests`.`image` AS 'guestImage'
		FROM `event_guests`
        WHERE `event_guests`.`EVENT_ID` = in_eventId;

        SELECT `event_sponsors`.`SPONSOR_ID` AS 'sponsorId',
			`event_sponsors`.`name` AS 'sponsorName', `event_sponsors`.`image` AS 'sponsorImage', `event_sponsors`.`aboutSponsor`
		FROM `event_sponsors`
        WHERE `event_sponsors`.`EVENT_ID` = in_eventId;

        SELECT `event_comments`.`COMMENT_ID` AS 'commentId', `event_comments`.`name` AS 'commenter', `event_comments`.`comment` AS 'comment',
				`event_comments`.`commented_on` AS 'commentedOn', `event_comments`.`last_updated` AS 'updatedOn'
		FROM `event_comments`
        WHERE `event_comments`.`EVENT_ID` = in_eventId;





END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getEventEndDateTime`;
DELIMITER $$
CREATE  PROCEDURE `getEventEndDateTime`(IN `in_eventId` INT)
    READS SQL DATA
BEGIN

		PREPARE get_eventEndDateTime_statement FROM
			"SELECT `event`.`EVENT_ID` AS 'eventId', `event`.`end_date` AS 'endDate', `event`.`end_Time` AS 'endTime'
					FROM `egate_db`.`event`
					WHERE `event`.`EVENT_ID` = ?";
			SET @eventId = in_eventId;
		EXECUTE get_eventEndDateTime_statement USING @eventId ;

        DEALLOCATE PREPARE get_eventEndDateTime_statement;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getEventGeneralInfo`;
DELIMITER $$
CREATE  PROCEDURE `getEventGeneralInfo`(IN `in_eventId` INT)
BEGIN
        SELECT `event`.`EVENT_ID` AS 'eventId', `event`.`ORGANIZER_ID` AS 'organizerId',  `event`.`name` AS 'eventName',`venue`, `event`.`discription` AS 'adoutEvent',
				`event_category`.`category_name` AS 'event_category', `event`.`start_date` AS 'startDate', `event`.`start_time` AS 'startTime',
                `event`.`end_date` AS 'endDate', `event`.`end_time` AS 'endTime', `longitude`, `latitude`,  `location`,
			`event`.`sub_city` AS 'subCity', `event`.`city`,  `event`.`country` , `event`.`picture` AS 'eventImage',
                `event`.`status`, `event`.`created_on` AS 'createdOn', `event`.`last_updated` AS 'lastUpdated'
		FROM `event`
        LEFT JOIN `event_category` USING(`CATEGORY_ID`)
        WHERE `EVENT_ID` = in_eventId;


END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getEventGuest`;
DELIMITER $$
CREATE  PROCEDURE `getEventGuest`(IN `in_eventId` INT)
    READS SQL DATA
BEGIN
       PREPARE get_event_guests_statement FROM
       "SELECT `event_guests`.`GUEST_ID` AS 'guestId', `event_guests`.`first_name` AS 'firstName', `event_guests`.`last_name` AS 'lastName',
       `event_guests`.`aka_name` AS 'nickName' , `event_guests`.`title`, `event_guests`.`bio` AS 'aboutGuest',`event_guests`.`image` AS 'guestImage',
       `event_guests`.`date_added` AS 'dateAdded', `event_guests`.`last_updated` AS 'lastUpdated'
				FROM `event_guests`
				WHERE `event_guests`.`EVENT_ID` = ?";

       SET @eventId = in_eventId;

       EXECUTE get_event_guests_statement USING @eventId;

       DEALLOCATE PREPARE get_event_guests_statement;
END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getEventOrganizerId`;
DELIMITER $$
CREATE  PROCEDURE `getEventOrganizerId`(IN `in_eventId` INT)
    READS SQL DATA
BEGIN

		PREPARE get_organizerId_statement FROM
			"SELECT `ORGANIZER_ID` AS 'organizerId'
					FROM `event`
					WHERE `EVENT_ID` = ?";
			SET @eventId = in_eventId;
		EXECUTE get_organizerId_statement USING @eventId ;

        DEALLOCATE PREPARE get_organizer_statement;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getEventsBasic`;
DELIMITER $$
CREATE  PROCEDURE `getEventsBasic`(IN `in_limit` INT)
    READS SQL DATA
BEGIN

		SELECT `EVENT_ID` AS 'eventId' , `ORGANIZER_ID` AS 'organizerId', `event`.`name` AS 'eventName' , `venue`,
				`event_category`.`category_name` AS 'category', `event`.`discription` AS 'aboutEvent', `event`.`picture` AS 'eventImage', `start_date` AS 'startDate',
                `start_time` AS 'startTime', `end_date` AS 'endDate', `end_time` AS 'endTime' , `location`, CONCAT(`sub_city`, ", ", `city`, " ", `country`) AS 'address',
                COUNT(`TICKET_ID`) AS 'totalTicket', MAX(`price`) AS 'maxPrice', MIN(`price`) AS 'minPrice', `event`.`status`

		FROM `event`
        LEFT JOIN `event_category` USING(`CATEGORY_ID`)
        LEFT JOIN `event_tickets` USING(`EVENT_ID`)
        WHERE `event`.`status` = 'OPEN' OR `event`.`status` = 'ACTIVE'
        GROUP BY `EVENT_ID`
        LIMIT in_limit;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getEventSchedule`;
DELIMITER $$
CREATE  PROCEDURE `getEventSchedule`(IN `in_eventId` INT)
    READS SQL DATA
BEGIN

		PREPARE get_eventSchedule_statement FROM
			"SELECT `EVENT_ID` AS 'eventId', `start_date` AS 'startDate', `start_time` AS `startTime`, `end_date` AS 'endDate', `end_Time` AS 'endTime'
					FROM `event`
					WHERE `EVENT_ID` = ?";
			SET @eventId = in_eventId;
		EXECUTE get_eventSchedule_statement USING @eventId ;

        DEALLOCATE PREPARE get_eventSchedule_statement;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getEventSponsor`;
DELIMITER $$
CREATE  PROCEDURE `getEventSponsor`(IN `in_eventId` INT)
    READS SQL DATA
BEGIN
       PREPARE get_event_sponsors_statement FROM
       "SELECT `event_sponsors`.`SPONSOR_ID` AS 'sponsorId', `event_sponsors`.`name` AS 'sponsorName', `event_sponsors`.`image` AS 'sponsorImage',
       `event_sponsors`.`aboutSponsor`, 	`event_sponsors`.`date_added` AS 'dateAdded', `event_sponsors`.`last_updated` AS 'lastUpdated'
				FROM `event_sponsors`
				WHERE `event_sponsors`.`EVENT_ID` = ?";

       SET @eventId = in_eventId;

       EXECUTE get_event_sponsors_statement USING @eventId;

       DEALLOCATE PREPARE get_event_sponsors_statement;
END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getEventStartDateTime`;
DELIMITER $$
CREATE  PROCEDURE `getEventStartDateTime`(IN `in_eventId` INT)
    READS SQL DATA
BEGIN

		PREPARE get_eventStartDatetime_statement FROM
			"SELECT `EVENT_ID` AS 'eventId', `start_date` AS 'startDate', `start_time` AS `startTime`
					FROM `event`
					WHERE `EVENT_ID` = ?";
			SET @eventId = in_eventId;
		EXECUTE get_eventStartDatetime_statement USING @eventId ;

        DEALLOCATE PREPARE get_eventStartDatetime_statement;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getEventTicket`;
DELIMITER $$
CREATE  PROCEDURE `getEventTicket`(IN `in_eventId` INT)
    READS SQL DATA
BEGIN
       PREPARE get_event_tickets_statement FROM
       "SELECT `event_tickets`.`TICKET_ID` AS 'ticketId', `event_tickets`.`name` AS 'ticketName', `event_tickets`.`type` AS 'ticketType' ,
       `event_tickets`.`price` AS 'ticketPrice', `event_tickets`.`discription` AS 'aboutTicket', `event_tickets`.`quantity` AS 'ticketQuantity' ,
       `event_tickets`.`available` AS 'availableTicket' , `event_tickets`.`sale_start` AS 'saleStart', `event_tickets`.`sale_end` AS 'saleEnd',
       `event_tickets`.`status` AS 'ticketStatus',  `event_tickets`.`date_added` AS 'dateAdded', `event_tickets`.`last_updated` AS 'lastUpdated'
				FROM `event_tickets`
				WHERE `event_tickets`.`EVENT_ID` = ?";

       SET @eventId = in_eventId;

       EXECUTE get_event_tickets_statement USING @eventId;

       DEALLOCATE PREPARE get_event_tickets_statement;
END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getEventTime`;
DELIMITER $$
CREATE  PROCEDURE `getEventTime`(IN `in_eventId` INT, OUT `out_startDate` DATE, OUT `out_startTime` TIME, OUT `out_endDate` DATE, OUT `out_endTime` TIME)
    READS SQL DATA
BEGIN
		SET @total = 0;

        SELECT `start_date`, `start_time`, `end_date`, `end_time`  FROM `event`
			WHERE `EVENT_ID` = in_eventId  INTO out_startDate, out_startTime, out_endDate, out_endTime;

END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `getGuest`;
DELIMITER $$
CREATE  PROCEDURE `getGuest`(IN `in_guestId` INT)
    READS SQL DATA
BEGIN
       PREPARE get_guest_statement FROM
       "SELECT `event_guests`.`GUEST_ID` AS 'guestId', `event_guests`.`EVENT_ID` AS 'eventId', `event_guests`.`first_name` AS 'firstName', `event_guests`.`last_name` AS 'lastName',
       `event_guests`.`aka_name` AS 'nickName' , `event_guests`.`title`, `event_guests`.`bio` AS 'aboutGuest',`event_guests`.`image` AS 'guestImage',
       `event_guests`.`date_added` AS 'dateAdded', `event_guests`.`last_updated` AS 'lastUpdated'
				FROM `event_guests`
				WHERE `event_guests`.`GUEST_ID` = ?";

       SET @guestId = in_guestId;

       EXECUTE get_guest_statement USING @guestId;

       DEALLOCATE PREPARE get_guest_statement;
END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getOrganizationAddress`;
DELIMITER $$
CREATE  PROCEDURE `getOrganizationAddress`(IN `in_organizerId` INT)
    MODIFIES SQL DATA
BEGIN

        PREPARE get_address_prepare FROM "SELECT `ORG_ADD_ID` AS 'addressId',`sub_city` AS 'subCity' , `city`, `country`,
			`location`,`longitude`, `latitude`
			FROM `egate_db`.`organization_address`
            LEFT JOIN `egate_db`.`organizer` USING(`ORGANIZATION_ID`)
			WHERE  `ORGANIZER_ID` = ?";
        SET @organizationId = in_organizerId;

        EXECUTE get_address_prepare USING @organizationId;

        DEALLOCATE PREPARE get_address_prepare;

END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `getOrganizationSocials`;
DELIMITER $$
CREATE  PROCEDURE `getOrganizationSocials`(IN `in_organizerId` INT)
    READS SQL DATA
BEGIN

            SELECT  `ORGANIZATION_ID` AS 'organizationId', `social` , `website`
			FROM `egate_db`.`organization`
            LEFT JOIN `egate_db`.`organizer` USING(`ORGANIZATION_ID`)
            WHERE `ORGANIZER_ID` = in_organizerId;


END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getOrganizer`;
DELIMITER $$
CREATE  PROCEDURE `getOrganizer`(IN `in_organizerId` INT)
    READS SQL DATA
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


END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getOrganizerAddress`;
DELIMITER $$
CREATE  PROCEDURE `getOrganizerAddress`(IN `in_organizationId` INT)
    MODIFIES SQL DATA
BEGIN

        PREPARE get_address_prepare FROM "SELECT `ORG_ADD_ID` AS 'addressId',`sub_city` AS 'subCity' , `city`, `country`,
			`location`,`longitude`, `latitude`
			FROM `egate_db`.`organization_address`
			WHERE  `ORGANIZATION_ID` = ?";
        SET @organizationId = in_organizationId;

        EXECUTE get_address_prepare USING @organizationId;

        DEALLOCATE PREPARE get_address_prepare;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getOrganizerEvent`;
DELIMITER $$
CREATE  PROCEDURE `getOrganizerEvent`(IN `in_eventId` INT, IN `in_organizerId` INT)
BEGIN
        SELECT `event`.`EVENT_ID` AS 'eventId', `event`.`ORGANIZER_ID` AS 'organizerId',  `event`.`name` AS 'eventName',`venue`, `event`.`discription` AS 'aboutEvent',
				`event_category`.`category_name` AS 'event_category', `event`.`start_date` AS 'startDate', `event`.`start_time` AS 'startTime',
                `event`.`end_date` AS 'endDate', `event`.`end_time` AS 'endTime', `longitude`, `latitude`,  `location`,
                `event`.`sub_city` AS 'subCity', `event`.`city`, `event`.`country`, `event`.`picture` AS 'eventImage',
                `event`.`status`, `event`.`created_on` AS 'createdOn', `event`.`last_updated` AS 'lastUpdated'
		FROM `event`
        RIGHT JOIN `event_category` USING(`CATEGORY_ID`)
        WHERE `ORGANIZER_ID` = in_organizerId AND `EVENT_ID` = in_eventId;


END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getOrganizerEvents`;
DELIMITER $$
CREATE  PROCEDURE `getOrganizerEvents`(IN `in_organizerId` INT)
BEGIN
        SELECT `event`.`EVENT_ID` AS 'eventId', `event`.`ORGANIZER_ID` AS 'organizerId',  `event`.`name` AS 'eventName',`venue`, `event`.`discription` AS 'adoutEvent',
				`event_category`.`category_name` AS 'event_category', `event`.`start_date` AS 'startDate', `event`.`start_time` AS 'startTime',
                `event`.`end_date` AS 'endDate', `event`.`end_time` AS 'endTime', `longitude`, `latitude`,  `location`,
                CONCAT(`event`.`sub_city`,', ', `event`.`city`, ' ', `event`.`country`) AS 'address', `event`.`picture` AS 'eventImage',
                `event`.`status`, `event`.`created_on` AS 'createdOn', `event`.`last_updated` AS 'lastUpdated'
		FROM `event`
        LEFT JOIN `event_category` USING(`CATEGORY_ID`)
        WHERE `ORGANIZER_ID` = in_organizerId;


END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getOrganizerInformation`;
DELIMITER $$
CREATE  PROCEDURE `getOrganizerInformation`(IN `in_organizerId` INT)
    READS SQL DATA
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


END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getReciept`;
DELIMITER $$
CREATE  PROCEDURE `getReciept`(IN `in_reservationId` INT)
    READS SQL DATA
BEGIN

       PREPARE get_reciept_prepare FROM
        'SELECT * FROM `egate_db`.`recieptdetails`
        WHERE `reservationId` = ? ';

        SET @attendeeId = in_reservationId;

       EXECUTE get_reciept_prepare USING @attendeeId;

        DEALLOCATE PREPARE get_reciept_prepare;

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getSponsor`;
DELIMITER $$
CREATE  PROCEDURE `getSponsor`(IN `in_sponsorId` INT)
    READS SQL DATA
BEGIN
       PREPARE get_sponsor_statement FROM
       "SELECT `event_sponsors`.`SPONSOR_ID` AS 'sponsorId', `event_sponsors`.`EVENT_ID` AS 'eventId',  `event_sponsors`.`name` AS 'sponsorName', `event_sponsors`.`image` AS 'sponsorImage',
       `event_sponsors`.`aboutSponor`, 	`event_sponsors`.`date_added` AS 'dateAdded', `event_sponsors`.`last_updated` AS 'lastUpdated'
				FROM `event_sponsors`
				WHERE `event_sponsors`.`SPONSOR_ID` = ?";

       SET @sponsorId = in_sponsorId;

       EXECUTE get_sponsor_statement USING @sponsorId;

       DEALLOCATE PREPARE get_sponsor_statement;
END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getSubscription`;
DELIMITER $$
CREATE  PROCEDURE `getSubscription`(IN `in_subscriber` JSON)
    MODIFIES SQL DATA
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

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `getTicket`;
DELIMITER $$
CREATE  PROCEDURE `getTicket`(IN `in_ticketId` INT)
    READS SQL DATA
BEGIN
       PREPARE get_ticket_statement FROM
       "SELECT `event_tickets`.`TICKET_ID` AS 'ticketId', `event_tickets`.`EVENT_ID` AS 'eventId', `event_tickets`.`name` AS 'ticketName', `event_tickets`.`type` AS 'ticketType' ,
       `event_tickets`.`price` AS 'ticketPrice', `event_tickets`.`discription` AS 'aboutTicket', `event_tickets`.`quantity` ,
       `event_tickets`.`available` AS 'availableTickets' , `event_tickets`.`sale_start` AS 'saleStart', `event_tickets`.`sale_end` AS 'saleEnd',
       `event_tickets`.`status` AS 'ticketStatus',  `event_tickets`.`date_added` AS 'dateAdded', `event_tickets`.`last_updated` AS 'lastUpdated'
				FROM `event_tickets`
				WHERE `event_tickets`.`TICKET_ID` = ?";

       SET @ticketId = in_ticketId;

       EXECUTE get_ticket_statement USING @ticketId;

       DEALLOCATE PREPARE get_ticket_statement;
END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `logIn`;
DELIMITER $$
CREATE  PROCEDURE `logIn`(IN `in_organizer` JSON)
    READS SQL DATA
BEGIN

        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
        RESIGNAL;
        END;

        IF JSON_CONTAINS_PATH(in_organizer, 'all', '$[0].email', '$[0].password') THEN
        PREPARE log_in_statement FROM
				"SELECT SQL_CALC_FOUND_ROWS `ORGANIZER_ID` AS organizerId, `first_name` AS 'firstName',  `last_name` AS lastName
					FROM `organizer` WHERE `e_mail` = ? AND `password` = ? ";
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

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `ticketStatusAndType`;
DELIMITER $$
CREATE  PROCEDURE `ticketStatusAndType`(IN `in_ticketId` INT, OUT `out_status` VARCHAR(15), OUT `out_type` VARCHAR(15))
    READS SQL DATA
BEGIN
       SELECT `status`, `type`
       FROM `event_tickets`
       WHERE `TICKET_ID` = in_ticketId INTO out_status, out_type;
END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `updateBillingAddress`;
DELIMITER $$
CREATE  PROCEDURE `updateBillingAddress`(IN `in_organizerId` INT, IN `in_accountInfo` JSON)
    MODIFIES SQL DATA
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

 END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `updateComment`;
DELIMITER $$
CREATE  PROCEDURE `updateComment`(IN `in_eventId` INT, IN `in_comment` JSON)
    MODIFIES SQL DATA
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

END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `updateEvent`;
DELIMITER $$
CREATE  PROCEDURE `updateEvent`(IN `in_organizerId` INT, IN `in_event` JSON)
    MODIFIES SQL DATA
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
END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `updateEventAddress`;
DELIMITER $$
CREATE  PROCEDURE `updateEventAddress`(IN `in_organizerId` INT, IN `in_eventAddress` JSON)
    MODIFIES SQL DATA
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
END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `updateEventAttendee`;
DELIMITER $$
CREATE  PROCEDURE `updateEventAttendee`(IN `in_attendee` JSON, OUT `out_result` INT)
    MODIFIES SQL DATA
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
							'UPDATE `event_attendees`
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
END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `updateEventCategory`;
DELIMITER $$
CREATE  PROCEDURE `updateEventCategory`(IN `in_category` JSON)
    MODIFIES SQL DATA
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
                'UPDATE `egat_db`.`event_category` SET `category_name` = ?
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

END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `updateEventGuest`;
DELIMITER $$
CREATE  PROCEDURE `updateEventGuest`(IN `in_eventID` INT, IN `in_guest` JSON)
    MODIFIES SQL DATA
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
			 'UPDATE `event_guests`	SET `first_name` = ? , `last_name` = ?, `aka_name` = ? ,
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

END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `updateEventInfo`;
DELIMITER $$
CREATE  PROCEDURE `updateEventInfo`(IN `in_organizerId` INT, IN `in_event` JSON)
    MODIFIES SQL DATA
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
END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `updateEventPicture`;
DELIMITER $$
CREATE  PROCEDURE `updateEventPicture`(IN `in_eventId` INT, IN `in_picture` VARCHAR(50))
    MODIFIES SQL DATA
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


END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `updateEventSponsor`;
DELIMITER $$
CREATE  PROCEDURE `updateEventSponsor`(IN `in_eventID` INT, IN `in_sponsor` JSON)
    MODIFIES SQL DATA
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

         PREPARE   update_sponsor_statement FROM 'UPDATE `event_sponsors`
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




END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `updateEventStatus`;
DELIMITER $$
CREATE  PROCEDURE `updateEventStatus`(IN `in_organizerId` INT, IN `in_eventId` INT, IN `in_eventStatus` VARCHAR(20), OUT `out_result` BOOLEAN)
    MODIFIES SQL DATA
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

END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `updateEventTicket`;
DELIMITER $$
CREATE  PROCEDURE `updateEventTicket`(IN `in_eventId` INT, IN `in_ticket` JSON)
    MODIFIES SQL DATA
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
            'UPDATE `event_tickets`
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

END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `updateEventTime`;
DELIMITER $$
CREATE  PROCEDURE `updateEventTime`(IN `in_organizerId` INT, IN `in_eventTime` JSON)
    MODIFIES SQL DATA
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
END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `updateOrganization`;
DELIMITER $$
CREATE  PROCEDURE `updateOrganization`(IN `in_organization` JSON)
    MODIFIES SQL DATA
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


END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `updateOrganizationAddress`;
DELIMITER $$
CREATE  PROCEDURE `updateOrganizationAddress`(IN `in_organizerId` INT, IN `in_address` JSON)
    MODIFIES SQL DATA
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

 END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `updateOrganizationProfile`;
DELIMITER $$
CREATE  PROCEDURE `updateOrganizationProfile`(IN `in_organizerId` INT, IN `in_organizationId` INT, IN `in_organizationInfo` JSON)
    MODIFIES SQL DATA
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




END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `updateOrganizationSocialAddress`;
DELIMITER $$
CREATE  PROCEDURE `updateOrganizationSocialAddress`(IN `in_organizerId` INT, IN `in_socialAddress` JSON)
    MODIFIES SQL DATA
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

 END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS `updateOrganizer`;
DELIMITER $$
CREATE  PROCEDURE `updateOrganizer`(IN `in_organizerId` INT, IN `in_newEmail` VARCHAR(50))
    MODIFIES SQL DATA
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

END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `updateOrganizerEmail`;
DELIMITER $$
CREATE  PROCEDURE `updateOrganizerEmail`(IN `in_organizerId` INT, IN `in_newEmail` VARCHAR(50))
    MODIFIES SQL DATA
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

END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `updateOrganizerPassword`;
DELIMITER $$
CREATE  PROCEDURE `updateOrganizerPassword`(IN `in_organizerId` INT, IN `in_oldPassword` VARCHAR(100), IN `in_newPassword` VARCHAR(100))
    MODIFIES SQL DATA
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

END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `updateOrganizerProfile`;
DELIMITER $$
CREATE  PROCEDURE `updateOrganizerProfile`(IN `in_organizerId` INT, IN `in_profileInfo` JSON)
    MODIFIES SQL DATA
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

END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS `updateSubscription`;
DELIMITER $$
CREATE  PROCEDURE `updateSubscription`(IN `in_subscription` JSON, OUT `out_subscriptionId` INT)
    MODIFIES SQL DATA
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


END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS eventCategories;
DELIMITER $$
CREATE PROCEDURE eventCategories()
    READS SQL DATA
BEGIN
		SELECT `CATEGORY_ID` AS 'categoryId', upper(`category_name`) AS 'categoryName'
        FROM `event_category`;
END$$
DELIMITER ;
