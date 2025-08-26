import os
import random
import psycopg2
from psycopg2 import sql
from faker import Faker
from datetime import datetime, timedelta, date
from dotenv import load_dotenv
import pgcrypto

load_dotenv()

DB_HOST = os.getenv('POSTGRES_HOST', 'haproxy')
DB_PORT = os.getenv('POSTGRES_PORT', '5000')
DB_NAME = os.getenv('POSTGRES_DB', 'booking_db')
DB_USER = os.getenv('DB_ADMIN_USER')
DB_PASSWORD = os.getenv('DB_ADMIN_PASSWORD')
SEED_COUNT = int(os.getenv('SEED_COUNT', '1'))

cnt = SEED_COUNT
user_cnt = 1000 * cnt
user_profile_cnt = user_cnt
user_social_cnt = 500 * cnt
two_factor_auth_cnt = 50 * cnt
payment_card_cnt = 900 * cnt
loyalty_program_cnt = user_profile_cnt
travel_companion_cnt = 400 * cnt
property_cnt = 20 * cnt
favorite_property_cnt = 50 * cnt
location_cnt = property_cnt
property_image_cnt = 10 * property_cnt
property_amenity_cnt = 3 * property_cnt
room_cnt = 2 * property_cnt
room_availability_cnt = 5 * room_cnt
booking_cnt = 200 * cnt
booking_guest_cnt = 100 * cnt
booking_service_cnt = 100 * cnt
payment_cnt = 150 * cnt
review_cnt = 100 * cnt
message_cnt = 150 * cnt
notification_cnt = message_cnt

t = Faker()

conn = psycopg2.connect(host=DB_HOST, port=DB_PORT, dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD)
conn.autocommit = True
cur = conn.cursor()

def table_exists(table_name):
    cur.execute(
        "SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name=%s)",
        [table_name]
    )
    return cur.fetchone()[0]

def truncate(table):
    cur.execute(sql.SQL("TRUNCATE TABLE {} RESTART IDENTITY CASCADE").format(sql.Identifier(table)))

def fetch_ids(table, id_col, limit):
    cur.execute(sql.SQL("SELECT {} FROM {} ORDER BY random() LIMIT %s").format(
        sql.Identifier(id_col), sql.Identifier(table)
    ), [limit])
    return [row[0] for row in cur.fetchall()]

def seed_user():
    if table_exists('user'):
        truncate('user')
        for i in range(user_cnt):
            email = t.company_email()
            password = 'password' + str(i+1)
            reg_date = datetime.now() - timedelta(days=random.random() * 365)
            cur.execute(
                sql.SQL("INSERT INTO \"user\" (email, password, registration_date) VALUES (%s, %s, %s)"),
                [email, password, reg_date]
            )

def seed_user_profile():
    if table_exists('user_profile'):
        truncate('user_profile')
        user_ids = fetch_ids('user', 'user_id', user_profile_cnt)
        for uid in user_ids:
            cur.execute(
                sql.SQL("INSERT INTO user_profile (user_id, first_name, last_name, date_of_birth, gender, contact_number, passport_data, profile_picture, preferred_currency, preferred_language) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"),
                [
                    uid,
                    t.first_name(),
                    t.last_name(),
                    (datetime.now() - timedelta(days=random.random()*365*40)).date(),
                    random.choice(['M','F','U']),
                    t.msisdn(),
                    t.text(max_nb_chars=20),
                    f"https://picsum.photos/seed/{uid}/200/200",
                    random.choice(['USD','EUR','GBP']),
                    random.choice(['en','de','fr'])
                ]
            )

def seed_user_social():
    if table_exists('user_social'):
        truncate('user_social')
        user_ids = fetch_ids('user', 'user_id', user_social_cnt)
        for uid in user_ids:
            cur.execute(
                sql.SQL("INSERT INTO user_social (user_id, provider, social_identifier, token) VALUES (%s,%s,%s,%s)"),
                [uid, random.choice(['facebook','google','twitter']), t.uuid4(), t.uuid4()]
            )

def seed_two_factor_auth():
    if table_exists('two_factor_auth'):
        truncate('two_factor_auth')
        user_ids = fetch_ids('user', 'user_id', two_factor_auth_cnt)
        for uid in user_ids:
            cur.execute(
                sql.SQL("INSERT INTO two_factor_auth (user_id, method, secret, enabled) VALUES (%s,%s,%s,%s)"),
                [uid, random.choice(['sms','email','app']), t.md5(raw_output=False), random.random()<0.5]
            )

def seed_payment_card():
    if table_exists('payment_card'):
        truncate('payment_card')
        user_ids = fetch_ids('user', 'user_id', payment_card_cnt)
        for uid in user_ids:
            cur.execute(
                sql.SQL("INSERT INTO payment_card (user_id, provider, token, last_four) VALUES (%s,%s,%s,%s)"),
                [uid, random.choice(['visa','mastercard','amex']), t.credit_card_number(), str(random.randint(0,9999)).zfill(4)]
            )

