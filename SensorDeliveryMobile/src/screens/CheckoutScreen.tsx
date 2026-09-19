import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  TextInput,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  ArrowLeft,
  Bike,
  Store,
  QrCode,
  Banknote,
  CreditCard,
  MapPin,
  CheckCircle2,
} from 'lucide-react-native';
import { THEME } from '../constants/theme';
import { useCart } from '../contexts/CartContext';
import { useStore } from '../contexts/StoreContext';
import { ApiService, STORAGE_KEYS } from '../services/api';
import {
  TipoEntrega,
  FormaPagamento,
  ClienteEndereco,
  PedidoPayload,
  PedidoResponse,
} from '../types';

interface CheckoutScreenProps {
  onBack: () => void;
  onOrderSuccess: (pedido: PedidoResponse) => void;
}

export const CheckoutScreen: React.FC<CheckoutScreenProps> = ({
  onBack,
  onOrderSuccess,
}) => {
  const { itens, subtotal, limparCarrinho } = useCart();
  const { empresa, statusLoja } = useStore();

  const [tipoEntrega, setTipoEntrega] = useState<TipoEntrega>('DELIVERY');
  const [formaPagamento, setFormaPagamento] = useState<FormaPagamento>('PIX');
  const [trocoPara, setTrocoPara] = useState('');
  const [observacaoGeral, setObservacaoGeral] = useState('');
  const [enviando, setEnviando] = useState(false);

  // Dados do cliente
  const [nome, setNome] = useState('');
  const [telefone, setTelefone] = useState('');
  const [cpf, setCpf] = useState('');

  // Endereço
  const [cep, setCep] = useState('');
  const [logradouro, setLogradouro] = useState('');
  const [numero, setNumero] = useState('');
  const [complemento, setComplemento] = useState('');
  const [bairro, setBairro] = useState('');
  const [cidade, setCidade] = useState('Bombinhas');
  const [uf, setUf] = useState('SC');
  const [referencia, setReferencia] = useState('');
  const [buscandoCep, setBuscandoCep] = useState(false);

  useEffect(() => {
    carregarDadosCliente();
  }, []);

  const carregarDadosCliente = async () => {
    try {
      const infoStr = await AsyncStorage.getItem(STORAGE_KEYS.CLIENTE_INFO);
      if (infoStr) {
        const info = JSON.parse(infoStr);
        setNome(info.nome || '');
        setTelefone(info.telefone || '');
        setCpf(info.cpf || '');
      }

      const endStr = await AsyncStorage.getItem(STORAGE_KEYS.CLIENTE_ENDERECO);
      if (endStr) {
        const end: ClienteEndereco = JSON.parse(endStr);
        setCep(end.cep || '');
        setLogradouro(end.logradouro || '');
        setNumero(end.numero || '');
        setComplemento(end.complemento || '');
        setBairro(end.bairro || '');
        setCidade(end.cidade || 'Bombinhas');
        setUf(end.uf || 'SC');
        setReferencia(end.referencia || '');
      }
    } catch (err) {
      console.warn('Erro ao carregar dados salvos do cliente:', err);
    }
  };

  const salvarDadosCliente = async () => {
    try {
      await AsyncStorage.setItem(
        STORAGE_KEYS.CLIENTE_INFO,
        JSON.stringify({ nome, telefone, cpf })
      );
      if (tipoEntrega === 'DELIVERY') {
        await AsyncStorage.setItem(
          STORAGE_KEYS.CLIENTE_ENDERECO,
          JSON.stringify({
            nome,
            telefone,
            cep,
            logradouro,
            numero,
            complemento,
            bairro,
            cidade,
            uf,
            referencia,
          })
        );
      }
    } catch (err) {
      console.warn('Erro ao salvar dados do cliente:', err);
    }
  };

  const handleCepBlur = async () => {
    if (cep.replace(/\D/g, '').length === 8) {
      setBuscandoCep(true);
      const res = await ApiService.buscarCep(cep);
      setBuscandoCep(false);
      if (res && !res.erro) {
        setLogradouro(res.logradouro || logradouro);
        setBairro(res.bairro || bairro);
        setCidade(res.localidade || cidade);
        setUf(res.uf || uf);
      }
    }
  };

  const taxaEntrega = tipoEntrega === 'DELIVERY' ? (statusLoja?.taxaEntregaPadrao || 5.0) : 0;
  const total = subtotal + taxaEntrega;

  const handleFinalizarPedido = async () => {
    if (!nome.trim()) {
      Alert.alert('Atenção', 'Por favor, informe seu nome.');
      return;
    }
    if (!telefone.trim() || telefone.replace(/\D/g, '').length < 10) {
      Alert.alert('Atenção', 'Por favor, informe um WhatsApp válido com DDD.');
      return;
    }

    if (tipoEntrega === 'DELIVERY') {
      if (!logradouro.trim() || !numero.trim() || !bairro.trim()) {
        Alert.alert('Atenção', 'Por favor, preencha o endereço completo para entrega.');
        return;
      }
    }

    setEnviando(true);
    try {
      await salvarDadosCliente();

      const payload: PedidoPayload = {
        empresaId: empresa?.id || 'a24167b2-21e4-4b66-b3ff-38827d4a45ea',
        cliente: {
          nome: nome.trim(),
          telefone: telefone.replace(/\D/g, ''),
          cpf: cpf.trim() || undefined,
        },
        tipoEntrega,
        enderecoEntrega:
          tipoEntrega === 'DELIVERY'
            ? {
                nome: nome.trim(),
                telefone: telefone.trim(),
                cep,
                logradouro,
                numero,
                complemento,
                bairro,
                cidade,
                uf,
                referencia,
              }
            : undefined,
        itens: itens.map((i) => ({
          produtoId: i.produtoId,
          nome: i.nome,
          quantidade: i.quantidade,
          precoUnitario: i.precoUnitario,
          observacao: i.observacao,
          tamanhoId: i.tamanho?.id,
          saboresIds: i.sabores?.map((s) => s.id),
          bordaId: i.borda?.id,
        })),
        formaPagamento,
        trocoPara: formaPagamento === 'DINHEIRO' && trocoPara ? parseFloat(trocoPara.replace(',', '.')) : undefined,
        observacaoGeral: observacaoGeral.trim() || undefined,
        subtotal,
        taxaEntrega,
        total,
      };

      const pedidoCriado = await ApiService.criarPedido(payload);
      limparCarrinho();
      onOrderSuccess(pedidoCriado);
    } catch (err: any) {
      Alert.alert(
        'Erro ao enviar pedido',
        err.message || 'Verifique sua conexão ou tente novamente.'
      );
    } finally {
      setEnviando(false);
    }
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={onBack} style={styles.backButton}>
          <ArrowLeft size={22} color={THEME.colors.textPrimary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Finalizar Pedido</Text>
        <View style={{ width: 40 }} />
      </View>

      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        {/* 1. Tipo de Entrega */}
        <View style={styles.card}>
          <Text style={styles.sectionTitle}>Como quer receber?</Text>
          <View style={styles.deliverySelector}>
            <TouchableOpacity
              style={[
                styles.deliveryOption,
                tipoEntrega === 'DELIVERY' && styles.deliveryOptionActive,
              ]}
              onPress={() => setTipoEntrega('DELIVERY')}
            >
              <Bike
                size={20}
                color={tipoEntrega === 'DELIVERY' ? THEME.colors.primary : THEME.colors.textSecondary}
              />
              <Text
                style={[
                  styles.deliveryOptionText,
                  tipoEntrega === 'DELIVERY' && styles.deliveryOptionTextActive,
                ]}
              >
                Entrega (Delivery)
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[
                styles.deliveryOption,
                tipoEntrega === 'RETIRADA' && styles.deliveryOptionActive,
              ]}
              onPress={() => setTipoEntrega('RETIRADA')}
            >
              <Store
                size={20}
                color={tipoEntrega === 'RETIRADA' ? THEME.colors.primary : THEME.colors.textSecondary}
              />
              <Text
                style={[
                  styles.deliveryOptionText,
                  tipoEntrega === 'RETIRADA' && styles.deliveryOptionTextActive,
                ]}
              >
                Retirar no Balcão
              </Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* 2. Seus Dados */}
        <View style={styles.card}>
          <Text style={styles.sectionTitle}>Seus Dados</Text>
          <View style={styles.formGroup}>
            <Text style={styles.inputLabel}>Seu Nome *</Text>
            <TextInput
              style={styles.input}
              placeholder="Ex: João Silva"
              placeholderTextColor={THEME.colors.textMuted}
              value={nome}
              onChangeText={setNome}
            />
          </View>

          <View style={styles.formGroup}>
            <Text style={styles.inputLabel}>WhatsApp com DDD *</Text>
            <TextInput
              style={styles.input}
              placeholder="Ex: (47) 99999-9999"
              placeholderTextColor={THEME.colors.textMuted}
              keyboardType="phone-pad"
              value={telefone}
              onChangeText={setTelefone}
            />
          </View>

          <View style={styles.formGroup}>
            <Text style={styles.inputLabel}>CPF na Nota (Opcional)</Text>
            <TextInput
              style={styles.input}
              placeholder="000.000.000-00"
              placeholderTextColor={THEME.colors.textMuted}
              keyboardType="numeric"
              value={cpf}
              onChangeText={setCpf}
            />
          </View>
        </View>

        {/* 3. Endereço de Entrega (se Delivery) */}
        {tipoEntrega === 'DELIVERY' && (
          <View style={styles.card}>
            <View style={styles.titleWithIcon}>
              <MapPin size={18} color={THEME.colors.primary} />
              <Text style={styles.sectionTitle}>Endereço de Entrega</Text>
            </View>

            <View style={styles.formGroup}>
              <Text style={styles.inputLabel}>CEP</Text>
              <View style={styles.cepRow}>
                <TextInput
                  style={[styles.input, { flex: 1 }]}
                  placeholder="88215-000"
                  placeholderTextColor={THEME.colors.textMuted}
                  keyboardType="numeric"
                  value={cep}
                  onChangeText={setCep}
                  onBlur={handleCepBlur}
                  maxLength={9}
                />
                {buscandoCep && (
                  <ActivityIndicator size="small" color={THEME.colors.primary} style={{ marginLeft: 8 }} />
                )}
              </View>
            </View>

            <View style={styles.row}>
              <View style={[styles.formGroup, { flex: 3, marginRight: 8 }]}>
                <Text style={styles.inputLabel}>Rua / Logradouro *</Text>
                <TextInput
                  style={styles.input}
                  placeholder="Ex: Av. Leopoldo Zarling"
                  placeholderTextColor={THEME.colors.textMuted}
                  value={logradouro}
                  onChangeText={setLogradouro}
                />
              </View>
              <View style={[styles.formGroup, { flex: 1 }]}>
                <Text style={styles.inputLabel}>Nº *</Text>
                <TextInput
                  style={styles.input}
                  placeholder="123"
                  placeholderTextColor={THEME.colors.textMuted}
                  value={numero}
                  onChangeText={setNumero}
                />
              </View>
            </View>

            <View style={styles.formGroup}>
              <Text style={styles.inputLabel}>Bairro *</Text>
              <TextInput
                style={styles.input}
                placeholder="Ex: Bombas"
                placeholderTextColor={THEME.colors.textMuted}
                value={bairro}
                onChangeText={setBairro}
              />
            </View>

            <View style={styles.formGroup}>
              <Text style={styles.inputLabel}>Complemento</Text>
              <TextInput
                style={styles.input}
                placeholder="Apto 201, Bloco B"
                placeholderTextColor={THEME.colors.textMuted}
                value={complemento}
                onChangeText={setComplemento}
              />
            </View>

            <View style={styles.formGroup}>
              <Text style={styles.inputLabel}>Ponto de Referência</Text>
              <TextInput
                style={styles.input}
                placeholder="Próximo ao supermercado"
                placeholderTextColor={THEME.colors.textMuted}
                value={referencia}
                onChangeText={setReferencia}
              />
            </View>
          </View>
        )}

        {/* 4. Forma de Pagamento */}
        <View style={styles.card}>
          <Text style={styles.sectionTitle}>Forma de Pagamento</Text>
          <View style={styles.paymentList}>
            <TouchableOpacity
              style={[
                styles.paymentOption,
                formaPagamento === 'PIX' && styles.paymentOptionActive,
              ]}
              onPress={() => setFormaPagamento('PIX')}
            >
              <QrCode size={20} color={formaPagamento === 'PIX' ? THEME.colors.primary : THEME.colors.textSecondary} />
              <View style={styles.paymentInfo}>
                <Text style={[styles.paymentTitle, formaPagamento === 'PIX' && styles.paymentTitleActive]}>
                  PIX Instantâneo
                </Text>
                <Text style={styles.paymentDesc}>Aprovação automática e envio imediato</Text>
              </View>
              {formaPagamento === 'PIX' && <CheckCircle2 size={18} color={THEME.colors.primary} />}
            </TouchableOpacity>

            <TouchableOpacity
              style={[
                styles.paymentOption,
                formaPagamento === 'DINHEIRO' && styles.paymentOptionActive,
              ]}
              onPress={() => setFormaPagamento('DINHEIRO')}
            >
              <Banknote size={20} color={formaPagamento === 'DINHEIRO' ? THEME.colors.primary : THEME.colors.textSecondary} />
              <View style={styles.paymentInfo}>
                <Text style={[styles.paymentTitle, formaPagamento === 'DINHEIRO' && styles.paymentTitleActive]}>
                  Dinheiro
                </Text>
                <Text style={styles.paymentDesc}>Pagamento na entrega ou balcão</Text>
              </View>
              {formaPagamento === 'DINHEIRO' && <CheckCircle2 size={18} color={THEME.colors.primary} />}
            </TouchableOpacity>

            {formaPagamento === 'DINHEIRO' && (
              <View style={styles.trocoContainer}>
                <Text style={styles.inputLabel}>Precisa de troco para quanto?</Text>
                <TextInput
                  style={styles.input}
                  placeholder="Ex: R$ 100,00 (ou deixe em branco se não precisar)"
                  placeholderTextColor={THEME.colors.textMuted}
                  keyboardType="numeric"
                  value={trocoPara}
                  onChangeText={setTrocoPara}
                />
              </View>
            )}

            <TouchableOpacity
              style={[
                styles.paymentOption,
                formaPagamento === 'CARTAO_ENTREGA' && styles.paymentOptionActive,
              ]}
              onPress={() => setFormaPagamento('CARTAO_ENTREGA')}
            >
              <CreditCard size={20} color={formaPagamento === 'CARTAO_ENTREGA' ? THEME.colors.primary : THEME.colors.textSecondary} />
              <View style={styles.paymentInfo}>
                <Text style={[styles.paymentTitle, formaPagamento === 'CARTAO_ENTREGA' && styles.paymentTitleActive]}>
                  Cartão (Máquina na Entrega)
                </Text>
                <Text style={styles.paymentDesc}>Crédito ou Débito</Text>
              </View>
              {formaPagamento === 'CARTAO_ENTREGA' && <CheckCircle2 size={18} color={THEME.colors.primary} />}
            </TouchableOpacity>
          </View>
        </View>

        {/* 5. Observação Geral */}
        <View style={styles.card}>
          <Text style={styles.sectionTitle}>Observação para a Loja</Text>
          <TextInput
            style={[styles.input, styles.textArea]}
            placeholder="Ex: Tocar o interfone 202, enviar talheres..."
            placeholderTextColor={THEME.colors.textMuted}
            multiline
            numberOfLines={2}
            value={observacaoGeral}
            onChangeText={setObservacaoGeral}
          />
        </View>

        {/* Resumo de Valores */}
        <View style={styles.card}>
          <Text style={styles.sectionTitle}>Resumo do Pedido</Text>
          <View style={styles.calcRow}>
            <Text style={styles.calcLabel}>Subtotal</Text>
            <Text style={styles.calcVal}>R$ {subtotal.toFixed(2).replace('.', ',')}</Text>
          </View>
          <View style={styles.calcRow}>
            <Text style={styles.calcLabel}>Taxa de Entrega</Text>
            <Text style={styles.calcVal}>
              {taxaEntrega > 0 ? `R$ ${taxaEntrega.toFixed(2).replace('.', ',')}` : 'Grátis'}
            </Text>
          </View>
          <View style={styles.calcDivider} />
          <View style={styles.calcRow}>
            <Text style={styles.totalLabel}>Total</Text>
            <Text style={styles.totalVal}>R$ {total.toFixed(2).replace('.', ',')}</Text>
          </View>
        </View>
      </ScrollView>

      {/* Botão de Envio */}
      <View style={styles.footer}>
        <TouchableOpacity
          style={[styles.submitBtn, enviando && { opacity: 0.7 }]}
          onPress={handleFinalizarPedido}
          disabled={enviando}
          activeOpacity={0.88}
        >
          {enviando ? (
            <ActivityIndicator color={THEME.colors.white} />
          ) : (
            <>
              <Text style={styles.submitBtnText}>Confirmar e Enviar Pedido</Text>
              <Text style={styles.submitBtnPrice}>R$ {total.toFixed(2).replace('.', ',')}</Text>
            </>
          )}
        </TouchableOpacity>
      </View>
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
  content: {
    padding: 16,
    gap: 14,
  },
  card: {
    backgroundColor: THEME.colors.card,
    borderRadius: THEME.borderRadius.lg,
    padding: 16,
    borderWidth: 1,
    borderColor: THEME.colors.borderLight,
    ...THEME.shadows.card,
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: THEME.colors.textPrimary,
    marginBottom: 12,
  },
  titleWithIcon: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  deliverySelector: {
    flexDirection: 'row',
    gap: 10,
  },
  deliveryOption: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingVertical: 12,
    borderRadius: THEME.borderRadius.md,
    borderWidth: 1,
    borderColor: THEME.colors.borderLight,
    backgroundColor: THEME.colors.background,
  },
  deliveryOptionActive: {
    borderColor: THEME.colors.primary,
    backgroundColor: THEME.colors.primaryLight,
  },
  deliveryOptionText: {
    fontSize: 13,
    fontWeight: '600',
    color: THEME.colors.textSecondary,
  },
  deliveryOptionTextActive: {
    color: THEME.colors.primary,
    fontWeight: '700',
  },
  formGroup: {
    marginBottom: 10,
  },
  inputLabel: {
    fontSize: 12,
    fontWeight: '600',
    color: THEME.colors.textSecondary,
    marginBottom: 4,
  },
  input: {
    backgroundColor: THEME.colors.background,
    borderRadius: THEME.borderRadius.md,
    borderWidth: 1,
    borderColor: THEME.colors.borderLight,
    paddingHorizontal: 12,
    height: 44,
    fontSize: 14,
    color: THEME.colors.textPrimary,
  },
  textArea: {
    height: 70,
    paddingTop: 10,
    textAlignVertical: 'top',
  },
  row: {
    flexDirection: 'row',
  },
  cepRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  paymentList: {
    gap: 8,
  },
  paymentOption: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
    borderRadius: THEME.borderRadius.md,
    borderWidth: 1,
    borderColor: THEME.colors.borderLight,
    backgroundColor: THEME.colors.background,
    gap: 12,
  },
  paymentOptionActive: {
    borderColor: THEME.colors.primary,
    backgroundColor: '#FFF9F7',
  },
  paymentInfo: {
    flex: 1,
  },
  paymentTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: THEME.colors.textPrimary,
  },
  paymentTitleActive: {
    color: THEME.colors.primary,
  },
  paymentDesc: {
    fontSize: 11,
    color: THEME.colors.textSecondary,
    marginTop: 2,
  },
  trocoContainer: {
    marginTop: 8,
    paddingHorizontal: 8,
  },
  calcRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 6,
  },
  calcLabel: {
    fontSize: 13,
    color: THEME.colors.textSecondary,
  },
  calcVal: {
    fontSize: 13,
    fontWeight: '600',
    color: THEME.colors.textPrimary,
  },
  calcDivider: {
    height: 1,
    backgroundColor: THEME.colors.borderLight,
    marginVertical: 10,
  },
  totalLabel: {
    fontSize: 16,
    fontWeight: '800',
    color: THEME.colors.textPrimary,
  },
  totalVal: {
    fontSize: 18,
    fontWeight: '800',
    color: THEME.colors.primary,
  },
  footer: {
    backgroundColor: THEME.colors.card,
    padding: 16,
    borderTopWidth: 1,
    borderColor: THEME.colors.borderLight,
    ...THEME.shadows.floating,
  },
  submitBtn: {
    backgroundColor: THEME.colors.primary,
    borderRadius: THEME.borderRadius.md,
    paddingVertical: 16,
    paddingHorizontal: 20,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  submitBtnText: {
    color: THEME.colors.white,
    fontSize: 15,
    fontWeight: '700',
  },
  submitBtnPrice: {
    color: THEME.colors.white,
    fontSize: 16,
    fontWeight: '800',
  },
});
