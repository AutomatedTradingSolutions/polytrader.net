DELIMITER ;

SHOW WARNINGS;

SET @_json_type_char_len = 64;

DELIMITER //

DROP PROCEDURE IF EXISTS _GetCodedSQL//

CREATE PROCEDURE _GetCodedSQL(_targetsql VARCHAR(1024), _argcount TINYINT, _args JSON, OUT _result VARCHAR(1024))
BEGIN
  IF _argcount > 0 THEN
    SET @_sql = _targetsql;
    PREPARE _statement FROM @_sql;
    SET @_arg1 = JSON_EXTRACT(_args, '$[0]');
    IF _argcount > 1 THEN
      SET @_arg2 = JSON_EXTRACT(_args, '$[1]');
    END IF;
    IF _argcount > 2 THEN
      SET @_arg3 = JSON_EXTRACT(_args, '$[2]');
    END IF;
    SET @_result = NULL;
    IF _argcount = 1 THEN
      EXECUTE _statement USING @_result, @_arg1;
    ELSEIF _argcount = 2 THEN
      EXECUTE _statement USING @_result, @_arg1, @_arg2;
    ELSEIF _argcount = 3 THEN
      EXECUTE _statement USING @_result, @_arg1, @_arg2, @_arg3;
    ELSE
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid arg count', MYSQL_ERRNO = ER_SIGNAL_EXCEPTION;
    END IF;
    SET _result = @_result;
    DEALLOCATE PREPARE _statement;
  END IF;
END//

DROP FUNCTION IF EXISTS GetCodedSQL//

CREATE FUNCTION GetCodedSQL(_schemaId TINYINT UNSIGNED, _context VARCHAR(64), _code VARCHAR(16), _args JSON) RETURNS VARCHAR(1024)
BEGIN
  DECLARE _objectName VARCHAR(64) DEFAULT NULL;
  DECLARE _targetsql VARCHAR(1024) DEFAULT NULL;
  DECLARE _argCount TINYINT DEFAULT 0;
  DECLARE _result VARCHAR(1024) DEFAULT NULL;
  SELECT object_name, target_sql, arg_count INTO _objectName, _targetsql, _argCount FROM REFDATA.dynamic_sql WHERE code = _code AND schema_id = _schemaId;
  IF _argCount = 0 THEN
    RETURN IF(ISNULL(_objectName) OR _objectName = _context, _targetsql, CONCAT(_objectName, '.', _targetsql));
  END IF;
  CALL _GetCodedSQL(_targetsql, _argCount, _args, _result);
  RETURN _result;
END//

DROP FUNCTION IF EXISTS IsNotEqualOperator//

CREATE FUNCTION IsNotEqualOperator(_doc JSON) RETURNS TINYINT UNSIGNED
BEGIN
  -- IF _json REGEXP '^!' AND NOT _json REGEXP '^!!' THEN
  DECLARE _unquote VARCHAR(1024) DEFAULT JSON_UNQUOTE(_doc);
  RETURN IF(IsString(_doc) AND SUBSTR(_unquote, 1, 1) = '!' AND SUBSTR(_unquote, 1, 2) <> '!!', 1, 0);
END//

DROP FUNCTION IF EXISTS RemoveNotEqualOperator//

CREATE FUNCTION RemoveNotEqualOperator(_doc JSON) RETURNS JSON
BEGIN
  DECLARE _res VARCHAR(1024) DEFAULT NULL;
  IF NOT IsNotEqualOperator(_doc) THEN
    RETURN _doc;
  END IF;
  SELECT SUBSTR(JSON_UNQUOTE(_doc), 2) INTO _res;
  IF IsQuoted(_doc) THEN
    SELECT JSON_QUOTE(_res) INTO _res;
  END IF;
  RETURN CAST(_res AS JSON);
END//

DROP FUNCTION IF EXISTS RemoveRegularExpressions//

