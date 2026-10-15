-- =============================================================================
-- Migration V4: Add ROLE_MANAGE permission for RBAC management
-- =============================================================================

INSERT INTO permissions (permission_name, description) VALUES
    ('ROLE_MANAGE', 'Manage roles and configure permission mappings')
ON CONFLICT (permission_name) DO NOTHING;

-- Assign to ROLE_ADMIN
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.role_name = 'ROLE_ADMIN'
  AND p.permission_name = 'ROLE_MANAGE'
ON CONFLICT DO NOTHING;
