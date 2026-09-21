import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
  RefreshControl,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  ArrowLeft,
  CheckCircle2,
  Clock,
  ChefHat,
  Bike,
  PackageCheck,
  RefreshCw,
} from 'lucide-react-native';
import { THEME } from '../constants/theme';
import { ApiService } from '../services/api';

const STEPS = [
  {
    status: 'NOVO',
    label: 'Pedido Recebido',
    desc: 'Aguardando confirmação do restaurante',
    icon: Clock,
  },
  {
    status: 'CONFIRMADO',
    label: 'Pedido Confirmado',
    desc: 'Pagamento identificado e pedido aceito',
    icon: CheckCircle2,
  },
  {
    status: 'EM_PREPARO',
    label: 'Em Preparo',
    desc: 'Nossos pizzaiolos estão preparando sua pizza',
    icon: ChefHat,
  },
  {
    status: 'SAIU_ENTREGA',
    label: 'Saiu para Entrega',
    desc: 'O entregador está a caminho do seu endereço',
    icon: Bike,
  },
  {
    status: 'ENTREGUE',
    label: 'Pedido Entregue',
    desc: 'Bom apetite!',
    icon: PackageCheck,
  },
];

export const OrderTrackingScreen = ({ pedidoId, onBack, onGoHome }) => {
  const [pedido, setPedido] = useState(null);
  const [carregando, setCarregando] = useState(true);
  const [atualizando, setAtualizando] = useState(false);

  useEffect(() => {
    carregarPedido();
    const interval = setInterval(carregarPedidoSilencioso, 5000);
    return () => clearInterval(interval);
  }, [pedidoId]);

  const carregarPedido = async () => {
    setCarregando(true);
    try {
      const res = await ApiService.getStatusPedido(pedidoId);
      setPedido(res);
    } catch (err) {
      console.warn('Erro ao carregar pedido:', err);
    } finally {
      setCarregando(false);
    }
  };

  const carregarPedidoSilencioso = async () => {
    try {
      const res = await ApiService.getStatusPedido(pedidoId);
      setPedido(res);
    } catch {
      // Silencioso
    }
  };

  const getStatusIndex = (status) => {
    switch (status) {
      case 'RASCUNHO':
      case 'NOVO':
        return 0;
      case 'CONFIRMADO':
        return 1;
      case 'EM_PREPARO':
        return 2;
      case 'PRONTO':
      case 'SAIU_ENTREGA':
        return 3;
      case 'ENTREGUE':
      case 'FINALIZADO':
        return 4;
      default:
        return 0;
    }
  };

  const currentStepIndex = getStatusIndex(pedido?.status);

  return (
    <SafeAreaView style={styles.safeArea}>
      <View style={styles.header}>
        <TouchableOpacity onPress={onBack} style={styles.backButton}>
          <ArrowLeft size={22} color={THEME.colors.textPrimary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Acompanhar Pedido</Text>
        <TouchableOpacity onPress={carregarPedido} style={styles.refreshButton}>
          <RefreshCw size={18} color={THEME.colors.primary} />
        </TouchableOpacity>
      </View>

      {carregando && !pedido ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={THEME.colors.primary} />
          <Text style={styles.loadingText}>Buscando informações do pedido...</Text>
        </View>
      ) : (
        <ScrollView
          contentContainerStyle={styles.content}
          showsVerticalScrollIndicator={false}
          refreshControl={
            <RefreshControl
              refreshing={atualizando}
              onRefresh={async () => {
                setAtualizando(true);
                await carregarPedido();
                setAtualizando(false);
              }}
            />
          }
        >
          {/* Card Resumo */}
          <View style={styles.orderSummaryCard}>
            <View style={styles.orderHeaderRow}>
              <View>
                <Text style={styles.orderNumberLabel}>PEDIDO</Text>
                <Text style={styles.orderNumber}>#{pedido?.numero || pedidoId.substring(0, 6)}</Text>
              </View>
              <View style={styles.totalBadge}>
                <Text style={styles.totalBadgeText}>
                  R$ {pedido?.total ? Number(pedido.total).toFixed(2).replace('.', ',') : '0,00'}
                </Text>
              </View>
            </View>

            <View style={styles.divider} />

            <View style={styles.orderMetaRow}>
              <Text style={styles.metaLabel}>Forma de Pagamento:</Text>
              <Text style={styles.metaValue}>{pedido?.formaPagamento || 'PIX'}</Text>
            </View>
            <View style={styles.orderMetaRow}>
              <Text style={styles.metaLabel}>Entrega:</Text>
              <Text style={styles.metaValue}>{pedido?.tipoEntrega === 'DELIVERY' ? 'Delivery' : 'Retirada no Balcão'}</Text>
            </View>
          </View>

          {/* Stepper Vertical (uFrameAcompanharPedido) */}
          <View style={styles.stepperCard}>
            <Text style={styles.stepperTitle}>Progresso do Pedido</Text>

            <View style={styles.stepsContainer}>
              {STEPS.map((step, index) => {
                const IconComponent = step.icon;
                const isCompleted = index <= currentStepIndex;
                const isCurrent = index === currentStepIndex;
                const isLast = index === STEPS.length - 1;

                return (
                  <View key={step.status} style={styles.stepRow}>
                    <View style={styles.iconColumn}>
                      <View
                        style={[
                          styles.iconCircle,
                          isCompleted && styles.iconCircleCompleted,
                          isCurrent && styles.iconCircleCurrent,
                        ]}
                      >
                        <IconComponent
                          size={18}
                          color={isCompleted ? THEME.colors.white : THEME.colors.textMuted}
                        />
                      </View>
                      {!isLast && (
                        <View
                          style={[
                            styles.verticalLine,
                            index < currentStepIndex && styles.verticalLineCompleted,
                          ]}
                        />
                      )}
                    </View>

                    <View style={styles.stepInfoColumn}>
                      <Text
                        style={[
                          styles.stepLabel,
                          isCompleted && styles.stepLabelCompleted,
                          isCurrent && styles.stepLabelCurrent,
                        ]}
                      >
                        {step.label}
                      </Text>
                      <Text style={styles.stepDesc}>{step.desc}</Text>
                    </View>
                  </View>
                );
              })}
            </View>
          </View>

          {/* Botão Voltar */}
          <TouchableOpacity
            style={styles.homeButton}
            onPress={onGoHome}
            activeOpacity={0.88}
          >
            <Text style={styles.homeButtonText}>Voltar ao Início</Text>
          </TouchableOpacity>
        </ScrollView>
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
  refreshButton: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: THEME.colors.primaryLight,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: THEME.colors.textPrimary,
  },
  loadingContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  loadingText: {
    marginTop: 12,
    color: THEME.colors.textSecondary,
    fontSize: 14,
  },
  content: {
    padding: 20,
    paddingBottom: 50,
    gap: 16,
  },
  orderSummaryCard: {
    backgroundColor: THEME.colors.card,
    borderRadius: THEME.borderRadius.lg,
    padding: 18,
    borderWidth: 1,
    borderColor: THEME.colors.borderLight,
    ...THEME.shadows.card,
  },
  orderHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  orderNumberLabel: {
    fontSize: 11,
    fontWeight: '700',
    color: THEME.colors.textSecondary,
    letterSpacing: 0.5,
  },
  orderNumber: {
    fontSize: 22,
    fontWeight: '800',
    color: THEME.colors.textPrimary,
  },
  totalBadge: {
    backgroundColor: THEME.colors.primaryLight,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: THEME.borderRadius.full,
  },
  totalBadgeText: {
    fontSize: 15,
    fontWeight: '800',
    color: THEME.colors.primary,
  },
  divider: {
    height: 1,
    backgroundColor: THEME.colors.borderLight,
    marginVertical: 12,
  },
  orderMetaRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 4,
  },
  metaLabel: {
    fontSize: 13,
    color: THEME.colors.textSecondary,
  },
  metaValue: {
    fontSize: 13,
    fontWeight: '600',
    color: THEME.colors.textPrimary,
  },
  stepperCard: {
    backgroundColor: THEME.colors.card,
    borderRadius: THEME.borderRadius.lg,
    padding: 20,
    borderWidth: 1,
    borderColor: THEME.colors.borderLight,
    ...THEME.shadows.card,
  },
  stepperTitle: {
    fontSize: 16,
    fontWeight: '800',
    color: THEME.colors.textPrimary,
    marginBottom: 20,
  },
  stepsContainer: {
    paddingLeft: 4,
  },
  stepRow: {
    flexDirection: 'row',
    minHeight: 64,
  },
  iconColumn: {
    alignItems: 'center',
    width: 36,
  },
  iconCircle: {
    width: 34,
    height: 34,
    borderRadius: 17,
    backgroundColor: THEME.colors.borderLight,
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconCircleCompleted: {
    backgroundColor: THEME.colors.primary,
  },
  iconCircleCurrent: {
    backgroundColor: THEME.colors.primary,
    borderWidth: 3,
    borderColor: THEME.colors.primaryLight,
  },
  verticalLine: {
    flex: 1,
    width: 2,
    backgroundColor: THEME.colors.borderLight,
    marginVertical: 4,
  },
  verticalLineCompleted: {
    backgroundColor: THEME.colors.primary,
  },
  stepInfoColumn: {
    flex: 1,
    paddingLeft: 14,
    paddingTop: 4,
  },
  stepLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: THEME.colors.textSecondary,
  },
  stepLabelCompleted: {
    color: THEME.colors.textPrimary,
    fontWeight: '700',
  },
  stepLabelCurrent: {
    color: THEME.colors.primary,
    fontWeight: '800',
  },
  stepDesc: {
    fontSize: 12,
    color: THEME.colors.textSecondary,
    marginTop: 2,
  },
  homeButton: {
    backgroundColor: THEME.colors.card,
    borderWidth: 1.5,
    borderColor: THEME.colors.primary,
    borderRadius: THEME.borderRadius.md,
    paddingVertical: 14,
    alignItems: 'center',
    marginTop: 10,
  },
  homeButtonText: {
    color: THEME.colors.primary,
    fontSize: 15,
    fontWeight: '700',
  },
});
