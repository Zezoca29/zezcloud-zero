package com.zezcloud;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@SpringBootApplication
@RestController
public class ZezCloudApplication {

    public static void main(String[] args) {
        SpringApplication.run(ZezCloudApplication.class, args);
    }

    @GetMapping("/")
    public Map<String, String> index() {
        return Map.of("message", "ZezCloud Zero API", "status", "running");
    }
}
