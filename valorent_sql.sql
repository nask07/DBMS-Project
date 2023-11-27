-- Create the database for the valorent
CREATE DATABASE ValorantCrossHair;

-- Use the created database
USE ValorantCrossHair;

-- Create a table for storing information about Player
CREATE TABLE Player (
    PlayerID INT AUTO_INCREMENT PRIMARY KEY,
    FirstName VARCHAR(255) NOT NULL,
    LastName VARCHAR(255) NOT NULL,
    EmailID VARCHAR(255) NOT NULL,
	DOB Date NOT NULL,
	Passwrd VARCHAR(255) NOT NULL,
	ISAdmin TINYINT(1) NOT NULL
);

-- Create a table for storing Player Phone Number
CREATE TABLE PlayerPhone (
    PlayerID INT,
	PhoneNo  BIGINT,
	PRIMARY KEY(PlayerID, PhoneNo) ,
	FOREIGN KEY (PlayerID) REFERENCES Player(PlayerID) ON DELETE CASCADE  ON UPDATE CASCADE
	);

	   
-- Create a table to store user cart information
CREATE TABLE Crosshair (
    CrosshairID INT AUTO_INCREMENT PRIMARY KEY,
	CrosshairImage MEDIUMBLOB NOT NULL
);

	   
-- Create a table to store crosshair Setting
CREATE TABLE CrosshairSetting (
	SettingID INT AUTO_INCREMENT PRIMARY KEY,
	CrosshairColor	VARCHAR(10) NOT NULL,
	OutLines TINYINT(1),
	OutLinesThickness TINYINT,
	InnerLines TINYINT(1),
	InnerLinesThickness TINYINT,
	FOREIGN KEY (CrosshairID) REFERENCES Crosshair(CrosshairID) ON DELETE CASCADE  ON UPDATE CASCADE
	   	   
);

-- Create a table to store crosshair Setting
CREATE TABLE CrosshairPlayerSetting (
	SettingID INT ,
	PlayerID  INT ,
	PRIMARY KEY(SettingID, PlayerID) ,
	FOREIGN KEY (SettingID) REFERENCES CrosshairSetting(SettingID) ON DELETE CASCADE  ON UPDATE CASCADE,
	FOREIGN KEY (PlayerID) REFERENCES Player(PlayerID) ON DELETE CASCADE  ON UPDATE CASCADE

);

-- Create a table to store player logs
CREATE TABLE PlayerLog (
    LogID INT AUTO_INCREMENT PRIMARY KEY,
    PlayerID INT,
    LogMessage VARCHAR(255) NOT NULL,
    LogTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (PlayerID) REFERENCES Player(PlayerID) ON DELETE CASCADE ON UPDATE CASCADE
);

DELIMITER //
CREATE TRIGGER ChangeToAdminLog
AFTER UPDATE ON Player
FOR EACH ROW
BEGIN
    -- Check if the ISAdmin column is updated to 1 (admin)
    IF NEW.ISAdmin = 1 AND OLD.ISAdmin = 0 THEN
        -- Insert a log entry into PlayerLog
        INSERT INTO PlayerLog (PlayerID, LogMessage)
        VALUES (NEW.PlayerID, 'Player changed to admin');
    END IF;
END //
DELIMITER ;



--Create Player and Phone NUmber during Signin
DELIMITER //
CREATE PROCEDURE AddPlayerAndPhones(
    IN p_FirstName VARCHAR(255),
    IN p_LastName VARCHAR(255),
    IN p_EmailID VARCHAR(255),
    IN p_DOB DATE,
    IN p_Passwrd VARCHAR(255),
    IN p_ISAdmin TINYINT,
    IN p_PhoneNumbersCSV VARCHAR(255)
)
BEGIN
    DECLARE newPlayerID INT;


-- Create a temporary table to store phone numbers
	CREATE TEMPORARY TABLE IF NOT EXISTS TempPhoneNumbers (
	 PlayerID INT,
		PhoneNo BIGINT
 );

 CREATE TEMPORARY TABLE IF NOT EXISTS Numbers (
    digit INT
);

INSERT INTO Numbers (digit) VALUES (0), (1), (2), (3), (4), (5);

-- Insert data into the Player table
INSERT INTO Player (FirstName, LastName, EmailID, DOB, Passwrd, ISAdmin)
VALUES (p_FirstName, p_LastName, p_EmailID, p_DOB, p_Passwrd, p_ISAdmin);

-- Get the last inserted PlayerID
SET @newPlayerID = LAST_INSERT_ID();

INSERT INTO TempPhoneNumbers (PlayerID, PhoneNo)
SELECT @newPlayerID AS PlayerID,
       CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(p_PhoneNumbersCSV, ',', Numbers.digit+1), ',', -1) AS SIGNED) AS PhoneNo
FROM Numbers
WHERE Numbers.digit < (LENGTH(p_PhoneNumbersCSV) - LENGTH(REPLACE(p_PhoneNumbersCSV, ',', '')) + 1);

-- Insert data into the PlayerPhone table from the temporary table
INSERT INTO PlayerPhone (PlayerID, PhoneNo)
SELECT PlayerID, PhoneNo FROM TempPhoneNumbers;

-- Drop the temporary table
DROP TEMPORARY TABLE IF EXISTS TempPhoneNumbers;

DROP TEMPORARY TABLE IF EXISTS Numbers;

END //
DELIMITER ;

DELIMITER //

CREATE PROCEDURE GetAllPlayersAndPhones()
BEGIN
 
    -- Declare a cursor for selecting player information with phone numbers
        SELECT P.PlayerID, P.FirstName, P.LastName, P.EmailID, P.DOB, P.Passwrd, P.ISAdmin, PP.PhoneNo
        FROM Player P
        LEFT JOIN PlayerPhone PP ON P.PlayerID = PP.PlayerID;

  
END //

DELIMITER ;
----------------------------------------------
	DELIMITER //

	CREATE PROCEDURE InsertCrosshairAndSetting(
		IN p_CrosshairImage MEDIUMBLOB,
		IN p_CrosshairColor VARCHAR(10),
		IN p_OutLines TINYINT,
		IN p_OutLinesThickness TINYINT,
		IN p_InnerLines TINYINT,
		IN p_InnerLinesThickness TINYINT
	)
	BEGIN
		DECLARE v_CrosshairID INT;

		-- Insert data into Crosshair table
		INSERT INTO Crosshair (CrosshairImage) VALUES (p_CrosshairImage);
		SET v_CrosshairID = LAST_INSERT_ID();

		-- Insert data into CrosshairSetting table
		INSERT INTO CrosshairSetting (CrosshairColor, OutLines, OutLinesThickness, InnerLines, InnerLinesThickness, CrosshairID)
		VALUES (p_CrosshairColor, p_OutLines, p_OutLinesThickness, p_InnerLines, p_InnerLinesThickness, v_CrosshairID);
	END //

	DELIMITER ;


DELIMITER //

CREATE PROCEDURE GetPlayerCredentialsByEmail(IN p_email VARCHAR(255))
BEGIN
    SELECT PlayerID, EmailID, passwrd,ISAdmin,FirstName
    FROM player
    WHERE EmailID = p_email;
END //

DELIMITER ;



