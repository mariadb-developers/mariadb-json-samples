/* 
Once you have connected to a MariaDB database instance, you can use the following SQL 
statements to test out the JSON functions that are provided by MariaDB.
*/ 

/**************************************/
-- Create database

CREATE database demo;


/**************************************/
-- Create locations table

CREATE TABLE `locations` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(500),
  `type` CHAR(1) NOT NULL,
  `latitude` DECIMAL(9,6) NOT NULL,
  `longitude` DECIMAL(9,6) NOT NULL,
  `attr` JSON,
  PRIMARY KEY (`id`)
);


/**************************************/
-- Insert data into locations table

INSERT INTO locations (`type`, `name`, latitude, longitude, attr)
VALUES ('R', 'Giordanos', 41.876388, -87.647639, 
    '{
        "details": { "foodType": "Pizza", "menu": "https://www.giordanos.com/menu"}, 
        "favorites": [
            {"description": "Pepperoni Deep Dish", "price": "$18.75"}, 
            {"description": "The Classic", "price": "$24.75"}
        ]
    }'
);

INSERT INTO locations (`type`, `name`, latitude, longitude, attr) 
VALUES ('A', 'Cloud Gate', 41.8826572, -87.6233039, '{"category": "Landmark" }');


/**************************************/
-- Read a value 

SELECT 
    `name`, longitude, latitude, JSON_VALUE(attr, '$.details.foodType') AS food_type
FROM locations;


/**************************************/
-- Read an entire object

SELECT 
    `name`, JSON_QUERY(attr, '$.details') AS details
FROM locations
WHERE `type` = 'R';


/**************************************/
-- Filter by JSON Value

SELECT COUNT(*) FROM locations WHERE JSON_VALUE(attr, '$.category') = 'Landmark';


/**************************************/
-- Insert a new property 

UPDATE locations SET attr = JSON_INSERT(attr, '$.lastVisitDate', '2021-06-13') WHERE id = 2;

--> Check: SELECT attr FROM locations WHERE id = 2;


/**************************************/
-- Read an array element value

SELECT `name`, JSON_VALUE(attr, '$.favorites[1].description') as latest_favorite
FROM locations
WHERE id = 1;

/**************************************/
-- Append to an array

UPDATE locations 
SET attr = JSON_ARRAY_APPEND(attr, '$.favorites', '{ "description": "A salad" }') 
WHERE id = 1;

-- Check: SELECT attr FROM locations WHERE id = 1;

/**************************************/
-- Delete from an array

UPDATE locations SET attr = JSON_REMOVE(attr, '$.favorites[2]') WHERE id = 1;


-- JSON merge 
SELECT 
    JSON_OBJECT('name', name, 'latitude', latitude, 'longitude', longitude, 'foodType', 
      JSON_VALUE(attr, '$.details.foodType')) AS json_data
FROM locations
WHERE type = 'R';


-- Add a new constraint

ALTER TABLE locations ADD CONSTRAINT check_attr
    CHECK(
        type != 'S' OR (type = 'S' AND 
            JSON_TYPE(JSON_QUERY(attr, '$.details')) = 'OBJECT' AND
            JSON_TYPE(JSON_QUERY(attr, '$.events')) = 'ARRAY' AND
            JSON_TYPE(JSON_VALUE(attr, '$.details.yearOpened')) = 'INTEGER' AND
            JSON_TYPE(JSON_VALUE(attr, '$.details.capacity')) = 'INTEGER' AND
            JSON_EXISTS(attr, '$.details.yearOpened') = 1 AND
            JSON_EXISTS(attr, '$.details.capacity') = 1 AND
            JSON_LENGTH(JSON_QUERY(attr, '$.events')) > 0));


-- Invalid Events
INSERT INTO locations (type, name, latitude, longitude, attr) 
VALUES ('S', 'United Center', 41.880691, -87.674176, 
    '{
        "details": {"yearOpened": 1994, "capacity": 23500}
        
    }'
);

INSERT INTO locations (type, name, latitude, longitude, attr) 
VALUES ('S', 'United Center', 41.880691, -87.674176, 
    '{
        "details": {"yearOpened": 1994, "capacity": 23500}, 
        "events": [
            {"date": "10/18/2021", "description": "Bulls vs Celtics"}
        ]
    }'
);