use egate;

DROP VIEW IF EXISTS `bookingdetails`;
CREATE 
	ALGORITHM = UNDEFINED 
    SQL SECURITY DEFINER 
VIEW `bookingdetails` AS
    SELECT 
        ANY_VALUE(`event_attendees`.`EVENT_ID`) AS `eventId`,
        ANY_VALUE(`event_bookings`.`ATTENDEE_ID`) AS `attendeeId`,
        ANY_VALUE(`event_bookings`.`BOOKING_ID`) AS `bookingId`,
        ANY_VALUE(`event_bookings`.`TICKET_ID`) AS `ticketId`,
        ANY_VALUE(`event_attendees`.`first_name`) AS `firstName`,
        ANY_VALUE(`event_attendees`.`last_name`) AS `lastName`,
        ANY_VALUE(`event_attendees`.`phone`) AS `billingAddress`,
        ANY_VALUE(`service_provider`.`name`) AS `serviceProvider`,
        ANY_VALUE(`billing_address`.`phone_number`) AS `paymentAddress`,
        SUM(ANY_VALUE(`event_tickets`.`price`)) AS `totalPrice`,
        ANY_VALUE(`event_bookings`.`booked_on`) AS `bookedOn`
    FROM
        ((((((`event_bookings`
        LEFT JOIN `event_attendees` ON ((`event_bookings`.`ATTENDEE_ID` = `event_attendees`.`ATTENDEE_ID`)))
        LEFT JOIN `event_tickets` ON ((`event_bookings`.`TICKET_ID` = `event_tickets`.`TICKET_ID`)))
        LEFT JOIN `event` ON ((`event_attendees`.`EVENT_ID` = `event`.`EVENT_ID`)))
        LEFT JOIN `organizer` ON ((`event`.`ORGANIZER_ID` = `organizer`.`ORGANIZER_ID`)))
        LEFT JOIN `billing_address` ON ((`organizer`.`ORGANIZATION_ID` = `billing_address`.`ORGANIZATION_ID`)))
        LEFT JOIN `service_provider` ON ((`service_provider`.`PROVIDER_ID` = (CASE
            WHEN (`billing_address`.`PROVIDER_ID` = `event_attendees`.`PROVIDER_ID`) THEN `billing_address`.`PROVIDER_ID`
            ELSE NULL
        END))))
    GROUP BY `event_bookings`.`ATTENDEE_ID` , `event_tickets`.`TICKET_ID`;
    
    
DROP VIEW IF EXISTS `bookingstatus`;
CREATE 
	ALGORITHM = UNDEFINED 
    SQL SECURITY DEFINER 
VIEW  `bookingstatus` AS
    SELECT 
        `event_bookings`.`BOOKING_ID` AS `bookingId`,
        `reciept`.`RECIEPT_ID` AS `recieptId`,
        (CASE
            WHEN ISNULL(`reciept`.`RECIEPT_ID`) THEN 'PENDING'
            WHEN (`reciept`.`RECIEPT_ID` IS NOT NULL) THEN 'PAID'
        END) AS `status`
    FROM
        (`event_bookings`
        LEFT JOIN `reciept` ON ((`event_bookings`.`BOOKING_ID` = `reciept`.`BOOKING_ID`)));


DROP VIEW IF EXISTS `confirmerdbookings`;
CREATE 
	ALGORITHM = UNDEFINED 
    SQL SECURITY DEFINER 
