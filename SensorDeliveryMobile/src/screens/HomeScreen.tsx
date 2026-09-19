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
import { Search, ShoppingBag, Bell, Star, Plus } from 'lucide-react-native';
import { THEME } from '../constants/theme';
import { useStore } from '../contexts/StoreContext';
import { useCart } from '../contexts/CartContext';
import { ApiService } from '../services/api';
import { Categoria, Produto } from '../types';

interface HomeScreenProps {
  onOpenProduct: (produto: Produto) => void;
  onOpenCart: () => void;
}

export const HomeScreen: React.FC<HomeScreenProps> = ({ onOpenProduct, onOpenCart }) => {
  const { empresa } = useStore();
  const { totalItens, subtotal } = useCart();

  const [categorias, setCategorias] = useState<Categoria[]>([]);
  const [categoriaSelecionada, setCategoriaSelecionada] = useState<string>('all');
  const [produtos, setProdutos] = useState<Produto[]>([]);
  const [carregando, setCarregando] = useState(true);
  const [busca, setBusca] = useState('');

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

      {/* Header Topo */}
      <View style={styles.header}>
        <View>
          <Text style={styles.headerSub}>Cardápio Digital</Text>
          <Text style={styles.headerTitle}>{empresa?.nome || 'Sensor Delivery'}</Text>
        </View>
        <TouchableOpacity style={styles.iconButton}>
          <Bell size={20} color={THEME.colors.textPrimary} />
        </TouchableOpacity>
      </View>

      {/* Barra de Busca */}
      <View style={styles.searchContainer}>
        <Search size={18} color={THEME.colors.textSecondary} style={styles.searchIcon} />
        <TextInput
          style={styles.searchInput}
          placeholder="Buscar no cardápio..."
          placeholderTextColor={THEME.colors.textMuted}
          value={busca}
          onChangeText={setBusca}
        />
      </View>

      {/* Lista Horizontal de Categorias */}
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

      {/* Lista de Produtos (Grid / List matching Delphi uFrameHomeMobile) */}
      {carregando ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={THEME.colors.primary} />
          <Text style={styles.loadingText}>Carregando cardápio...</Text>
        </View>
      ) : (
        <FlatList
          data={produtosFiltrados}
          keyExtractor={(item) => item.id}
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
                    {item.preco > 0
                      ? `R$ ${item.preco.toFixed(2).replace('.', ',')}`
                      : 'A partir de R$ 35,00'}
                  </Text>
                  <View style={styles.addButton}>
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

      {/* Floating Cart Bar (uFrameHomeMobile / Bottom Bar) */}
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
  headerSub: {
    fontSize: 12,
    color: THEME.colors.textSecondary,
    fontWeight: '600',
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '800',
    color: THEME.colors.textPrimary,
  },
  iconButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: THEME.colors.card,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: THEME.colors.borderLight,
  },
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: THEME.colors.card,
    borderRadius: THEME.borderRadius.md,
    marginHorizontal: 20,
    marginVertical: 12,
    paddingHorizontal: 14,
    height: 48,
    borderWidth: 1,
    borderColor: THEME.colors.borderLight,
    ...THEME.shadows.card,
  },
  searchIcon: {
    marginRight: 10,
  },
  searchInput: {
    flex: 1,
    fontSize: 14,
    color: THEME.colors.textPrimary,
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
    borderRadius: THEME.borderRadius.full,
    backgroundColor: THEME.colors.card,
    borderWidth: 1,
    borderColor: THEME.colors.borderLight,
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
    paddingTop: 8,
    paddingBottom: 100,
    gap: 14,
  },
  productCard: {
    backgroundColor: THEME.colors.card,
    borderRadius: THEME.borderRadius.lg,
    padding: 14,
    flexDirection: 'row',
    borderWidth: 1,
    borderColor: THEME.colors.borderLight,
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
    borderRadius: THEME.borderRadius.sm,
    alignSelf: 'flex-start',
    marginBottom: 4,
  },
  badgeDestaqueText: {
    fontSize: 10,
    fontWeight: '700',
    color: '#B45309',
  },
  productName: {
    fontSize: 16,
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
  addButton: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: THEME.colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  productImage: {
    width: 90,
    height: 90,
    borderRadius: THEME.borderRadius.md,
  },
  productImagePlaceholder: {
    width: 90,
    height: 90,
    borderRadius: THEME.borderRadius.md,
    backgroundColor: THEME.colors.background,
    alignItems: 'center',
    justifyContent: 'center',
  },
  placeholderEmoji: {
    fontSize: 32,
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
    fontSize: 16,
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
    borderRadius: THEME.borderRadius.lg,
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
