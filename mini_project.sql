-- MySQL dump 10.13  Distrib 8.0.45, for Win64 (x86_64)
--
-- Host: localhost    Database: mini_project
-- ------------------------------------------------------
-- Server version	8.0.45

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Temporary view structure for view `available_resources`
--

DROP TABLE IF EXISTS `available_resources`;
/*!50001 DROP VIEW IF EXISTS `available_resources`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `available_resources` AS SELECT 
 1 AS `resource_id`,
 1 AS `resource_name`,
 1 AS `location`,
 1 AS `capacity`,
 1 AS `status`,
 1 AS `incharge_name`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `booking`
--

DROP TABLE IF EXISTS `booking`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `booking` (
  `booking_id` int NOT NULL AUTO_INCREMENT,
  `start_datetime` datetime DEFAULT NULL,
  `end_datetime` datetime DEFAULT NULL,
  `booking_status` varchar(20) DEFAULT NULL,
  `user_id` int DEFAULT NULL,
  `resource_id` int DEFAULT NULL,
  `event_id` int DEFAULT NULL,
  `approved_by` int DEFAULT NULL,
  PRIMARY KEY (`booking_id`),
  KEY `approved_by` (`approved_by`),
  KEY `fk_booking_event` (`event_id`),
  KEY `idx_booking_dates` (`start_datetime`,`end_datetime`),
  KEY `idx_booking_resource_dates` (`resource_id`,`start_datetime`,`end_datetime`),
  KEY `idx_booking_user` (`user_id`),
  KEY `idx_booking_status` (`booking_status`),
  CONSTRAINT `fk_booking_event` FOREIGN KEY (`event_id`) REFERENCES `event` (`event_id`) ON DELETE SET NULL,
  CONSTRAINT `fk_booking_resource` FOREIGN KEY (`resource_id`) REFERENCES `resources` (`resource_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_booking_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `booking`
--

LOCK TABLES `booking` WRITE;
/*!40000 ALTER TABLE `booking` DISABLE KEYS */;
INSERT INTO `booking` VALUES (1,'2026-04-15 10:00:00','2026-04-15 12:00:00','confirmed',1,201,1,NULL),(2,'2026-04-16 14:00:00','2026-04-16 16:00:00','confirmed',2,202,2,NULL),(3,'2026-04-18 11:00:00','2026-04-18 13:00:00','pending',1,203,4,NULL),(8,'2026-04-14 15:36:00','2026-04-15 15:36:00','confirmed',4,202,7,NULL);
/*!40000 ALTER TABLE `booking` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `booking_details`
--

DROP TABLE IF EXISTS `booking_details`;
/*!50001 DROP VIEW IF EXISTS `booking_details`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `booking_details` AS SELECT 
 1 AS `booking_id`,
 1 AS `user_id`,
 1 AS `user_name`,
 1 AS `resource_id`,
 1 AS `resource_name`,
 1 AS `event_id`,
 1 AS `event_name`,
 1 AS `start_datetime`,
 1 AS `end_datetime`,
 1 AS `booking_status`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `event`
--

DROP TABLE IF EXISTS `event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `event` (
  `event_id` int NOT NULL AUTO_INCREMENT,
  `event_name` varchar(100) DEFAULT NULL,
  `location` varchar(100) DEFAULT NULL,
  `organiser` varchar(100) DEFAULT NULL,
  `date` date DEFAULT NULL,
  PRIMARY KEY (`event_id`),
  KEY `idx_event_name` (`event_name`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `event`
--

LOCK TABLES `event` WRITE;
/*!40000 ALTER TABLE `event` DISABLE KEYS */;
INSERT INTO `event` VALUES (1,'Tech Workshop','Building A','Dr. Kulkarni','2026-04-15'),(2,'Seminar on AI','Seminar Hall','Prof. Mehta','2026-04-20'),(3,'Coding Competition','Computer Lab Advanced','Mr. Patil','2026-04-25'),(4,'Dance Workshop','Seminar Hall','Ms. Desai','2026-04-18'),(5,'Project Presentation','Conference Room A','Admin Joshi','2026-04-22'),(7,'dance','TBD','TBD','2026-04-06');
/*!40000 ALTER TABLE `event` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `resource_incharge`
--

DROP TABLE IF EXISTS `resource_incharge`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resource_incharge` (
  `incharge_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `department` varchar(50) DEFAULT NULL,
  `proven` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`incharge_id`)
) ENGINE=InnoDB AUTO_INCREMENT=103 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `resource_incharge`
--

LOCK TABLES `resource_incharge` WRITE;
/*!40000 ALTER TABLE `resource_incharge` DISABLE KEYS */;
INSERT INTO `resource_incharge` VALUES (101,'Mr. Patil','patil@gmail.com','IT','Senior'),(102,'Ms. Desai','desai@gmail.com','EXTC','Senior');
/*!40000 ALTER TABLE `resource_incharge` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `resources`
--

DROP TABLE IF EXISTS `resources`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resources` (
  `resource_id` int NOT NULL AUTO_INCREMENT,
  `resource_name` varchar(100) DEFAULT NULL,
  `location` varchar(100) DEFAULT NULL,
  `capacity` int DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL,
  `incharge_id` int DEFAULT NULL,
  PRIMARY KEY (`resource_id`),
  KEY `fk_resources_incharge` (`incharge_id`),
  CONSTRAINT `fk_resources_incharge` FOREIGN KEY (`incharge_id`) REFERENCES `resource_incharge` (`incharge_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=209 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `resources`
--

LOCK TABLES `resources` WRITE;
/*!40000 ALTER TABLE `resources` DISABLE KEYS */;
INSERT INTO `resources` VALUES (201,'Lab 1','Building A - Floor 1',40,'Available',101),(202,'Lab 2','Building A - Floor 2',35,'Available',101),(203,'Conference Room A','Building B - Floor 1',20,'Available',102),(204,'Conference Room B','Building B - Floor 2',15,'Available',102),(205,'Seminar Hall','Main Block',100,'Available',102),(206,'Projector 1','Store Room',1,'Available',101),(207,'Projector 2','Store Room',1,'Available',101),(208,'Computer Lab Advanced','Building C',50,'Available',102);
/*!40000 ALTER TABLE `resources` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `first_name` varchar(50) DEFAULT NULL,
  `last_name` varchar(50) DEFAULT NULL,
  `department` varchar(50) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `role` varchar(20) DEFAULT NULL,
  `priority` int DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user`
--

LOCK TABLES `user` WRITE;
/*!40000 ALTER TABLE `user` DISABLE KEYS */;
INSERT INTO `user` VALUES (1,'Amit','Sharma','IT','amit@gmail.com','Student',1),(2,'Sneha','Patil','EXTC','sneha@gmail.com','Student',1),(3,'Dr','Kulkarni','IT','kulkarni@gmail.com','Faculty',3),(4,'Admin','Joshi','Admin','admin@gmail.com','Admin',5);
/*!40000 ALTER TABLE `user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_phone`
--

DROP TABLE IF EXISTS `user_phone`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_phone` (
  `user_id` int NOT NULL,
  `phone_no` varchar(15) NOT NULL,
  PRIMARY KEY (`user_id`,`phone_no`),
  CONSTRAINT `fk_user_phone_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_phone`
--

LOCK TABLES `user_phone` WRITE;
/*!40000 ALTER TABLE `user_phone` DISABLE KEYS */;
INSERT INTO `user_phone` VALUES (1,'9123456780'),(1,'9876543210'),(2,'9988776655'),(3,'9765432109'),(4,'9000000001');
/*!40000 ALTER TABLE `user_phone` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Final view structure for view `available_resources`
--

/*!50001 DROP VIEW IF EXISTS `available_resources`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `available_resources` AS select `r`.`resource_id` AS `resource_id`,`r`.`resource_name` AS `resource_name`,`r`.`location` AS `location`,`r`.`capacity` AS `capacity`,`r`.`status` AS `status`,`ri`.`name` AS `incharge_name` from (`resources` `r` left join `resource_incharge` `ri` on((`r`.`incharge_id` = `ri`.`incharge_id`))) where (`r`.`status` = 'Available') */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `booking_details`
--

/*!50001 DROP VIEW IF EXISTS `booking_details`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `booking_details` AS select `b`.`booking_id` AS `booking_id`,`b`.`user_id` AS `user_id`,concat(`u`.`first_name`,' ',`u`.`last_name`) AS `user_name`,`b`.`resource_id` AS `resource_id`,`r`.`resource_name` AS `resource_name`,`b`.`event_id` AS `event_id`,`e`.`event_name` AS `event_name`,`b`.`start_datetime` AS `start_datetime`,`b`.`end_datetime` AS `end_datetime`,`b`.`booking_status` AS `booking_status` from (((`booking` `b` left join `user` `u` on((`b`.`user_id` = `u`.`user_id`))) left join `resources` `r` on((`b`.`resource_id` = `r`.`resource_id`))) left join `event` `e` on((`b`.`event_id` = `e`.`event_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-11 22:56:04
