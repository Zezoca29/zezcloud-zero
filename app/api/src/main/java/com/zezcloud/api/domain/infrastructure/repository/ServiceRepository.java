package com.zezcloud.api.domain.infrastructure.repository;

import com.zezcloud.api.domain.infrastructure.entity.ServiceEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ServiceRepository extends JpaRepository<ServiceEntity, Long> {
    List<ServiceEntity> findByStatus(String status);
}
