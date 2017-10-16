DELIMITER ;

SHOW WARNINGS;

SET @_json_type_char_len = 64;

DELIMITER //

DROP PROCEDURE IF EXISTS ParseJSONObjectUpdateIteration//

CREATE PROCEDURE ParseJSONObjectUpdateIteration(_doc JSON, _parent JSON, _key JSON, _uncodedKey VARCHAR(512), _obj JSON, _iter INT UNSIGNED, OUT _res VARCHAR(1024))
BEGIN
  SELECT CONCAT(IF(_iter > 0, ',', ''), _uncodedKey, GetComparisonOperator(_obj)) INTO _res;
END//

DROP PROCEDURE IF EXISTS GetUpdateClause//

CREATE PROCEDURE GetUpdateClause(_schemaId TINYINT UNSIGNED, _context VARCHAR(64), _doc JSON, INOUT _res VARCHAR(1024))
BEGIN
  DECLARE _root JSON DEFAULT NULL;
  DECLARE _parser JSON;
  DECLARE _maxrecur INT UNSIGNED DEFAULT 0;

  SELECT @@max_sp_recursion_depth INTO _maxrecur;
  SET @@max_sp_recursion_depth = 255;

  IF ISNULL(_res) THEN
    SELECT CONCAT('UPDATE ', _context, ' SET') INTO _res;
  END IF;

  -- customise behaviour
  SELECT JSON_OBJECT('ArrayIteration', 'CALL ParseJSONArrayAddDelim(?, ?, ?, ?, ?)') INTO _parser;
  SELECT JSON_INSERT(_parser, '$.ObjectIteration', 'CALL ParseJSONObjectUpdateIteration(?, ?, ?, ?, ?, ?, ?)') INTO _parser;
  SELECT JSON_INSERT(_parser, '$.ValueAction', 'CALL ParseJSONValueCastAction(?, ?, ?)') INTO _parser;

  CALL ParseJSONDocument(_schemaId, _context, _doc, _root, _parser, _res);

  SET @@max_sp_recursion_depth = _maxrecur;
END//

DROP PROCEDURE IF EXISTS UpdateTable//

CREATE PROCEDURE UpdateTable(_schemaId TINYINT UNSIGNED, _tablename VARCHAR(64), _update JSON, _where JSON)
BEGIN
  DECLARE _updateClause VARCHAR(1024) DEFAULT NULL;
  DECLARE _whereClause VARCHAR(1024) DEFAULT NULL;
  CALL GetUpdateClause(_schemaId, _tablename, _update, _updateClause);
  CALL GetwhereClause(_schemaId, _tablename, _where, _whereClause);
  SET @_sql = CONCAT(_updateClause, ' ', _whereClause);
  PREPARE _update FROM @_sql;
  -- SET @_tablename = _tablename;
  EXECUTE _update;
  DEALLOCATE PREPARE _update;
END//

DELIMITER ;
