package joppe.backend.domain.user;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PermissionRepository extends JpaRepository<Permission, Integer> {

    Optional<Permission> findByPermissionName(String permissionName);

    boolean existsByPermissionName(String permissionName);

    @Query("SELECT p.permissionName FROM Permission p JOIN RolePermission rp ON p.id = rp.id.permissionId WHERE rp.id.roleId = :roleId")
    List<String> findPermissionNamesByRoleId(@Param("roleId") Integer roleId);

    @Query("SELECT p.permissionName FROM Permission p JOIN RolePermission rp ON p.id = rp.id.permissionId JOIN Role r ON r.id = rp.id.roleId WHERE r.roleName = :roleName")
    List<String> findPermissionNamesByRoleName(@Param("roleName") String roleName);
}