VIEW `confirmerdbookings` AS
    SELECT 
        `event_attendees`.`EVENT_ID` AS `eventId`,
        `event_attendees`.`ATTENDEE_ID` AS `reservationId`,
        `event_bookings`.`BOOKING_ID` AS `bookingId`,
        `reciept`.`RECIEPT_ID` AS `RECIEPT_ID`,
        `event_attendees`.`first_name` AS `firstName`,
        `event_attendees`.`last_name` AS `lastName`,
        `event_attendees`.`email` AS `email`,
        `event_attendees`.`phone` AS `phoneNumber`,
        `service_provider`.`name` AS `paymentProvider`,
        `event_bookings`.`booked_on` AS `bookedOn`,
        `event_bookings`.`status` AS `bookingStatus`,
        `event_bookings`.`TICKET_ID` AS `ticketId`,
        `reciept`.`status` AS `recieptStatus`,
        `reciept`.`issued_on` AS `recieptIssued`
    FROM
        (`reciept`
        LEFT JOIN ((`event_attendees`
        LEFT JOIN `service_provider` ON
        ((`event_attendees`.`PROVIDER_ID` = `service_provider`.`PROVIDER_ID`)))
        LEFT JOIN `event_bookings` ON 
        ((`event_attendees`.`ATTENDEE_ID` = `event_bookings`.`ATTENDEE_ID`))) ON
        ((`event_bookings`.`BOOKING_ID` = `reciept`.`BOOKING_ID`)));


DROP VIEW IF EXISTS `eventcheckins`;
CREATE 
	ALGORITHM = UNDEFINED 
    SQL SECURITY DEFINER 
VIEW `eventcheckins` AS
    SELECT 
        `checkins`.`CHECK_IN_ID` AS `checkInId`,
        `reciept`.`BOOKING_ID` AS `bookingId`,
        `checkins`.`RECIEPT_ID` AS `recieptId`,
        `checkins`.`EVENT_ID` AS `eventId`,
        (CASE
            WHEN (`checkins`.`status` = 1) THEN 'IN'
            ELSE 'OUT'
        END) AS `status`,
        `checkins`.`first_check_in` AS `firstCheckIn`,
        `checkins`.`last_check_out` AS `lastCheckout`,
        `checkins`.`last_check_in` AS `lastCheckIn`
    FROM
        (((`checkins`
        LEFT JOIN `reciept` ON ((`checkins`.`RECIEPT_ID` = `reciept`.`RECIEPT_ID`)))
        LEFT JOIN `event_bookings` ON ((`reciept`.`BOOKING_ID` = `event_bookings`.`BOOKING_ID`)))
        LEFT JOIN `event_tickets` ON ((`checkins`.`EVENT_ID` = `event_tickets`.`EVENT_ID`)));

DROP VIEW IF EXISTS `eventreciepts`;
CREATE 
    ALGORITHM = UNDEFINED 
    SQL SECURITY DEFINER
VIEW `eventreciepts` AS
    SELECT 
        `event_tickets`.`EVENT_ID` AS `eventId`,
        `event_bookings`.`TICKET_ID` AS `ticketId`,
        `reciept`.`BOOKING_ID` AS `bookingId`,
        `event_bookings`.`ATTENDEE_ID` AS `reservationId`,
        `reciept`.`RECIEPT_ID` AS `recieptId`
    FROM
        (`reciept`
        LEFT JOIN (`event_bookings`
        LEFT JOIN `event_tickets` ON 
                  ((`event_bookings`.`TICKET_ID` = `event_tickets`.`TICKET_ID`))) ON 
                  ((`event_bookings`.`BOOKING_ID` = `reciept`.`BOOKING_ID`)));

DROP VIEW IF EXISTS `event_ticketsstatstics`;
CREATE 
    ALGORITHM = UNDEFINED  
    SQL SECURITY DEFINER
VIEW `event_ticketsstatstics` AS
    SELECT 
        `event_tickets`.`EVENT_ID` AS `eventId`,
        `event_tickets`.`TICKET_ID` AS `ticketId`,
        `event_tickets`.`price` AS `ticketPrice`,
        `event_tickets`.`quantity` AS `quantity`,
        (`event_tickets`.`quantity` - COUNT(`event_bookings`.`BOOKING_ID`)) AS `availableTicket`,
        COUNT(`event_bookings`.`BOOKING_ID`) AS `totalBooking`,
        COUNT(`reciept`.`RECIEPT_ID`) AS `confirmedBooking`,
        (COUNT(`event_bookings`.`BOOKING_ID`) - COUNT(`reciept`.`RECIEPT_ID`)) AS `pendingBooking`,
        (`event_tickets`.`price` * (COUNT(`event_bookings`.`BOOKING_ID`) - COUNT(`reciept`.`RECIEPT_ID`))) AS `pendingSale`,
        (`event_tickets`.`price` * COUNT(`reciept`.`RECIEPT_ID`)) AS `confirmedSale`
    FROM
        ((`event_tickets`
        LEFT JOIN `event_bookings` ON 
                  ((`event_tickets`.`TICKET_ID` = `event_bookings`.`TICKET_ID`)))
        LEFT JOIN `reciept` ON 
                  ((`event_bookings`.`BOOKING_ID` = `reciept`.`BOOKING_ID`)))
    GROUP BY `event_tickets`.`TICKET_ID`;
    
