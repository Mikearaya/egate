DROP DATABASE IF EXISTS `egate_db`;

CREATE DATABASE `egate_db`;

USE `egate_db`;


CREATE TABLE IF NOT EXISTS `organization` (
  `ORGANIZATION_ID` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(30) DEFAULT NULL,
  `po_num` varchar(10) DEFAULT NULL,
  `logo` varchar(100) DEFAULT NULL,
  `info` text,
  `registered_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `social` json DEFAULT NULL,
  `mobile_number` json DEFAULT NULL,
  `office_number` json DEFAULT NULL,
  `website` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`ORGANIZATION_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=210 DEFAULT CHARSET=latin1;


CREATE TABLE IF NOT EXISTS `organization_address` (
  `city` varchar(20) DEFAULT NULL,
  `sub_city` varchar(30) DEFAULT NULL,
  `country` varchar(20) DEFAULT NULL,
  `location` varchar(30) DEFAULT NULL,
  `longitude` varchar(20) DEFAULT NULL,
  `latitude` varchar(20) DEFAULT NULL,
  `ORG_ADD_ID` int(11) NOT NULL AUTO_INCREMENT,
  `ORGANIZATION_ID` int(11) NOT NULL,
  PRIMARY KEY (`ORG_ADD_ID`),
  KEY `ORGANIZATION_ID` (`ORGANIZATION_ID`),
  CONSTRAINT `organization_address_fk` FOREIGN KEY (`ORGANIZATION_ID`) REFERENCES `organization` (`ORGANIZATION_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=latin1;


CREATE TABLE IF NOT EXISTS `organizer` (
  `ORGANIZER_ID` int(11) NOT NULL AUTO_INCREMENT,
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
  `bio` text,
  PRIMARY KEY (`ORGANIZER_ID`),
  UNIQUE KEY `org_email` (`e_mail`),
  UNIQUE KEY `ORGANIZATION_ID` (`ORGANIZATION_ID`),
  CONSTRAINT `organization_organizer_fk` FOREIGN KEY (`ORGANIZATION_ID`) REFERENCES `organization` (`ORGANIZATION_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=202 DEFAULT CHARSET=latin1;

#event categories table
CREATE TABLE IF NOT EXISTS `event_category` (
  `CATEGORY_ID` int(11) NOT NULL AUTO_INCREMENT,
  `category_name` varchar(30) NOT NULL,
  `date_added` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`CATEGORY_ID`),
  UNIQUE KEY `category_name` (`category_name`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;

#digital(mobile/online) payment service providers table
CREATE TABLE IF NOT EXISTS `service_provider` (
  `PROVIDER_ID` int(11) NOT NULL AUTO_INCREMENT,
  `name` enum('HELLO CASH','MBIRR') NOT NULL,
  `added_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_updated` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`PROVIDER_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;

#event table
CREATE TABLE  IF NOT EXISTS `event` (
  `EVENT_ID` int(11) NOT NULL AUTO_INCREMENT,
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
  `total_view` int(11) DEFAULT '0',
  PRIMARY KEY (`EVENT_ID`),
  UNIQUE KEY `uq_event_organizer` (`EVENT_ID`,`ORGANIZER_ID`),
  UNIQUE KEY `uq_event_category` (`EVENT_ID`,`CATEGORY_ID`),
  UNIQUE KEY `uq_event_organizer_category` (`EVENT_ID`,`ORGANIZER_ID`,`CATEGORY_ID`),
  KEY `ORGANIZER_ID` (`ORGANIZER_ID`) USING BTREE,
  KEY `event_category_idx` (`CATEGORY_ID`),
  CONSTRAINT `event_category_fk` FOREIGN KEY (`CATEGORY_ID`) REFERENCES `event_category` (`CATEGORY_ID`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `organizer_event` FOREIGN KEY (`ORGANIZER_ID`) REFERENCES `organizer` (`ORGANIZER_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=828 DEFAULT CHARSET=latin1;


# event attendees table
CREATE TABLE IF NOT EXISTS `event_tickets` (
  `TICKET_ID` int(11) NOT NULL AUTO_INCREMENT,
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
  `status` enum('ACTIVE','SOLD OUT','DRAFT','REMOVED') NOT NULL DEFAULT 'ACTIVE',
  PRIMARY KEY (`TICKET_ID`),
  UNIQUE KEY `UQ_event_ticket` (`TICKET_ID`,`EVENT_ID`),
  KEY `EVNT_ID` (`EVENT_ID`),
  CONSTRAINT `event_ticket_fk` FOREIGN KEY (`EVENT_ID`) REFERENCES `event` (`EVENT_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=355 DEFAULT CHARSET=latin1;

# event special guests table
CREATE TABLE IF NOT EXISTS `event_guests` (
  `GUEST_ID` int(11) NOT NULL AUTO_INCREMENT,
  `EVENT_ID` int(11) NOT NULL,
  `first_name` varchar(30) NOT NULL,
  `last_name` varchar(20) NOT NULL,
  `aka_name` varchar(50) DEFAULT NULL,
  `title` varchar(50) DEFAULT NULL,
  `bio` text,
  `image` varchar(100) DEFAULT NULL,
  `date_added` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`GUEST_ID`),
  UNIQUE KEY `UQ_event_guest` (`GUEST_ID`,`EVENT_ID`),
  KEY `EVNT_ID` (`EVENT_ID`),
  CONSTRAINT `event_guest` FOREIGN KEY (`EVENT_ID`) REFERENCES `event` (`EVENT_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=177 DEFAULT CHARSET=latin1;

# event sponsors table
CREATE TABLE IF NOT EXISTS `event_sponsors` (
  `SPONSOR_ID` int(11) NOT NULL AUTO_INCREMENT,
  `EVENT_ID` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `image` varchar(100) DEFAULT NULL,
  `date_added` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `aboutSponsor` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`SPONSOR_ID`),
  UNIQUE KEY `UQ_event_sponsor` (`SPONSOR_ID`,`EVENT_ID`),
  KEY `EVT_ID` (`EVENT_ID`),
  KEY `EVNT_ID` (`EVENT_ID`),
  KEY `EVNT_ID_2` (`EVENT_ID`),
  CONSTRAINT `event_sponsor_fk` FOREIGN KEY (`EVENT_ID`) REFERENCES `event` (`EVENT_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=74 DEFAULT CHARSET=latin1;

# event people comments table
CREATE TABLE IF NOT EXISTS `event_comments` (
  `COMMENT_ID` int(11) NOT NULL AUTO_INCREMENT,
  `EVENT_ID` int(11) NOT NULL,
  `name` varchar(30) NOT NULL,
  `comment` varchar(255) NOT NULL,
  `commented_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`COMMENT_ID`),
  KEY `EVNT_ID` (`EVENT_ID`),
  CONSTRAINT `event_comment_fk` FOREIGN KEY (`EVENT_ID`) REFERENCES `event` (`EVENT_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;

# event attendees table
CREATE TABLE IF NOT EXISTS `event_attendees` (
  `ATTENDEE_ID` int(11) NOT NULL AUTO_INCREMENT,
  `EVENT_ID` int(11) NOT NULL,
  `phone` varchar(15) NOT NULL,
  `first_name` varchar(20) NOT NULL,
  `last_name` varchar(20) NOT NULL,
  `email` varchar(30) DEFAULT NULL,
  `registered_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `PROVIDER_ID` int(11) DEFAULT NULL,
  PRIMARY KEY (`ATTENDEE_ID`),
  UNIQUE KEY `eventattendee_billing_unq` (`EVENT_ID`,`phone`),
  KEY `attendee_paymentAdd_fk` (`PROVIDER_ID`),
  CONSTRAINT `attendee_paymentAddrss_fk` FOREIGN KEY (`PROVIDER_ID`) REFERENCES `service_provider` (`PROVIDER_ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `event_attendee_fk` FOREIGN KEY (`EVENT_ID`) REFERENCES `event` (`EVENT_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=latin1;

#event bookings table
CREATE TABLE IF NOT EXISTS `event_bookings` (
  `BOOKING_ID` int(11) NOT NULL AUTO_INCREMENT,
  `TICKET_ID` int(11) NOT NULL,
  `ATTENDEE_ID` int(11) NOT NULL,
  `booked_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status` enum('PENDING','CONFIRMED','CANCELED') NOT NULL DEFAULT 'PENDING',
  `last_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`BOOKING_ID`),
  KEY `TIK_ID` (`TICKET_ID`),
  KEY `TIK_ID_2` (`TICKET_ID`),
  KEY `ATT_ID` (`ATTENDEE_ID`),
  KEY `ATT_ID_2` (`ATTENDEE_ID`),
  KEY `ATTENDEE_ID` (`ATTENDEE_ID`),
  CONSTRAINT `booked_attendee_fk` FOREIGN KEY (`ATTENDEE_ID`) REFERENCES `event_attendees` (`ATTENDEE_ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `booked_ticket_fk` FOREIGN KEY (`TICKET_ID`) REFERENCES `event_tickets` (`TICKET_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=35 DEFAULT CHARSET=latin1;

# ticket payment reciepts table
CREATE TABLE IF NOT EXISTS `reciept` (
  `RECIEPT_ID` int(11) NOT NULL AUTO_INCREMENT,
  `BOOKING_ID` int(11) NOT NULL,
  `status` enum('ACTIVE','USED') NOT NULL DEFAULT 'ACTIVE',
  `issued_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`RECIEPT_ID`),
  KEY `BOOKING_ID` (`BOOKING_ID`),
  KEY `BOOKING_ID_2` (`BOOKING_ID`),
  CONSTRAINT `bookin_reciept_fk` FOREIGN KEY (`BOOKING_ID`) REFERENCES `event_bookings` (`BOOKING_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=latin1;


#notifications subscribers table
CREATE TABLE IF NOT EXISTS `subscriber` (
  `SUBSCRIBER_ID` int(11) NOT NULL AUTO_INCREMENT,
  `e_mail` varchar(50) NOT NULL,
  `added_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`SUBSCRIBER_ID`),
  UNIQUE KEY `e_mail` (`e_mail`),
  UNIQUE KEY `uq_subscriber_email` (`SUBSCRIBER_ID`,`e_mail`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;

#subscriptions table
CREATE TABLE IF NOT EXISTS `subscription` (
  `SUBSCRIPTION_ID` int(11) NOT NULL AUTO_INCREMENT,
  `CATEGORY_ID` int(11) DEFAULT NULL,
  `SUBSCRIBER_ID` int(11) NOT NULL,
  `added_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`SUBSCRIPTION_ID`),
  UNIQUE KEY `UQ_subscription` (`CATEGORY_ID`,`SUBSCRIBER_ID`),
  KEY `subscribed_subscriber_fk` (`SUBSCRIBER_ID`),
  CONSTRAINT `subscribed_category_fk` FOREIGN KEY (`CATEGORY_ID`) REFERENCES `event_category` (`CATEGORY_ID`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `subscribed_subscriber_fk` FOREIGN KEY (`SUBSCRIBER_ID`) REFERENCES `subscriber` (`SUBSCRIBER_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2102 DEFAULT CHARSET=latin1;

#viewers table people that would like 
#to contact the event organizer through e-mail
CREATE TABLE IF NOT EXISTS `viewers` (
  `VIEWER_ID` int(11) NOT NULL AUTO_INCREMENT,
  `ORGANIZER_ID` int(11) NOT NULL,
  `sent_on` datetime DEFAULT NULL,
  `first_name` varchar(30) NOT NULL,
  `last_name` varchar(30) NOT NULL,
  `e_mail` varchar(50) NOT NULL,
  `subject` varchar(30) NOT NULL,
  `mail` varchar(30) NOT NULL,
  PRIMARY KEY (`VIEWER_ID`),
  KEY `ORGANIZER_ID` (`ORGANIZER_ID`),
  KEY `ORGANIZER_ID_2` (`ORGANIZER_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=latin1;

#organizations billing address to accept payment for events table
CREATE TABLE IF NOT EXISTS `billing_address` (
  `BILLING_ID` int(11) NOT NULL AUTO_INCREMENT,
  `ORGANIZATION_ID` int(11) NOT NULL,
  `PROVIDER_ID` int(11) NOT NULL,
  `phone_number` varchar(15) NOT NULL,
  `added_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_updated` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`BILLING_ID`),
  UNIQUE KEY `organizer_billing_unq` (`ORGANIZATION_ID`,`PROVIDER_ID`),
  KEY `ORGANIZATION_ID` (`ORGANIZATION_ID`),
  KEY `PROVIDER_ID` (`PROVIDER_ID`),
  CONSTRAINT `event_billinaddress_fk` FOREIGN KEY (`ORGANIZATION_ID`) REFERENCES `organization` (`ORGANIZATION_ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `service_provider_fx` FOREIGN KEY (`PROVIDER_ID`) REFERENCES `service_provider` (`PROVIDER_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;

#checkins record table
CREATE TABLE IF NOT EXISTS `checkins` (
  `CHECK_IN_ID` int(11) NOT NULL AUTO_INCREMENT,
  `RECIEPT_ID` int(11) NOT NULL,
  `status` tinyint(1) NOT NULL DEFAULT '1',
  `first_check_in` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_check_in` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_check_out` datetime DEFAULT NULL,
  `updated_on` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `EVENT_ID` int(11) NOT NULL,
  PRIMARY KEY (`CHECK_IN_ID`),
  UNIQUE KEY `RECIEPT_ID` (`RECIEPT_ID`),
  KEY `RECIEPT_ID_2` (`RECIEPT_ID`),
  KEY `event_checkin_idx` (`EVENT_ID`),
  CONSTRAINT `event_checkin_fk` FOREIGN KEY (`EVENT_ID`) REFERENCES `event` (`EVENT_ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `recipt_checkin_fk` FOREIGN KEY (`RECIEPT_ID`) REFERENCES `reciept` (`RECIEPT_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;

#deactivated accounts
CREATE TABLE IF NOT EXISTS `deactivated` (
  `DEACTIVATION_ID` int(11) NOT NULL AUTO_INCREMENT,
  `registered_on` date NOT NULL,
  `deactivated_on` date NOT NULL,
  `ORGANIZATION_ID` int(11) NOT NULL,
  `organizer_name` varchar(30) DEFAULT NULL,
  `email_address` varchar(50) NOT NULL,
  PRIMARY KEY (`DEACTIVATION_ID`),
  UNIQUE KEY `ORGANIZATION_ID` (`ORGANIZATION_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=latin1;

#account deactivation reasons table
CREATE TABLE IF NOT EXISTS `deactivation_reasons` (
  `REASON_ID` int(11) NOT NULL AUTO_INCREMENT,
  `DEACTIVATION_ID` int(11) NOT NULL,
  `reason` varchar(255) NOT NULL,
  PRIMARY KEY (`REASON_ID`),
  KEY `DEACTIVATION_ID` (`DEACTIVATION_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=latin1;
