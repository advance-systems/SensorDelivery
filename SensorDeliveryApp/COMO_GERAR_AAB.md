# Sensor Delivery - Aplicativo Mobile (React Native CLI / .jsx)

Aplicativo mobile oficial do **Sensor Delivery** portado diretamente do Delphi FireMonkey para **React Native Nativo Puro (JavaScript / .jsx)**, sem Expo Go, com pasta `android/` completa pronta para compilar **`.aab` (Android App Bundle)** para publicação na Google Play Store.

---

## 📱 Estrutura do Projeto (100% .jsx / JS)

- `App.jsx`: Componente raiz com Safe Area e Context Providers.
- `src/constants/theme.js`: Design System idêntico ao Delphi (`#FF4B0A`, `#24A865`, `#E84D4D`, `#F8F9FA`).
- `src/services/api.js`: Conexão com a API em produção Railway (`https://sensordelivery-production.up.railway.app`) e fallback offline inteligente.
- `src/contexts/CartContext.jsx`: Gerenciador do carrinho com AsyncStorage nativo.
- `src/contexts/StoreContext.jsx`: Status de funcionamento da loja e carregamento da empresa.
- `src/screens/StoreEntranceScreen.jsx`: Tela de entrada da loja (`uFrameEntradaLoja.pas`).
- `src/screens/HomeScreen.jsx`: Cardápio com categorias em pills e busca em tempo real (`uFrameHomeMobile.pas`).
- `src/components/PizzaBuilderModal.jsx`: Montador completo de Pizza com tamanhos, múltiplos sabores e bordas (`uFrameMontarPizza.pas`).
- `src/screens/CartScreen.jsx`: Carrinho de compras com resumo e controle de itens (`uFrameCarrinho.pas`).
- `src/screens/CheckoutScreen.jsx`: Finalização de pedido com Delivery/Retirada, ViaCEP e PIX/Dinheiro/Cartão (`uFrameFinalizarPedido.pas`).
- `src/screens/PixPaymentScreen.jsx`: Tela de pagamento PIX com QR Code, botão Copia e Cola e verificação automática (`uFramePagamentoPix.pas`).
- `src/screens/OrderTrackingScreen.jsx`: Rastreamento de pedidos em tempo real com stepper vertical (`uFrameAcompanharPedido.pas`).
- `src/screens/OrderHistoryScreen.jsx`: Histórico de pedidos do cliente (`uFrameHistoricoPedidos.pas`).
- `src/screens/AccountScreen.jsx`: Tela Minha Conta e seletor da URL do servidor (`uFrameContaMobile.pas`).

---

## 🛠️ Como Gerar o `.AAB` (Para a Google Play Store)

### 1. Entrar na pasta do projeto
```bash
cd h:\Projetos\SensorDelivery\SensorDeliveryApp
```

### 2. Gerar o arquivo `.aab` de Release usando o Gradle
No Windows (PowerShell / CMD):
```bash
cd android
./gradlew bundleRelease
```

O arquivo gerado para publicar na Play Console ficará localizado em:
`android/app/build/outputs/bundle/release/app-release.aab`

---

## 🚀 Como Rodar em Modo de Desenvolvimento / Emulador

1. Iniciar o Metro Bundler:
```bash
npm start
```

2. Executar no Emulador ou Celular via cabo USB:
```bash
npx react-native run-android
```
