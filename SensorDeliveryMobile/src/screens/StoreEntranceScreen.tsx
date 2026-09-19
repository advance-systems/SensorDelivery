import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Image,
  ActivityIndicator,
  StatusBar,
  ScrollView,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { MapPin, Clock, ChevronRight, ChevronDown, ChevronUp, Store, RefreshCw, Calendar } from 'lucide-react-native';
import { THEME } from '../constants/theme';
import { useStore } from '../contexts/StoreContext';

interface StoreEntranceScreenProps {
  onEnter: () => void;
}

const DIAS_SEMANA = [
  'Domingo',
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
];

export const StoreEntranceScreen: React.FC<StoreEntranceScreenProps> = ({ onEnter }) => {
  const { empresa, statusLoja, carregando, recarregarStatus } = useStore();
  const [mostrarHorarios, setMostrarHorarios] = useState(false);

  const isAberta = statusLoja?.aberta ?? true;
  const diaAtual = new Date().getDay();
  const resumoHorario = statusLoja?.horarioFuncionamento || '18:00 às 23:30';

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar barStyle="dark-content" backgroundColor={THEME.colors.background} />
      <ScrollView contentContainerStyle={styles.container} bounces={false}>
        {/* Top Branding */}
        <View style={styles.logoSection}>
          <View style={styles.logoBadge}>
            <Image
              source={
                empresa?.logoUrl
                  ? { uri: empresa.logoUrl }
                  : require('../../assets/icon.png')
              }
              style={styles.logoImage}
              resizeMode="contain"
            />
          </View>
          <Text style={styles.storeTitle}>{empresa?.nome || 'Sensor Delivery'}</Text>
          <View style={styles.locationRow}>
            <MapPin size={16} color={THEME.colors.textSecondary} />
            <Text style={styles.locationText}>
              {empresa?.endereco || `${empresa?.cidade || 'Bombinhas'} - ${empresa?.uf || 'SC'}`}
            </Text>
          </View>
        </View>

        {/* Status Card (Idêntico ao layout Delphi uFrameEntradaLoja) */}
        <View style={styles.statusCard}>
          <View style={styles.statusRow}>
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

          <View style={styles.infoDivider} />

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

          {/* Lista semanal */}
          {mostrarHorarios && (
            <View style={styles.weeklyScheduleContainer}>
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

        {/* Call to Action Button */}
        <View style={styles.bottomSection}>
          <TouchableOpacity
            style={styles.enterButton}
            onPress={onEnter}
            activeOpacity={0.88}
          >
            <Text style={styles.enterButtonText}>Ver Cardápio</Text>
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
    paddingHorizontal: 24,
    paddingTop: 40,
    paddingBottom: 32,
    justifyContent: 'space-between',
  },
  logoSection: {
    alignItems: 'center',
    marginTop: 20,
  },
  logoBadge: {
    width: 120,
    height: 120,
    borderRadius: 60,
    backgroundColor: THEME.colors.card,
    alignItems: 'center',
    justifyContent: 'center',
    ...THEME.shadows.card,
    borderWidth: 2,
    borderColor: THEME.colors.borderLight,
    marginBottom: 20,
  },
  logoImage: {
    width: 80,
    height: 80,
  },
  storeTitle: {
    fontSize: 24,
    fontWeight: '800',
    color: THEME.colors.textPrimary,
    textAlign: 'center',
    marginBottom: 8,
  },
  locationRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  locationText: {
    fontSize: 14,
    color: THEME.colors.textSecondary,
    fontWeight: '500',
  },
  statusCard: {
    backgroundColor: THEME.colors.card,
    borderRadius: THEME.borderRadius.lg,
    padding: 20,
    marginTop: 30,
    borderWidth: 1,
    borderColor: THEME.colors.borderLight,
    ...THEME.shadows.card,
  },
  statusRow: {
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
    gap: 8,
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
  },
  infoDivider: {
    height: 1,
    backgroundColor: THEME.colors.borderLight,
    marginVertical: 16,
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
    fontSize: 12,
    color: THEME.colors.textSecondary,
    fontWeight: '500',
  },
  hoursValue: {
    fontSize: 14,
    color: THEME.colors.textPrimary,
    fontWeight: '600',
    marginTop: 2,
  },
  deliveryEstimate: {
    marginTop: 12,
    backgroundColor: THEME.colors.background,
    padding: 10,
    borderRadius: THEME.borderRadius.sm,
    alignItems: 'center',
  },
  estimateText: {
    fontSize: 12,
    color: THEME.colors.textSecondary,
    fontWeight: '600',
  },
  weeklyScheduleContainer: {
    marginTop: 14,
    padding: 12,
    backgroundColor: THEME.colors.background,
    borderRadius: THEME.borderRadius.md,
    borderWidth: 1,
    borderColor: THEME.colors.borderLight,
  },
  weeklyHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 8,
    paddingBottom: 6,
    borderBottomWidth: 1,
    borderBottomColor: THEME.colors.borderLight,
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
    paddingVertical: 4.5,
  },
  dayRowToday: {
    backgroundColor: THEME.colors.card,
    paddingHorizontal: 6,
    borderRadius: 6,
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
    color: THEME.colors.primary,
    fontWeight: '700',
  },
  todayBadge: {
    backgroundColor: THEME.colors.primaryLight,
    paddingHorizontal: 5,
    paddingVertical: 1,
    borderRadius: 4,
  },
  todayBadgeText: {
    fontSize: 9,
    color: THEME.colors.primary,
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
    fontWeight: '600',
  },
  bottomSection: {
    marginTop: 40,
    alignItems: 'center',
  },
  enterButton: {
    backgroundColor: THEME.colors.primary,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    width: '100%',
    paddingVertical: 16,
    borderRadius: THEME.borderRadius.md,
    gap: 8,
    ...THEME.shadows.floating,
  },
  enterButtonText: {
    color: THEME.colors.white,
    fontSize: 16,
    fontWeight: '700',
  },
  disclaimerText: {
    fontSize: 12,
    color: THEME.colors.textMuted,
    textAlign: 'center',
    marginTop: 14,
  },
});
