USE ROLE ACCOUNTADMIN;
-- DEV Database Creation
create database if not exists ECOM_DWH_DEV;
USE database ECOM_DWH_DEV;

USE ROLE SYSADMIN;
-- Create Schema for files landing
create schema if not exists LANDING;

-- Create Schema for pipeline metadata
create schema if not exists CONTROL;

-- Create Schema for Bronze Layer
create schema if not exists raw_data;

-- Create Schema for Silver Layer
create schema if not exists transformed_data;

-- Create Schema for ERROR Records
create schema if not exists error;