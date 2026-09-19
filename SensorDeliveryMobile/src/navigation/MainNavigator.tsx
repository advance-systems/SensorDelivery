import React, { useState } from 'react';
import { View, StyleSheet, TouchableOpacity, Text } from 'react-native';
import { UtensilsCrossed, ShoppingBag, Clock, User } from 'lucide-react-native';
import { THEME } from '../constants/theme';
import { useCart } from '../contexts/CartContext';
import { HomeScreen } from '../screens/HomeScreen';
import { CartScreen } from '../screens/CartScreen';
import { OrderHistoryScreen } from '../screens/OrderHistoryScreen';
import { AccountScreen } from '../screens/AccountScreen';
import { StoreEntranceScreen } from '../screens/StoreEntranceScreen';
import { CheckoutScreen } from '../screens/CheckoutScreen';
import { PixPaymentScreen } from '../screens/PixPaymentScreen';
import { OrderTrackingScreen } from '../screens/OrderTrackingScreen';
import { PizzaBuilderModal } from '../components/PizzaBuilderModal';
import { Produto, PedidoResponse } from '../types';

type Tab = 'CARDAPIO' | 'CARRINHO' | 'PEDIDOS' | 'CONTA';

export const MainNavigator: React.FC = () => {
  const { totalItens } = useCart();

  // Estados de navegação principal
  const [activeTab, setActiveTab] = useState<Tab>('CARDAPIO');
  const [inEntrance, setInEntrance] = useState(true);

  // Estados modais / fluxos adicionais
  const [produtoModal, setProdutoModal] = useState<Produto | null>(null);
  const [inCheckout, setInCheckout] = useState(false);
  const [pixPedido, setPixPedido] = useState<PedidoResponse | null>(null);
  const [trackingPedidoId, setTrackingPedidoId] = useState<string | null>(null);

  // Se estiver na tela de entrada da loja (uFrameEntradaLoja)
  if (inEntrance) {
    return <StoreEntranceScreen onEnter={() => setInEntrance(false)} />;
  }

  // Se estiver na tela de acompanhamento de pedido
  if (trackingPedidoId) {
    return (
      <OrderTrackingScreen
        pedidoId={trackingPedidoId}
        onBack={() => setTrackingPedidoId(null)}
        onGoHome={() => {
          setTrackingPedidoId(null);
          setActiveTab('CARDAPIO');
        }}
      />
    );
  }

  // Se estiver no fluxo de pagamento PIX
  if (pixPedido) {
    return (
      <PixPaymentScreen
        pedido={pixPedido}
        onPaymentConfirmed={(pedido) => {
          setPixPedido(null);
          setTrackingPedidoId(pedido.id);
        }}
        onTrackOrder={(pedido) => {
          const id = pedido.id;
          setPixPedido(null);
          setTrackingPedidoId(id);
        }}
      />
    );
  }

  // Se estiver no checkout
  if (inCheckout) {
    return (
      <CheckoutScreen
        onBack={() => setInCheckout(false)}
        onOrderSuccess={(pedido) => {
          setInCheckout(false);
          if (pedido.formaPagamento === 'PIX' && pedido.pix) {
            setPixPedido(pedido);
          } else {
            setTrackingPedidoId(pedido.id);
          }
        }}
      />
    );
  }

  return (
    <View style={styles.container}>
      {/* Conteúdo da Aba */}
      <View style={styles.content}>
        {activeTab === 'CARDAPIO' && (
          <HomeScreen
            onOpenProduct={(prod) => setProdutoModal(prod)}
            onOpenCart={() => setActiveTab('CARRINHO')}
          />
        )}
        {activeTab === 'CARRINHO' && (
          <CartScreen
            onBack={() => setActiveTab('CARDAPIO')}
            onCheckout={() => setInCheckout(true)}
          />
        )}
        {activeTab === 'PEDIDOS' && (
          <OrderHistoryScreen
            onSelectOrder={(id) => setTrackingPedidoId(id)}
            onBackToMenu={() => setActiveTab('CARDAPIO')}
          />
        )}
        {activeTab === 'CONTA' && <AccountScreen />}
      </View>

      {/* Modal de Personalização de Pizza */}
      <PizzaBuilderModal
        visible={!!produtoModal}
        produto={produtoModal}
        onClose={() => setProdutoModal(null)}
      />

      {/* Bottom Navigation Bar */}
      <View style={styles.tabBar}>
        <TouchableOpacity
          style={styles.tabItem}
          onPress={() => setActiveTab('CARDAPIO')}
          activeOpacity={0.8}
        >
          <UtensilsCrossed
            size={22}
            color={activeTab === 'CARDAPIO' ? THEME.colors.primary : THEME.colors.textSecondary}
          />
          <Text
            style={[
              styles.tabText,
              activeTab === 'CARDAPIO' && styles.tabTextActive,
            ]}
          >
            Cardápio
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.tabItem}
          onPress={() => setActiveTab('CARRINHO')}
          activeOpacity={0.8}
        >
          <View>
            <ShoppingBag
              size={22}
              color={activeTab === 'CARRINHO' ? THEME.colors.primary : THEME.colors.textSecondary}
            />
            {totalItens > 0 && (
              <View style={styles.cartBadge}>
                <Text style={styles.cartBadgeText}>{totalItens}</Text>
              </View>
            )}
          </View>
          <Text
            style={[
              styles.tabText,
              activeTab === 'CARRINHO' && styles.tabTextActive,
            ]}
          >
            Carrinho
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.tabItem}
          onPress={() => setActiveTab('PEDIDOS')}
          activeOpacity={0.8}
        >
          <Clock
            size={22}
            color={activeTab === 'PEDIDOS' ? THEME.colors.primary : THEME.colors.textSecondary}
          />
          <Text
            style={[
              styles.tabText,
              activeTab === 'PEDIDOS' && styles.tabTextActive,
            ]}
          >
            Pedidos
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.tabItem}
          onPress={() => setActiveTab('CONTA')}
          activeOpacity={0.8}
        >
          <User
            size={22}
            color={activeTab === 'CONTA' ? THEME.colors.primary : THEME.colors.textSecondary}
          />
          <Text
            style={[
              styles.tabText,
              activeTab === 'CONTA' && styles.tabTextActive,
            ]}
          >
            Conta
          </Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: THEME.colors.background,
  },
  content: {
    flex: 1,
  },
  tabBar: {
    flexDirection: 'row',
    backgroundColor: THEME.colors.card,
    borderTopWidth: 1,
    borderColor: THEME.colors.borderLight,
    paddingTop: 8,
    paddingBottom: 14,
    ...THEME.shadows.floating,
  },
  tabItem: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 4,
  },
  tabText: {
    fontSize: 11,
    fontWeight: '600',
    color: THEME.colors.textSecondary,
  },
  tabTextActive: {
    color: THEME.colors.primary,
    fontWeight: '700',
  },
  cartBadge: {
    position: 'absolute',
    top: -4,
    right: -8,
    backgroundColor: THEME.colors.primary,
    borderRadius: 8,
    width: 16,
    height: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  cartBadgeText: {
    color: THEME.colors.white,
    fontSize: 9,
    fontWeight: '800',
  },
});
