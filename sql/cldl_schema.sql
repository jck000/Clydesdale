-- phpMyAdmin SQL Dump
-- version 4.1.5
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Jun 10, 2016 at 08:11 PM
-- Server version: 5.1.73-log
-- PHP Version: 5.3.3

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: 'cldl'
--
CREATE DATABASE IF NOT EXISTS cldl DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE cldl;

-- --------------------------------------------------------

--
-- Table structure for table 'cldl_company'
--

DROP TABLE IF EXISTS cldl_company;
CREATE TABLE IF NOT EXISTS cldl_company (
  company_id int(11) unsigned NOT NULL,
  active tinyint(1) unsigned NOT NULL DEFAULT '1',
  created timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  updated timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  company_type smallint(1) unsigned NOT NULL DEFAULT '0',
  company_name varchar(50) NOT NULL,
  address1 varchar(50) DEFAULT NULL,
  address2 varchar(50) DEFAULT NULL,
  city varchar(30) DEFAULT NULL,
  state char(2) DEFAULT NULL,
  zip varchar(9) DEFAULT NULL,
  phone varchar(20) DEFAULT NULL,
  phone_toll_free varchar(20) DEFAULT NULL,
  fax varchar(20) DEFAULT NULL,
  web varchar(100) DEFAULT NULL,
  custom_menu tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '1=Use custom menu',
  logo_path varchar(100) DEFAULT NULL,
  logo_url varchar(100) NOT NULL,
  email varchar(100) DEFAULT NULL,
  time_zone tinyint(4) DEFAULT NULL,
  cms_path varchar(100) NOT NULL,
  cms_url varchar(100) NOT NULL,
  `language` smallint(1) unsigned NOT NULL DEFAULT '0' COMMENT '0 = English, 1 = Spanish',
  unit_type tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '0 = US, 1 = Metric',
  user_pass_change smallint(1) unsigned NOT NULL DEFAULT '0' COMMENT 'Force password change for users at 1st login.  0 = No, 1 = Yes',
  user_needs_approval smallint(1) unsigned NOT NULL DEFAULT '0' COMMENT 'Manually approve new users',
  PRIMARY KEY (company_id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='indexes done';

--
-- Triggers 'cldl_company'
--
DROP TRIGGER IF EXISTS `tr_ins_cldl_company`;
DELIMITER //
CREATE TRIGGER `tr_ins_cldl_company` BEFORE INSERT ON `cldl_company`
 FOR EACH ROW SET NEW.created = CURRENT_TIMESTAMP
//
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table 'cldl_dv'
--

DROP TABLE IF EXISTS cldl_dv;
CREATE TABLE IF NOT EXISTS cldl_dv (
  dv_id int(11) unsigned NOT NULL AUTO_INCREMENT,
  company_id int(11) unsigned NOT NULL,
  active tinyint(1) unsigned NOT NULL DEFAULT '1',
  dv_name varchar(30) NOT NULL,
  dv_db_table varchar(30) NOT NULL,
  dv_type tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '0 = Datatable, 1 = Form',
  dv_title varchar(30) NOT NULL,
  dt_add tinyint(1) unsigned NOT NULL DEFAULT '0',
  dt_del tinyint(1) unsigned NOT NULL DEFAULT '0',
  dt_edit tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '0 = No Add/Edit; 1 = click, 2 = double-click ',
  dv_name_add varchar(30) DEFAULT NULL COMMENT 'Path to custom form',
  dv_name_edit varchar(30) NOT NULL,
  dv_select_sql text NOT NULL,
  dv_insert_sql text NOT NULL,
  dv_update_sql text NOT NULL,
  dv_search_sql text NOT NULL COMMENT 'Regex where clause',
  dv_template varchar(100) NOT NULL,
  dv_js_functions text,
  dv_data_attributes text,
  dv_notes tinytext,
  PRIMARY KEY (dv_id),
  UNIQUE KEY dv_type_name (dv_type,dv_name),
  KEY table_name (dv_db_table),
  KEY company_id (company_id)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=100000 ;

-- --------------------------------------------------------

--
-- Table structure for table 'cldl_dvf'
--

DROP TABLE IF EXISTS cldl_dvf;
CREATE TABLE IF NOT EXISTS cldl_dvf (
  dvf_id int(11) unsigned NOT NULL AUTO_INCREMENT,
  dv_id int(11) NOT NULL,
  active tinyint(1) unsigned NOT NULL DEFAULT '1',
  ordr int(3) unsigned NOT NULL,
  dvf_db_column varchar(30) NOT NULL,
  dvf_name varchar(30) NOT NULL,
  dvf_label varchar(30) DEFAULT NULL,
  dvf_type tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '0=text, 1=textarea, 2=date, 3=hidden, 4=checkbox, 5=radio, 6=select,  7=password, 8=span, 9=paragraph',
  dvf_placeholder tinytext,
  dvf_help tinytext,
  dvf_key tinyint(1) unsigned NOT NULL DEFAULT '0',
  dvf_sortable tinyint(1) unsigned NOT NULL DEFAULT '1',
  dvf_sort_ordr tinyint(3) unsigned DEFAULT NULL,
  dvf_sort_asc_desc tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '1 = Ascending, 2 = Descending',
  dvf_before_display text COMMENT 'Perl function ',
  dvf_before_save text COMMENT 'Perl function',
  dvf_values text COMMENT 'Perl hash for drop down lists',
  dvf_default_value text COMMENT 'Default value for this column',
  dvf_js_functions text,
  dvf_data_attributes text,
  dvf_notes tinytext,
  PRIMARY KEY (dvf_id),
  KEY dv_id (dv_id)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=110000 ;

-- --------------------------------------------------------

--
-- Table structure for table 'cldl_menu'
--

DROP TABLE IF EXISTS cldl_menu;
CREATE TABLE IF NOT EXISTS cldl_menu (
  menu_id int(11) unsigned NOT NULL AUTO_INCREMENT,
  company_id int(11) unsigned NOT NULL,
  active tinyint(1) unsigned NOT NULL DEFAULT '1',
  pmenu_id int(11) unsigned DEFAULT NULL,
  ordr smallint(3) unsigned NOT NULL DEFAULT '0',
  menu_label varchar(50) NOT NULL,
  menu_link varchar(250) NOT NULL,
  menu_js_functions text NOT NULL,
  menu_data_attributes text NOT NULL,
  menu_notes tinytext NOT NULL,
  PRIMARY KEY (menu_id),
  KEY pmenu_id (pmenu_id),
  KEY company_id (company_id)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=120000 ;

-- --------------------------------------------------------

--
-- Table structure for table 'cldl_role'
--

DROP TABLE IF EXISTS cldl_role;
CREATE TABLE IF NOT EXISTS cldl_role (
  role_id int(11) unsigned NOT NULL AUTO_INCREMENT,
  company_id int(11) unsigned NOT NULL,
  active tinyint(1) unsigned NOT NULL DEFAULT '1',
  role_name varchar(32) NOT NULL,
  PRIMARY KEY (role_id),
  KEY company_id (company_id)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=130000 ;

-- --------------------------------------------------------

--
-- Table structure for table 'cldl_role_members'
--

DROP TABLE IF EXISTS cldl_role_members;
CREATE TABLE IF NOT EXISTS cldl_role_members (
  role_id int(11) unsigned NOT NULL,
  user_id int(11) unsigned NOT NULL,
  KEY role_id (role_id,user_id),
  KEY user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table 'cldl_role_permission_dv'
--

DROP TABLE IF EXISTS cldl_role_permission_dv;
CREATE TABLE IF NOT EXISTS cldl_role_permission_dv (
  role_permission_id int(11) unsigned NOT NULL AUTO_INCREMENT,
  role_id int(11) unsigned NOT NULL,
  dv_id int(11) unsigned NOT NULL,
  dt_add tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT 'Should default to value in cldl_dv',
  dt_del tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT 'Should default to value in cldl_dv',
  dt_edit tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT 'Should default to value in cldl_dv',
  PRIMARY KEY (role_permission_id),
  KEY role_id (role_id),
  KEY dv_id (dv_id)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=140000 ;

-- --------------------------------------------------------

--
-- Table structure for table 'cldl_role_permission_menu'
--

DROP TABLE IF EXISTS cldl_role_permission_menu;
CREATE TABLE IF NOT EXISTS cldl_role_permission_menu (
  role_permission_id int(11) unsigned NOT NULL AUTO_INCREMENT,
  role_id int(11) unsigned NOT NULL,
  menu_id int(11) unsigned NOT NULL,
  PRIMARY KEY (role_permission_id),
  KEY role_id (role_id),
  KEY menu_id (menu_id)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=210000 ;

-- --------------------------------------------------------

--
-- Table structure for table 'cldl_sql'
--

DROP TABLE IF EXISTS cldl_sql;
CREATE TABLE IF NOT EXISTS cldl_sql (
  sql_id int(11) unsigned NOT NULL AUTO_INCREMENT,
  company_id int(11) unsigned NOT NULL,
  active tinyint(1) unsigned NOT NULL DEFAULT '1',
  sql_stmt text NOT NULL,
  PRIMARY KEY (sql_id),
  KEY company_id (company_id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=220000 ;

-- --------------------------------------------------------

--
-- Table structure for table 'cldl_user'
--

DROP TABLE IF EXISTS cldl_user;
CREATE TABLE IF NOT EXISTS cldl_user (
  user_id int(11) unsigned NOT NULL AUTO_INCREMENT,
  company_id int(11) unsigned NOT NULL,
  active tinyint(1) unsigned NOT NULL DEFAULT '1',
  updated timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `language` smallint(1) unsigned NOT NULL DEFAULT '0' COMMENT '0 = English, 1 = Spanish',
  user_name varchar(32) NOT NULL,
  user_pass varchar(32) NOT NULL,
  first_name varchar(30) NOT NULL,
  last_name varchar(30) NOT NULL,
  user_email varchar(50) DEFAULT NULL,
  approved smallint(1) NOT NULL DEFAULT '0',
  pass_change smallint(1) unsigned NOT NULL DEFAULT '0' COMMENT 'Force password change. 0 = No, 1 = Yes',
  PRIMARY KEY (user_id),
  KEY company_id (company_id)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=230000 ;

--
-- Triggers 'cldl_user'
--
DROP TRIGGER IF EXISTS `tr_ins_cldl_user`;
DELIMITER //
CREATE TRIGGER `tr_ins_cldl_user` BEFORE INSERT ON `cldl_user`
 FOR EACH ROW SET NEW.created = CURRENT_TIMESTAMP
//
DELIMITER ;

--
-- Constraints for dumped tables
--

--
-- Constraints for table cldl_dv
--
ALTER TABLE cldl_dv
  ADD CONSTRAINT cldl_dv_ibfk_1 FOREIGN KEY (company_id) REFERENCES cldl_company (company_id) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table cldl_menu
--
ALTER TABLE cldl_menu
  ADD CONSTRAINT cldl_menu_ibfk_1 FOREIGN KEY (pmenu_id) REFERENCES cldl_menu (menu_id) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT cldl_menu_ibfk_2 FOREIGN KEY (company_id) REFERENCES cldl_company (company_id) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table cldl_role_members
--
ALTER TABLE cldl_role_members
  ADD CONSTRAINT cldl_role_members_ibfk_1 FOREIGN KEY (role_id) REFERENCES cldl_role (role_id),
  ADD CONSTRAINT cldl_role_members_ibfk_2 FOREIGN KEY (user_id) REFERENCES cldl_user (user_id);

--
-- Constraints for table cldl_role_permission_dv
--
ALTER TABLE cldl_role_permission_dv
  ADD CONSTRAINT cldl_role_permission_dv_ibfk_1 FOREIGN KEY (role_id) REFERENCES cldl_role (role_id),
  ADD CONSTRAINT cldl_role_permission_dv_ibfk_2 FOREIGN KEY (dv_id) REFERENCES cldl_dv (dv_id);

--
-- Constraints for table cldl_role_permission_menu
--
ALTER TABLE cldl_role_permission_menu
  ADD CONSTRAINT cldl_role_permission_menu_ibfk_1 FOREIGN KEY (role_id) REFERENCES cldl_role (role_id),
  ADD CONSTRAINT cldl_role_permission_menu_ibfk_2 FOREIGN KEY (menu_id) REFERENCES cldl_menu (menu_id);

--
-- Constraints for table cldl_user
--
ALTER TABLE cldl_user
  ADD CONSTRAINT cldl_user_ibfk_1 FOREIGN KEY (company_id) REFERENCES cldl_company (company_id) ON DELETE CASCADE ON UPDATE CASCADE;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
