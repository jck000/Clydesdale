INSERT INTO `cldl_user` VALUES (1,1,1,'2015-01-01 00:00:00','2015-01-01 00:00:00',0,'jbilemjian_jffc','1664e05e26181f5e139b85d03a1b7f8f','Jack','Bilemjian','jck000@gmail.com',0,0,NULL,NULL),(2,1,1,'2016-06-24 15:06:51','2016-06-24 15:06:51',0,'jack','Kevorkjan9','Jack','Bilemjian','jck000@gmail.com',0,0,NULL,NULL),(3,1,1,'2016-06-27 15:26:30','2016-06-27 15:26:30',0,'test1234','2df518cdf619ab0ad86ec23ab4292bb0','test1234','Test1234','tetst@test.com',0,0,NULL,NULL),(4,1,1,'2016-06-27 15:31:49','2016-06-27 15:31:49',0,'test12345','d06d15e27fbda256964109be0593208b','test12345','test12345','test12345@test.com',0,0,NULL,NULL),(5,1,1,'2016-07-01 10:59:47','2016-07-01 10:59:47',0,'jack0701','988eaaaaef132fd306a74aa2735ea8d1','Jack','B','jack0701@test.com',0,0,NULL,NULL),(6,1,1,'2016-07-01 11:03:42','2016-07-01 11:03:42',0,'jack0701_01','d67449292ac9aa32d7ee6a7445822567','Jack','B','jack0701@test.com',0,0,NULL,NULL),(7,1,1,'2016-07-04 12:56:41','2016-07-04 12:56:41',0,'test070401','cb15f4ea7a8195d5c3eb3abb1b7a6d0b','Jack','B','test070401@test1235',0,0,NULL,NULL);
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_AUTO_VALUE_ON_ZERO' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`jack`@`localhost`*/ /*!50003 TRIGGER `tr_ins_cldl_user` BEFORE INSERT ON `cldl_user`
 FOR EACH ROW SET NEW.created = CURRENT_TIMESTAMP */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
