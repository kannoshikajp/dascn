-- =============================================================================
-- Migration V5: Add ROLE_NON_LOGIN and Guest Permissions
-- =============================================================================

-- 1. Insert new granular permissions
INSERT INTO permissions (permission_name, description) VALUES
    ('REVIEW_READ', 'View approved product reviews and customer ratings'),
    ('PC_BUILD_SIMULATE', 'Simulate PC builds and run component compatibility check without saving'),
    ('ORDER_TRACK_GUEST', 'Track shipment and order status using tracking number and phone')
ON CONFLICT (permission_name) DO NOTHING;

-- 2. Insert ROLE_NON_LOGIN
INSERT INTO roles (role_name, description) VALUES
    ('ROLE_NON_LOGIN', 'Anonymous or guest visitor with public browsing privileges')
ON CONFLICT (role_name) DO NOTHING;

-- 3. Map guest permissions to ROLE_NON_LOGIN
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_name = 'ROLE_NON_LOGIN'
  AND p.permission_name IN (
      'CATALOG_READ',
      'PROMOTION_READ',
      'REVIEW_READ',
      'PC_BUILD_SIMULATE',
      'ORDER_TRACK_GUEST'
  )
ON CONFLICT DO NOTHING;

-- 4. Grant new reading/simulation permissions to existing authenticated roles
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_name IN ('ROLE_CUSTOMER', 'ROLE_STAFF', 'ROLE_ADMIN')
  AND p.permission_name IN (
      'REVIEW_READ',
      'PC_BUILD_SIMULATE',
      'ORDER_TRACK_GUEST'
  )
ON CONFLICT DO NOTHING;
