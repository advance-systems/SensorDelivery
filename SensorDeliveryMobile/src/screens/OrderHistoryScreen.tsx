import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  ActivityIndicator,
  RefreshControl,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Clock, ChevronRight, ShoppingBag, RotateCcw } from 'lucide-react-native';
import { THEME } from '../constants/theme';
import { PedidoResponse } from '../types';
import { ApiService, STORAGE_KEYS } from '../services/api';

interface OrderHistoryScreenProps {
  onSelectOrder: (pedidoId: string) => void;
  onBackToMenu: () => void;
}

export const OrderHistoryScreen: React.FC<OrderHistoryScreenProps> = ({
  onSelectOrder,
  onBackToMenu,
}) => {
  const [pedidos, setPedidos] = useState<PedidoResponse[]>([]);
  const [carregando, setCarregando] = useState(true);
  const [telefone, setTelefone] = useState('');

  useEffect(() => {
    carregarHistorico();
  }, []);

  const carregarHistorico = async () => {
    setCarregando(true);
    try {
      const infoStr = await AsyncStorage.getItem(STORAGE_KEYS.CLIENTE_INFO);
      let tel = '';
      if (infoStr) {
        const info = JSON.parse(infoStr);
        tel = info.telefone || '';
        setTelefone(tel);
      }

      if (tel) {
        const lista = await ApiService.getHistorico(tel);
        setPedidos(lista);
      }
    } catch (err) {
      console.warn('Erro ao carregar histórico:', err);
    } finally {
      setCarregando(false);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'ENTREGUE':
      case 'FINALIZADO':
        return { label: 'Entregue', bg: THEME.colors.successLight, color: THEME.colors.success };
      case 'CANCELADO':
        return { label: 'Cancelado', bg: THEME.colors.dangerLight, color: THEME.colors.danger };
      default:
        return { label: 'Em Andamento', bg: THEME.colors.primaryLight, color: THEME.colors.primary };
    }
  };

  return (
    <SafeAreaView style={styles.safeArea} edges={['top', 'left', 'right']}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Meus Pedidos</Text>
      </View>

      {carregando ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={THEME.colors.primary} />
          <Text style={styles.loadingText}>Carregando histórico...</Text>
        </View>
      ) : (
        <FlatList
          data={pedidos}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.listContent}
          showsVerticalScrollIndicator={false}
          refreshControl={
            <RefreshControl refreshing={carregando} onRefresh={carregarHistorico} />
          }
          renderItem={({ item }) => {
            const badge = getStatusBadge(item.status);
            return (
              <TouchableOpacity
                style={styles.orderCard}
                onPress={() => onSelectOrder(item.id)}
                activeOpacity={0.88}
              >
                <View style={styles.cardTop}>
                  <View>
                    <Text style={styles.orderNum}>Pedido #{item.numero}</Text>
                    <Text style={styles.orderDate}>
                      {new Date(item.criadoEm || Date.now()).toLocaleDateString('pt-BR', {
                        day: '2-digit',
                        month: '2-digit',
                        hour: '2-digit',
                        minute: '2-digit',
                      })}
                    </Text>
                  </View>
                  <View style={[styles.statusBadge, { backgroundColor: badge.bg }]}>
                    <Text style={[styles.statusText, { color: badge.color }]}>{badge.label}</Text>
                  </View>
                </View>

                <View style={styles.divider} />

                <View style={styles.cardBottom}>
                  <Text style={styles.orderTotal}>
                    R$ {item.total.toFixed(2).replace('.', ',')}
                  </Text>
                  <View style={styles.trackLink}>
                    <Text style={styles.trackLinkText}>Ver detalhes</Text>
                    <ChevronRight size={16} color={THEME.colors.primary} />
                  </View>
                </View>
              </TouchableOpacity>
            );
          }}
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <ShoppingBag size={48} color={THEME.colors.textMuted} />
              <Text style={styles.emptyTitle}>Nenhum pedido encontrado</Text>
              <Text style={styles.emptyDesc}>
                Você ainda não realizou pedidos no aplicativo.
              </Text>
              <TouchableOpacity style={styles.menuBtn} onPress={onBackToMenu}>
                <Text style={styles.menuBtnText}>Fazer meu primeiro pedido</Text>
              </TouchableOpacity>
            </View>
          }
        />
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
    paddingHorizontal: 20,
    paddingVertical: 16,
    backgroundColor: THEME.colors.card,
    borderBottomWidth: 1,
    borderColor: THEME.colors.borderLight,
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '800',
    color: THEME.colors.textPrimary,
  },
  listContent: {
    padding: 20,
    gap: 12,
  },
  orderCard: {
    backgroundColor: THEME.colors.card,
    borderRadius: THEME.borderRadius.lg,
    padding: 16,
    borderWidth: 1,
    borderColor: THEME.colors.borderLight,
    ...THEME.shadows.card,
  },
  cardTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  orderNum: {
    fontSize: 16,
    fontWeight: '800',
    color: THEME.colors.textPrimary,
  },
  orderDate: {
    fontSize: 12,
    color: THEME.colors.textSecondary,
    marginTop: 2,
  },
  statusBadge: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: THEME.borderRadius.full,
  },
  statusText: {
    fontSize: 11,
    fontWeight: '700',
  },
  divider: {
    height: 1,
    backgroundColor: THEME.colors.borderLight,
    marginVertical: 12,
  },
  cardBottom: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  orderTotal: {
    fontSize: 16,
    fontWeight: '800',
    color: THEME.colors.textPrimary,
  },
  trackLink: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  trackLinkText: {
    fontSize: 13,
    fontWeight: '700',
    color: THEME.colors.primary,
  },
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  loadingText: {
    marginTop: 12,
    fontSize: 14,
    color: THEME.colors.textSecondary,
  },
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 60,
    paddingHorizontal: 20,
  },
  emptyTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: THEME.colors.textPrimary,
    marginTop: 16,
  },
  emptyDesc: {
    fontSize: 13,
    color: THEME.colors.textSecondary,
    textAlign: 'center',
    marginTop: 6,
    marginBottom: 20,
  },
  menuBtn: {
    backgroundColor: THEME.colors.primary,
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: THEME.borderRadius.md,
  },
  menuBtnText: {
    color: THEME.colors.white,
    fontSize: 14,
    fontWeight: '700',
  },
});
