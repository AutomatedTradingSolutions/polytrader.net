DELIMITER //

SHOW WARNINGS//

DROP PROCEDURE IF EXISTS _CreateTable//

CREATE PROCEDURE _CreateTable(_targetSchema VARCHAR(64), _tableName VARCHAR(64), _likeTable VARCHAR(64))
BEGIN
  SET @_sql = CONCAT('CREATE TABLE ', _targetSchema, '.', _tableName, ' LIKE ', _likeTable);
  PREPARE _createTable FROM @_sql;
  EXECUTE _createTable;
  DEALLOCATE PREPARE _createTable;
END
//

DROP PROCEDURE IF EXISTS _SetupTables//

CREATE PROCEDURE _SetupTables(_instrumentId INT UNSIGNED, _schemaName VARCHAR(64))
BEGIN
  DECLARE _freqCode VARCHAR(8);
  DECLARE _refTablename VARCHAR(64);
  DECLARE _foundFlag BOOL DEFAULT TRUE;
  DECLARE _getFrequencies CURSOR FOR \
    SELECT freq.code, ifreq.ref_tablename \
    FROM REFDATA.instrument_frequency ifreq JOIN REFDATA.frequency freq ON freq.id = ifreq.frequency_id \
    WHERE ifreq.instrument_id = _instrumentId;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _foundFlag = FALSE;

  OPEN _getFrequencies;

  REPEAT FETCH _getFrequencies INTO _freqCode, _refTablename;

  IF _foundFlag THEN
    CALL _HELPER._CreateTable(_schemaName, CONCAT(_freqCode, '_', _schemaName), _refTablename);
  END IF;

  UNTIL NOT _foundFlag END REPEAT;

  CLOSE _getFrequencies;

END//

DELIMITER ;
