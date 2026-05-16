package com.zezcloud.api.infrastructure.web;

import com.zezcloud.api.domain.infrastructure.entity.ServiceEntity;
import com.zezcloud.api.domain.infrastructure.repository.ServiceRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/services")
@RequiredArgsConstructor
public class ServiceController {

    private final ServiceRepository serviceRepository;

    @GetMapping
    public ResponseEntity<List<ServiceEntity>> listAll() {
        return ResponseEntity.ok(serviceRepository.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<ServiceEntity> getById(@PathVariable Long id) {
        return serviceRepository.findById(id)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<ServiceEntity> create(@Valid @RequestBody CreateServiceRequest request) {
        ServiceEntity entity = new ServiceEntity();
        entity.setName(request.name());
        entity.setStatus("ACTIVE");
        return ResponseEntity.status(HttpStatus.CREATED).body(serviceRepository.save(entity));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        if (!serviceRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        serviceRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    public record CreateServiceRequest(@NotBlank String name) {}
}
