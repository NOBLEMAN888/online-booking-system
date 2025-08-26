-- name: user_profiles
SELECT *
FROM "user" u
JOIN  user_profile up ON u.user_id = up.user_id
LEFT JOIN user_social us ON u.user_id = us.user_id;


-- name: user_profiles_filtered
SELECT *
FROM user_profile u
WHERE u.gender = 'M'
  AND u.date_of_birth BETWEEN '1990-01-01' AND '2000-12-31';


-- name: users_filtered
SELECT *
FROM "user" u
ORDER BY u.registration_date DESC;


-- name: users_payment_card
SELECT u.user_id, u.email, up.first_name, up.last_name, pc.card_id, pc.provider, pc.last_four
FROM "user" u
LEFT JOIN user_profile up ON u.user_id = up.user_id
LEFT JOIN payment_card pc ON u.user_id = pc.user_id
ORDER BY u.user_id;


-- name: users_loyalty_program_level
SELECT *
FROM  user_profile up
JOIN loyalty_program lp ON up.user_id = lp.user_id
JOIN loyalty_level ll ON lp.level_id = ll.level_id;


-- name: loyalty_levels_user_count
SELECT ll.level_name, COUNT(*) AS user_count
FROM loyalty_program lp
JOIN loyalty_level ll ON lp.level_id = ll.level_id
GROUP BY ll.level_name;


-- name: properties_amenity_count
SELECT p.property_id, p.owner_id, p.title,
       COUNT(pa.amenity_id) AS amenity_count
FROM property p
JOIN property_amenity pa ON p.property_id = pa.property_id
GROUP BY p.property_id;


-- name: properties_filtered
SELECT p.property_id, p.owner_id, p.title,
       COUNT(pa.amenity_id) AS amenity_count
FROM property p
JOIN property_amenity pa ON p.property_id = pa.property_id
GROUP BY p.property_id
HAVING COUNT(pa.amenity_id) >= 2;


-- name: bookings_users_payments
SELECT b.booking_id, up.first_name, up.last_name, p.amount
FROM booking b
JOIN payment p ON b.booking_id = p.booking_id
JOIN "user" u ON b.user_id = u.user_id
LEFT JOIN user_profile up ON u.user_id = up.user_id;