/* Create the custom logging table if it doesn't already exist */
CREATE TABLE IF NOT EXISTS phpipam.rpi_custom_log(
	logId BIGINT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	objectName VARCHAR(100) NOT NULL,
	objectType VARCHAR(100) NOT NULL,
	associatedTables VARCHAR(1000) NOT NULL,
	description VARCHAR(4000) NOT NULL,
	idAssociations VARCHAR(4000) NOT NULL DEFAULT '[NONE]',
	id1 INT NULL,
	id2 INT NULL,
	id3 INT NULL
);

/* Create the trigger that will set default location on IPs to that of the IP's parent subnet, if defined */
delimiter //
CREATE TRIGGER setDefaultLocation BEFORE INSERT ON ipaddresses
FOR EACH ROW
BEGIN
DECLARE subnetLocId INT;
DECLARE subnetDesc VARCHAR(1000);
IF NEW.location IS NULL THEN
SELECT l.id, s.description
INTO subnetLocId, subnetDesc
FROM subnets s
LEFT JOIN locations l on s.location = l.id
WHERE s.id = NEW.subnetId;
IF subnetLocId IS NOT NULL THEN
SET NEW.location = subnetLocId;
INSERT INTO phpipam.rpi_custom_log(objectName, objectType, associatedTables, description, idAssociations, id1)
SELECT
'setDefaultLocation',
'TRIGGER',
'ipaddresses',
CONCAT('New IP address ', INET_NTOA(NEW.ip_addr), ' with ID: ',
CAST(NEW.ID AS VARCHAR(8)),'; setting default location to that of its parent subnet (',
subnetDesc,')'
), 'id1 = locID of parent subnet', subnetLocId;
ELSE
INSERT INTO phpipam.rpi_custom_log(objectName, objectType, associatedTables, description)
SELECT
'setDefaultLocation',
'TRIGGER',
'ipaddresses',
CONCAT('New IP address ',INET_NTOA(NEW.ip_addr),' with ID: ',
CAST(NEW.ID AS VARCHAR(8)),'; NOT setting default location because its parent subnet (',
subnetDesc,') does not have a location set;'
);
END IF;
ELSE
INSERT INTO phpipam.rpi_custom_log(objectName, objectType, associatedTables, description, idAssociations, id1)
SELECT
'setDefaultLocation',
'TRIGGER',
'ipaddresses',
CONCAT('New IP address ',INET_NTOA(NEW.ip_addr),' with ID: ',
CAST(NEW.ID AS VARCHAR(8)),'; NOT modifying location because it was already set by the user; '
), 'id1 = locID set by user', NEW.location;
END IF;
END
//
delimiter ;
