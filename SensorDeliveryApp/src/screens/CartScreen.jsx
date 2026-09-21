import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { ArrowLeft, Trash2, Plus, Minus, ShoppingBag, ArrowRight } from 'lucide-react-native';
import { THEME } from '../constants/theme';
import { useCart } from '../contexts/CartContext';

export const CartScreen = ({ onBack, onCheckout }) => {
  const { itens, removerItem, atualizarQuantidade, limparCarrinho, subtotal } = useCart();

  const renderItem = ({ item }) => {
    return (
      <View style={styles.itemCard}>
        <View style={styles.itemMain}>
          <View style={styles.itemHeader}>
            <Text style={styles.itemName}>{item.nome}</Text>
            <TouchableOpacity
              onPress={() => removerItem(item.id)}
              style={styles.deleteButton}
            >
              <Trash2 size={16} color={THEME.colors.danger} />
            </TouchableOpacity>
          </View>

          {/* Sabores */}
          {item.sabores && item.sabores.length > 0 && (
            <Text style={styles.itemDetails}>
              🍕 Sabores: {item.sabores.map((s) => s.nome).join(' / ')}
            </Text>
          )}

          {/* Borda */}
          {item.borda && item.borda.id !== 'sem_borda' && (
            <Text style={styles.itemDetails}>
              🧀 Borda: {item.borda.nome}
            </Text>
          )}

          {/* Observação */}
          {item.observacao ? (
            <Text style={styles.itemObs}>Obs: {item.observacao}</Text>
          ) : null}

          {/* Preço e Controle */}
          <View style={styles.itemFooter}>
            <Text style={styles.itemPrice}>
              R$ {(item.precoUnitario * item.quantidade).toFixed(2).replace('.', ',')}
            </Text>

            <View style={styles.qtyContainer}>
              <TouchableOpacity
                style={styles.qtyBtn}
                onPress={() => atualizarQuantidade(item.id, -1)}
              >
                <Minus size={14} color={THEME.colors.textPrimary} />
              </TouchableOpacity>
              <Text style={styles.qtyText}>{item.quantidade}</Text>
              <TouchableOpacity
                style={styles.qtyBtn}
                onPress={() => atualizarQuantidade(item.id, 1)}
              >
                <Plus size={14} color={THEME.colors.textPrimary} />
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </View>
    );
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <View style={styles.header}>
        <TouchableOpacity onPress={onBack} style={styles.backButton}>
          <ArrowLeft size={22} color={THEME.colors.textPrimary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Meu Carrinho</Text>
        {itens.length > 0 ? (
          <TouchableOpacity onPress={limparCarrinho}>
            <Text style={styles.clearText}>Limpar</Text>
          </TouchableOpacity>
        ) : (
          <View style={{ width: 40 }} />
        )}
      </View>

      {itens.length === 0 ? (
        <View style={styles.emptyContainer}>
          <View style={styles.emptyIconCircle}>
            <ShoppingBag size={48} color={THEME.colors.textMuted} />
          </View>
          <Text style={styles.emptyTitle}>Seu carrinho está vazio</Text>
          <Text style={styles.emptyDesc}>
            Adicione itens saborosos do nosso cardápio para continuar!
          </Text>
          <TouchableOpacity style={styles.backToMenuBtn} onPress={onBack}>
            <Text style={styles.backToMenuText}>Ver Cardápio</Text>
          </TouchableOpacity>
        </View>
      ) : (
        <>
          <FlatList
            data={itens}
            keyExtractor={(item) => item.id}
            renderItem={renderItem}
            contentContainerStyle={styles.listContent}
            showsVerticalScrollIndicator={false}
          />

          <View style={styles.summaryContainer}>
            <View style={styles.summaryRow}>
              <Text style={styles.summaryLabel}>Subtotal</Text>
              <Text style={styles.summaryValue}>
                R$ {subtotal.toFixed(2).replace('.', ',')}
              </Text>
            </View>

            <TouchableOpacity
              style={styles.checkoutBtn}
              onPress={onCheckout}
              activeOpacity={0.88}
            >
              <Text style={styles.checkoutBtnText}>Continuar para Entrega</Text>
              <ArrowRight size={20} color={THEME.colors.white} />
            </TouchableOpacity>
          </View>
        </>
      )}
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: THEME.colors.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingVertical: 14,
    backgroundColor: THEME.colors.card,
    borderBottomWidth: 1,
    borderColor: THEME.colors.borderLight,
  },
  backButton: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: THEME.colors.background,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: THEME.colors.textPrimary,
  },
  clearText: {
    fontSize: 13,
    color: THEME.colors.danger,
    fontWeight: '600',
  },
  listContent: {
    padding: 20,
    gap: 12,
  },
  itemCard: {
    backgroundColor: THEME.colors.card,
    borderRadius: THEME.borderRadius.lg,
    padding: 16,
    borderWidth: 1,
    borderColor: THEME.colors.borderLight,
    ...THEME.shadows.card,
  },
  itemMain: {
    flex: 1,
  },
  itemHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 6,
  },
  itemName: {
    fontSize: 15,
    fontWeight: '700',
    color: THEME.colors.textPrimary,
    flex: 1,
    marginRight: 8,
  },
  deleteButton: {
    padding: 4,
  },
  itemDetails: {
    fontSize: 13,
    color: THEME.colors.textSecondary,
    marginBottom: 2,
  },
  itemObs: {
    fontSize: 12,
    color: THEME.colors.textMuted,
    fontStyle: 'italic',
    marginTop: 4,
  },
  itemFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 12,
    paddingTop: 10,
    borderTopWidth: 1,
    borderColor: THEME.colors.borderLight,
  },
  itemPrice: {
    fontSize: 16,
    fontWeight: '800',
    color: THEME.colors.primary,
  },
  qtyContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: THEME.colors.background,
    borderRadius: THEME.borderRadius.md,
    borderWidth: 1,
    borderColor: THEME.colors.borderLight,
    paddingHorizontal: 4,
    paddingVertical: 2,
  },
  qtyBtn: {
    width: 28,
    height: 28,
    alignItems: 'center',
    justifyContent: 'center',
  },
  qtyText: {
    fontSize: 14,
    fontWeight: '700',
    color: THEME.colors.textPrimary,
    paddingHorizontal: 8,
  },
  emptyContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
  },
  emptyIconCircle: {
    width: 90,
    height: 90,
    borderRadius: 45,
    backgroundColor: THEME.colors.card,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 20,
    ...THEME.shadows.card,
  },
  emptyTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: THEME.colors.textPrimary,
    marginBottom: 8,
  },
  emptyDesc: {
    fontSize: 14,
    color: THEME.colors.textSecondary,
    textAlign: 'center',
    marginBottom: 24,
    lineHeight: 20,
  },
  backToMenuBtn: {
    backgroundColor: THEME.colors.primary,
    paddingHorizontal: 24,
    paddingVertical: 14,
    borderRadius: THEME.borderRadius.md,
  },
  backToMenuText: {
    color: THEME.colors.white,
    fontSize: 14,
    fontWeight: '700',
  },
  summaryContainer: {
    backgroundColor: THEME.colors.card,
    paddingHorizontal: 20,
    paddingTop: 16,
    paddingBottom: 20,
    borderTopWidth: 1,
    borderColor: THEME.colors.border,
    borderTopLeftRadius: THEME.borderRadius.xl,
    borderTopRightRadius: THEME.borderRadius.xl,
    ...THEME.shadows.floating,
  },
  summaryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  summaryLabel: {
    fontSize: 15,
    color: THEME.colors.textSecondary,
    fontWeight: '600',
  },
  summaryValue: {
    fontSize: 20,
    fontWeight: '800',
    color: THEME.colors.textPrimary,
  },
  checkoutBtn: {
    backgroundColor: THEME.colors.primary,
    borderRadius: THEME.borderRadius.xl,
    height: 48,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 8,
    ...THEME.shadows.button,
  },
  checkoutBtnText: {
    color: THEME.colors.white,
    fontSize: 15,
    fontWeight: '700',
  },
});
