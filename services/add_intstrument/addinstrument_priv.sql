DELIMITER ;

SHOW WARNINGS;

REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'addinstrument'@'localhost';

GRANT CREATE ON *.* TO 'addinstrument'@'localhost';
GRANT EXECUTE ON PROCEDURE REFDATA.AddInstrument TO 'addinstrument'@'localhost';
GRANT EXECUTE ON PROCEDURE REFDATA.AddInstrumentFrequencies TO 'addinstrument'@'localhost';
GRANT EXECUTE ON PROCEDURE REFDATA.AddInstrumentFrequency TO 'addinstrument'@'localhost';
GRANT INSERT, SELECT ON TABLE REFDATA.instrument TO 'addinstrument'@'localhost';
GRANT INSERT, SELECT ON TABLE REFDATA.instrument_frequency TO 'addinstrument'@'localhost';
