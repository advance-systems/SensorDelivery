# Painel administrativo web

Aplicação React, TypeScript e Vite do Sensor Delivery.

## Desenvolvimento local

Na pasta SensorDeliveryAdminWeb, execute:

    npm install
    npm run dev

O arquivo .env.local aponta para a API local em http://localhost:3031/api,
que usa o banco SENSOR_DELIVERY_TESTE.

## API do cliente

Para a instalação Railway da pizzaria, configure VITE_API_URL como:

    https://api-sensordelivery.sistemassensor.com.br/api

O valor deve terminar em /api. Nunca versione .env.local, tokens ou credenciais.

## Build

    npm run build
