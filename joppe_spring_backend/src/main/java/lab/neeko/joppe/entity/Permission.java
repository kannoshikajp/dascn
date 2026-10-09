package lab.neeko.joppe.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "permissions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Permission {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "permission_name", length = 100, nullable = false, unique = true)
    private String permissionName;

    @Column(name = "description", length = 255)
    private String description;

    @Column(name = "category", length = 100)
    private String category;
}
