DELIMITER ;

SHOW WARNINGS;

-- reference tables for asset classes ...

DROP TABLE IF EXISTS tocv;

CREATE TABLE tocv (
  id BIGINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  price_timestamp DATETIME NOT NULL,
  open_price DECIMAL(18, 6) UNSIGNED NOT NULL,
  close_price DECIMAL(18, 6) UNSIGNED NOT NULL,
  volume_traded DECIMAL(18, 6) UNSIGNED,
  flag_id TINYINT UNSIGNED DEFAULT 0,
  FOREIGN KEY (flag_id) REFERENCES REFDATA.ohlc_flag_type(id) ON UPDATE RESTRICT ON DELETE RESTRICT
);

DROP PROCEDURE IF EXISTS AddTOCV;

DELIMITER //

CREATE PROCEDURE AddTOCV(_tableName VARCHAR(64), _priceTimestamp DATETIME, _openPrice DECIMAL(18, 6) UNSIGNED, _closePrice DECIMAL(18, 6) UNSIGNED, _volTraded DECIMAL(18, 6) UNSIGNED)
BEGIN
  SET @_sql = CONCAT('INSERT INTO ', _tableName, ' (price_timestamp, open_price, close_price, volume_traded) VALUES (?, ?, ?, ?)');
  PREPARE _insert FROM @_sql;
  SET @_priceTimestamp = _priceTimestamp;
  SET @_openPrice = _openPrice;
  SET @_closePrice = _closePrice;
  SET @_volTraded = _volTraded;
  EXECUTE _insert USING @_priceTimestamp, @_openPrice, @_closePrice, @_volTraded;
  DEALLOCATE PREPARE _insert;
END
//

DELIMITER ;
