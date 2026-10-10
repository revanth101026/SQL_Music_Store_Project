create database music_store;
use music_store;

-- 1. Genre and MediaType
CREATE TABLE Genre (
genre_id INT PRIMARY KEY,
name VARCHAR(120)
);
CREATE TABLE MediaType (
media_type_id INT PRIMARY KEY,
name VARCHAR(120)
);
SELECT count(*) FROM genre;
SELECT * FROM mediatype LIMIT 3;

-- 2. Employee
CREATE TABLE Employee (
employee_id INT PRIMARY KEY,
last_name VARCHAR(120),
first_name VARCHAR(120),
title VARCHAR(120),
reports_to INT,
levels VARCHAR(255),
birthdate DATE,
hire_date DATE,
address VARCHAR(255),
city VARCHAR(100),
state VARCHAR(100),
country VARCHAR(100),
postal_code VARCHAR(20),
phone VARCHAR(50),
fax VARCHAR(50),
email VARCHAR(100)
);
SELECT count(*) FROM employee;
-- 3. Customer
CREATE TABLE Customer (
customer_id INT PRIMARY KEY,
first_name VARCHAR(120),
last_name VARCHAR(120),
company VARCHAR(120),
address VARCHAR(255),
city VARCHAR(100),
state VARCHAR(100),
country VARCHAR(100),
postal_code VARCHAR(20),
phone VARCHAR(50),
fax VARCHAR(50),
email VARCHAR(100),
support_rep_id INT,
FOREIGN KEY (support_rep_id) REFERENCES Employee(employee_id)
);

-- 4. Artist
CREATE TABLE Artist (
artist_id INT PRIMARY KEY,
name VARCHAR(120)
);
SELECT count(*) FROM artist;

-- 5. Album
CREATE TABLE Album (
album_id INT PRIMARY KEY,
title VARCHAR(160),
artist_id INT,
FOREIGN KEY (artist_id) REFERENCES Artist(artist_id)
);
SELECT count(*) FROM album;


-- 6. Track
CREATE TABLE Track (
track_id INT PRIMARY KEY,
name VARCHAR(200),
album_id INT,
media_type_id INT,
genre_id INT,
composer VARCHAR(220),
milliseconds INT,
bytes INT,
unit_price DECIMAL(10,2),
FOREIGN KEY (album_id) REFERENCES Album(album_id),
FOREIGN KEY (media_type_id) REFERENCES MediaType(media_type_id),
FOREIGN KEY (genre_id) REFERENCES Genre(genre_id)
);

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE  'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/track.csv'
INTO TABLE  track
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(track_id, name, album_id, media_type_id, genre_id, composer, milliseconds, bytes, unit_price);

select count(*) from track;


-- 7. Invoice
CREATE TABLE Invoice (
invoice_id INT PRIMARY KEY,
customer_id INT,
invoice_date DATE,
billing_address VARCHAR(255),
billing_city VARCHAR(100),
billing_state VARCHAR(100),
billing_country VARCHAR(100),
billing_postal_code VARCHAR(20),
total DECIMAL(10,2),
FOREIGN KEY (customer_id) REFERENCES Customer(customer_id)
);

-- 8. InvoiceLine
CREATE TABLE InvoiceLine (
invoice_line_id INT PRIMARY KEY,
invoice_id INT,
track_id INT,
unit_price DECIMAL(10,2),
quantity INT,
FOREIGN KEY (invoice_id) REFERENCES Invoice(invoice_id),
FOREIGN KEY (track_id) REFERENCES Track(track_id)
);

-- 9. Playlist
CREATE TABLE Playlist (
playlist_id INT PRIMARY KEY,
name VARCHAR(255)
);

-- 10. PlaylistTrack
CREATE TABLE PlaylistTrack (
playlist_id INT,
track_id INT,
PRIMARY KEY (playlist_id, track_id),
FOREIGN KEY (playlist_id) REFERENCES Playlist(playlist_id),
FOREIGN KEY (track_id) REFERENCES Track(track_id)
);

# 1. Who is the senior most employee based on job title?
select employee_id,last_name,first_name,title,levels
from employee
order by levels desc
limit 1;

# 2. Which countries have the most Invoices?
select billing_country as country ,count(invoice_id) as no_of_invoices
from invoice
group by country
order by no_of_invoices desc;

