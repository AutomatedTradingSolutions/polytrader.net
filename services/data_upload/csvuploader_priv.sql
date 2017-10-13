DELIMITER ;

SHOW WARNINGS;

REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'csvuploader'@'localhost';

-- metadata privileges
GRANT EXECUTE ON PROCEDURE REFDATA.GetInstrument TO 'csvuploader'@'localhost';
GRANT EXECUTE ON PROCEDURE REFDATA.GetFrequency TO 'csvuploader'@'localhost';
GRANT SELECT ON TABLE REFDATA.frequency TO 'csvuploader'@'localhost';
GRANT SELECT ON TABLE REFDATA.asset_class TO 'csvuploader'@'localhost';
GRANT SELECT ON TABLE REFDATA.instrument TO 'csvuploader'@'localhost';

-- price data privileges

DROP PROCEDURE IF EXISTS _HELPER._Grant;

DELIMITER //

CREATE PROCEDURE _HELPER._Grant()
BEGIN
  DECLARE _schemaName VARCHAR(64);
  DECLARE _foundFlag BOOL DEFAULT TRUE;
  DECLARE _getSchemas CURSOR FOR SELECT schema_name FROM REFDATA.instrument;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _foundFlag = FALSE;

  OPEN _getSchemas;

  REPEAT FETCH _getSchemas INTO _schemaName;

  IF _foundFlag THEN
    SET @_sql = CONCAT('GRANT SELECT, INSERT ON TABLE ', _schemaName, '.csv_upload TO \'csvuploader\'@\'localhost\'');
    PREPARE _grant FROM @_sql;
    EXECUTE _grant;
    DEALLOCATE PREPARE _grant;
    SET @_sql = CONCAT('GRANT EXECUTE ON PROCEDURE ', _schemaName, '.AddCSVUpload TO \'csvuploader\'@\'localhost\'');
    PREPARE _grant FROM @_sql;
    EXECUTE _grant;
    DEALLOCATE PREPARE _grant;
  END IF;

  UNTIL NOT _foundFlag END REPEAT;

  CLOSE _getSchemas;

END//

DELIMITER ;

CALL _HELPER._Grant();

DROP PROCEDURE IF EXISTS _HELPER._Grant;
