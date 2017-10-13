DELIMITER ;

SHOW WARNINGS;

DROP TABLE IF EXISTS csv_upload;

CREATE TABLE csv_upload (
  id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT COMMENT 'CSVUPID',
  filename VARCHAR(256) NOT NULL COMMENT 'CSVUPFILE',
  frequency_id INT UNSIGNED NOT NULL COMMENT 'CSVUPFREQ',
  asset_class_id INT UNSIGNED NOT NULL COMMENT 'CSVUPASSCLS',
  instrument_id INT UNSIGNED NOT NULL COMMENT 'CSVUPINSTR',
  upload_timestamp DATE NOT NULL COMMENT 'CSVUPTIME',
  period_start DATE COMMENT 'CSVUPSTART',
  period_end DATE COMMENT 'CSVUPEND',
  uploader_id INT UNSIGNED NOT NULL COMMENT 'CSVUPLOADID',
  FOREIGN KEY (frequency_id) REFERENCES REFDATA.frequency(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  FOREIGN KEY (asset_class_id) REFERENCES REFDATA.asset_class(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  FOREIGN KEY (instrument_id) REFERENCES REFDATA.instrument(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  FOREIGN KEY (uploader_id) REFERENCES USERAUTH.sys_user(id) ON UPDATE RESTRICT ON DELETE RESTRICT
);

DELIMITER //

DROP TRIGGER IF EXISTS before_csv_upload_insert//

CREATE TRIGGER before_csv_upload_insert
  BEFORE INSERT ON csv_upload
  FOR EACH ROW
  BEGIN
    SET NEW.upload_timestamp = NOW();
  END//

DROP PROCEDURE IF EXISTS GetCSVUpload//

CREATE PROCEDURE GetCSVUpload(_filter JSON)
BEGIN
  DECLARE _whereClause VARCHAR(1024) DEFAULT NULL;
  DECLARE _schemaName VARCHAR(64) DEFAULT SCHEMA();
  CALL _HELPER.GetWhereClause(REFDATA.GetDataSchemaId(_schemaName), 'csv_upload', _filter, _whereClause);
  SET @_sql = CONCAT('SELECT id, filename, frequency_id, asset_class_id, instrument_id upload_timestamp, period_start, period_end FROM csv_upload ', _whereClause);
  PREPARE _select FROM @_sql;
  EXECUTE _select;
  DEALLOCATE PREPARE _select;
END//

DROP PROCEDURE IF EXISTS AddCSVUpload//

CREATE PROCEDURE AddCSVUpload(_jsonDoc JSON)
BEGIN
  -- INSERT INTO csv_upload (filename, frequency_id, asset_class_id, instrument_id, upload_timestamp, period_start, period_end, uploader_id)
  --  VALUES (_filename, _frequencyId, _assetClassId, _instrumentId, _timeStamp, _periodStart, _periodEnd, _uploaderId);

  DECLARE _insertClause VARCHAR(1024) DEFAULT NULL;
  DECLARE _schemaName VARCHAR(64) DEFAULT SCHEMA();
  CALL _HELPER.GetInsertClause(REFDATA.GetDataSchemaId(_schemaName), 'csv_upload', _jsonDoc, _insertClause);
  SET @_sql = _insertClause;
  PREPARE _insert FROM @_sql;
  EXECUTE _insert;
  DEALLOCATE PREPARE _insert;
  -- SELECT id, upload_timestamp FROM csv_upload WHERE id = LAST_INSERT_ID() AND uploader_id = CAST(JSON_EXTRACT(_jsonDoc, '$.uploader_id') AS INT) AND upload_timestamp >= _timeStamp;
  SELECT id, upload_timestamp FROM csv_upload WHERE id = LAST_INSERT_ID();
END//

DELIMITER ;

SET @_tablename = 'csv_upload';

CALL REFDATA.DeleteDynamicSQL(SCHEMA(), @_tablename);

CALL REFDATA.AddDynamicSQL(SCHEMA(), 'CSVUPID', @_tablename, 'id');
CALL REFDATA.AddDynamicSQL(SCHEMA(), 'CSVUPFILE', @_tablename, 'filename');
CALL REFDATA.AddDynamicSQL(SCHEMA(), 'CSVUPFREQ', @_tablename, 'frequency_id');
CALL REFDATA.AddDynamicSQL(SCHEMA(), 'CSVUPASSCLS', @_tablename, 'asset_class_id');
CALL REFDATA.AddDynamicSQL(SCHEMA(), 'CSVUPINSTR', @_tablename, 'instrument_id');
CALL REFDATA.AddDynamicSQL(SCHEMA(), 'CSVUPTIME', @_tablename, 'upload_timestamp');
CALL REFDATA.AddDynamicSQL(SCHEMA(), 'CSVUPSTART', @_tablename, 'period_start');
CALL REFDATA.AddDynamicSQL(SCHEMA(), 'CSVUPEND', @_tablename, 'period_end');
CALL REFDATA.AddDynamicSQL(SCHEMA(), 'CSVUPLOADID', @_tablename, 'uploader_id');
