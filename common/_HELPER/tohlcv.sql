DELIMITER ;

SHOW WARNINGS;

-- reference tables for asset classes ...

DROP TABLE IF EXISTS tohlcv;

CREATE TABLE tohlcv LIKE tocv;

ALTER TABLE tohlcv
  ADD high_price DECIMAL(18, 6) UNSIGNED NOT NULL AFTER open_price,
  ADD low_price DECIMAL(18, 6) UNSIGNED NOT NULL AFTER high_price
-- check contraints parsed but not implemented in MySQL
-- CONSTRAINT CHECK (open_price <= high_price AND open_price >= low_price AND close_price >= low_price AND close_price <= high_price)
;

DROP TRIGGER IF EXISTS before_tohlcv_insert;

DELIMITER //

CREATE TRIGGER before_tohlcv_insert
  BEFORE INSERT ON tohlcv
  FOR EACH ROW
  BEGIN
    IF NEW.open_price > NEW.high_price OR NEW.open_price < NEW.low_price OR NEW.close_price < NEW.low_price OR NEW.close_price > NEW.high_price THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid price data', MYSQL_ERRNO = ER_SIGNAL_EXCEPTION;
    END IF;
  END
//

DROP PROCEDURE IF EXISTS AddTOHLCV//

CREATE PROCEDURE AddTOHLCV(_tableName VARCHAR(64), _priceTimestamp DATETIME, _openPrice DECIMAL(18, 6) UNSIGNED, _highPrice DECIMAL(18, 6) UNSIGNED, _lowPrice DECIMAL(18, 6) UNSIGNED, _closePrice DECIMAL(18, 6) UNSIGNED, _volTraded DECIMAL(18, 6) UNSIGNED)
BEGIN
  SET @_sql = CONCAT('INSERT INTO ', _tableName, ' (price_timestamp, open_price, high_price, low_price, close_price, volume_traded) VALUES (?, ?, ?, ?, ?, ?)');
  PREPARE _insert FROM @_sql;
  SET @_priceTimestamp = _priceTimestamp;
  SET @_openPrice = _openPrice;
  SET @_highPrice = _highPrice;
  SET @_lowPrice = _lowPrice;
  SET @_closePrice = _closePrice;
  SET @_volTraded = _volTraded;
  EXECUTE _insert USING @_priceTimestamp, @_openPrice, @_highPrice, @_lowPrice, @_closePrice, @_volTraded;
  DEALLOCATE PREPARE _insert;
END
//

DELIMITER ;
