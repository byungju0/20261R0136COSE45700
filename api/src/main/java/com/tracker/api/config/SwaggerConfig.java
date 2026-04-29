package com.tracker.api.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SwaggerConfig {

    @Bean
    public OpenAPI trackerOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("Tracker API")
                        .version("1.0.0")
                        .description("불법 게시글 탐지 결과 조회 및 통계 API"));
    }
}