# 3. What are the top 3 values of total invoice?
select total as total_invoice from invoice
order by total desc
limit 3;

# 4. Which city has the best customers? - We would like to throw a promotional Music Festival in the city we made the most money. Write a query that returns one city that has the highest sum ofinvoice totals. Return both the city name & sum of all invoice totals
select billing_city as city, sum(total) as Total_bill
from invoice
group by city
order by total_bill desc
limit 1;

# 5. Who is the best customer? - The customer who has spent the most money will be declared the best customer. Write a query that returns the person who has spent the most money
select i.customer_id,c.first_name,c.last_name,sum(i.total) as Total_bill
from invoice as i
join customer as c
on i.customer_id = c.customer_id
group by i.customer_id
order by total_bill desc
limit 1;

# 6. Write a query to return the email, first name, last name, & Genre of all Rock Music listeners. Return your list ordered alphabetically by email starting with A
select distinct c.first_name,c.last_name,c.email,g.name as genre
from customer as c
join invoice as i
on i.customer_id = c.customer_id
join invoiceline as il
on i.invoice_id = il.invoice_id
join track as t
on il.track_id = t.track_id
join genre as g
on t.genre_id = g.genre_id
where g.name = 'Rock'
order by c.email; 

# 7. Let's invite the artists who have written the most rock music in our dataset. Write a query that returns the Artist name and total track count of the top 10 rock bands
select a.name as artist_name,count(t.track_id) as No_of_tracks
from artist as a
join album as al
on a.artist_id = al.artist_id
join track as t
on al.album_id = t.album_id
join genre as g
on t.genre_id = g.genre_id
where g.name = 'Rock'
group by artist_name
order by no_of_tracks desc
limit 10;

# 8. Return all the track names that have a song length longer than the average song length.-Return the Name and Milliseconds for each track. Order by the song length, with the longest songs listed first
select name as Track_name, milliseconds as Length_of_song
from track
where milliseconds >(select avg(milliseconds) from track)
order by milliseconds desc;

# 9. Find how much amount is spent by each customer on artists? Write a query to return customer name, artist name and total spent
select c.customer_id,c.first_name,c.last_name,ar.name as artist_name,Sum(il.unit_price * il.quantity) as total_spent 
from customer as c
join invoice as i
on c.customer_id = i.customer_id
join invoiceline as il
on i.invoice_id = il.invoice_id
join track as t
on t.track_id = il.track_id
join album as a
on t.album_id = a.album_id
join artist as ar
on ar.artist_id = a.artist_id
group by c.customer_id,c.first_name,c.last_name,ar.name,ar.artist_id
order by total_spent desc;

# 10. We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared, return all Genres
with popular_genre as (
select i.billing_country as country,count(il.invoice_id) as No_of_purchases,g.name as genre
from invoice as i
join invoiceline as il
on i.invoice_id = il.invoice_id
join track as t
on il.track_id = t.track_id
join genre as g
on g.genre_id = t.genre_id
group by i.billing_country, g.genre_id, g.name),

max_purchase as (
select country,max(No_of_purchases) as Purchased
from popular_genre
group by country)

select pg.country,pg.No_of_purchases, pg.genre from popular_genre as pg
join max_purchase as mp
on pg.country = mp.country
and pg.No_of_purchases = mp.purchased
order by No_of_purchases;

# 11. Write a query that determines the customer that has spent the most on music for each country. Write a query that returns the country along with the top customer and how much they spent. For countries where the top amount spent is shared, provide all customers who spent this amount
with customer_by_country as (select i.customer_id,c.first_name,c.last_name,i.billing_country as country,sum(il.unit_price*il.quantity) as Amount_spent
from invoice as i
join customer as c
on c.customer_id = i.customer_id
join invoiceline as il
on i.invoice_id = il.invoice_id
group by i.customer_id,i.billing_country),

Max_spend as (
select country, max(Amount_spent) as Maximum_spent
from customer_by_country
group by country)

select cb.customer_id,cb.first_name,cb.last_name,cb.country,m.maximum_spent
from customer_by_country as cb
join Max_spend as m
on cb.country = m.country
and cb.Amount_spent = m.maximum_spent
order by maximum_spent desc;