CREATE FUNCTION RemoveRegularExpressions(_doc JSON) RETURNS JSON
BEGIN
  RETURN RemoveNotEqualOperator(_doc);
END//

DROP FUNCTION IF EXISTS IsWildcard//

CREATE FUNCTION IsWildcard(_doc JSON) RETURNS TINYINT UNSIGNED
BEGIN
  DECLARE _instr INT UNSIGNED DEFAULT INSTR(_doc, '%');
  RETURN IF(_instr != 0 AND SUBSTR(_doc, _instr, 2) != '%%', 1, 0);
END//

DROP FUNCTION IF EXISTS IsAnyChar//

CREATE FUNCTION IsAnyChar(_doc JSON) RETURNS TINYINT UNSIGNED
BEGIN
  DECLARE _instr INT UNSIGNED DEFAULT INSTR(_doc, '_');
  RETURN IF(_instr != 0 AND SUBSTR(_doc, _instr, 2) != '__', 1, 0);
END//

DROP FUNCTION IF EXISTS IsPatternMatch//

CREATE FUNCTION IsPatternMatch(_doc JSON) RETURNS TINYINT UNSIGNED
BEGIN
  RETURN IF(IsString(_doc) AND (IsWildcard(_doc) OR IsAnyChar(_doc)), 1, 0);
END//

DROP FUNCTION IF EXISTS IsEqualOperator//

CREATE FUNCTION IsEqualOperator(_doc JSON) RETURNS TINYINT UNSIGNED
BEGIN
  RETURN IF(IsNumber(_doc) OR (NOT IsNotEqualOperator(_doc) AND NOT IsPatternMatch(_doc)), 1, 0);
END//

DROP FUNCTION IF EXISTS IsLogicalAnd//

CREATE FUNCTION IsLogicalAnd(_doc JSON, _parent JSON) RETURNS TINYINT UNSIGNED
BEGIN
  -- RETURN IF(IsString(_doc) AND UPPER(JSON_UNQUOTE(_doc)) = 'AND', 1, 0);
  RETURN IF(IsArray(_parent), 0, 1);
END//

DROP FUNCTION IF EXISTS IsLogicalOr//

CREATE FUNCTION IsLogicalOr(_doc JSON, _parent JSON) RETURNS TINYINT UNSIGNED
BEGIN
  -- RETURN IF(IsString(_doc) AND UPPER(JSON_UNQUOTE(_doc)) = 'OR', 1, 0);
  RETURN IF(IsArray(_parent), 1, 0);
END//

DROP FUNCTION IF EXISTS GetLogicalOperator//

CREATE FUNCTION GetLogicalOperator(_doc JSON, _parent JSON) RETURNS VARCHAR(64)
BEGIN
  DECLARE _res VARCHAR(64) DEFAULT NULL;
  IF IsLogicalAnd(_doc, _parent) THEN
    SELECT ' AND ' INTO _res;
  ELSEIF IsLogicalOr(_doc, _parent) THEN
    SELECT ' OR ' INTO _res;
  ELSE
    SELECT JSON_UNQUOTE(_doc) INTO _res;
  END IF;
  RETURN _res;
END//

DROP FUNCTION IF EXISTS GetComparisonOperator//

CREATE FUNCTION GetComparisonOperator(_doc JSON) RETURNS VARCHAR(16)
BEGIN
  IF IsArray(_doc) THEN
    RETURN ' IN ';
  ELSEIF IsObject(_doc) THEN
    RETURN '';
  ELSEIF IsNotEqualOperator(_doc) THEN
    RETURN '<>';
  ELSEIF IsEqualOperator(_doc) THEN
    RETURN '=';
  ELSEIF IsPatternMatch(_doc) THEN
    RETURN ' LIKE ';
  ELSE
    RETURN '';
  END IF;
END//

DROP PROCEDURE IF EXISTS ParseJSONValueCastAction//

