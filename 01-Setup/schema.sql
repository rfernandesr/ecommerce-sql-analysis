-- Dataset usado: Brazilian E-Commerce Public Dataset by Olist
-- Todos os CREATE TABLE do projeto


-- Tabela clientes
-- customer_id: chave primária, identifica cada pedido feito por um cliente
-- customer_unique_id: identifica a pessoa física, pode se repetir se ela comprou mais de uma vez
-- zip_code como VARCHAR pra preservar zero a esquerda do CEP
CREATE TABLE ecommerce_analytics.customers (
    customer_id VARCHAR(32) NOT NULL PRIMARY KEY,
    customer_unique_id VARCHAR(32) NOT NULL,
    customer_zip_code_prefix VARCHAR(5) NOT NULL,
    customer_city VARCHAR(100) NOT NULL,
    customer_state VARCHAR(2) NOT NULL
);

-- Tabela de geolocalização
-- Não possui chave primária: o mesmo CEP (zip_code_prefix) se repete em várias linhas,
-- zip_code_prefix como VARCHAR pra preservar zero à esquerda do CEP
-- lat/lng em DECIMAL(10,7)
CREATE TABLE ecommerce_analytics.geolocation (
    geolocation_zip_code_prefix VARCHAR(5) NOT NULL,
    geolocation_lat DECIMAL(10,7) NOT NULL,
    geolocation_lng DECIMAL(10,7) NOT NULL,
    geolocation_city VARCHAR(100) NOT NULL,
    geolocation_state VARCHAR(2) NOT NULL
);

-- Tabela de itens pedidos
-- Cria tabela order_items com chave primária composta
-- Cria tabela order_items (Foreign Keys serão adicionadas após criação de orders, products e sellers)
-- Chaves primárias compostas usadas quando uma única coluna não garante linha única (ex: order_items, onde um pedido pode ter vários itens)
-- Foreign keys adicionadas em etapa separada (via ALTER TABLE) após a criação de todas as tabelas, para não depender de uma ordem rígida de criação

CREATE TABLE ecommerce_analytics.order_items (
    order_id VARCHAR(32) NOT NULL,
    order_item_id INT NOT NULL,
    product_id VARCHAR(32) NOT NULL,
    seller_id VARCHAR(32) NOT NULL,
    shipping_limit_date DATETIME NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    freight_value DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id)
);


-- Tabela de pagamentos de pedidos
-- Chave primária composta: order_id + payment_sequential, pois um pedido pode ter mais de um pagamento (ex: parte no cartão, parte em voucher)
-- payment_type como ENUM: valores confirmados via filtro no Excel, apenas 5 opções fixas
CREATE TABLE ecommerce_analytics.order_payments (
    order_id VARCHAR(32) NOT NULL,
    payment_sequential INT NOT NULL,
    payment_type ENUM('credit_card', 'boleto', 'voucher', 'debit_card', 'not_defined') NOT NULL,
    payment_installments INT NOT NULL,
    payment_value DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential)
);

-- Tabela de avaliações de pedidos
-- review_comment_message como TEXT: comentário livre do cliente, sem limite de tamanho previsível
-- review_score como TINYINT: nota vai de 1 a 5, não precisa da faixa de INT
CREATE TABLE ecommerce_analytics.order_reviews (
    review_id VARCHAR(32) NOT NULL PRIMARY KEY,
    order_id VARCHAR(32) NOT NULL,
    review_score TINYINT NOT NULL,
    review_comment_title VARCHAR(100),
    review_comment_message TEXT,
    review_creation_date DATETIME NOT NULL,
    review_answer_timestamp DATETIME NOT NULL
);

-- Tabela central de pedidos
-- Datas de aprovação/entrega como NULL permitido: só recebem valor depois que o evento acontece (ex: pedido cancelado nunca terá data de entrega)
-- order_purchase_timestamp e order_estimated_delivery_date são NOT NULL: sempre existem desde a criação do pedido
-- Utilizando o ENUM novamente como validador de dados.
CREATE TABLE ecommerce_analytics.orders (
    order_id VARCHAR(32) NOT NULL PRIMARY KEY,
    customer_id VARCHAR(32) NOT NULL,
    order_status ENUM('delivered','approved','canceled','invoiced','created','processing','shipped','unavailable') NOT NULL,
    order_purchase_timestamp DATETIME NOT NULL,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME NOT NULL
);

-- Tabela de produtos
-- product_category_name e colunas de medida sem NOT NULL: dataset original tem produtos sem categoria definida e algumas medidas físicas ausentes (Confirmado usando excel)
CREATE TABLE ecommerce_analytics.products (
    product_id VARCHAR(32) NOT NULL PRIMARY KEY,
    product_category_name VARCHAR(50),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty TINYINT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

-- Tabela de vendedores
CREATE TABLE ecommerce_analytics.sellers (
    seller_id VARCHAR(32) NOT NULL PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(5) NOT NULL,
    seller_city VARCHAR(100) NOT NULL,
    seller_state VARCHAR(2) NOT NULL
);

-- Após a importação de dados, realizei a inserção das chaves estrangeiras (Foreign Keys)
-- orders depende de customers (todo pedido pertence a um cliente)
ALTER TABLE ecommerce_analytics.orders
ADD CONSTRAINT fk_orders_customer
FOREIGN KEY (customer_id) REFERENCES ecommerce_analytics.customers (customer_id);

-- order_items depende de orders, products e sellers
ALTER TABLE ecommerce_analytics.order_items
ADD CONSTRAINT fk_order_items_order
FOREIGN KEY (order_id) REFERENCES ecommerce_analytics.orders (order_id);

ALTER TABLE ecommerce_analytics.order_items
ADD CONSTRAINT fk_order_items_product
FOREIGN KEY (product_id) REFERENCES ecommerce_analytics.products (product_id);

ALTER TABLE ecommerce_analytics.order_items
ADD CONSTRAINT fk_order_items_seller
FOREIGN KEY (seller_id) REFERENCES ecommerce_analytics.sellers (seller_id);

-- order_payments depende de orders
ALTER TABLE ecommerce_analytics.order_payments
ADD CONSTRAINT fk_order_payments_order
FOREIGN KEY (order_id) REFERENCES ecommerce_analytics.orders (order_id);

-- order_reviews depende de orders
ALTER TABLE ecommerce_analytics.order_reviews
ADD CONSTRAINT fk_order_reviews_order
FOREIGN KEY (order_id) REFERENCES ecommerce_analytics.orders (order_id);
