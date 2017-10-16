DELIMITER ;

SHOW WARNINGS;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS data_format;

CREATE TABLE data_format (
  id TINYINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT COMMENT 'DATAFMTID',
  code VARCHAR(8) NOT NULL COMMENT 'DATAFMTCODE',
  name VARCHAR(32) COMMENT 'DATAFMTNAME',
  UNIQUE KEY (code)
);

INSERT INTO data_format (code, name) VALUES ('CSV', 'Comma Separated Values');
INSERT INTO data_format (code, name) VALUES ('CCSV', 'Compressed CSV');
INSERT INTO data_format (code, name) VALUES ('XML', 'eXtensible Markup Language');
INSERT INTO data_format (code, name) VALUES ('HTML', 'HyperText Markup Language');
INSERT INTO data_format (code, name) VALUES ('JSON', 'JavaScript Object Notation');

DROP TABLE IF EXISTS frequency;

CREATE TABLE frequency (
  id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT COMMENT 'FREQID',
  code VARCHAR(8) NOT NULL COMMENT 'FREQCODE',
  name VARCHAR(32) COMMENT 'FREQNAME',
  UNIQUE KEY (code)
);

INSERT INTO frequency (code, name) VALUES ('TICK', 'Ticks');
INSERT INTO frequency (code, name) VALUES ('1S', '1 Second');
INSERT INTO frequency (code, name) VALUES ('1M', '1 Min');
INSERT INTO frequency (code, name) VALUES ('30M', '30 Minutes');
INSERT INTO frequency (code, name) VALUES ('1H', '1 Hour');
INSERT INTO frequency (code, name) VALUES ('4H', '4 Hour');
INSERT INTO frequency (code, name) VALUES ('1D', '1 Day');
INSERT INTO frequency (code, name) VALUES ('1W', '1 Week');
INSERT INTO frequency (code, name) VALUES ('1MTH', '1 Month');

SET @_tablename = 'frequency';

CALL DeleteDynamicSQL(SCHEMA(), @_tablename);

CALL AddDynamicSQL(SCHEMA(), 'FREQID', @_tablename, 'id');
CALL AddDynamicSQL(SCHEMA(), 'FREQCODE', @_tablename, 'code');
CALL AddDynamicSQL(SCHEMA(), 'FREQNAME', @_tablename, 'name');

DROP PROCEDURE IF EXISTS GetFrequency;

DELIMITER //

CREATE PROCEDURE GetFrequency(_filter JSON)
BEGIN
  DECLARE _whereClause VARCHAR(1024) DEFAULT NULL;
  CALL _HELPER.GetWhereClause(GetDataSchemaId(SCHEMA()), 'frequency', _filter, _whereClause);
  SET @_sql = CONCAT('SELECT id, code, name FROM frequency ', _whereClause);
  PREPARE _select FROM @_sql;
  EXECUTE _select;
  DEALLOCATE PREPARE _select;
END//

/*
DROP PROCEDURE IF EXISTS GetFrequencies//

CREATE PROCEDURE GetFrequencies(_filter JSON)
BEGIN
  DECLARE _frequencies JSON DEFAULT '[]';
  DECLARE _id INT UNSIGNED;
  DECLARE _foundFlag BOOL DEFAULT TRUE;
  DECLARE _getFrequencies CURSOR FOR SELECT JSON_OBJECT('id', id), JSON_OBJECT('code', code), JSON_OBJECT('name', name) FROM frequency;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _foundFlag = FALSE;

  OPEN _getFrequencies;
  REPEAT FETCH _getFrequencies INTO _id;
  IF _foundFlag THEN
    SELECT JSON_ARRAY_APPEND(_frequencies, '$', _id) INTO _frequencies;
  END IF;
  UNTIL NOT _foundFlag END REPEAT;
  CLOSE _getFrequencies;
END//
*/

DELIMITER ;

DROP TABLE IF EXISTS asset_class;

CREATE TABLE asset_class (
  id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT COMMENT 'ASSCLSID',
  code VARCHAR(8) NOT NULL COMMENT 'ASSCLSCODE',
  name VARCHAR(32) COMMENT 'ASSCLSNAME',
  UNIQUE KEY (code)
);

