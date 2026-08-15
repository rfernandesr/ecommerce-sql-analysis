-- ============================================================
-- PERGUNTA DE NEGÓCIO
-- Qual o volume geral de pedidos processados, e como esse volume
-- está distribuído entre os status? Existe algum problema de
-- volume de cancelamento que precise de atenção?
-- ============================================================


-- 1. Volume geral de pedidos por status
-- Objetivo: entender a distribuição total de pedidos entre os
-- diferentes status (entregue, cancelado, em processamento etc.)

SELECT 
    order_status, 
    COUNT(*) AS total_por_status
FROM 
    ecommerce_analytics.orders
GROUP BY order_status
ORDER BY total_por_status DESC;

-- Total geral de pedidos, para referência
SELECT COUNT(*) AS total_pedidos
FROM ecommerce_analytics.orders;

-- Resultado: de 99.441 pedidos totais, 625 foram cancelados (~0,63%).


-- 2. Taxa de cancelamento por mês
-- Objetivo: verificar se os cancelamentos estão concentrados em
-- algum período específico, ou distribuídos igualmente ao longo do tempo

WITH total_pedidos_mes AS (
    SELECT 
        COUNT(*) AS total_pedidos,
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS mes_ano
    FROM ecommerce_analytics.orders
    GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
),
cancelados_por_mes AS (
    SELECT 
        COUNT(*) AS total_cancelados,
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS mes_ano
    FROM ecommerce_analytics.orders
    WHERE order_status = 'canceled'
    GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
)
SELECT
    tpm.mes_ano,
    tpm.total_pedidos,
    COALESCE(cm.total_cancelados, 0) AS total_cancelados,
    COALESCE(cm.total_cancelados, 0) / tpm.total_pedidos * 100 AS taxa_cancelamento
FROM total_pedidos_mes AS tpm
LEFT JOIN cancelados_por_mes AS cm 
    ON tpm.mes_ano = cm.mes_ano
ORDER BY tpm.mes_ano;

-- Resultado inicial: agosto/2018 aparentava ser o pico de cancelamentos (84 pedidos).
-- Porém, ao calcular a TAXA (não só o número absoluto), alguns meses de borda
-- do dataset (set/2016, out/2016, set/2018, out/2016) mostraram taxas de até 100%,
-- causadas por volume muito baixo de pedidos (ex: 4 pedidos no mês, 1 cancelado = 25%).
-- Esses meses foram tratados como ruído estatístico, não como tendência real,
-- e excluídos da leitura de tendência por terem volume insuficiente
-- (critério adotado: meses de borda do dataset, com poucas dezenas de pedidos ou menos).


-- 3. Taxa de cancelamento por ano (comparação mais robusta)
-- Objetivo: confirmar com dado agregado se o aumento de cancelamentos 
-- acompanha o crescimento natural do negócio, ou cresce desproporcionalmente

WITH total_pedidos_ano AS (
    SELECT 
        COUNT(*) AS total_pedidos,
        DATE_FORMAT(order_purchase_timestamp, '%Y') AS ano
    FROM ecommerce_analytics.orders
    GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y')
),
cancelados_por_ano AS (
    SELECT 
        COUNT(*) AS total_cancelados,
        DATE_FORMAT(order_purchase_timestamp, '%Y') AS ano
    FROM ecommerce_analytics.orders
    WHERE order_status = 'canceled'
    GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y')
)
SELECT
    tpa.ano,
    tpa.total_pedidos,
    COALESCE(ca.total_cancelados, 0) AS total_cancelados,
    COALESCE(ca.total_cancelados, 0) / tpa.total_pedidos * 100 AS taxa_cancelamento
FROM total_pedidos_ano AS tpa
LEFT JOIN cancelados_por_ano AS ca 
    ON tpa.ano = ca.ano
ORDER BY tpa.ano;


-- ============================================================
-- CONCLUSÃO
-- ============================================================
-- Desconsiderei 2016 da análise por ser, provavelmente, o ano de inauguração da operação (apenas 329 pedidos no total, volume insuficiente para representar um padrão confiável)
-- Entre 2017 e 2018, houve crescimento tanto no volume de pedidos quanto no volume de cancelamentos, na taxa geral próxima do esperado ao se comparar os dois anos. Os pontos de atenção reais estão em picos
-- pontuais dentro de 2018 (destacadamente agosto), que merecem investigação qualitativa (ex: problema logístico ou operacional específico daquele mês), mais do que uma tendência estrutural de alta.
-- ============================================================
