-- script to populate dynamic_sql table

DELIMITER //

DROP PROCEDURE IF EXISTS _HELPER._PopulateDynamicSQL//

CREATE PROCEDURE _HELPER._PopulateDynamicSQL()
BEGIN
  DECLARE _comment VARCHAR(1024);
  DECLARE _tablename VARCHAR(64);
  DECLARE _colname VARCHAR(64);
  DECLARE _foundFlag DEFAULT TRUE;
  DECLARE _getCols CURSOR FOR \
    SELECT col.column_comment, tab.table_name, col.column_name \
    FROM information_schema.columns col JOIN information_schema.tables tab ON tab.table_name = col.table_name \
    WHERE tab.table_schema = SCHEMA() AND NOT ISNULL(col.column_comment);
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET _foundFlag = FALSE;
  OPEN _getCols;
  fetch_: LOOP
    FETCH _getCols INTO _comment, _tablename, _colname;
    IF NOT _foundFlag THEN
      LEAVE fetch_;
    END IF;
    IF CHAR_LENGTH(_comment) > 16 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error comment length', MYSQL_ERRNO = ER_SIGNAL_EXCEPTION;
    END IF;
    CALL AddDynamicSQL(_comment, _tablename, _colname);
  END LOOP;
  CLOSE _getCols;
END//

DELIMITER ;

CALL _HELPER._PopulateDynamicSQL();

DROP PROCEDURE IF EXISTS _HELPER._PopulateDynamicSQL;
