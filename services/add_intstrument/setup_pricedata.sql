DELIMITER //

DROP PROCEDURE IF EXISTS _HELPER._CreateDatabase//

CREATE PROCEDURE _HELPER._CreateDatabase(_targetSchema VARCHAR(64))
BEGIN
  -- DROP DATABASE IF EXISTS REFDATA;
  SET @_sql = CONCAT('CREATE DATABASE IF NOT EXISTS ', _targetSchema);
  PREPARE _create FROM @_sql;
  EXECUTE _create;
  DEALLOCATE PREPARE _create;
  CALL REFDATA.AddDataSchema(_targetSchema);
END//

DROP PROCEDURE IF EXISTS _HELPER._Setup//

CREATE PROCEDURE _HELPER._Setup()
BEGIN
  DECLARE _instrumentId INT UNSIGNED;
  DECLARE _schemaName VARCHAR(64);
  DECLARE _foundFlag BOOL DEFAULT TRUE;
  DECLARE _getInstruments CURSOR FOR SELECT id, schema_name FROM REFDATA.instrument;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _foundFlag = FALSE;

  OPEN _getInstruments;

  REPEAT FETCH _getInstruments INTO _instrumentId, _schemaName;

  IF _foundFlag THEN
    CALL _HELPER._CreateDatabase(_schemaName);
    -- now add tables
    CALL _HELPER._SetupTables(_instrumentId, _schemaName);
  END IF;

  UNTIL NOT _foundFlag END REPEAT;

  CLOSE _getInstruments;

END//

DELIMITER ;

CALL _HELPER._Setup();

DROP PROCEDURE IF EXISTS _HELPER._Setup;
DROP PROCEDURE IF EXISTS _HELPER._CreateDatabase;
