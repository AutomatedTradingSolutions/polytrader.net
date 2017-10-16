DELIMITER ;

SHOW WARNINGS;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS instrument_frequency;

CREATE TABLE instrument_frequency (
  id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT COMMENT 'INSFREQID',
  instrument_id INT UNSIGNED NOT NULL COMMENT 'INSFREQINSTRID',
  frequency_id INT UNSIGNED NOT NULL COMMENT 'INSFREQFREQID',
  ref_tablename VARCHAR(64),
  FOREIGN KEY (instrument_id) REFERENCES instrument(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  FOREIGN KEY (frequency_id) REFERENCES frequency(id) ON UPDATE RESTRICT ON DELETE RESTRICT
);

SET @_tablename = 'instrument_frequency';

CALL DeleteDynamicSQL(SCHEMA(), @_tablename);

CALL AddDynamicSQL(SCHEMA(), 'INFREQID', @_tablename, 'id');
CALL AddDynamicSQL(SCHEMA(), 'INFREQINSTR', @_tablename, 'instrument_id');
CALL AddDynamicSQL(SCHEMA(), 'INFREQFREQ', @_tablename, 'frequency_id');

DROP PROCEDURE IF EXISTS AddInstrumentFrequency;

DELIMITER //

CREATE PROCEDURE AddInstrumentFrequency(_instrumentId INT UNSIGNED, _frequencyId INT UNSIGNED, _refTablename VARCHAR(64))
BEGIN
  INSERT INTO instrument_frequency (instrument_id, frequency_id, ref_tablename) VALUES (_instrumentId, _frequencyId, _refTablename);
END
//

DROP PROCEDURE IF EXISTS AddInstrumentFrequencies//

CREATE PROCEDURE AddInstrumentFrequencies(_instrumentId INT UNSIGNED, _frequencies JSON)
BEGIN
  DECLARE _frequency JSON;
  DECLARE _key JSON;
  DECLARE _frequencyId INT UNSIGNED;
  DECLARE _refTablename VARCHAR(64);
  DECLARE _iter INT UNSIGNED DEFAULT 0;
  iter_: LOOP
    SELECT JSON_EXTRACT(_frequencies, CONCAT('$[', _iter, ']')) INTO _frequency;
    IF ISNULL(_frequency) THEN
      LEAVE iter_;
    END IF;
    SELECT JSON_EXTRACT(JSON_KEYS(_frequency), '$[0]') INTO _key;
    SELECT id INTO _frequencyId FROM frequency WHERE code = JSON_UNQUOTE(_key);
    SELECT JSON_UNQUOTE(JSON_EXTRACT(_frequency, CONCAT('$.', _key))) INTO _refTablename;
    CALL AddInstrumentFrequency(_instrumentId, _frequencyId, _refTablename);
    SELECT _iter + 1 INTO _iter;
  END LOOP;
END
//

DELIMITER ;

DROP TABLE IF EXISTS instrument_csv_encoder;

CREATE TABLE instrument_csv_encoder (
  id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT COMMENT 'INSCSVENCID',
  instrument_id INT UNSIGNED NOT NULL COMMENT 'INSCSVENCINSID',
  frequency_id INT UNSIGNED NOT NULL COMMENT 'INSCSVENCFREQID',
  data_format_id TINYINT UNSIGNED NOT NULL,
  FOREIGN KEY (instrument_id) REFERENCES instrument(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  FOREIGN KEY (frequency_id) REFERENCES frequency(id) ON UPDATE RESTRICT ON DELETE RESTRICT,
  FOREIGN KEY (data_format_id) REFERENCES data_format(id) ON UPDATE RESTRICT ON DELETE RESTRICT
);

DROP TABLE IF EXISTS instrument;

CREATE TABLE instrument (
  id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT COMMENT 'INSTRID',
  code VARCHAR(10) NOT NULL COMMENT 'INSTRCODE',
  name VARCHAR(30) COMMENT 'INSTRNAME',
  asset_class_id INT UNSIGNED NOT NULL COMMENT 'INSTRASSCLS',
  decimals TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'INSTRDEC',
  schema_name VARCHAR(64) NOT NULL UNIQUE COMMENT 'INSTRSCHEMA',
  UNIQUE KEY (code),
  FOREIGN KEY (asset_class_id) REFERENCES asset_class(id) ON UPDATE RESTRICT ON DELETE RESTRICT
);

CREATE OR REPLACE VIEW v_instrument_name AS
  SELECT name FROM instrument;

SET @_tablename = 'instrument';

CALL DeleteDynamicSQL(SCHEMA(), @_tablename);

CALL AddDynamicSQL(SCHEMA(), 'INSTRID', @_tablename, 'id');
CALL AddDynamicSQL(SCHEMA(), 'INSTRCODE', @_tablename, 'code');
CALL AddDynamicSQL(SCHEMA(), 'INSTRNAME', @_tablename, 'name');
CALL AddDynamicSQL(SCHEMA(), 'INSTRASSCLS', @_tablename, 'asset_class_id');
CALL AddDynamicSQL(SCHEMA(), 'INSTRDEC', @_tablename, 'decimals');
CALL AddDynamicSQL(SCHEMA(), 'INSTRSCHEMA', @_tablename, 'schema_name');

DELIMITER //

DROP PROCEDURE IF EXISTS AddInstrument//

CREATE PROCEDURE AddInstrument(_code VARCHAR(10), _name VARCHAR(30), _assetClassId INT UNSIGNED, _decimals TINYINT UNSIGNED, _schemaName VARCHAR(64), _frequencies JSON)
BEGIN
  DECLARE _instrumentId INT UNSIGNED;
  INSERT INTO instrument (code, name, asset_class_id, decimals, schema_name) VALUES (_code, _name, _assetClassId, _decimals, _schemaName);
  SELECT id INTO _instrumentId FROM instrument WHERE code = _code;
  CALL AddInstrumentFrequencies(_instrumentId, _frequencies);
END
//

SET @_frequencies = '[\
{"TICK":"_HELPER.tocv"},\
{"1S":"_HELPER.tohlcv"},\
{"1M":"_HELPER.tohlcv"},\
{"30M":"_HELPER.tohlcv"},\
{"1H":"_HELPER.tohlcv"},\
{"4H":"_HELPER.tohlcv"},\
{"1D":"_HELPER.tohlcv"},\
{"1W":"_HELPER.tohlcv"},\
{"1MTH":"_HELPER.tohlcv"}\
]'//

CALL AddInstrument('GBPUSD', 'Cable', (SELECT id from asset_class WHERE code = 'SPTFX'), 5, 'GBPUSD', @_frequencies)//
CALL AddInstrument('EURUSD', 'Eurodollar', (SELECT id from asset_class WHERE code = 'SPTFX'), 5, 'EURUSD', @_frequencies)//
CALL AddInstrument('USDJPY', 'Dollaryen', (SELECT id from asset_class WHERE code = 'SPTFX'), 5, 'USDJPY', @_frequencies)//

DROP PROCEDURE IF EXISTS GetInstrument//

CREATE PROCEDURE GetInstrument(_filter JSON)
BEGIN
  DECLARE _whereClause VARCHAR(1024) DEFAULT NULL;
  CALL _HELPER.GetWhereClause(GetDataSchemaId(SCHEMA()), 'instrument', _filter, _whereClause);
  SET @_sql = CONCAT('SELECT id, code, name, asset_class_id, decimals, schema_name FROM instrument ', _whereClause);
  PREPARE _select FROM @_sql;
  EXECUTE _select;
  DEALLOCATE PREPARE _select;
END
//

/*
DROP TRIGGER IF EXISTS after_instrument_insert;

DELIMITER //

CREATE TRIGGER after_instrument_insert
  AFTER INSERT ON instrument
  FOR EACH ROW
  BEGIN
    CREATE TABLE NEW.table_name LIKE ref_price;
  END
//
*/

DELIMITER ;

SET FOREIGN_KEY_CHECKS = 1;