def seed_loyalty_level():
    if table_exists('loyalty_level'):
        truncate('loyalty_level')
        for lvl in [('Silver',5.00,5,1000.00),('Gold',10.00,15,5000.00),('Platinum',15.00,30,10000.00)]:
            cur.execute(
                sql.SQL("INSERT INTO loyalty_level (level_name, discount_rate, bookings_threshold, amount_threshold) VALUES (%s,%s,%s,%s)"),
                lvl
            )

def seed_loyalty_program():
    if table_exists('loyalty_program'):
        truncate('loyalty_program')
        user_ids = fetch_ids('user', 'user_id', loyalty_program_cnt)
        for uid in user_ids:
            cur.execute("INSERT INTO loyalty_program (user_id, level_id) SELECT %s, level_id FROM loyalty_level ORDER BY random() LIMIT 1", [uid])

def seed_travel_companion():
    if table_exists('travel_companion'):
        truncate('travel_companion')
        user_ids = fetch_ids('user', 'user_id', travel_companion_cnt)
        for uid in user_ids:
            cur.execute(
                sql.SQL("INSERT INTO travel_companion (user_id, first_name, last_name, date_of_birth, gender, contact_number, email) VALUES (%s,%s,%s,%s,%s,%s,%s)"),
                [uid, t.first_name(), t.last_name(), (datetime.now()-timedelta(days=random.random()*365*60)).date(), random.choice(['M','F','U']), t.msisdn(), t.email()]
            )

def seed_property():
    if table_exists('property'):
        truncate('property')
        user_ids = fetch_ids('user', 'user_id', property_cnt)
        for uid in user_ids:
            cur.execute(
                sql.SQL("INSERT INTO property (owner_id, title, description, property_type, cancellation_policy) VALUES (%s,%s,%s,%s,%s)"),
                [uid, ' '.join(t.words(3)), t.paragraph(), random.choice(['Apartment','House','Villa','Studio']), t.sentence()]
            )

def seed_favorite_property():
    if table_exists('favorite_property'):
        truncate('favorite_property')
        prop_ids = fetch_ids('property','property_id',favorite_property_cnt)
        for pid in prop_ids:
            cur.execute("INSERT INTO favorite_property (user_id, property_id) VALUES ((SELECT user_id FROM \"user\" ORDER BY random() LIMIT 1), %s)", [pid])

def seed_location():
    if table_exists('location'):
        truncate('location')
        prop_ids = fetch_ids('property','property_id',location_cnt)
        for pid in prop_ids:
            cur.execute("INSERT INTO location (property_id, latitude, longitude) VALUES (%s,%s,%s)", [pid, round(random.uniform(-90,90),6), round(random.uniform(-180,180),6)])

def seed_property_image():
    if table_exists('property_image'):
        truncate('property_image')
        ids = fetch_ids('property','property_id',property_image_cnt)
        for i, pid in enumerate(ids,1):
            cur.execute("INSERT INTO property_image (property_id, url, description) VALUES (%s,%s,%s)", [pid, f"https://picsum.photos/seed/{i}/800/600", t.sentence()])

def seed_amenity():
    if table_exists('amenity'):
        truncate('amenity')
        for name,desc in [('Wi-Fi','Wireless internet'),('Parking','Free on-site parking'),('Pool','Outdoor swimming pool'),('Air Conditioning','Climate control system'),('Kitchen','Fully equipped kitchen')]:
            cur.execute("INSERT INTO amenity (name, description) VALUES (%s,%s)",[name,desc])

def seed_property_amenity():
    if table_exists('property_amenity'):
        truncate('property_amenity')
        prop_ids = fetch_ids('property','property_id',property_amenity_cnt)
        amenity_ids = fetch_ids('amenity','amenity_id',len(fetch_ids('amenity','amenity_id',100)))
        for pid in prop_ids:
            cur.execute("INSERT INTO property_amenity (property_id, amenity_id) VALUES (%s,%s)",[pid, random.choice(amenity_ids)])

def seed_room():
    if table_exists('room'):
        truncate('room')
        room_types=['Single','Double','Suite']
        for prop_id in range(1, property_cnt+1):
            for _ in range(2):
                cur.execute("INSERT INTO room (property_id, room_number, room_type, price) VALUES (%s,%s,%s,%s)",
                    [prop_id, random.randint(1,100), random.choice(room_types), round(random.uniform(50,300),2)])

def seed_room_availability():
    if table_exists('room_availability'):
        truncate('room_availability')
        for room_id in range(1, room_cnt+1):
            for _ in range(5):
                date_from = t.date_between(start_date='-30d', end_date='+30d')
                date_to = date_from + timedelta(days=random.randint(1,5))
                cur.execute("INSERT INTO room_availability (room_id, date_from, date_to, is_available) VALUES (%s,%s,%s,%s)",[room_id, date_from, date_to, True])

