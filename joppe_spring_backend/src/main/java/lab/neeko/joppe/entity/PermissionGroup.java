package lab.neeko.joppe.entity;

import jakarta.persistence.*;
import lombok.*;
import java.util.List;

@Entity
@Table(name = "permission_groups")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PermissionGroup {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    // e.g., "USER", "REGISTER_USER", "SELL", "ACCOUNTANT", "ADMIN"
    @Column(name = "group_name", length = 50, nullable = false, unique = true)
    private String groupName;

    @Column(name = "description", length = 255)
    private String description;

    @OneToMany(mappedBy = "permissionGroup", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Permission> permissions;
}
