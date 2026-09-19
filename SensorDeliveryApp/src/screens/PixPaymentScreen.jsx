import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Image,
  Alert,
  ActivityIndicator,
  ScrollView,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import Clipboard from '@react-native-clipboard/clipboard';
import { Copy, CheckCircle2, Clock, ArrowRight } from 'lucide-react-native';
import { THEME } from '../constants/theme';
import { ApiService } from '../services/api';

export const PixPaymentScreen = ({ pedido, onPaymentConfirmed, onTrackOrder }) => {
  const [copiado, setCopiado] = useState(false);
  const [verificando, setVerificando] = useState(false);
  const [tempoRestante, setTempoRestante] = useState(15 * 60);

  useEffect(() => {
    const timer = setInterval(() => {
      setTempoRestante((prev) => (prev > 0 ? prev - 1 : 0));
    }, 1000);

    const polling = setInterval(async () => {
      try {
        const atual = await ApiService.getStatusPedido(pedido.id);
        if (
          atual.status === 'CONFIRMADO' ||
          atual.status === 'EM_PREPARO' ||
          atual.status === 'PRONTO'
        ) {
          clearInterval(polling);
          clearInterval(timer);
          onPaymentConfirmed(atual);
        }
      } catch (err) {
        // Silencioso
      }
    }, 4000);

    return () => {
      clearInterval(timer);
      clearInterval(polling);
    };
  }, [pedido.id]);

  const handleCopiarPix = () => {
    if (pedido.pix?.copiaCola) {
      Clipboard.setString(pedido.pix.copiaCola);
      setCopiado(true);
      setTimeout(() => setCopiado(false), 3000);
      Alert.alert('Sucesso', 'Código PIX Copia e Cola copiado para a área de transferência!');
    }
  };

  const handleVerificarManual = async () => {
    setVerificando(true);
    try {
      const atual = await ApiService.getStatusPedido(pedido.id);
      if (
        atual.status === 'CONFIRMADO' ||
        atual.status === 'EM_PREPARO' ||
        atual.status === 'PRONTO'
      ) {
        onPaymentConfirmed(atual);
      } else {
        Alert.alert('Aguardando Pagamento', 'O pagamento ainda não foi identificado pelo banco. Tente novamente em instantes.');
      }
    } catch {
      Alert.alert('Aviso', 'Não foi possível verificar no momento.');
    } finally {
      setVerificando(false);
    }
  };

  const formatarTempo = (segundos) => {
    const mins = Math.floor(segundos / 60);
    const secs = segundos % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        {/* Header Card */}
        <View style={styles.headerCard}>
          <View style={styles.badgePix}>
            <Text style={styles.badgePixText}>PIX Instantâneo</Text>
          </View>
          <Text style={styles.orderNumber}>Pedido #{pedido.numero}</Text>
          <Text style={styles.totalText}>
            R$ {Number(pedido.total).toFixed(2).replace('.', ',')}
          </Text>

          <View style={styles.timerRow}>
            <Clock size={16} color={THEME.colors.warning} />
            <Text style={styles.timerText}>
              Pague em até {formatarTempo(tempoRestante)}
            </Text>
          </View>
        </View>

        {/* QR Code */}
        <View style={styles.qrCodeCard}>
          {pedido.pix?.qrCodeBase64 ? (
            <Image
              source={{ uri: `data:image/png;base64,${pedido.pix.qrCodeBase64}` }}
              style={styles.qrCodeImage}
              resizeMode="contain"
            />
          ) : (
            <View style={styles.qrCodePlaceholder}>
              <Text style={{ fontSize: 40 }}>📱</Text>
              <Text style={styles.qrCodeHint}>Abra o app do seu banco e use o Pix Copia e Cola abaixo</Text>
            </View>
          )}

          <Text style={styles.instructionsTitle}>Como pagar:</Text>
          <Text style={styles.stepText}>1. Copie o código PIX abaixo</Text>
          <Text style={styles.stepText}>2. Abra o aplicativo do seu banco</Text>
          <Text style={styles.stepText}>3. Escolha a opção PIX Copia e Cola e conclua o pagamento</Text>
        </View>

        {/* Botão Copiar */}
        <TouchableOpacity
          style={[styles.copyButton, copiado && styles.copyButtonActive]}
          onPress={handleCopiarPix}
          activeOpacity={0.88}
        >
          {copiado ? (
            <CheckCircle2 size={20} color={THEME.colors.white} />
          ) : (
            <Copy size={20} color={THEME.colors.white} />
          )}
          <Text style={styles.copyButtonText}>
            {copiado ? 'Código Copiado!' : 'Copiar Código PIX (Copia e Cola)'}
          </Text>
        </TouchableOpacity>

        {/* Verificação Manual */}
        <TouchableOpacity
          style={styles.verifyButton}
          onPress={handleVerificarManual}
          disabled={verificando}
          activeOpacity={0.88}
        >
          {verificando ? (
            <ActivityIndicator size="small" color={THEME.colors.primary} />
          ) : (
            <Text style={styles.verifyButtonText}>Já fiz o pagamento</Text>
          )}
        </TouchableOpacity>

        {/* Acompanhar Pedido */}
        <TouchableOpacity
          style={styles.trackButton}
          onPress={() => onTrackOrder(pedido)}
          activeOpacity={0.88}
        >
          <Text style={styles.trackButtonText}>Acompanhar status do pedido</Text>
          <ArrowRight size={18} color={THEME.colors.textSecondary} />
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: THEME.colors.background,
  },
  content: {
    padding: 20,
    alignItems: 'center',
    gap: 16,
  },
  headerCard: {
    backgroundColor: THEME.colors.card,
    borderRadius: THEME.borderRadius.lg,
    padding: 20,
    alignItems: 'center',
    width: '100%',
    borderWidth: 1,
    borderColor: THEME.colors.borderLight,
    ...THEME.shadows.card,
  },
  badgePix: {
    backgroundColor: THEME.colors.successLight,
    paddingHorizontal: 12,
    paddingVertical: 4,
    borderRadius: THEME.borderRadius.full,
    marginBottom: 8,
  },
  badgePixText: {
    fontSize: 12,
    fontWeight: '700',
    color: THEME.colors.success,
  },
  orderNumber: {
    fontSize: 15,
    fontWeight: '600',
    color: THEME.colors.textSecondary,
    marginBottom: 4,
  },
  totalText: {
    fontSize: 28,
    fontWeight: '800',
    color: THEME.colors.textPrimary,
    marginBottom: 10,
  },
  timerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: THEME.colors.warningLight,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: THEME.borderRadius.full,
  },
  timerText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#B45309',
  },
  qrCodeCard: {
    backgroundColor: THEME.colors.card,
    borderRadius: THEME.borderRadius.lg,
    padding: 20,
    alignItems: 'center',
    width: '100%',
    borderWidth: 1,
    borderColor: THEME.colors.borderLight,
    ...THEME.shadows.card,
  },
  qrCodeImage: {
    width: 200,
    height: 200,
    marginBottom: 16,
  },
  qrCodePlaceholder: {
    width: 200,
    height: 180,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: THEME.colors.background,
    borderRadius: THEME.borderRadius.md,
    marginBottom: 16,
    padding: 12,
  },
  qrCodeHint: {
    fontSize: 12,
    color: THEME.colors.textSecondary,
    textAlign: 'center',
    marginTop: 8,
  },
  instructionsTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: THEME.colors.textPrimary,
    alignSelf: 'flex-start',
    marginBottom: 6,
  },
  stepText: {
    fontSize: 12,
    color: THEME.colors.textSecondary,
    alignSelf: 'flex-start',
    marginBottom: 4,
  },
  copyButton: {
    backgroundColor: THEME.colors.primary,
    borderRadius: THEME.borderRadius.md,
    paddingVertical: 16,
    paddingHorizontal: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    width: '100%',
    gap: 8,
    ...THEME.shadows.floating,
  },
  copyButtonActive: {
    backgroundColor: THEME.colors.success,
  },
  copyButtonText: {
    color: THEME.colors.white,
    fontSize: 15,
    fontWeight: '700',
  },
  verifyButton: {
    backgroundColor: THEME.colors.card,
    borderRadius: THEME.borderRadius.md,
    paddingVertical: 14,
    alignItems: 'center',
    justifyContent: 'center',
    width: '100%',
    borderWidth: 1.5,
    borderColor: THEME.colors.primary,
  },
  verifyButtonText: {
    color: THEME.colors.primary,
    fontSize: 14,
    fontWeight: '700',
  },
  trackButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginTop: 10,
  },
  trackButtonText: {
    fontSize: 14,
    fontWeight: '600',
    color: THEME.colors.textSecondary,
  },
});
