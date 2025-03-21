-- Таблица клиентов (уже должна быть в системе)
CREATE TABLE clients (
    client_id VARCHAR(36) PRIMARY KEY,
    /* Остальные поля */
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Таблица для типов блокировок
CREATE TABLE block_types (
    block_type_id VARCHAR(20) PRIMARY KEY,
    description VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Добавляем два основных типа блокировок
INSERT INTO block_types (block_type_id, description) 
VALUES 
    ('FRAUD_SUSPICION', 'Client suspected of fraudulent activity'),
    ('WRONG_DETAILS', 'Client provided incorrect payment details');

-- Таблица для самих блокировок платежей
CREATE TABLE payment_blocks (
    block_id VARCHAR(36) PRIMARY KEY,
    client_id VARCHAR(36) NOT NULL,
    block_type_id VARCHAR(20) NOT NULL,
    reason TEXT NOT NULL,
    expected_resolution_date TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(36) NOT NULL,
    ended_at TIMESTAMP NULL,
    ended_by VARCHAR(36) NULL,
    resolution_notes TEXT NULL,
    
    FOREIGN KEY (client_id) REFERENCES clients(client_id),
    FOREIGN KEY (block_type_id) REFERENCES block_types(block_type_id),
    INDEX idx_client_block (client_id, block_type_id, ended_at),
    INDEX idx_active_blocks (client_id, ended_at)
);

-- Удобное представление для использования в запросах где необходимы активные блокировки
CREATE VIEW active_payment_blocks AS
SELECT 
    pb.*,
    bt.description as block_type_description
FROM 
    payment_blocks pb
JOIN 
    block_types bt ON pb.block_type_id = bt.block_type_id
WHERE 
    pb.ended_at IS NULL;

-- Примеры запросов:

-- Проверяем если у клиента активные блокировки
SELECT EXISTS(
    SELECT 1 FROM payment_blocks 
    WHERE client_id = ? AND ended_at IS NULL
) AS is_blocked;

-- Получаем все активные блокировки клиента
SELECT * FROM active_payment_blocks
WHERE client_id = ?;

-- Получаем все активные блокировки клиента определенного типа
SELECT * FROM active_payment_blocks
WHERE client_id = ? AND block_type_id = ?;