INSERT INTO asset_class (code, name) VALUES ('SPTFX', 'Spot FX');
INSERT INTO asset_class (code, name) VALUES ('SPTCOMM', 'Spot Commodity');
INSERT INTO asset_class (code, name) VALUES ('RESPROP', 'Residential Property');

SET @_tablename = 'asset_class';

CALL DeleteDynamicSQL(SCHEMA(), @_tablename);

CALL AddDynamicSQL(SCHEMA(), 'ASSCLSID', @_tablename, 'id');
CALL AddDynamicSQL(SCHEMA(), 'ASSCLSCODE', @_tablename, 'code');
CALL AddDynamicSQL(SCHEMA(), 'ASSCLSNAME', @_tablename, 'name');

DROP PROCEDURE IF EXISTS GetAssetClass;

DELIMITER //

CREATE PROCEDURE GetAssetClass(_filter JSON)
BEGIN
  DECLARE _whereClause VARCHAR(1024) DEFAULT NULL;
  CALL _HELPER.GetWhereClause(GetDataSchemaId(SCHEMA()), 'asset_class', _filter, _whereClause);
  SET @_sql = CONCAT('SELECT id, code, name FROM asset_class ', _whereClause);
  PREPARE _select FROM @_sql;
  EXECUTE _select;
  DEALLOCATE PREPARE _select;
END//

DELIMITER ;

DROP TABLE IF EXISTS news_feed_type;

CREATE TABLE news_feed_type (
  id INT UNSIGNED NOT NULL PRIMARY KEY COMMENT 'NFTID',
  name VARCHAR(32) COMMENT 'NFTNAME',
  description VARCHAR(128) COMMENT 'NFTDESC'
);

DROP PROCEDURE IF EXISTS GetNewsFeedType;

DELIMITER //

CREATE PROCEDURE GetNewsFeedType(_filter JSON)
BEGIN
  DECLARE _whereClause VARCHAR(1024) DEFAULT NULL;
  CALL _HELPER.GetWhereClause(GetDataSchemaId(SCHEMA()), 'news_feed_type', _filter, _whereClause);
  SET @_sql = CONCAT('SELECT id, name, description FROM news_feed_type ', _whereClause);
  PREPARE _select FROM @_sql;
  EXECUTE _select;
  DEALLOCATE PREPARE _select;
END//

DELIMITER ;

DROP TABLE IF EXISTS news_feed_source;

CREATE TABLE news_feed_source (
  id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT COMMENT 'NFSID',
  source_name VARCHAR(32) NOT NULL COMMENT 'NFSSRCNAME',
  feed_type_id INT UNSIGNED NOT NULL COMMENT 'NFSFTID',
  link TEXT COMMENT 'NFSLINK',
  FOREIGN KEY (feed_type_id) REFERENCES news_feed_type(id)
);

DROP PROCEDURE IF EXISTS GetNewsFeedSource;

DELIMITER //

CREATE PROCEDURE GetNewsFeedSource(_filter JSON)
BEGIN
  DECLARE _whereClause VARCHAR(1024) DEFAULT NULL;
  CALL _HELPER.GetWhereClause(GetDataSchemaId(SCHEMA()), 'news_feed_source', _filter, _whereClause);
  SET @_sql = CONCAT('SELECT id, source_name, feed_type_id, link FROM news_feed_source ', _whereClause);
  PREPARE _select FROM @_sql;
  EXECUTE _select;
  DEALLOCATE PREPARE _select;
END//

DELIMITER ;

DROP TABLE IF EXISTS ohlc_flag_type;

CREATE TABLE ohlc_flag_type (
  id TINYINT UNSIGNED NOT NULL PRIMARY KEY,
  name VARCHAR(32)
);

INSERT INTO ohlc_flag_type (id, name) VALUES (0, 'Valid');
INSERT INTO ohlc_flag_type (id, name) VALUES (9, 'Invalid');
INSERT INTO ohlc_flag_type (id, name) VALUES (99, 'Outlier');

SET FOREIGN_KEY_CHECKS = 1;
