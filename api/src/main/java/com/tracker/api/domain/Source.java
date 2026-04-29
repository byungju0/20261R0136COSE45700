package com.tracker.api.domain;

import jakarta.persistence.*;
import lombok.Getter;
import java.time.Instant;

@Entity
@Table(name = "sources")
@Getter
public class Source {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "site_name", nullable = false, length = 50)
    private String siteName;

    @Column(name = "board_name", length = 200)
    private String boardName;

    @Column(name = "base_url", nullable = false, length = 500)
    private String baseUrl;

    @Column(name = "created_at")
    private Instant createdAt;
}
