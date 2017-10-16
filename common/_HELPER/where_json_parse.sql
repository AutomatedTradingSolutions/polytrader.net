DELIMITER ;

SHOW WARNINGS;

SET @_json_type_char_len = 64;

DELIMITER //

DROP PROCEDURE IF EXISTS ParseJSONValueWhereAction//

CREATE PROCEDURE ParseJSONValueWhereAction(_doc JSON, _key JSON, OUT _res VARCHAR(1024))
BEGIN
  SELECT CAST(RemoveNotEqualOperator(_doc) AS CHAR) INTO _res;
END//

DROP PROCEDURE IF EXISTS ParseJSONObjectWherePreprocess//

CREATE PROCEDURE ParseJSONObjectWherePreprocess(_doc JSON, _parent JSON, OUT _res VARCHAR(1024))
BEGIN
  SELECT GetLogicalOperator(_doc, _parent) INTO _res;
END//

DROP PROCEDURE IF EXISTS ParseJSONObjectWhereIteration//

CREATE PROCEDURE ParseJSONObjectWhereIteration(_doc JSON, _parent JSON, _key JSON, _uncodedKey VARCHAR(512), _obj JSON, _iter INT UNSIGNED, OUT _res VARCHAR(1024))
BEGIN
  SELECT CONCAT( \
    IF(_iter > 0, GetLogicalOperator(_doc, _parent), ''), \
    _uncodedKey, \
    IF(IsNotEqualOperator(_key), ' NOT ', ''), \
    GetComparisonOperator(_obj) ) \
    INTO _res;
END//

DROP PROCEDURE IF EXISTS GetWhereClause//

CREATE PROCEDURE GetWhereClause(_schemaId TINYINT UNSIGNED, _context VARCHAR(64), _doc JSON, INOUT _res VARCHAR(1024))
BEGIN
  DECLARE _root JSON DEFAULT NULL;
  DECLARE _parser JSON;
  DECLARE _maxrecur INT UNSIGNED DEFAULT 0;

  SELECT @@max_sp_recursion_depth INTO _maxrecur;
  SET @@max_sp_recursion_depth = 255;

  IF ISNULL(_res) THEN
    SELECT 'WHERE 1=1' INTO _res;
  END IF;

  -- customise behaviour
  SELECT JSON_OBJECT('ArrayIteration', 'CALL ParseJSONArrayAddDelim(?, ?, ?, ?, ?)') INTO _parser;
  SELECT JSON_INSERT(_parser, '$.ObjectPreprocess', 'CALL ParseJSONObjectWherePreprocess(?, ?, ?)') INTO _parser;
  SELECT JSON_INSERT(_parser, '$.ObjectIteration', 'CALL ParseJSONObjectWhereIteration(?, ?, ?, ?, ?, ?, ?)') INTO _parser;
  SELECT JSON_INSERT(_parser, '$.ValueAction', 'CALL ParseJSONValueWhereAction(?, ?, ?)') INTO _parser;

  CALL ParseJSONDocument(_schemaId, _context, _doc, _root, _parser, _res);

  SET @@max_sp_recursion_depth = _maxrecur;
END//

DELIMITER ;
