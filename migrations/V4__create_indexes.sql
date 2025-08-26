CREATE INDEX idx_user_profile_user_id ON user_profile(user_id);

CREATE INDEX idx_user_social_user_id ON user_social(user_id);

CREATE INDEX idx_user_profile_gender_dob
    ON user_profile (gender, date_of_birth);

CREATE INDEX idx_user_profile_male_dob
    ON user_profile(date_of_birth)
    WHERE gender = 'M';

CREATE INDEX idx_user_regdate_desc
    ON "user" (registration_date DESC);

CREATE INDEX idx_payment_card_user_id ON payment_card(user_id);

CREATE INDEX idx_lp_user_id ON loyalty_program(user_id);

CREATE INDEX idx_lp_level_id ON loyalty_program(level_id);

CREATE INDEX idx_lp_level_id_inc
    ON loyalty_program(level_id)
    INCLUDE (user_id);

CREATE INDEX idx_pa_property_id ON property_amenity(property_id);

CREATE INDEX idx_pa_property_amenity ON property_amenity(property_id, amenity_id);

CREATE INDEX idx_payment_booking_id ON payment(booking_id);

CREATE INDEX idx_booking_user_id ON booking(user_id);