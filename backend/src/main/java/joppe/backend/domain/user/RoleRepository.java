package joppe.backend.domain.user;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface RoleRepository extends JpaRepository<Role, Integer> {

    Optional<Role> findByRoleName(String roleName);

    boolean existsByRoleName(String roleName);

    @Query("SELECT r.roleName FROM Role r WHERE r.id = :id")
    Optional<String> findRoleNameById(@Param("id") Integer id);
}
