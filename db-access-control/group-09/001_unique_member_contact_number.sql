ALTER TABLE members
ADD CONSTRAINT members_contact_number_unique UNIQUE (contact_number);
