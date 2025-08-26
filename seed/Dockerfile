FROM python:3.11-slim

WORKDIR /seed
RUN pip install psycopg2-binary==2.9.9 Faker==24.8.0 python-dotenv==1.0.0 django-pgcrypto
COPY . .

CMD ["sh", "-c", "if [ \"$APP_ENV\" = \"dev\" ]; then python seed_data.py; else echo 'Seeding skipped (APP_ENV != dev)'; fi"]