CREATE PROCEDURE ParseJSONValueCastAction(_doc JSON, _key JSON, OUT _res VARCHAR(1024))
BEGIN
  SELECT CAST(_doc AS CHAR) INTO _res;
END//

DROP PROCEDURE IF EXISTS ParseJSONValue//

CREATE PROCEDURE ParseJSONValue(_doc JSON, _parent JSON, _parse JSON, INOUT _res VARCHAR(1024))
BEGIN
  -- encapsulate variation
  SET @_jsonsql = JSON_UNQUOTE(JSON_EXTRACT(_parse, '$.ValueAction'));
  IF NOT ISNULL(@_jsonsql) THEN
    PREPARE _statement FROM @_jsonsql;
    SET @_jsondoc = _doc, @_jsonparent = _parent, @_jsonresult = NULL;
    EXECUTE _statement USING @_jsondoc, @_jsonparent, @_jsonresult;
    IF NOT ISNULL(@_jsonresult) THEN
      SELECT CONCAT(_res, @_jsonresult) INTO _res;
    END IF;
    DEALLOCATE PREPARE _statement;
  END IF;
  -- end of variation
END//

DROP PROCEDURE IF EXISTS ParseJSONArrayAddDelim//

CREATE PROCEDURE ParseJSONArrayAddDelim(_doc JSON, _key JSON, _obj JSON, _iter INT UNSIGNED, OUT _res VARCHAR(4))
BEGIN
  SELECT IF(_iter > 0, ',', '') INTO _res;
END//

DROP PROCEDURE IF EXISTS ParseJSONArray//

CREATE PROCEDURE ParseJSONArray(_schemaId TINYINT UNSIGNED, _context VARCHAR(64), _doc JSON, _parent JSON, _parse JSON, INOUT _res VARCHAR(1024))
BEGIN
  DECLARE _iter INT UNSIGNED DEFAULT 0;
  DECLARE _obj JSON;
  SET @_jsonsql = JSON_UNQUOTE(JSON_EXTRACT(_parse, '$.ArrayIteration'));
  PREPARE _statement FROM @_jsonsql;
  SELECT CONCAT(_res, ' (') INTO _res;
  iter_: LOOP
    SELECT JSON_EXTRACT(_doc, CONCAT('$[', _iter, ']')) INTO _obj;
    IF ISNULL(_obj) THEN
      LEAVE iter_;
    END IF;
    -- encapsulate variation
    SET @_jsondoc = _doc, @_jsonparent = _parent, @_jsonobj = _obj, @_jsoniter = _iter, @_jsonresult = NULL;
    EXECUTE _statement USING @_jsondoc, @_jsonparent, @_jsonobj, @_jsoniter, @_jsonresult;
    IF NOT ISNULL(@_jsonresult) THEN
      SELECT CONCAT(_res, @_jsonresult) INTO _res;
    END IF;
    -- end of variation
    CALL ParseJSONDocument(_schemaId, _context, _obj, _doc, _parse, _res);
    SELECT _iter + 1 INTO _iter;
  END LOOP;
  SELECT CONCAT(_res, ')') INTO _res;
  DEALLOCATE PREPARE _statement;
END//

DROP PROCEDURE IF EXISTS ParseJSONObjectProcess//

CREATE PROCEDURE ParseJSONObjectProcess(_doc JSON, _parent JSON, _parse JSON, _parseKey VARCHAR(64), INOUT _res VARCHAR(1024))
BEGIN
  SET @_jsonsql = JSON_UNQUOTE(JSON_EXTRACT(_parse, _parseKey));
  IF NOT ISNULL(@_jsonsql) THEN
    PREPARE _statement FROM @_jsonsql;
    SET @_jsondoc = _doc, @_jsonparent = _parent, @_jsonresult = NULL;
    EXECUTE _statement USING @_jsondoc, @_jsonparent, @_jsonresult;
    DEALLOCATE PREPARE _statement;
    IF NOT ISNULL(@_jsonresult) THEN
      SELECT CONCAT(_res, @_jsonresult) INTO _res;
    END IF;
  END IF;
