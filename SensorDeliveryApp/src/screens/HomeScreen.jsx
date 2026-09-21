import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  TextInput,
  Image,
  ActivityIndicator,
  StatusBar,
  ScrollView,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Search, ShoppingBag, Bell, Star, Plus, Store } from 'lucide-react-native';
import { THEME } from '../constants/theme';
import { useStore } from '../contexts/StoreContext';
import { useCart } from '../contexts/CartContext';
import { ApiService } from '../services/api';

export const HomeScreen = ({ onOpenProduct, onOpenCart }) => {
  const { empresa } = useStore();
  const { totalItens, subtotal } = useCart();

  const [categorias, setCategorias] = useState([]);
  const [categoriaSelecionada, setCategoriaSelecionada] = useState('all');
  const [produtos, setProdutos] = useState([]);
  const [carregando, setCarregando] = useState(true);
  const [busca, setBusca] = useState('');
  const [emFocoBusca, setEmFocoBusca] = useState(false);

  useEffect(() => {
    carregarDados();
  }, [empresa]);

  useEffect(() => {
    carregarProdutos();
  }, [categoriaSelecionada, empresa]);

  const carregarDados = async () => {
    if (!empresa) return;
    try {
      const cats = await ApiService.getCategorias(empresa.id);
      setCategorias([{ id: 'all', nome: 'Todos' }, ...cats]);
    } catch (err) {
      console.warn('Erro ao carregar categorias:', err);
    }
  };

  const carregarProdutos = async () => {
    if (!empresa) return;
    setCarregando(true);
    try {
      const prods = await ApiService.getProdutos(empresa.id, categoriaSelecionada);
      setProdutos(prods);
    } catch (err) {
      console.warn('Erro ao carregar produtos:', err);
    } finally {
      setCarregando(false);
    }
  };

  const produtosFiltrados = produtos.filter((p) =>
    p.nome.toLowerCase().includes(busca.toLowerCase()) ||
    (p.descricao && p.descricao.toLowerCase().includes(busca.toLowerCase()))
  );

  return (
    <SafeAreaView style={styles.safeArea} edges={['top', 'left', 'right']}>
      <StatusBar barStyle="dark-content" backgroundColor={THEME.colors.background} />

      {/* Header Clássico */}
      <View style={styles.header}>
        <View style={styles.headerBrand}>
          <View style={styles.logoMini}>
            {empresa?.logoUrl ? (
              <Image source={{ uri: empresa.logoUrl }} style={styles.logoMiniImg} />
            ) : (
              <Store size={18} color={THEME.colors.primary} />
            )}
          </View>
          <View>
            <Text style={styles.headerSub}>Cardápio Digital</Text>
            <Text style={styles.headerTitle}>{empresa?.nome || 'Sensor Delivery'}</Text>
          </View>
        </View>

        <TouchableOpacity style={styles.iconButton}>
          <Bell size={18} color={THEME.colors.textPrimary} />
        </TouchableOpacity>
      </View>

      {/* Campo de Busca no Padrão SensorEdit do Delphi */}
      <View style={styles.sensorEditContainer}>
        <Text style={styles.sensorEditLabel}>Pesquisar no Cardápio</Text>
        <View
          style={[
            styles.sensorEditBox,
            emFocoBusca && styles.sensorEditBoxFocus,
          ]}
        >
          <Search
            size={18}
            color={emFocoBusca ? THEME.colors.primary : THEME.colors.textSecondary}
            style={styles.sensorEditIcon}
          />
          <TextInput
            style={styles.sensorEditInput}
            placeholder="Digite o nome ou descrição..."
            placeholderTextColor={THEME.colors.textMuted}
            value={busca}
            onChangeText={setBusca}
            onFocus={() => setEmFocoBusca(true)}
            onBlur={() => setEmFocoBusca(false)}
          />
          {emFocoBusca && <View style={styles.sensorEditFocusLine} />}
        </View>
      </View>

      {/* Categorias Pills Clássicas */}
      <View style={styles.categoriesWrapper}>
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.categoriesList}
        >
          {categorias.map((cat) => {
            const isSelected = categoriaSelecionada === cat.id;
            return (
              <TouchableOpacity
                key={cat.id}
                style={[
                  styles.categoryPill,
                  isSelected && styles.categoryPillActive,
                ]}
                onPress={() => setCategoriaSelecionada(cat.id)}
                activeOpacity={0.7}
              >
                <Text
                  style={[
                    styles.categoryPillText,
                    isSelected && styles.categoryPillTextActive,
                  ]}
                >
                  {cat.nome}
                </Text>
              </TouchableOpacity>
            );
          })}
        </ScrollView>
      </View>

      {/* Lista de Produtos */}
      {carregando ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={THEME.colors.primary} />
          <Text style={styles.loadingText}>Carregando cardápio...</Text>
        </View>
      ) : (
        <FlatList
          data={produtosFiltrados}
          keyExtractor={(item) => item.id.toString()}
          contentContainerStyle={styles.productList}
          showsVerticalScrollIndicator={false}
          renderItem={({ item }) => (
            <TouchableOpacity
              style={styles.productCard}
              onPress={() => onOpenProduct(item)}
              activeOpacity={0.85}
            >
              <View style={styles.productInfo}>
                {item.destaque && (
                  <View style={styles.badgeDestaque}>
                    <Star size={10} color={THEME.colors.warning} />
                    <Text style={styles.badgeDestaqueText}>Mais Pedido</Text>
                  </View>
                )}
                <Text style={styles.productName}>{item.nome}</Text>
                {item.descricao ? (
                  <Text style={styles.productDesc} numberOfLines={2}>
                    {item.descricao}
                  </Text>
                ) : null}
                <View style={styles.priceRow}>
                  <Text style={styles.productPrice}>
                    {item.precoPromocional && item.precoPromocional > 0
                      ? `R$ ${item.precoPromocional.toFixed(2).replace('.', ',')}`
                      : item.preco > 0
                        ? `R$ ${item.preco.toFixed(2).replace('.', ',')}`
                        : 'Consulte o valor'}
                  </Text>
                  <View style={styles.sensorAddButton}>
                    <Plus size={16} color={THEME.colors.white} />
                  </View>
                </View>
              </View>

              {item.imagemUrl ? (
                <Image
                  source={{ uri: item.imagemUrl }}
                  style={styles.productImage}
                  resizeMode="cover"
                />
              ) : (
                <View style={styles.productImagePlaceholder}>
                  <Text style={styles.placeholderEmoji}>🍕</Text>
                </View>
              )}
            </TouchableOpacity>
          )}
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Text style={styles.emptyTitle}>Nenhum item encontrado</Text>
              <Text style={styles.emptyDesc}>Tente buscar por outro termo ou categoria.</Text>
            </View>
          }
        />
      )}

      {/* Floating Cart Bar Estilo SensorButton */}
      {totalItens > 0 && (
        <View style={styles.floatingCartContainer}>
          <TouchableOpacity
            style={styles.floatingCart}
            onPress={onOpenCart}
            activeOpacity={0.9}
          >
            <View style={styles.cartCountBadge}>
              <Text style={styles.cartCountText}>{totalItens}</Text>
            </View>
            <View style={styles.cartInfo}>
              <Text style={styles.cartLabel}>Ver meu pedido</Text>
              <Text style={styles.cartValue}>
                R$ {subtotal.toFixed(2).replace('.', ',')}
              </Text>
            </View>
            <ShoppingBag size={20} color={THEME.colors.white} />
          </TouchableOpacity>
        </View>
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
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 12,
    paddingBottom: 8,
  },
  headerBrand: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  logoMini: {
    width: 36,
    height: 36,
    borderRadius: 10,
    backgroundColor: THEME.colors.primaryLight,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: THEME.colors.border,
  },
  logoMiniImg: {
    width: 34,
    height: 34,
    borderRadius: 9,
  },
  headerSub: {
    fontSize: 11,
    color: THEME.colors.textSecondary,
    fontWeight: '600',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: THEME.colors.textPrimary,
  },
  iconButton: {
    width: 38,
    height: 38,
    borderRadius: THEME.borderRadius.md,
    backgroundColor: THEME.colors.card,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: THEME.colors.border,
    ...THEME.shadows.card,
  },
  sensorEditContainer: {
    marginHorizontal: 20,
    marginTop: 8,
    marginBottom: 12,
  },
  sensorEditLabel: {
    fontSize: 11,
    fontWeight: '600',
    color: THEME.colors.textSecondary,
    marginBottom: 4,
    marginLeft: 2,
    textTransform: 'uppercase',
  },
  sensorEditBox: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: THEME.colors.inputBackground,
    borderRadius: THEME.borderRadius.md,
    paddingHorizontal: 12,
    height: 44,
    borderWidth: 1,
    borderColor: THEME.colors.inputBorder,
    overflow: 'hidden',
  },
  sensorEditBoxFocus: {
    borderColor: THEME.colors.inputBorderFocus,
    backgroundColor: THEME.colors.card,
  },
  sensorEditIcon: {
    marginRight: 8,
  },
  sensorEditInput: {
    flex: 1,
    fontSize: 14,
    color: THEME.colors.textPrimary,
    paddingVertical: 0,
  },
  sensorEditFocusLine: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    height: 2,
    backgroundColor: THEME.colors.primary,
  },
  categoriesWrapper: {
    marginBottom: 8,
  },
  categoriesList: {
    paddingHorizontal: 20,
    gap: 8,
  },
  categoryPill: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: THEME.borderRadius.xl,
    backgroundColor: THEME.colors.card,
    borderWidth: 1,
    borderColor: THEME.colors.border,
  },
  categoryPillActive: {
    backgroundColor: THEME.colors.primary,
    borderColor: THEME.colors.primary,
  },
  categoryPillText: {
    fontSize: 13,
    fontWeight: '600',
    color: THEME.colors.textSecondary,
  },
  categoryPillTextActive: {
    color: THEME.colors.white,
  },
  productList: {
    paddingHorizontal: 20,
    paddingTop: 6,
    paddingBottom: 100,
    gap: 12,
  },
  productCard: {
    backgroundColor: THEME.colors.card,
    borderRadius: THEME.borderRadius.lg,
    padding: 14,
    flexDirection: 'row',
    borderWidth: 1,
    borderColor: THEME.colors.border,
    ...THEME.shadows.card,
    justifyContent: 'space-between',
  },
  productInfo: {
    flex: 1,
    marginRight: 12,
    justifyContent: 'space-between',
  },
  badgeDestaque: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: THEME.colors.warningLight,
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: THEME.borderRadius.xs,
    alignSelf: 'flex-start',
    marginBottom: 4,
  },
  badgeDestaqueText: {
    fontSize: 10,
    fontWeight: '700',
    color: '#B45309',
  },
  productName: {
    fontSize: 15,
    fontWeight: '700',
    color: THEME.colors.textPrimary,
    marginBottom: 4,
  },
  productDesc: {
    fontSize: 12,
    color: THEME.colors.textSecondary,
    lineHeight: 16,
    marginBottom: 8,
  },
  priceRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 4,
  },
  productPrice: {
    fontSize: 15,
    fontWeight: '800',
    color: THEME.colors.primary,
  },
  sensorAddButton: {
    width: 32,
    height: 32,
    borderRadius: THEME.borderRadius.md,
    backgroundColor: THEME.colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    ...THEME.shadows.button,
  },
  productImage: {
    width: 86,
    height: 86,
    borderRadius: THEME.borderRadius.md,
  },
  productImagePlaceholder: {
    width: 86,
    height: 86,
    borderRadius: THEME.borderRadius.md,
    backgroundColor: THEME.colors.inputBackground,
    alignItems: 'center',
    justifyContent: 'center',
  },
  placeholderEmoji: {
    fontSize: 30,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 12,
    fontSize: 14,
    color: THEME.colors.textSecondary,
  },
  emptyContainer: {
    alignItems: 'center',
    paddingVertical: 60,
  },
  emptyTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: THEME.colors.textPrimary,
  },
  emptyDesc: {
    fontSize: 13,
    color: THEME.colors.textSecondary,
    marginTop: 4,
  },
  floatingCartContainer: {
    position: 'absolute',
    bottom: 20,
    left: 20,
    right: 20,
  },
  floatingCart: {
    backgroundColor: THEME.colors.primary,
    borderRadius: THEME.borderRadius.xl,
    paddingVertical: 14,
    paddingHorizontal: 18,
    flexDirection: 'row',
    alignItems: 'center',
    ...THEME.shadows.floating,
  },
  cartCountBadge: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: 'rgba(255,255,255,0.25)',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  cartCountText: {
    color: THEME.colors.white,
    fontWeight: '800',
    fontSize: 13,
  },
  cartInfo: {
    flex: 1,
  },
  cartLabel: {
    fontSize: 12,
    color: 'rgba(255,255,255,0.85)',
    fontWeight: '500',
  },
  cartValue: {
    fontSize: 16,
    color: THEME.colors.white,
    fontWeight: '800',
  },
});