def seed_service():
    if table_exists('service'):
        truncate('service')
        services=[('Breakfast','Continental breakfast',15),('Airport Pickup','Airport transfer',50),('Cleaning','Extra cleaning',30)]
        for name,desc,price in services:
            cur.execute("INSERT INTO service (service_name, description, price) VALUES (%s,%s,%s)",[name,desc,price])

def seed_booking():
    if table_exists('booking'):
        truncate('booking')
        rooms_list=fetch_ids('room','room_id',room_cnt)
        for _ in range(booking_cnt):
            user_id=random.randint(1,user_cnt)
            room_id=random.choice(rooms_list)
            start= t.date_between(start_date='-30d', end_date='+30d')
            end=start+timedelta(days=random.randint(1,7))
            status=random.choice(['pending','confirmed','cancelled'])
            cur.execute("INSERT INTO booking (user_id, room_id, booking_date, check_in, check_out, status) VALUES (%s,%s,%s,%s,%s,%s)",[user_id,room_id, datetime.now(), start, end, status])

def seed_booking_guest():
    if table_exists('booking_guest'):
        truncate('booking_guest')
        for bid in range(1, booking_cnt+1):
            cur.execute("INSERT INTO booking_guest (booking_id, guest_id) VALUES (%s,%s)",[bid, random.randint(1, travel_companion_cnt)])

def seed_booking_service():
    if table_exists('booking_service'):
        truncate('booking_service')
        for bid in range(1, booking_cnt+1):
            cur.execute("INSERT INTO booking_service (booking_id, service_id) VALUES (%s,%s)",[bid, random.randint(1, len(fetch_ids('service','service_id',100)))])

def seed_payment():
    if table_exists('payment'):
        truncate('payment')
        for bid in range(1, booking_cnt+1):
            amount= round(random.uniform(50,500),2)
            method=random.choice(['card','paypal','bank_transfer'])
            status=random.choice(['paid','pending','failed'])
            cur.execute("INSERT INTO payment (booking_id, user_id, payment_date, amount, payment_method, payment_status) VALUES (%s, (SELECT user_id FROM booking WHERE booking_id=%s), %s, %s, %s, %s)",[bid,bid, datetime.now(), amount, method, status])

def seed_review():
    if table_exists('review'):
        truncate('review')
        for bid in range(1, booking_cnt+1):
            rating=random.randint(1,5)
            comment=t.sentence()
            cur.execute(
                            """
                            INSERT INTO review
                              (booking_id, user_id, property_id, review_text, rating, review_date)
                            SELECT
                              b.booking_id,
                              b.user_id,
                              r.property_id,
                              %s,
                              %s,
                              %s
                            FROM booking b
                            JOIN room r ON b.room_id = r.room_id
                            WHERE b.booking_id = %s;
                            """,
                            [comment, rating, datetime.now(), bid]
                        )

def seed_message():
    if table_exists('message'):
        truncate('message')
        for bid in range(1, booking_cnt + 1):
            cur.execute(
                """
                SELECT b.user_id AS guest_id,
                       p.owner_id AS host_id
                FROM booking b
                JOIN room r      ON b.room_id = r.room_id
                JOIN property p  ON r.property_id = p.property_id
                WHERE b.booking_id = %s
                """,
                [bid]
            )
            row = cur.fetchone()
            if not row:
                continue
            guest_id, host_id = row

            participants = [(guest_id, host_id), (host_id, guest_id), (guest_id, host_id)]
            for sender_id, receiver_id in participants:
                content = t.sentence()
                sent_date = datetime.now() - timedelta(days=random.randint(0, 30), hours=random.randint(0,23))
                is_read = False

                cur.execute(
                    """
                    INSERT INTO message
                      (booking_id, sender_id, receiver_id, content, sent_date, is_read)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    """,
                    [bid, sender_id, receiver_id, content, sent_date, is_read]
                )

def seed_notification():
    if table_exists('notification'):
        truncate('notification')
        templates=["Booking %s confirmed","Payment for Booking %s received","New message for Booking %s"]
        for bid in range(1, booking_cnt+1):
            for uid in [random.randint(1,user_cnt), random.randint(1,user_cnt)]:
                content=random.choice(templates)%bid
                cur.execute("INSERT INTO notification (user_id, message, sent_date, is_read) VALUES (%s, %s, %s, %s)",[uid,content, datetime.now(),False])

def main():
    seed_user()
    seed_user_profile()
    seed_user_social()
    seed_two_factor_auth()
    seed_payment_card()
    seed_loyalty_level()
    seed_loyalty_program()
    seed_travel_companion()
    seed_property()
    seed_favorite_property()
    seed_location()
    seed_property_image()
    seed_amenity()
    seed_property_amenity()
    seed_room()
    seed_room_availability()
    seed_service()
    seed_booking()
    seed_booking_guest()
    seed_booking_service()
    seed_payment()
    seed_review()
    seed_message()
    seed_notification()

if __name__ == '__main__':
    main()
    conn.close()
