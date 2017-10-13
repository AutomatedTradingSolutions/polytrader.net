DELIMITER ;

SHOW WARNINGS;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS signin_method;

CREATE TABLE signin_method (
  id TINYINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  code VARCHAR(16) NOT NULL,
  UNIQUE KEY (code)
);

INSERT INTO signin_method (code) VALUES ('LinkedIn');
INSERT INTO signin_method (code) VALUES ('Facebook');
INSERT INTO signin_method (code) VALUES ('Google');
INSERT INTO signin_method (code) VALUES ('Email');
INSERT INTO signin_method (code) VALUES ('None');

DROP TABLE IF EXISTS sys_user;

CREATE TABLE sys_user (
  id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  signin_method_id TINYINT UNSIGNED NOT NULL,
  signin_id VARCHAR(64) NOT NULL,
  FOREIGN KEY (signin_method_id) REFERENCES signin_method(id) ON UPDATE RESTRICT ON DELETE RESTRICT
);

INSERT INTO sys_user (signin_method_id, signin_id) VALUES ((SELECT id FROM signin_method WHERE code = 'None'), 'anonymous');
INSERT INTO sys_user (signin_method_id, signin_id) VALUES ((SELECT id FROM signin_method WHERE code = 'None'), 'guest');

SET FOREIGN_KEY_CHECKS = 1;
