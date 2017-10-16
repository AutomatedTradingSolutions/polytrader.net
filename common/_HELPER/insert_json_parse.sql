DELIMITER ;

SHOW WARNINGS;

SET @_json_type_char_len = 64;

DELIMITER //

DROP PROCEDURE IF EXISTS ParseJSONObjectInsertValuesPreprocess//

CREATE PROCEDURE ParseJSONObjectInsertValuesPreprocess(_doc JSON, _key JSON, OUT _res VARCHAR(1024))
BEGIN
  SELECT ' VALUES ' INTO _res;
END//

DROP PROCEDURE IF EXISTS ParseJSONObjectInsertFieldIteration//

CREATE PROCEDURE ParseJSONObjectInsertFieldIteration(_doc JSON, _parent JSON, _key JSON, _uncodedKey VARCHAR(512), _obj JSON, _iter INT UNSIGNED, OUT _res VARCHAR(1024))
BEGIN
  SELECT CONCAT(IF(_iter > 0, ',', ''), _uncodedKey) INTO _res;
END//

DROP PROCEDURE IF EXISTS ParseJSONObjectInsertValueIteration//

CREATE PROCEDURE ParseJSONObjectInsertValueIteration(_doc JSON, _parent JSON, _key JSON, _uncodedKey VARCHAR(512), _obj JSON, _iter INT UNSIGNED, OUT _res VARCHAR(1024))
BEGIN
  SELECT IF(_iter > 0, ',', '') INTO _res;
END//

DROP PROCEDURE IF EXISTS GetInsertClause//

CREATE PROCEDURE GetInsertClause(_schemaId TINYINT UNSIGNED, _context VARCHAR(64), _doc JSON, INOUT _res VARCHAR(1024))
BEGIN
  DECLARE _root JSON DEFAULT NULL;
  DECLARE _parser JSON;
  DECLARE _maxrecur INT UNSIGNED DEFAULT 0;

  SELECT @@max_sp_recursion_depth INTO _maxrecur;
  SET @@max_sp_recursion_depth = 255;

  IF ISNULL(_res) THEN
    SELECT CONCAT('INSERT INTO ', _context) INTO _res;
  END IF;

  -- customise behaviour
  -- get fields first
  SELECT JSON_OBJECT('ArrayIteration', 'CALL ParseJSONArrayAddDelim(?, ?, ?, ?, ?)') INTO _parser;
  SELECT JSON_INSERT(_parser, '$.ObjectIteration', 'CALL ParseJSONObjectInsertFieldIteration(?, ?, ?, ?, ?, ?, ?)') INTO _parser;

  CALL ParseJSONDocument(_schemaId, _context, _doc, _root, _parser, _res);

  -- now get values
  SELECT JSON_INSERT(_parser, '$.ObjectPreprocess', 'CALL ParseJSONObjectInsertValuesPreprocess(?, ?, ?)') INTO _parser;
  SELECT JSON_REPLACE(_parser, '$.ObjectIteration', 'CALL ParseJSONObjectInsertValueIteration(?, ?, ?, ?, ?, ?, ?)') INTO _parser;
  SELECT JSON_INSERT(_parser, '$.ValueAction', 'CALL ParseJSONValueCastAction(?, ?, ?)') INTO _parser;

  CALL ParseJSONDocument(_schemaId, _context, _doc, _root, _parser, _res);

  SET @@max_sp_recursion_depth = _maxrecur;
END//

DROP PROCEDURE IF EXISTS InsertIntoTable//

CREATE PROCEDURE InsertIntoTable(_schemaId TINYINT UNSIGNED, _tablename VARCHAR(64), _jsonDoc JSON, OUT _lastInsertId INT UNSIGNED)
BEGIN
  DECLARE _insertClause VARCHAR(1024) DEFAULT NULL;
  CALL GetInsertClause(_schemaId, _tablename, _jsonDoc, _insertClause);
  SET @_sql = _insertClause;
  PREPARE _insert FROM @_sql;
  EXECUTE _insert;
  DEALLOCATE PREPARE _insert;
  SELECT LAST_INSERT_ID() INTO _lastInsertId;
END//

DELIMITER ;
