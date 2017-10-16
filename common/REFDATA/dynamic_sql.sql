DELIMITER ;

SHOW WARNINGS;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS data_schema;

CREATE TABLE data_schema (
  id TINYINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  schema_name VARCHAR(64) NOT NULL,
  UNIQUE KEY (schema_name)
);

DROP FUNCTION IF EXISTS GetDataSchemaId;

DELIMITER //

CREATE FUNCTION GetDataSchemaId(_schemaName VARCHAR(64)) RETURNS TINYINT UNSIGNED
BEGIN
  DECLARE _id TINYINT UNSIGNED DEFAULT NULL;
  SELECT id INTO _id FROM data_schema WHERE schema_name = _schemaName;
  RETURN _id;
END//

DELIMITER ;

DROP PROCEDURE IF EXISTS AddDataSchema;

DELIMITER //

CREATE PROCEDURE AddDataSchema(_schemaName VARCHAR(64))
BEGIN
  INSERT INTO data_schema (schema_name) VALUES (_schemaName);
END//

DELIMITER ;

CALL AddDataSchema(SCHEMA());

DROP TABLE IF EXISTS dynamic_sql;

CREATE TABLE dynamic_sql (
  id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  schema_id TINYINT UNSIGNED NOT NULL,
  code VARCHAR(16) NOT NULL,
  object_name VARCHAR(64),
  target_sql VARCHAR(1024) NOT NULL,
  arg_count TINYINT UNSIGNED NOT NULL DEFAULT 0,
  UNIQUE KEY (schema_id, code),
  FOREIGN KEY (schema_id) REFERENCES data_schema(id) ON UPDATE RESTRICT ON DELETE RESTRICT
);

DROP PROCEDURE IF EXISTS AddDynamicSQL;

DELIMITER //

CREATE PROCEDURE AddDynamicSQL(_schemaName VARCHAR(64), _code VARCHAR(16), _objectname VARCHAR(64), _targetsql VARCHAR(1024))
BEGIN
  INSERT INTO dynamic_sql (schema_id, code, object_name, target_sql) \
    VALUES (GetDataSchemaId(_schemaName), _code, _objectname, _targetsql);
END//

DROP PROCEDURE IF EXISTS DeleteDynamicSQL//

CREATE PROCEDURE DeleteDynamicSQL(_schemaName VARCHAR(64), _objectName VARCHAR(64), _code VARCHAR(16))
BEGIN
  DELETE FROM dynamic_sql WHERE schema_id = GetDataSchemaId(_schemaName) AND ( ISNULL(_objectName) OR object_name = _objectName ) AND ( ISNULL(_code) OR code = _code );
END//

DELIMITER ;

SET FOREIGN_KEY_CHECKS = 1;
