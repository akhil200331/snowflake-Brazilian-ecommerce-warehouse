use role ACCOUNTADMIN;
use warehouse ECOM_DEV;
use database ECOM_DWH_DEV;
use schema LANDING;

-- CSV file ingestion file format definition
create file format if not exists FF_OLIST_CSV
  TYPE=CSV
  FIELD_DELIMITER=','
  SKIP_HEADER=1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  NULL_IF = ('', 'NULL')
  EMPTY_FIELD_AS_NULL = TRUE
  TRIM_SPACE = FALSE
  ENCODING = 'UTF8'
  COMMENT = 'Olist CSVs: quoted fields, multi-line review comments';

-- stage creation for uploading the raw files
create stage if not exists STG_RAW_OLIST
  FILE_FORMAT=FF_OLIST_CSV
  DIRECTORY = (ENABLE = TRUE)
  COMMENT = 'Internal stage for original Olist files';