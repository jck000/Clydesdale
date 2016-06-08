-- phpMyAdmin SQL Dump
-- version 4.1.5
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Dec 16, 2015 at 12:53 AM
-- Server version: 5.1.73-log
-- PHP Version: 5.3.3

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

DROP DATABASE cldl;

--
-- Database: `cldl`
--
CREATE DATABASE IF NOT EXISTS `cldl` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `cldl`;

-- --------------------------------------------------------

--
-- Table structure for table `cldl_company`
--

DROP TABLE IF EXISTS `cldl_company`;
CREATE TABLE IF NOT EXISTS `cldl_company` (
  `company_id` int(11) unsigned NOT NULL,
  `active` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `created` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `company_type` smallint(1) unsigned NOT NULL DEFAULT '0',
  `company_name` varchar(50) NOT NULL,
  `address1` varchar(50) DEFAULT NULL,
  `address2` varchar(50) DEFAULT NULL,
  `city` varchar(30) DEFAULT NULL,
  `state` char(2) DEFAULT NULL,
  `zip` varchar(9) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `phone_toll_free` varchar(20) DEFAULT NULL,
  `fax` varchar(20) DEFAULT NULL,
  `web` varchar(100) DEFAULT NULL,
  `custom_menu` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '1=Use custom menu',
  `logo_path` varchar(100) DEFAULT NULL,
  `logo_url` varchar(100) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `time_zone` tinyint(4) DEFAULT NULL,
  `cms_path` varchar(100) NOT NULL,
  `cms_url` varchar(100) NOT NULL,
  `language` smallint(1) unsigned NOT NULL DEFAULT '0' COMMENT '0 = English, 1 = Spanish',
  `unit_type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '0 = US, 1 = Metric',
  `user_pass_change` smallint(1) unsigned NOT NULL DEFAULT '0' COMMENT 'Force password change for users at 1st login.  0 = No, 1 = Yes',
  `user_needs_approval` smallint(1) unsigned NOT NULL DEFAULT '0' COMMENT 'Manually approve new users',
  PRIMARY KEY (`company_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COMMENT='indexes done';

--
-- Dumping data for table `cldl_company`
--

INSERT INTO `cldl_company` (`company_id`, `active`, `created`, `updated`, `company_type`, `company_name`, `address1`, `address2`, `city`, `state`, `zip`, `phone`, `phone_toll_free`, `fax`, `web`, `custom_menu`, `logo_path`, `logo_url`, `email`, `time_zone`, `cms_path`, `cms_url`, `language`, `unit_type`, `user_pass_change`, `user_needs_approval`) VALUES
(1, 1, '2015-01-01 00:00:00', '2015-01-01 09:00:00', 0, 'CLDL Default', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, '', NULL, NULL, '', '', 0, 0, 0, 0);

--
-- Triggers `cldl_company`
--
DROP TRIGGER IF EXISTS `tr_ins_cldl_company`;
DELIMITER //
CREATE TRIGGER `tr_ins_cldl_company` BEFORE INSERT ON `cldl_company`
 FOR EACH ROW SET NEW.created = CURRENT_TIMESTAMP
//
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `cldl_dv`
--

DROP TABLE IF EXISTS `cldl_dv`;
CREATE TABLE IF NOT EXISTS `cldl_dv` (
  `dv_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `company_id` int(11) unsigned NOT NULL,
  `active` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `dv_name` varchar(30) NOT NULL,
  `dv_db_table` varchar(30) NOT NULL,
  `sql_id` int(11) unsigned DEFAULT NULL COMMENT 'predefined SQL statement',
  `dv_type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '0 = Datatable, 1 = Form',
  `dv_title` varchar(30) NOT NULL,
  `dt_add` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `dt_del` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `dt_edit` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '0 = No Add/Edit; 1 = click, 2 = double-click ',
  `dv_name_add` varchar(30) DEFAULT NULL COMMENT 'Path to custom form',
  `dv_name_edit` varchar(30) NOT NULL,
  `dv_template` varchar(100) NOT NULL,
  `dv_js_functions` text,
  `dv_data_attributes` text,
  `dv_notes` tinytext,
  PRIMARY KEY (`dv_id`),
  UNIQUE KEY `dv_type_name` (`dv_type`,`dv_name`),
  KEY `table_name` (`dv_db_table`),
  KEY `company_id` (`company_id`),
  KEY `sql_id` (`sql_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=200000 ;

--
-- Dumping data for table `cldl_dv`
--

INSERT INTO `cldl_dv` (`dv_id`, `company_id`, `active`, `dv_name`, `dv_db_table`, `sql_id`, `dv_type`, `dv_title`, `dt_add`, `dt_del`, `dt_edit`, `dv_name_add`, `dv_name_edit`, `dv_template`, `dv_js_functions`, `dv_data_attributes`, `dv_notes`) VALUES
(3, 1, 1, 'menu_list', 'cldl_menu', NULL, 0, 'Menu List',                    1, 0, 2, NULL, '', 'dv_form', NULL, '\nbuttonAlign: ''left'',\ncache: true, \ncardView: false,\ncontentType: ''json'',\niconPrefix: ''fa'',\nicons:{  \n  refresh: ''glyphicon-refresh icon-refresh'',\n  toggle: ''glyphicon-list-alt icon-list-alt'',\n  columns: ''glyphicon-th icon-th''\n},\nmaintainSelected: true,\nmethod: ''get'',\ncountColumns: 1,\npagination: true,\npageList: [ 50, 100, 250, 500],\npageSize: 50,\nshowHeader: true,\nshowColumns: false,\nshowRefresh: false,\nshowToggle: false,\nsidePagination: ''client'',\nsingleSelect: false,\nsmartDisplay: true,\nstriped: true,\nsearch: true', NULL),
(4, 1, 1, 'menu_edit', 'cldl_menu', NULL, 0, 'Menu Insert/Update',           1, 1, 2, NULL, '', '',        NULL, '\n                 buttonAlign: ''left'',\n                 cache: true, \n                 cardView: false,\n                 contentType: ''json'',\n                 iconPrefix: ''fa'',\n                 icons:{\n                   refresh: ''glyphicon-refresh icon-refresh'',\n                   toggle: ''glyphicon-list-alt icon-list-alt'',\n                   columns: ''glyphicon-th icon-th''\n                 },\n                 maintainSelected: true,\n                 method: ''get'',\n                 countColumns: 1,\n                 pagination: true,\n                 pageList: [ 50, 100, 250, 500],\n                 pageSize: 50,\n                 showHeader: true,\n                 showColumns: false,\n                 showRefresh: false,\n                 showToggle: false,\n                 sidePagination: ''client'',\n                 singleSelect: false,\n                 smartDisplay: true,\n                 striped: true,\n                 search: true', NULL),
(1, 1, 1, 'dv_list', 'cldl_dv',     NULL, 0, 'DataView List',                0, 0, 2, NULL, '', 'dv_form', NULL, '\nbuttonAlign: ''left'',\ncache: true, \ncardView: false,\ncontentType: ''json'',\niconPrefix: ''fa'',\nicons:{  \n  refresh: ''glyphicon-refresh icon-refresh'',\n  toggle: ''glyphicon-list-alt icon-list-alt'',\n  columns: ''glyphicon-th icon-th''\n},\nmaintainSelected: true,\nmethod: ''get'',\ncountColumns: 1,\npagination: true,\npageList: [ 50, 100, 250, 500],\npageSize: 50,\nshowHeader: true,\nshowColumns: false,\nshowRefresh: false,\nshowToggle: false,\nsidePagination: ''client'',\nsingleSelect: false,\nsmartDisplay: true,\nstriped: true,\nsearch: true', 'This is a basic DataView of the cldl_dv table.'),
(2, 1, 1, 'dv_edit', 'cldl_dv',     NULL, 0, 'DataView Insert/Update',       0, 0, 0, NULL, '', 'dv_form', NULL, '\nbuttonAlign: ''left'',\ncache: true, \ncardView: false,\ncontentType: ''json'',\niconPrefix: ''fa'',\nicons:{  \n  refresh: ''glyphicon-refresh icon-refresh'',\n  toggle: ''glyphicon-list-alt icon-list-alt'',\n  columns: ''glyphicon-th icon-th''\n},\nmaintainSelected: true,\nmethod: ''get'',\ncountColumns: 1,\npagination: true,\npageList: [ 50, 100, 250, 500],\npageSize: 50,\nshowHeader: true,\nshowColumns: false,\nshowRefresh: false,\nshowToggle: false,\nsidePagination: ''client'',\nsingleSelect: false,\nsmartDisplay: true,\nstriped: true,\nsearch: true', NULL),
(5, 1, 1, 'dvf_list', 'cldl_dvf',   NULL, 0, 'DataView Field List',          0, 0, 0, NULL, '', '',        NULL, '\n                 buttonAlign: ''left'',\n                 cache: true, \n                 cardView: false,\n                 contentType: ''json'',\n                 iconPrefix: ''fa'',\n                 icons:{\n                   refresh: ''glyphicon-refresh icon-refresh'',\n                   toggle: ''glyphicon-list-alt icon-list-alt'',\n                   columns: ''glyphicon-th icon-th''\n                 },\n                 maintainSelected: true,\n                 method: ''get'',\n                 countColumns: 1,\n                 pagination: true,\n                 pageList: [ 50, 100, 250, 500],\n                 pageSize: 50,\n                 showHeader: true,\n                 showColumns: false,\n                 showRefresh: false,\n                 showToggle: false,\n                 sidePagination: ''client'',\n                 singleSelect: false,\n                 smartDisplay: true,\n                 striped: true,\n                 search: true', NULL),
(6, 1, 1, 'dvf_edit', 'cldl_dvf',   NULL, 0, 'Dataview Field Insert/Update', 0, 0, 0, NULL, '', '',        NULL, '\n                 buttonAlign: ''left'',\n                 cache: true, \n                 cardView: false,\n                 contentType: ''json'',\n                 iconPrefix: ''fa'',\n                 icons:{\n                   refresh: ''glyphicon-refresh icon-refresh'',\n                   toggle: ''glyphicon-list-alt icon-list-alt'',\n                   columns: ''glyphicon-th icon-th''\n                 },\n                 maintainSelected: true,\n                 method: ''get'',\n                 countColumns: 1,\n                 pagination: true,\n                 pageList: [ 50, 100, 250, 500],\n                 pageSize: 50,\n                 showHeader: true,\n                 showColumns: false,\n                 showRefresh: false,\n                 showToggle: false,\n                 sidePagination: ''client'',\n                 singleSelect: false,\n                 smartDisplay: true,\n                 striped: true,\n                 search: true', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `cldl_dvf`
--

DROP TABLE IF EXISTS `cldl_dvf`;
CREATE TABLE IF NOT EXISTS `cldl_dvf` (
  `dvf_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `dv_id` int(11) NOT NULL,
  `active` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `ordr` int(3) unsigned NOT NULL,
  `dvf_db_column` varchar(30) NOT NULL,
  `dvf_name` varchar(30) NOT NULL,
  `dvf_label` varchar(30) DEFAULT NULL,
  `dvf_type` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT '0=text, 1=textarea, 2=date, 3=hidden, 4=checkbox, 5=radio, 6=select,  7=password, 8=span, 9=paragraph',
  `dvf_placeholder` tinytext,
  `dvf_help` tinytext,
  `dvf_key` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `dvf_sortable` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `dvf_sort_ordr` tinyint(3) unsigned DEFAULT NULL,
  `dvf_sort_asc_desc` tinyint(1) unsigned NOT NULL DEFAULT '1' COMMENT '1 = Ascending, 2 = Descending',
  `d_id` int(11) unsigned DEFAULT NULL,
  `dvf_js_functions` text,
  `dvf_data_attributes` text,
  `dvf_notes` tinytext,
  PRIMARY KEY (`dvf_id`),
  KEY `dv_id` (`dv_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=200000 ;

--
-- Dumping data for table `cldl_dvf`
--

INSERT INTO `cldl_dvf` (`dvf_id`, `dv_id`, `active`, `ordr`, `dvf_db_column`, `dvf_name`, `dvf_label`, `dvf_type`, `dvf_placeholder`, `dvf_help`, `dvf_key`, `dvf_sortable`, `dvf_sort_ordr`, `dvf_sort_asc_desc`, `d_id`, `dvf_js_functions`, `dvf_data_attributes`, `dvf_notes`) VALUES
(1, 1, 1, 0, 'dv_id', 'dv_id', 'ID', 0, NULL, NULL, 1, 1, NULL, 1, NULL, NULL, 'READONLY', NULL),
(2, 1, 1, 1, 'company_id', 'company_id', 'Company ID', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(3, 1, 1, 2, 'dv_name', 'dv_name', 'Name', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(4, 1, 1, 3, 'active', 'active', 'Status', 4, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, 'formatter: adtiveLookup', NULL),
(5, 1, 1, 4, 'dv_db_table', 'dv_db_table', 'Table', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(6, 1, 1, 5, 'dv_type', 'dv_type', 'Type', 5, NULL, NULL, 0, 1, NULL, 1, 100004, NULL, 'formatter:dvtypeLookup', NULL),
(7, 1, 1, 6, 'dv_title', 'dv_title', 'Title', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(8, 1, 1, 9, 'dt_del', 'dt_del', 'Delete Button', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(9, 1, 1, 10, 'dt_edit', 'dt_edit', 'Click', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(10, 1, 1, 11, 'dv_js_functions', 'dv_js_functions', 'JS', 1, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(11, 2, 1, 1, 'dv_id', 'dv_id', 'ID', 0, NULL, NULL, 1, 1, 1, 1, NULL, NULL, NULL, NULL),
(12, 2, 1, 2, 'company_id', 'company_id', 'Company ID', 0, NULL, NULL, 0, 2, 2, 1, NULL, NULL, NULL, NULL),
(13, 2, 1, 3, 'active', 'active', 'Active', 4, NULL, NULL, 0, 2, 2, 1, NULL, NULL, NULL, NULL),
(14, 2, 1, 4, 'dv_name', 'dv_name', 'Name', 0, NULL, NULL, 0, 2, 2, 1, NULL, NULL, NULL, NULL),
(15, 2, 1, 5, 'dv_db_table', 'dv_db_table', 'Table', 0, NULL, NULL, 0, 2, 2, 1, NULL, NULL, NULL, NULL),
(16, 2, 1, 6, 'dv_type', 'dv_type', 'Type', 0, NULL, NULL, 0, 2, 2, 1, NULL, NULL, NULL, NULL),
(17, 2, 1, 7, 'dv_title', 'dv_title', 'Title', 0, NULL, NULL, 0, 2, 2, 1, NULL, NULL, NULL, NULL),
(18, 2, 1, 8, 'dt_del_button', 'dt_del_button', 'Delete', 0, NULL, NULL, 0, 2, 2, 1, NULL, NULL, NULL, NULL),
(19, 2, 1, 9, 'dt_edit_click', 'dt_edit_click', 'Edit Click', 0, NULL, NULL, 0, 2, 2, 1, NULL, NULL, NULL, NULL),
(20, 2, 1, 10, 'dv_form_path', 'dv_form_path', 'Form Path', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(21, 2, 1, 11, 'dv_form_id', 'dv_form_id', 'Form', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(22, 100003, 1, 4, 'ordr', 'ordr', 'Order', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(23, 100003, 1, 2, 'company_id', 'company_id', 'company_id', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(24, 100003, 1, 9, 'dv_notes', 'dv_notes', 'dv_notes', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(25, 100003, 1, 8, 'dv_data_attributes', 'dv_data_attributes', 'dv_data_attributes', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(26, 100003, 1, 7, 'dv_js_functions', 'dv_js_functions', 'dv_js_functions', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(27, 100003, 1, 1, 'menu_id', 'menu_id', 'ID', 0, NULL, NULL, 1, 1, NULL, 1, NULL, NULL, NULL, NULL),
(28, 100003, 1, 6, 'link', 'link', 'Link', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(29, 100003, 1, 3, 'pmenu_id', 'pmenu_id', 'Parent Menu ID', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(30, 100000, 1, 7, 'dt_add', 'dt_add', 'Add', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(31, 100003, 1, 6, 'menu_text', 'menu_text', 'Menu Text', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(32, 100005, 1, 7, 'link', 'link', 'link', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(33, 100005, 1, 5, 'ordr', 'ordr', 'ordr', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(34, 100005, 1, 2, 'company_id', 'company_id', 'company_id', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101070, 100005, 1, 10, 'dv_notes', 'dv_notes', 'dv_notes', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101071, 100005, 1, 3, 'active', 'active', 'active', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101072, 100005, 1, 9, 'dv_data_attributes', 'dv_data_attributes', 'dv_data_attributes', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101073, 100005, 1, 6, 'menu_text', 'menu_text', 'menu_text', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101074, 100005, 1, 8, 'dv_js_functions', 'dv_js_functions', 'dv_js_functions', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101075, 100005, 1, 1, 'menu_id', 'menu_id', 'menu_id', 0, NULL, NULL, 1, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101076, 100005, 1, 4, 'pmenu_id', 'pmenu_id', 'pmenu_id', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101077, 100006, 1, 13, 'dv_template', 'dv_template', 'dv_template', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101078, 100006, 1, 15, 'dv_data_attributes', 'dv_data_attributes', 'dv_data_attributes', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101079, 100006, 1, 9, 'dt_del', 'dt_del', 'dt_del', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101080, 100006, 1, 14, 'dv_js_functions', 'dv_js_functions', 'dv_js_functions', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101081, 100006, 1, 4, 'dv_name', 'dv_name', 'dv_name', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101082, 100006, 1, 6, 'dv_type', 'dv_type', 'dv_type', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101083, 100006, 1, 12, 'dv_name_edit', 'dv_name_edit', 'dv_name_edit', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101084, 100006, 1, 1, 'dv_id', 'dv_id', 'dv_id', 0, NULL, NULL, 1, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101085, 100006, 1, 2, 'company_id', 'company_id', 'company_id', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101086, 100006, 1, 10, 'dt_edit', 'dt_edit', 'dt_edit', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101087, 100006, 1, 11, 'dv_name_add', 'dv_name_add', 'dv_name_add', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101088, 100006, 1, 16, 'dv_notes', 'dv_notes', 'dv_notes', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101089, 100006, 1, 3, 'active', 'active', 'active', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101090, 100006, 1, 8, 'dt_add', 'dt_add', 'dt_add', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101091, 100006, 1, 7, 'dv_title', 'dv_title', 'dv_title', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101092, 100006, 1, 5, 'dv_db_table', 'dv_db_table', 'dv_db_table', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101093, 100007, 1, 13, 'dvf_sort_ordr', 'dvf_sort_ordr', 'dvf_sort_ordr', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101094, 100007, 1, 9, 'dvf_placeholder', 'dvf_placeholder', 'dvf_placeholder', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101095, 100007, 1, 6, 'dvf_name', 'dvf_name', 'dvf_name', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101096, 100007, 1, 5, 'dvf_db_column', 'dvf_db_column', 'dvf_db_column', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101097, 100007, 1, 4, 'ordr', 'ordr', 'ordr', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101098, 100007, 1, 1, 'dvf_id', 'dvf_id', 'dvf_id', 0, NULL, NULL, 1, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101099, 100007, 1, 14, 'dvf_sort_asc_desc', 'dvf_sort_asc_desc', 'dvf_sort_asc_desc', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101100, 100007, 1, 11, 'dvf_key', 'dvf_key', 'dvf_key', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101101, 100007, 1, 3, 'active', 'active', 'active', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101102, 100007, 1, 16, 'dvf_js_functions', 'dvf_js_functions', 'dvf_js_functions', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101103, 100007, 1, 17, 'dvf_data_attributes', 'dvf_data_attributes', 'dvf_data_attributes', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101104, 100007, 1, 10, 'dvf_help', 'dvf_help', 'dvf_help', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101105, 100007, 1, 12, 'dvf_sortable', 'dvf_sortable', 'dvf_sortable', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101106, 100007, 1, 2, 'dv_id', 'dv_id', 'dv_id', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101107, 100007, 1, 7, 'dvf_label', 'dvf_label', 'dvf_label', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101108, 100007, 1, 8, 'dvf_type', 'dvf_type', 'dvf_type', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101109, 100007, 1, 15, 'd_id', 'd_id', 'd_id', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL),
(101110, 100007, 1, 18, 'dvf_notes', 'dvf_notes', 'dvf_notes', 0, NULL, NULL, 0, 1, NULL, 1, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `cldl_menu`
--

DROP TABLE IF EXISTS `cldl_menu`;
CREATE TABLE IF NOT EXISTS `cldl_menu` (
  `menu_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `company_id` int(11) unsigned NOT NULL,
  `active` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `pmenu_id` int(11) unsigned DEFAULT NULL,
  `ordr` smallint(3) unsigned NOT NULL DEFAULT '0',
  `menu_label` varchar(50) NOT NULL,
  `menu_link` varchar(250) NOT NULL,
  `menu_js_functions` text NOT NULL,
  `menu_data_attributes` text NOT NULL,
  `menu_notes` tinytext NOT NULL,
  PRIMARY KEY (`menu_id`),
  KEY `pmenu_id` (`pmenu_id`),
  KEY `company_id` (`company_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=200000 ;

--
-- Dumping data for table `cldl_menu`
--

INSERT INTO `cldl_menu` (`menu_id`, `company_id`, `active`, `pmenu_id`, `ordr`, `menu_label`, `menu_link`, `menu_js_functions`, `menu_data_attributes`, `menu_notes`) VALUES
(1, 1, 1, NULL, 0,  'CLDL', '', '', '', ''),
(2, 1, 1, 1, 0,  'Menus', 'admin/menu/display', '', '', ''),
(3, 1, 1, 1, 0,  'DataViews', 'admin/dv/display', '', '', ''),
(4, 1, 1, 1, 0,  'Roles', 'admin/roles/display', '', '', ''),
(5, 1, 1, 1, 1,  'Permissions', 'admin/permissions/display', '', '', ''),
(6, 1, 1, 1, 2,  'Users', 'dv/display/users', '', '', ''),
(7, 1, 1, 1, 3,  'Company', 'dv/display/company', '', '', '');

-- --------------------------------------------------------

--
-- Table structure for table `cldl_role`
--

DROP TABLE IF EXISTS `cldl_role`;
CREATE TABLE IF NOT EXISTS `cldl_role` (
  `role_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `company_id` int(11) unsigned NOT NULL,
  `active` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `role_name` varchar(32) NOT NULL,
  PRIMARY KEY (`role_id`),
  KEY `company_id` (`company_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=200000 ;

--
-- Dumping data for table `cldl_role`
--

INSERT INTO `cldl_role` (`role_id`, `company_id`, `active`, `role_name`) VALUES
(1, 1, 1, 'View Only'),
(2, 1, 1, 'Demo'),
(3, 1, 1, 'Regular'),
(4, 1, 1, 'Company Administrator'),
(5, 1, 1, 'Super-User');

-- --------------------------------------------------------

--
-- Table structure for table `cldl_role_members`
--

DROP TABLE IF EXISTS `cldl_role_members`;
CREATE TABLE IF NOT EXISTS `cldl_role_members` (
  `role_id` int(11) unsigned NOT NULL,
  `user_id` int(11) unsigned NOT NULL,
  KEY `role_id` (`role_id`,`user_id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `cldl_role_members`
--

INSERT INTO `cldl_role_members` (`role_id`, `user_id`) VALUES
(5, 1);

-- --------------------------------------------------------

--
-- Table structure for table `cldl_role_permission_dv`
--

DROP TABLE IF EXISTS `cldl_role_permission_dv`;
CREATE TABLE IF NOT EXISTS `cldl_role_permission_dv` (
  `role_permission_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `role_id` int(11) unsigned NOT NULL,
  `dv_id` int(11) unsigned NOT NULL,
  `dt_add` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT 'Should default to value in cldl_dv',
  `dt_del` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT 'Should default to value in cldl_dv',
  `dt_edit` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT 'Should default to value in cldl_dv',
  PRIMARY KEY (`role_permission_id`),
  KEY `role_id` (`role_id`),
  KEY `dv_id` (`dv_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=200000 ;

-- --------------------------------------------------------
INSERT INTO `cldl_role_permission_dv` (`role_permission_id`, `role_id`, `dv_id`, `dt_add`, `dt_del`, `dt_edit`) VALUES
(1, 5, 1, 1, 1, 1);

--
-- Table structure for table `cldl_role_permission_menu`
--

DROP TABLE IF EXISTS `cldl_role_permission_menu`;
CREATE TABLE IF NOT EXISTS `cldl_role_permission_menu` (
  `role_permission_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `role_id` int(11) unsigned NOT NULL,
  `menu_id` int(11) unsigned NOT NULL,
  PRIMARY KEY (`role_permission_id`),
  KEY `role_id` (`role_id`),
  KEY `menu_id` (`menu_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=200000 ;

--
-- Dumping data for table `cldl_role_permission_menu`
--

INSERT INTO `cldl_role_permission_menu` (`role_permission_id`, `role_id`, `menu_id`) VALUES
(1, 5, 1),
(2, 5, 2),
(3, 5, 3),
(4, 5, 4),
(5, 5, 5),
(6, 5, 6),
(7, 5, 7);

-- --------------------------------------------------------

--
-- Table structure for table `cldl_sql`
--

DROP TABLE IF EXISTS `cldl_sql`;
CREATE TABLE IF NOT EXISTS `cldl_sql` (
  `sql_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `company_id` int(11) unsigned NOT NULL,
  `active` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `sql_stmt` text NOT NULL,
  PRIMARY KEY (`sql_id`),
  KEY `company_id` (`company_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=200000 ;

-- --------------------------------------------------------

--
-- Table structure for table `cldl_user`
--

DROP TABLE IF EXISTS `cldl_user`;
CREATE TABLE IF NOT EXISTS `cldl_user` (
  `user_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `company_id` int(11) unsigned NOT NULL,
  `active` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `language` smallint(1) unsigned NOT NULL DEFAULT '0' COMMENT '0 = English, 1 = Spanish',
  `user_name` varchar(32) NOT NULL,
  `user_pass` varchar(32) NOT NULL,
  `first_name` varchar(30) NOT NULL,
  `last_name` varchar(30) NOT NULL,
  `user_email` varchar(50) DEFAULT NULL,
  `approved` smallint(1) NOT NULL DEFAULT '0',
  `pass_change` smallint(1) unsigned NOT NULL DEFAULT '0' COMMENT 'Force password change. 0 = No, 1 = Yes',
  PRIMARY KEY (`user_id`),
  KEY `company_id` (`company_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=200000 ;

--
-- Dumping data for table `cldl_user`
--

INSERT INTO `cldl_user` (`user_id`, `company_id`, `active`, `updated`, `created`, `language`, `user_name`, `user_pass`, `first_name`, `last_name`, `user_email`, `approved`, `pass_change`) VALUES
(1, 1, 1, '2015-01-01 00:00:00', '2015-01-01 00:00:00', 0, 'jbilemjian_jffc', '1664e05e26181f5e139b85d03a1b7f8f', 'Jack', 'Bilemjian', 'jck000@gmail.com', 0, 0);

--
-- Triggers `cldl_user`
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
-- Constraints for table `cldl_dv`
--
ALTER TABLE `cldl_dv`
  ADD CONSTRAINT `cldl_dv_ibfk_1` FOREIGN KEY (`company_id`) REFERENCES `cldl_company` (`company_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `cldl_dv_ibfk_2` FOREIGN KEY (`sql_id`) REFERENCES `cldl_sql` (`sql_id`);

--
-- Constraints for table `cldl_menu`
--
ALTER TABLE `cldl_menu`
  ADD CONSTRAINT `cldl_menu_ibfk_1` FOREIGN KEY (`pmenu_id`) REFERENCES `cldl_menu` (`menu_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `cldl_menu_ibfk_2` FOREIGN KEY (`company_id`) REFERENCES `cldl_company` (`company_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `cldl_role_members`
--
ALTER TABLE `cldl_role_members`
  ADD CONSTRAINT `cldl_role_members_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `cldl_role` (`role_id`),
  ADD CONSTRAINT `cldl_role_members_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `cldl_user` (`user_id`);

--
-- Constraints for table `cldl_role_permission_dv`
--
ALTER TABLE `cldl_role_permission_dv`
  ADD CONSTRAINT `cldl_role_permission_dv_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `cldl_role` (`role_id`),
  ADD CONSTRAINT `cldl_role_permission_dv_ibfk_2` FOREIGN KEY (`dv_id`) REFERENCES `cldl_dv` (`dv_id`);

--
-- Constraints for table `cldl_role_permission_menu`
--
ALTER TABLE `cldl_role_permission_menu`
  ADD CONSTRAINT `cldl_role_permission_menu_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `cldl_role` (`role_id`),
  ADD CONSTRAINT `cldl_role_permission_menu_ibfk_2` FOREIGN KEY (`menu_id`) REFERENCES `cldl_menu` (`menu_id`);

--
-- Constraints for table `cldl_sql`
--
ALTER TABLE `cldl_sql`
  ADD CONSTRAINT `cldl_sql_ibfk_1` FOREIGN KEY (`company_id`) REFERENCES `cldl_company` (`company_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `cldl_user`
--
ALTER TABLE `cldl_user`
  ADD CONSTRAINT `cldl_user_ibfk_1` FOREIGN KEY (`company_id`) REFERENCES `cldl_company` (`company_id`) ON DELETE CASCADE ON UPDATE CASCADE;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

