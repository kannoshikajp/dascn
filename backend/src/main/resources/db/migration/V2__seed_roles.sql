INSERT INTO roles (role_name, description) VALUES
    ('ROLE_CUSTOMER', 'Standard customer account'),
    ('ROLE_STAFF', 'Staff account for warehouse and order handling'),
    ('ROLE_ADMIN', 'Administrator with full system privileges')
ON CONFLICT (role_name) DO NOTHING;