END//

DROP PROCEDURE IF EXISTS ParseJSONObjectIteration//

CREATE PROCEDURE ParseJSONObjectIteration(_schemaId TINYINT UNSIGNED, _context VARCHAR(64), _doc JSON, _parent JSON, _key JSON, _obj JSON, _iter INT UNSIGNED, _parse JSON, INOUT _res VARCHAR(1024))
BEGIN
  SET @_jsonsql = JSON_UNQUOTE(JSON_EXTRACT(_parse, '$.ObjectIteration'));
  IF NOT ISNULL(@_jsonsql) THEN
    PREPARE _statement FROM @_jsonsql;
    SET @_jsonuncodedkey = GetCodedSQL(_schemaId, _context, JSON_UNQUOTE(RemoveRegularExpressions(_key)), _obj);
    SET @_jsondoc = _doc, @_jsonparent = _parent, @_jsonkey = _key, @_jsonobj = _obj, @_jsoniter = _iter, @_jsonresult = NULL;
    EXECUTE _statement USING @_jsondoc, @_jsonparent, @_jsonkey, @_jsonuncodedkey, @_jsonobj, @_jsoniter, @_jsonresult;
    DEALLOCATE PREPARE _statement;
    IF NOT ISNULL(@_jsonresult) THEN
      SELECT CONCAT(_res, @_jsonresult) INTO _res;
    END IF;
  END IF;
END//

DROP PROCEDURE IF EXISTS ParseJSONObject//

CREATE PROCEDURE ParseJSONObject(_schemaId TINYINT UNSIGNED, _context VARCHAR(64), _doc JSON, _parent JSON, _parse JSON, INOUT _res VARCHAR(1024))
BEGIN
  DECLARE _iter INT UNSIGNED DEFAULT 0;
  DECLARE _keys JSON DEFAULT JSON_KEYS(_doc);
  DECLARE _key JSON;
  DECLARE _obj JSON;
  -- encapsulate variation
  CALL ParseJSONObjectProcess(_doc, _parent, _parse, '$.ObjectPreprocess', _res);
  -- end of variation
  SELECT CONCAT(_res, ' (') INTO _res;
  iter_: LOOP
    SELECT JSON_EXTRACT(_keys, CONCAT('$[', _iter, ']')) INTO _key;
    IF ISNULL(_key) THEN
      LEAVE iter_;
    END IF;
    SELECT JSON_EXTRACT(_doc, CONCAT('$.', _key)) INTO _obj;
    -- encapsulate variation
    CALL ParseJSONObjectIteration(_schemaId, _context, _doc, _parent, _key, _obj, _iter, _parse, _res);
    -- end of variation
    CALL ParseJSONDocument(_schemaId, _context, _obj, _doc, _parse, _res);
    SELECT _iter + 1 INTO _iter;
  END LOOP;
  SELECT CONCAT(_res, ')') INTO _res;
  -- encapsulate variation
  CALL ParseJSONObjectProcess(_doc, _parent, _parse, '$.ObjectPostprocess', _res);
  -- end of variation
END//

DROP PROCEDURE IF EXISTS ParseJSONDocument//

CREATE PROCEDURE ParseJSONDocument(_schemaId TINYINT UNSIGNED, _context VARCHAR(64), _doc JSON, _parent JSON, _parser JSON, INOUT _res VARCHAR(1024))
BEGIN
  IF IsObject(_doc) THEN
    CALL ParseJSONObject(_schemaId, _context, _doc, _parent, _parser, _res);
  ELSEIF IsArray(_doc) THEN
    CALL ParseJSONArray(_schemaId, _context, _doc, _parent, _parser, _res);
  ELSEIF IsStringOrNumber(_doc) THEN
    CALL ParseJSONValue(_doc, _parent, _parser, _res);
  END IF;
END//

DELIMITER ;
