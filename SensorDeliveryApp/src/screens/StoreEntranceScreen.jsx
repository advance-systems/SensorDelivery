import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
  StatusBar,
  ScrollView,
  Image,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  MapPin,
  Clock,
  ChevronRight,
  ChevronDown,
  ChevronUp,
  RefreshCw,
  Store,
  Calendar,
  Phone,
} from 'lucide-react-native';
import { THEME } from '../constants/theme';
import { useStore } from '../contexts/StoreContext';

const DIAS_SEMANA = [
  'Domingo',
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
];

export const StoreEntranceScreen = ({ onEnter }) => {
  const { empresa, statusLoja, carregando, recarregarStatus } = useStore();
  const [mostrarHorarios, setMostrarHorarios] = useState(false);

  const isAberta = statusLoja?.aberta ?? false;
  const diaAtual = new Date().getDay();
  const resumoHorario = statusLoja?.horarioFuncionamento || 'Consulte os horários';

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="dark-content" backgroundColor={THEME.colors.background} />
      <ScrollView contentContainerStyle={styles.container} bounces={false}>
        
        {/* Banner de Topo com Logotipo em Destaque (Identidade Delphi) */}
        <View style={styles.bannerContainer}>
          <View style={styles.bannerBackground} />
          
          <View style={styles.logoWrapper}>
            {empresa?.logoUrl ? (
              <Image
                source={{ uri: empresa.logoUrl }}
                style={styles.logoImage}
                resizeMode="cover"
              />
            ) : (
              <View style={styles.logoPlaceholder}>
                <Store size={48} color={THEME.colors.primary} />
              </View>
            )}
          </View>

          <Text style={styles.storeName}>{empresa?.nome || 'Carregando...'}</Text>
          
          {empresa?.razaoSocial && (
            <Text style={styles.razaoSocialText}>
              {empresa.razaoSocial}
            </Text>
          )}

          {empresa?.telefone && (
            <View style={styles.phoneContainer}>
              <Phone size={14} color={THEME.colors.textSecondary} />
              <Text style={styles.phoneText}>{empresa.telefone}</Text>
            </View>
          )}
        </View>

        {/* Card de Status de Funcionamento */}
        <View style={styles.statusCard}>
          <View style={styles.statusHeader}>
            <View
              style={[
                styles.statusBadge,
                { backgroundColor: isAberta ? THEME.colors.successLight : THEME.colors.dangerLight },
              ]}
            >
              <View
                style={[
                  styles.statusDot,
                  { backgroundColor: isAberta ? THEME.colors.success : THEME.colors.danger },
                ]}
              />
              <Text
                style={[
                  styles.statusText,
                  { color: isAberta ? THEME.colors.success : THEME.colors.danger },
                ]}
              >
                {isAberta ? 'Aberto Agora' : 'Fechado no Momento'}
              </Text>
            </View>

            <TouchableOpacity onPress={recarregarStatus} style={styles.refreshButton}>
              {carregando ? (
                <ActivityIndicator size="small" color={THEME.colors.primary} />
              ) : (
                <RefreshCw size={16} color={THEME.colors.textSecondary} />
              )}
            </TouchableOpacity>
          </View>

          <View style={styles.divider} />

          {/* Horário de Hoje com expansão para a semana */}
          <TouchableOpacity
            style={styles.hoursRow}
            onPress={() => setMostrarHorarios((v) => !v)}
            activeOpacity={0.7}
          >
            <Clock size={18} color={THEME.colors.primary} />
            <View style={styles.hoursInfo}>
              <Text style={styles.hoursLabel}>Horário de Atendimento (Hoje)</Text>
              <Text style={styles.hoursValue}>{resumoHorario}</Text>
            </View>
            {mostrarHorarios ? (
              <ChevronUp size={18} color={THEME.colors.textSecondary} />
            ) : (
              <ChevronDown size={18} color={THEME.colors.textSecondary} />
            )}
          </TouchableOpacity>

          {/* Grade Semanal */}
          {mostrarHorarios && (
            <View style={styles.weeklySchedule}>
              <View style={styles.weeklyHeader}>
                <Calendar size={14} color={THEME.colors.primary} />
                <Text style={styles.weeklyTitle}>Horário Semanal</Text>
              </View>
              {DIAS_SEMANA.map((dia, index) => {
                const configDia = statusLoja?.horarios?.find(
                  (h) => Number(h.dia_semana) === index
                );
                const isHoje = diaAtual === index;
                const fechado = configDia ? configDia.fechado : false;
                const abertura = configDia?.horario_abertura ? configDia.horario_abertura.slice(0, 5) : '18:00';
                const fechamento = configDia?.horario_fechamento ? configDia.horario_fechamento.slice(0, 5) : '23:30';

                return (
                  <View
                    key={dia}
                    style={[
                      styles.dayRow,
                      isHoje && styles.dayRowToday,
                    ]}
                  >
                    <View style={styles.dayNameWrapper}>
                      <Text style={[styles.dayName, isHoje && styles.dayNameToday]}>
                        {dia}
                      </Text>
                      {isHoje && (
                        <View style={styles.todayBadge}>
                          <Text style={styles.todayBadgeText}>Hoje</Text>
                        </View>
                      )}
                    </View>
                    <Text
                      style={[
                        styles.dayTime,
                        fechado && styles.dayClosed,
                        isHoje && !fechado && styles.dayTimeToday,
                      ]}
                    >
                      {fechado ? 'Fechado' : `${abertura} às ${fechamento}`}
                    </Text>
                  </View>
                );
              })}
            </View>
          )}

          {statusLoja?.tempoEntregaMin && (
            <View style={styles.deliveryEstimate}>
              <Text style={styles.estimateText}>
                ⏱️ Tempo estimado: {statusLoja.tempoEntregaMin}-{statusLoja.tempoEntregaMax || 50} min
              </Text>
            </View>
          )}
        </View>

        {/* Botão de Acesso Estilo SensorButton */}
        <View style={styles.actionSection}>
          <TouchableOpacity
            style={styles.sensorButton}
            onPress={onEnter}
            activeOpacity={0.88}
          >
            <Text style={styles.sensorButtonText}>Acessar Cardápio</Text>
            <ChevronRight size={20} color={THEME.colors.white} />
          </TouchableOpacity>

          <Text style={styles.disclaimerText}>
            Faça seu pedido online de forma rápida e segura
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: THEME.colors.background,
  },
  container: {
    flexGrow: 1,
    paddingBottom: 30,
  },
  bannerContainer: {
    alignItems: 'center',
    paddingTop: 16,
    paddingBottom: 24,
    paddingHorizontal: 20,
  },
  bannerBackground: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    height: 100,
    backgroundColor: THEME.colors.primaryLight,
    borderBottomLeftRadius: 30,
    borderBottomRightRadius: 30,
  },
  logoWrapper: {
    width: 96,
    height: 96,
    borderRadius: 24,
    backgroundColor: THEME.colors.card,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 3,
    borderColor: THEME.colors.card,
    ...THEME.shadows.card,
    marginBottom: 12,
  },
  logoImage: {
    width: 90,
    height: 90,
    borderRadius: 22,
  },
  logoPlaceholder: {
    width: 90,
    height: 90,
    borderRadius: 22,
    backgroundColor: THEME.colors.primaryLight,
    alignItems: 'center',
    justifyContent: 'center',
  },
  storeName: {
    fontSize: 22,
    fontWeight: '700',
    color: THEME.colors.textPrimary,
    textAlign: 'center',
    marginBottom: 2,
  },
  razaoSocialText: {
    fontSize: 12,
    color: THEME.colors.textSecondary,
    textAlign: 'center',
    marginBottom: 8,
  },
  locationContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    marginBottom: 4,
  },
  locationText: {
    fontSize: 13,
    color: THEME.colors.textSecondary,
    fontWeight: '500',
  },
  phoneContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    marginTop: 2,
  },
  phoneText: {
    fontSize: 12,
    color: THEME.colors.textSecondary,
    fontWeight: '500',
  },
  statusCard: {
    backgroundColor: THEME.colors.card,
    borderRadius: THEME.borderRadius.xl,
    marginHorizontal: 20,
    padding: 16,
    borderWidth: 1,
    borderColor: THEME.colors.border,
    ...THEME.shadows.card,
  },
  statusHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  statusBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: THEME.borderRadius.full,
    gap: 6,
  },
  statusDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  statusText: {
    fontSize: 13,
    fontWeight: '700',
  },
  refreshButton: {
    padding: 6,
    borderRadius: THEME.borderRadius.sm,
    backgroundColor: THEME.colors.inputBackground,
    borderWidth: 1,
    borderColor: THEME.colors.borderLight,
  },
  divider: {
    height: 1,
    backgroundColor: THEME.colors.borderLight,
    marginVertical: 14,
  },
  hoursRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  hoursInfo: {
    flex: 1,
  },
  hoursLabel: {
    fontSize: 11,
    color: THEME.colors.textSecondary,
    fontWeight: '600',
    textTransform: 'uppercase',
  },
  hoursValue: {
    fontSize: 14,
    color: THEME.colors.textPrimary,
    fontWeight: '700',
    marginTop: 2,
  },
  weeklySchedule: {
    marginTop: 14,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: THEME.colors.borderLight,
  },
  weeklyHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 8,
  },
  weeklyTitle: {
    fontSize: 12,
    fontWeight: '700',
    color: THEME.colors.textPrimary,
  },
  dayRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 6,
    paddingHorizontal: 8,
    borderRadius: THEME.borderRadius.sm,
  },
  dayRowToday: {
    backgroundColor: THEME.colors.primaryLight,
  },
  dayNameWrapper: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  dayName: {
    fontSize: 12,
    color: THEME.colors.textSecondary,
    fontWeight: '500',
  },
  dayNameToday: {
    fontWeight: '700',
    color: THEME.colors.primary,
  },
  todayBadge: {
    backgroundColor: THEME.colors.primary,
    paddingHorizontal: 6,
    paddingVertical: 1,
    borderRadius: 4,
  },
  todayBadgeText: {
    fontSize: 9,
    color: THEME.colors.white,
    fontWeight: '700',
  },
  dayTime: {
    fontSize: 12,
    color: THEME.colors.textPrimary,
    fontWeight: '600',
  },
  dayTimeToday: {
    color: THEME.colors.primary,
    fontWeight: '700',
  },
  dayClosed: {
    color: THEME.colors.danger,
  },
  deliveryEstimate: {
    marginTop: 12,
    padding: 10,
    backgroundColor: THEME.colors.inputBackground,
    borderRadius: THEME.borderRadius.md,
    alignItems: 'center',
  },
  estimateText: {
    fontSize: 12,
    fontWeight: '600',
    color: THEME.colors.textSecondary,
  },
  actionSection: {
    marginTop: 24,
    paddingHorizontal: 20,
  },
  sensorButton: {
    backgroundColor: THEME.colors.primary,
    height: 48,
    borderRadius: THEME.borderRadius.xl,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    ...THEME.shadows.button,
  },
  sensorButtonText: {
    color: THEME.colors.white,
    fontSize: 15,
    fontWeight: '700',
  },
  disclaimerText: {
    textAlign: 'center',
    fontSize: 12,
    color: THEME.colors.textMuted,
    marginTop: 10,
  },
});
