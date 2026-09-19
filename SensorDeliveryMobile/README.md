# Sensor Delivery - Aplicativo Mobile (React Native / Expo)

Aplicativo mobile do **Sensor Delivery** portado do Delphi FireMonkey para **React Native (Expo com TypeScript)**, mantendo a exata identidade visual, tokens de cores, fluxos e funcionalidades do aplicativo original.

---

## 🎨 Design & Layout (Fiel ao Delphi)
- **Cores & Tokens:** Laranja `#FF4B0A`, Sucesso `#24A865`, Erro `#E84D4D`, Background `#F8F9FA`.
- **Navegação em Abas:**
  1. 🍕 **Cardápio:** Seletor de categorias em pills horizontais, busca em tempo real, lista de pizzas e produtos com badges, barra flutuante de carrinho.
  2. 🛍️ **Carrinho:** Lista detalhada de itens com sabores combinados, bordas recheadas, observações, ajuste de quantidade e subtotal.
  3. 🕒 **Pedidos:** Histórico completo de pedidos realizados pelo cliente com status visual e atalho para rastreamento.
  4. 👤 **Conta:** Dados cadastrais do cliente, endereço padrão e configuração da URL do servidor API.

---

## 🚀 Fluxos Implementados

1. **Tela de Entrada da Loja (`StoreEntranceScreen` / `uFrameEntradaLoja`):**
   - Logo, nome da loja, cidade/UF, status Aberto/Fechado com horário de funcionamento e estimativa de entrega.
   - Tratamento offline amigável para permitir navegar no cardápio mesmo se a loja estiver fora do horário.

2. **Montagem de Pizza (`PizzaBuilderModal` / `uFrameMontarPizza`):**
   - Seleção de Tamanho (P, M, G, GG) com limite de sabores.
   - Seleção múltipla de Sabores com cálculo pela regra da pizzaria (maior valor de sabor).
   - Seleção de Borda Recheada.
   - Campo de observação e seletor de quantidade.

3. **Finalização do Pedido (`CheckoutScreen` / `uFrameFinalizarPedido`):**
   - Alternância entre **Delivery** e **Retirada no Balcão**.
   - Busca automática de endereço por CEP (ViaCEP) com persistência no armazenamento local (`AsyncStorage`).
   - Formas de Pagamento: **PIX**, **Dinheiro** (com campo de troco) e **Cartão na Entrega**.

4. **Pagamento PIX com Polling (`PixPaymentScreen` / `uFramePagamentoPix`):**
   - Exibição do QR Code em imagem base64.
   - Botão para copiar o código PIX Copia e Cola com 1 toque (Clipboard).
   - Polling periódico a cada 4 segundos checando confirmação no backend.

5. **Acompanhamento do Pedido em Tempo Real (`OrderTrackingScreen` / `uFrameAcompanharPedido`):**
   - Stepper vertical visual: *Recebido -> Confirmado -> Em Preparo -> Saiu para Entrega -> Entregue*.
   - Atualização automática em tempo real.

---

## 🛠️ Como Executar

### 1. Iniciar o Servidor de Desenvolvimento
No diretório `SensorDeliveryMobile`:
```bash
npm start
# ou
npx expo start
```

### 2. Rodar no Celular Físico
Abra o app **Expo Go** (Android ou iOS) e leia o QR Code gerado no terminal.

### 3. Rodar no Emulador Android
```bash
npm run android
```

### 4. Gerar Build de Produção (.AAB para Google Play)
```bash
npx eas build -p android --profile production
```
