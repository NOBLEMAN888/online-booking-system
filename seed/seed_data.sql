DO
$$
    DECLARE
        cnt                  INT  := ${SEED_COUNT};
        user_cnt             INT  := 1000 * cnt;
        user_profile_cnt      INT  := user_cnt;
        user_social_cnt       INT  := 500 * cnt;
        two_factor_auth_cnt    INT  := 50 * cnt;
        payment_card_cnt      INT  := 900 * cnt;
        loyalty_program_cnt   INT  := user_profile_cnt;
        travel_companion_cnt  INT  := 400 * cnt;
        property_cnt         INT  := 20 * cnt;
        favorite_property_cnt INT  := 50 * cnt;
        location_cnt         INT  := property_cnt;
        property_image_cnt    INT  := 10 * property_cnt;
        property_amenity_cnt  INT  := 3 * property_cnt;
        room_cnt             INT  := 2 * property_cnt;
        room_availability_cnt INT  := 5 * room_cnt;
        booking_cnt          INT  := 200 * cnt;
        booking_guest_cnt     INT  := 100 * cnt;
        booking_service_cnt  INT  := 100 * cnt;
        payment_cnt          INT  := 150 * cnt;
        review_cnt           INT  := 100 * cnt;
        message_cnt          INT  := 150 * cnt;
        notification_cnt     INT  := message_cnt;

    BEGIN
        -- 1. user
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'user') THEN
            TRUNCATE TABLE "user" RESTART IDENTITY CASCADE;
            INSERT INTO "user" (email, password, registration_date)
            SELECT faker.email() || '@example.com',
                   crypt('password' || gs, gen_salt('bf')),
                   NOW() - (random() * 365 || ' days')::interval
            FROM generate_series(1, user_cnt) AS gs;
        END IF;

        -- 2. user_profile
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'user_profile') THEN
            TRUNCATE TABLE "user_profile" RESTART IDENTITY CASCADE;
            INSERT INTO "user_profile" (user_id, first_name, last_name, date_of_birth, gender, contact_number,
                                        passport_data, profile_picture, preferred_currency, preferred_language)
            SELECT u.user_id,
                   faker.first_name(),
                   faker.last_name(),
                   (NOW() - (random() * 365 * 40 || ' days')::interval)::date,
                   (ARRAY ['M','F','U'])[floor(random() * 3 + 1)],
                   faker.phone_number(),
                   faker.text(20),
                   'https://picsum.photos/seed/' || u.user_id || '/200/200',
                   (ARRAY ['USD','EUR','GBP'])[floor(random() * 3 + 1)],
                   (ARRAY ['en','de','fr'])[floor(random() * 3 + 1)]
            FROM (SELECT user_id
                  FROM "user"
                  ORDER BY random()
                  LIMIT user_profile_cnt) AS u;
        END IF;

        -- 3. user_social
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'user_social') THEN
            TRUNCATE TABLE "user_social" RESTART IDENTITY CASCADE;
            INSERT INTO "user_social" (user_id, provider, social_identifier, token)
            SELECT u.user_id,
                   (ARRAY ['facebook','google','twitter'])[floor(random() * 3 + 1)],
                   faker.uuid(),
                   faker.uuid()
            FROM (SELECT user_id
                  FROM "user"
                  ORDER BY random()
                  LIMIT user_social_cnt) AS u;
        END IF;

        -- 4. two_factor_auth
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'two_factor_auth') THEN
            TRUNCATE TABLE "two_factor_auth" RESTART IDENTITY CASCADE;
            INSERT INTO "two_factor_auth" (user_id, method, secret, enabled)
            SELECT u.user_id,
                   (ARRAY ['sms','email','app'])[floor(random() * 3 + 1)],
                   md5(random()::text),
                   (random() < 0.5)
            FROM (SELECT user_id
                  FROM "user"
                  ORDER BY random()
                  LIMIT two_factor_auth_cnt) AS u;
        END IF;

        -- 5. payment_card
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'payment_card') THEN
            TRUNCATE TABLE "payment_card" RESTART IDENTITY CASCADE;
            INSERT INTO "payment_card" (user_id, provider, token, last_four)
            SELECT u.user_id,
                   (ARRAY ['visa','mastercard','amex'])[floor(random() * 3 + 1)],
                   md5(faker.cc_number()),
                   lpad((floor(random() * 10000))::text, 4, '0')
            FROM (SELECT user_id
                  FROM "user"
                  ORDER BY random()
                  LIMIT payment_card_cnt) AS u;
        END IF;

        -- 6. loyalty_level
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'loyalty_level') THEN
            TRUNCATE TABLE "loyalty_level" RESTART IDENTITY CASCADE;
            INSERT INTO "loyalty_level" (level_name, discount_rate, bookings_threshold, amount_threshold)
            VALUES ('Silver', 5.00, 5, 1000.00),
                   ('Gold', 10.00, 15, 5000.00),
                   ('Platinum', 15.00, 30, 10000.00);
        END IF;

        -- 7. loyalty_program
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'loyalty_program') THEN
            TRUNCATE TABLE "loyalty_program" RESTART IDENTITY CASCADE;
            INSERT INTO "loyalty_program" (user_id, level_id)
            SELECT u.user_id,
                   (SELECT level_id FROM "loyalty_level" ORDER BY random() LIMIT 1)
            FROM (SELECT user_id
                  FROM "user"
                  ORDER BY random()
                  LIMIT loyalty_program_cnt) AS u;
        END IF;

        -- 8. travel_companion
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'travel_companion') THEN
            TRUNCATE TABLE "travel_companion" RESTART IDENTITY CASCADE;
            INSERT INTO "travel_companion" (user_id, first_name, last_name, date_of_birth, gender, contact_number,
                                            email)
            SELECT u.user_id,
                   faker.first_name(),
                   faker.last_name(),
                   (NOW() - (random() * 365 * 60 || ' days')::interval)::date,
                   (ARRAY ['M','F','U'])[floor(random() * 3 + 1)],
                   faker.phone_number(),
                   faker.email()
            FROM (SELECT user_id
                  FROM "user"
                  ORDER BY random()
                  LIMIT travel_companion_cnt) AS u;
        END IF;

        -- 9. property
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'property') THEN
            TRUNCATE TABLE "property" RESTART IDENTITY CASCADE;
            INSERT INTO "property" (owner_id, title, description, property_type, cancellation_policy)
            SELECT u.user_id,
                   faker.words(3)::text,
                   faker.paragraph(),
                   (ARRAY ['Apartment','House','Villa','Studio'])[floor(random() * 4 + 1)],
                   faker.sentence()
            FROM (SELECT user_id
                  FROM "user"
                  ORDER BY random()
                  LIMIT property_cnt) AS u;
        END IF;

        -- 10. favorite_property
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'favorite_property') THEN
            TRUNCATE TABLE "favorite_property" RESTART IDENTITY CASCADE;
            INSERT INTO "favorite_property" (user_id, property_id)
            SELECT (SELECT user_id FROM "user" ORDER BY random() LIMIT 1),
                   p.property_id
            FROM (SELECT property_id
                  FROM "property"
                  ORDER BY random()
                  LIMIT favorite_property_cnt) AS p;
        END IF;

        -- 11. location
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'location') THEN
            TRUNCATE TABLE "location" RESTART IDENTITY CASCADE;
            INSERT INTO "location" (property_id, latitude, longitude)
            SELECT p.property_id,
                   (random() * 180 - 90)::numeric(9, 6),
                   (random() * 360 - 180)::numeric(9, 6)
            FROM (SELECT property_id
                  FROM "property"
                  ORDER BY random()
                  LIMIT location_cnt) AS p;
        END IF;

        -- 12. property_image
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'property_image') THEN
            TRUNCATE TABLE "property_image" RESTART IDENTITY CASCADE;
            INSERT INTO "property_image" (property_id, url, description)
            SELECT p.property_id,
                   'https://picsum.photos/seed/' || gs || '/800/600',
                   faker.sentence()
            FROM generate_series(1, property_image_cnt) AS gs
                     CROSS JOIN LATERAL (
                SELECT property_id FROM "property" ORDER BY random() LIMIT 1
                ) AS p;
        END IF;

        -- 13. amenity
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'amenity') THEN
            TRUNCATE TABLE "amenity" RESTART IDENTITY CASCADE;
            INSERT INTO "amenity" (name, description)
            VALUES ('Wi-Fi', 'Wireless internet'),
                   ('Parking', 'Free on-site parking'),
                   ('Pool', 'Outdoor swimming pool'),
                   ('Air Conditioning', 'Climate control system'),
                   ('Kitchen', 'Fully equipped kitchen');
        END IF;

        -- 14. property_amenity
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'property_amenity') THEN
            TRUNCATE TABLE "property_amenity" RESTART IDENTITY CASCADE;
            INSERT INTO "property_amenity" (property_id, amenity_id)
            SELECT p.property_id,
                   a.amenity_id
            FROM (SELECT property_id
                  FROM "property"
                  ORDER BY random()
                  LIMIT property_amenity_cnt) AS p,
                 (SELECT amenity_id FROM "amenity" ORDER BY random() LIMIT 1) AS a;
        END IF;

        -- 15. room
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'room') THEN
            TRUNCATE TABLE "room" RESTART IDENTITY CASCADE;
            INSERT INTO "room" (property_id, room_number, room_type, price)
            SELECT p.property_id,
                   (floor(random() * 100 + 1))::text,
                   (ARRAY ['Single','Double','Suite'])[floor(random() * 3 + 1)],
                   (random() * 300 + 50)::numeric(10, 2)
            FROM (SELECT property_id
                  FROM "property"
                  ORDER BY random()
                  LIMIT room_cnt) AS p;
        END IF;

        -- 16. room_availability
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'room_availability') THEN
            TRUNCATE TABLE "room_availability" RESTART IDENTITY CASCADE;
            INSERT INTO "room_availability" (room_id, date_from, date_to, is_available)
            SELECT r.room_id,
                   date_trunc('day', NOW()) + (i || ' days')::interval,
                   date_trunc('day', NOW()) + ((i + 1) || ' days')::interval,
                   (random() < 0.8)
            FROM generate_series(0, room_availability_cnt) AS i
                     CROSS JOIN LATERAL (
                SELECT room_id FROM "room" ORDER BY random() LIMIT 1
                ) AS r;
        END IF;

        -- 17. booking
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'booking') THEN
            TRUNCATE TABLE "booking" RESTART IDENTITY CASCADE;
            INSERT INTO "booking" (user_id, room_id, booking_date, check_in, check_out, status, special_requests)
            SELECT (SELECT user_id FROM "user" ORDER BY random() LIMIT 1),
                   (SELECT room_id FROM "room" ORDER BY random() LIMIT 1),
                   NOW() - (random() * 30 || ' days')::interval,
                   date_trunc('day', NOW()) + (random() * 10 || ' days')::interval,
                   date_trunc('day', NOW()) + ((random() * 10 + 2) || ' days')::interval,
                   (ARRAY ['pending','confirmed','cancelled'])[floor(random() * 3 + 1)],
                   faker.sentence()
            FROM generate_series(1, booking_cnt) AS gs;
        END IF;

        -- 18. booking_guest
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'booking_guest') THEN
            TRUNCATE TABLE "booking_guest" RESTART IDENTITY CASCADE;
            INSERT INTO "booking_guest" (booking_id, guest_id)
            SELECT b.booking_id,
                   (SELECT companion_id FROM "travel_companion" ORDER BY random() LIMIT 1)
            FROM (SELECT booking_id
                  FROM "booking"
                  ORDER BY random()
                  LIMIT booking_guest_cnt) AS b;
        END IF;

        -- 19. service
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'service') THEN
            TRUNCATE TABLE "service" RESTART IDENTITY CASCADE;
            INSERT INTO "service" (service_name, description, price)
            VALUES ('Breakfast', 'Continental breakfast', 15.00),
                   ('Airport Pickup', 'Private airport transfer', 50.00),
                   ('Cleaning', 'Extra cleaning service', 30.00);
        END IF;

        -- 20. booking_service
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'booking_service') THEN
            TRUNCATE TABLE "booking_service" RESTART IDENTITY CASCADE;
            INSERT INTO "booking_service" (booking_id, service_id)
            SELECT b.booking_id,
                   (SELECT service_id FROM "service" ORDER BY random() LIMIT 1)
            FROM (SELECT booking_id
                  FROM "booking"
                  ORDER BY random()
                  LIMIT booking_service_cnt) AS b;
        END IF;

        -- 21. payment
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'payment') THEN
            TRUNCATE TABLE "payment" RESTART IDENTITY CASCADE;
            INSERT INTO "payment" (booking_id, user_id, payment_method, payment_status, payment_date, amount)
            SELECT b.booking_id,
                   b.user_id,
                   (ARRAY ['card','paypal','bank_transfer'])[floor(random() * 3 + 1)],
                   (ARRAY ['pending','paid','failed'])[floor(random() * 3 + 1)],
                   NOW() - (random() * 30 || ' days')::interval,
                   (random() * 500 + 50)::numeric(10, 2)
            FROM (SELECT booking_id, user_id FROM "booking" ORDER BY random() LIMIT payment_cnt) AS b;
        END IF;

        -- 22. review
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'review') THEN
            TRUNCATE TABLE "review" RESTART IDENTITY CASCADE;
            INSERT INTO "review" (booking_id, user_id, property_id, review_text, rating, review_date)
            SELECT b.booking_id,
                   b.user_id,
                   b.property_id,
                   faker.paragraph(),
                   floor(random() * 5 + 1),
                   NOW() - (random() * 30 || ' days')::interval
            FROM (SELECT booking_id, user_id, property_id FROM "booking" ORDER BY random() LIMIT review_cnt) AS b;
        END IF;

        -- 23. message
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'message') THEN
            TRUNCATE TABLE "message" RESTART IDENTITY CASCADE;
            INSERT INTO "message" (sender_id, receiver_id, booking_id, content, sent_date, is_read)
            SELECT (SELECT user_id FROM "user" ORDER BY random() LIMIT 1),
                   (SELECT user_id FROM "user" ORDER BY random() LIMIT 1),
                   b.booking_id,
                   faker.sentence(),
                   NOW() - (random() * 5 || ' days')::interval,
                   (random() < 0.5)
            FROM (SELECT booking_id
                  FROM "booking"
                  ORDER BY random()
                  LIMIT message_cnt) AS b;
        END IF;

        -- 24. notification
        IF EXISTS (SELECT 1
                   FROM pg_tables
                   WHERE schemaname = 'public'
                     AND tablename = 'notification') THEN
            TRUNCATE TABLE "notification" RESTART IDENTITY CASCADE;
            INSERT INTO "notification" (user_id, message, type, sent_date, is_read)
            SELECT u.user_id,
                   faker.sentence(),
                   (ARRAY ['info','alert','reminder'])[floor(random() * 3 + 1)],
                   NOW() - (random() * 7 || ' days')::interval,
                   (random() < 0.5)
            FROM (SELECT user_id
                  FROM "user"
                  ORDER BY random()
                  LIMIT notification_cnt) AS u;
        END IF;
    END
$$;