DROP VIEW IF EXISTS `recieptdetails`;
CREATE 
    ALGORITHM = UNDEFINED 
    SQL SECURITY DEFINER
VIEW `recieptdetails` AS
    SELECT 
        `event_attendees`.`EVENT_ID` AS `eventId`,
        `event`.`name` AS `eventName`,
        CONCAT(`event`.`sub_city`,
                ', ',
                `event`.`city`,
                ' ',
                `event`.`country`) AS `address`,
        `event`.`location` AS `location`,
        `event_attendees`.`ATTENDEE_ID` AS `reservationId`,
        `event_bookings`.`BOOKING_ID` AS `bookingId`,
        `event`.`start_date` AS `startDate`,
        `event`.`start_time` AS `startTime`,
        `event`.`end_date` AS `endDate`,
        `event`.`picture` AS `eventImage`,
        `reciept`.`RECIEPT_ID` AS `recieptId`,
        `event_attendees`.`first_name` AS `firstName`,
        `event_attendees`.`last_name` AS `lastName`,
        `event_tickets`.`name` AS `ticketName`,
        `event_tickets`.`type` AS `ticketType`,
        `event_tickets`.`price` AS `ticketPrice`,
        `event_attendees`.`email` AS `email`,
        `event_attendees`.`phone` AS `phoneNumber`,
        `service_provider`.`name` AS `paymentProvider`,
        `event_bookings`.`booked_on` AS `bookedOn`,
        `event_bookings`.`status` AS `bookingStatus`,
        `event_bookings`.`TICKET_ID` AS `ticketId`,
        `reciept`.`status` AS `recieptStatus`,
        `reciept`.`issued_on` AS `recieptIssued`
    FROM
        (`reciept`
        LEFT JOIN ((((`event_attendees`
        LEFT JOIN `event` ON 
                  ((`event_attendees`.`EVENT_ID` = `event`.`EVENT_ID`)))
        LEFT JOIN `service_provider` ON 
                  ((`event_attendees`.`PROVIDER_ID` = `service_provider`.`PROVIDER_ID`)))
        LEFT JOIN `event_bookings` ON 
                  ((`event_attendees`.`ATTENDEE_ID` = `event_bookings`.`ATTENDEE_ID`)))
        LEFT JOIN `event_tickets` ON 
                  ((`event_bookings`.`TICKET_ID` = `event_tickets`.`TICKET_ID`))) ON 
                  ((`event_bookings`.`BOOKING_ID` = `reciept`.`BOOKING_ID`)));
	

DROP VIEW IF EXISTS `subscriptionlist`;
CREATE 
    ALGORITHM = UNDEFINED 
    SQL SECURITY DEFINER
VIEW `subscriptionlist` AS
    SELECT 
        `subscription`.`SUBSCRIPTION_ID` AS `subscriptionId`,
        `subscriber`.`SUBSCRIBER_ID` AS `subscriberId`,
        `subscriber`.`e_mail` AS `Email`,
        `event_category`.`category_name` AS `subscription`,
        `subscriber`.`added_on` AS `subscribedOn`,
        `subscription`.`updated_on` AS `lastUpdated`
    FROM
        ((`subscriber`
        LEFT JOIN `subscription` ON 
                  ((`subscriber`.`SUBSCRIBER_ID` = `subscription`.`SUBSCRIBER_ID`)))
        LEFT JOIN `event_category` ON 
                  ((`subscription`.`CATEGORY_ID` = `event_category`.`CATEGORY_ID`)))
    GROUP BY `subscriber`.`SUBSCRIBER_ID` , `subscription`.`SUBSCRIPTION_ID`;
