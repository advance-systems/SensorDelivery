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
  User,
  Phone,
  FileText,
  Search,
  MessageSquare,
} from 'lucide-react-native';
import { THEME } from '../constants/theme';
import { useCart } from '../contexts/CartContext';
import { useStore } from '../contexts/StoreContext';
import { ApiService, STORAGE_KEYS } from '../services/api';

export const CheckoutScreen = ({ onBack, onOrderSuccess }) => {
  const { itens, subtotal, limparCarrinho } = useCart();
  const { empresa, statusLoja } = useStore();

  const [tipoEntrega, setTipoEntrega] = useState('DELIVERY');
  const [formaPagamento, setFormaPagamento] = useState('PIX');
  const [trocoPara, setTrocoPara] = useState('');
  const [observacaoGeral, setObservacaoGeral] = useState('');
  const [enviando, setEnviando] = useState(false);

  // Focos para feedback visual estilo SensorEdit
  const [campoFocado, setCampoFocado] = useState(null);

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
      const savedUser = await AsyncStorage.getItem(STORAGE_KEYS.USER_DATA);
      if (savedUser) {
        const u = JSON.parse(savedUser);
        setNome(u.nome || '');
        setTelefone(u.telefone || '');
        setCpf(u.cpf || '');
      }
      const savedAddr = await AsyncStorage.getItem(STORAGE_KEYS.LAST_ADDRESS);
      if (savedAddr) {
        const a = JSON.parse(savedAddr);
        setCep(a.cep || '');
        setLogradouro(a.logradouro || '');
        setNumero(a.numero || '');
        setComplemento(a.complemento || '');
        setBairro(a.bairro || '');
        setCidade(a.cidade || 'Bombinhas');
        setUf(a.uf || 'SC');
        setReferencia(a.referencia || '');
      }
    } catch (e) {
      console.warn('Erro ao carregar dados salvos:', e);
    }
  };

  const buscarCep = async (valor) => {
    const limpo = valor.replace(/\D/g, '');
    setCep(limpo);
    if (limpo.length === 8) {
      setBuscandoCep(true);
      try {
        const res = await fetch(`https://viacep.com.br/ws/${limpo}/json/`);
        const data = await res.json();
        if (!data.erro) {
          setLogradouro(data.logradouro || '');
          setBairro(data.bairro || '');
          setCidade(data.localidade || cidade);
          setUf(data.uf || uf);
        }
      } catch (e) {
        console.warn('Erro ao buscar CEP:', e);
      } finally {
        setBuscandoCep(false);
      }
    }
  };

  const taxaEntrega = tipoEntrega === 'DELIVERY' ? Number(empresa?.taxaEntregaPadrao || 5.0) : 0;
  const valorTotal = subtotal + taxaEntrega;

  const validarFormulario = () => {
    if (!nome.trim()) {
      Alert.alert('Atenção', 'Por favor, informe seu nome.');
      return false;
    }
    if (!telefone.trim() || telefone.length < 8) {
      Alert.alert('Atenção', 'Por favor, informe um telefone/WhatsApp válido.');
      return false;
    }
    if (tipoEntrega === 'DELIVERY') {
      if (!logradouro.trim() || !numero.trim() || !bairro.trim()) {
        Alert.alert('Atenção', 'Por favor, preencha o endereço completo (Rua, Número e Bairro).');
        return false;
      }
    }
    return true;
  };

  const handleFinalizar = async () => {
    if (!validarFormulario()) return;

    setEnviando(true);
    try {
      await AsyncStorage.setItem(
        STORAGE_KEYS.USER_DATA,
        JSON.stringify({ nome, telefone, cpf })
      );
      if (tipoEntrega === 'DELIVERY') {
        await AsyncStorage.setItem(
          STORAGE_KEYS.LAST_ADDRESS,
          JSON.stringify({ cep, logradouro, numero, complemento, bairro, cidade, uf, referencia })
        );
      }

      const payload = {
        empresaId: empresa?.id || 1,
        clienteNome: nome,
        clienteTelefone: telefone,
        clienteCpf: cpf || null,
        tipoEntrega,
        formaPagamento,
        trocoPara: formaPagamento === 'DINHEIRO' && trocoPara ? Number(trocoPara.replace(',', '.')) : null,
        observacao: observacaoGeral || null,
        subtotal,
        taxaEntrega,
        total: valorTotal,
        endereco: tipoEntrega === 'DELIVERY' ? {
          cep,
          logradouro,
          numero,
          complemento,
          bairro,
          cidade,
          uf,
          referencia,
        } : null,
        itens: itens.map((item) => ({
          produtoId: item.produtoId,
          tipoProduto: item.tipoProduto || 'PRODUTO',
          nome: item.nome,
          quantidade: item.quantidade,
          precoUnitario: item.precoUnitario,
          precoTotal: item.precoTotal,
          observacao: item.observacao,
          detalhesPizza: item.detalhesPizza || null,
          adicionais: item.adicionais || [],
        })),
      };

      const pedidoCriado = await ApiService.criarPedido(payload);
      limparCarrinho();
      onOrderSuccess(pedidoCriado);
    } catch (err) {
      console.error('Erro ao enviar pedido:', err);
      Alert.alert('Erro ao enviar pedido', err.message || 'Tente novamente.');
    } finally {
      setEnviando(false);
    }
  };

  return (
    <SafeAreaView style={styles.safeArea} edges={['top', 'left', 'right']}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={onBack} style={styles.backButton}>
          <ArrowLeft size={20} color={THEME.colors.textPrimary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Finalizar Pedido</Text>
        <View style={{ width: 40 }} />
      </View>

      <ScrollView contentContainerStyle={styles.container} showsVerticalScrollIndicator={false}>
        {/* 1. Tipo de Entrega */}
        <View style={styles.card}>
          <Text style={styles.sectionTitle}>Como deseja receber?</Text>
          <View style={styles.deliveryToggle}>
            <TouchableOpacity
              style={[
                styles.deliveryOption,
                tipoEntrega === 'DELIVERY' && styles.deliveryOptionActive,
              ]}
              onPress={() => setTipoEntrega('DELIVERY')}
            >
              <Bike size={20} color={tipoEntrega === 'DELIVERY' ? THEME.colors.white : THEME.colors.textSecondary} />
              <Text
                style={[
                  styles.deliveryOptionText,
                  tipoEntrega === 'DELIVERY' && styles.deliveryOptionTextActive,
                ]}
              >
                Entrega
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[
                styles.deliveryOption,
                tipoEntrega === 'RETIRADA' && styles.deliveryOptionActive,
              ]}
              onPress={() => setTipoEntrega('RETIRADA')}
            >
              <Store size={20} color={tipoEntrega === 'RETIRADA' ? THEME.colors.white : THEME.colors.textSecondary} />
              <Text
                style={[
                  styles.deliveryOptionText,
                  tipoEntrega === 'RETIRADA' && styles.deliveryOptionTextActive,
                ]}
              >
                Retirar no Local
              </Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* 2. Seus Dados (Campos SensorEdit) */}
        <View style={styles.card}>
          <Text style={styles.sectionTitle}>Seus Dados</Text>

          <View style={styles.sensorEditGroup}>
            <Text style={styles.sensorEditLabel}>Nome Completo *</Text>
            <View style={[styles.sensorEditBox, campoFocado === 'nome' && styles.sensorEditBoxFocus]}>
              <User size={18} color={campoFocado === 'nome' ? THEME.colors.primary : THEME.colors.textSecondary} style={styles.sensorEditIcon} />
              <TextInput
                style={styles.sensorEditInput}
                placeholder="Ex: João da Silva"
                placeholderTextColor={THEME.colors.textMuted}
                value={nome}
                onChangeText={setNome}
                onFocus={() => setCampoFocado('nome')}
                onBlur={() => setCampoFocado(null)}
              />
              {campoFocado === 'nome' && <View style={styles.sensorEditFocusLine} />}
            </View>
          </View>

          <View style={styles.sensorEditGroup}>
            <Text style={styles.sensorEditLabel}>WhatsApp / Telefone *</Text>
            <View style={[styles.sensorEditBox, campoFocado === 'telefone' && styles.sensorEditBoxFocus]}>
              <Phone size={18} color={campoFocado === 'telefone' ? THEME.colors.primary : THEME.colors.textSecondary} style={styles.sensorEditIcon} />
              <TextInput
                style={styles.sensorEditInput}
                placeholder="(47) 99999-9999"
                placeholderTextColor={THEME.colors.textMuted}
                keyboardType="phone-pad"
                value={telefone}
                onChangeText={setTelefone}
                onFocus={() => setCampoFocado('telefone')}
                onBlur={() => setCampoFocado(null)}
              />
              {campoFocado === 'telefone' && <View style={styles.sensorEditFocusLine} />}
            </View>
          </View>

          <View style={styles.sensorEditGroup}>
            <Text style={styles.sensorEditLabel}>CPF (Opcional na Nota)</Text>
            <View style={[styles.sensorEditBox, campoFocado === 'cpf' && styles.sensorEditBoxFocus]}>
              <FileText size={18} color={campoFocado === 'cpf' ? THEME.colors.primary : THEME.colors.textSecondary} style={styles.sensorEditIcon} />
              <TextInput
                style={styles.sensorEditInput}
                placeholder="000.000.000-00"
                placeholderTextColor={THEME.colors.textMuted}
                keyboardType="numeric"
                value={cpf}
                onChangeText={setCpf}
                onFocus={() => setCampoFocado('cpf')}
                onBlur={() => setCampoFocado(null)}
              />
              {campoFocado === 'cpf' && <View style={styles.sensorEditFocusLine} />}
            </View>
          </View>
        </View>

        {/* 3. Endereço de Entrega */}
        {tipoEntrega === 'DELIVERY' && (
          <View style={styles.card}>
            <Text style={styles.sectionTitle}>Endereço de Entrega</Text>

            <View style={styles.sensorEditGroup}>
              <Text style={styles.sensorEditLabel}>CEP (Preenchimento Automático)</Text>
              <View style={[styles.sensorEditBox, campoFocado === 'cep' && styles.sensorEditBoxFocus]}>
                <MapPin size={18} color={campoFocado === 'cep' ? THEME.colors.primary : THEME.colors.textSecondary} style={styles.sensorEditIcon} />
                <TextInput
                  style={styles.sensorEditInput}
                  placeholder="88215-000"
                  placeholderTextColor={THEME.colors.textMuted}
                  keyboardType="numeric"
                  maxLength={8}
                  value={cep}
                  onChangeText={buscarCep}
                  onFocus={() => setCampoFocado('cep')}
                  onBlur={() => setCampoFocado(null)}
                />
                {buscandoCep && <ActivityIndicator size="small" color={THEME.colors.primary} />}
                {campoFocado === 'cep' && <View style={styles.sensorEditFocusLine} />}
              </View>
            </View>

            <View style={styles.row}>
              <View style={[styles.sensorEditGroup, { flex: 2.2, marginRight: 8 }]}>
                <Text style={styles.sensorEditLabel}>Rua / Logradouro *</Text>
                <View style={[styles.sensorEditBox, campoFocado === 'rua' && styles.sensorEditBoxFocus]}>
                  <TextInput
                    style={styles.sensorEditInput}
                    placeholder="Nome da rua"
                    placeholderTextColor={THEME.colors.textMuted}
                    value={logradouro}
                    onChangeText={setLogradouro}
                    onFocus={() => setCampoFocado('rua')}
                    onBlur={() => setCampoFocado(null)}
                  />
                  {campoFocado === 'rua' && <View style={styles.sensorEditFocusLine} />}
                </View>
              </View>

              <View style={[styles.sensorEditGroup, { flex: 1 }]}>
                <Text style={styles.sensorEditLabel}>Nº *</Text>
                <View style={[styles.sensorEditBox, campoFocado === 'numero' && styles.sensorEditBoxFocus]}>
                  <TextInput
                    style={styles.sensorEditInput}
                    placeholder="123"
                    placeholderTextColor={THEME.colors.textMuted}
                    value={numero}
                    onChangeText={setNumero}
                    onFocus={() => setCampoFocado('numero')}
                    onBlur={() => setCampoFocado(null)}
                  />
                  {campoFocado === 'numero' && <View style={styles.sensorEditFocusLine} />}
                </View>
              </View>
            </View>

            <View style={styles.row}>
              <View style={[styles.sensorEditGroup, { flex: 1, marginRight: 8 }]}>
                <Text style={styles.sensorEditLabel}>Bairro *</Text>
                <View style={[styles.sensorEditBox, campoFocado === 'bairro' && styles.sensorEditBoxFocus]}>
                  <TextInput
                    style={styles.sensorEditInput}
                    placeholder="Bairro"
                    placeholderTextColor={THEME.colors.textMuted}
                    value={bairro}
                    onChangeText={setBairro}
                    onFocus={() => setCampoFocado('bairro')}
                    onBlur={() => setCampoFocado(null)}
                  />
                  {campoFocado === 'bairro' && <View style={styles.sensorEditFocusLine} />}
                </View>
              </View>

              <View style={[styles.sensorEditGroup, { flex: 1 }]}>
                <Text style={styles.sensorEditLabel}>Complemento</Text>
                <View style={[styles.sensorEditBox, campoFocado === 'compl' && styles.sensorEditBoxFocus]}>
                  <TextInput
                    style={styles.sensorEditInput}
                    placeholder="Apto 101"
                    placeholderTextColor={THEME.colors.textMuted}
                    value={complemento}
                    onChangeText={setComplemento}
                    onFocus={() => setCampoFocado('compl')}
                    onBlur={() => setCampoFocado(null)}
                  />
                  {campoFocado === 'compl' && <View style={styles.sensorEditFocusLine} />}
                </View>
              </View>
            </View>

            <View style={styles.sensorEditGroup}>
              <Text style={styles.sensorEditLabel}>Ponto de Referência</Text>
              <View style={[styles.sensorEditBox, campoFocado === 'ref' && styles.sensorEditBoxFocus]}>
                <TextInput
                  style={styles.sensorEditInput}
                  placeholder="Ex: Próximo à padaria"
                  placeholderTextColor={THEME.colors.textMuted}
                  value={referencia}
                  onChangeText={setReferencia}
                  onFocus={() => setCampoFocado('ref')}
                  onBlur={() => setCampoFocado(null)}
                />
                {campoFocado === 'ref' && <View style={styles.sensorEditFocusLine} />}
              </View>
            </View>
          </View>
        )}

        {/* 4. Forma de Pagamento */}
        <View style={styles.card}>
          <Text style={styles.sectionTitle}>Forma de Pagamento</Text>

          <View style={styles.paymentOptions}>
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
              <View style={styles.sensorEditGroup}>
                <Text style={styles.sensorEditLabel}>Troco para quanto?</Text>
                <View style={styles.sensorEditBox}>
                  <TextInput
                    style={styles.sensorEditInput}
                    placeholder="Ex: R$ 100,00"
                    placeholderTextColor={THEME.colors.textMuted}
                    keyboardType="numeric"
                    value={trocoPara}
                    onChangeText={setTrocoPara}
                  />
                </View>
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

        {/* 5. Observação */}
        <View style={styles.card}>
          <Text style={styles.sectionTitle}>Observação para o Pedido</Text>
          <View style={[styles.sensorEditBox, { height: 72, alignItems: 'flex-start', paddingTop: 8 }]}>
            <MessageSquare size={18} color={THEME.colors.textSecondary} style={{ marginRight: 8, marginTop: 2 }} />
            <TextInput
              style={[styles.sensorEditInput, { height: 60, textAlignVertical: 'top' }]}
              placeholder="Ex: Tocar o interfone 202..."
              placeholderTextColor={THEME.colors.textMuted}
              multiline
              value={observacaoGeral}
              onChangeText={setObservacaoGeral}
            />
          </View>
        </View>

        {/* Resumo do Pedido */}
        <View style={styles.card}>
          <Text style={styles.sectionTitle}>Resumo dos Valores</Text>
          <View style={styles.calcRow}>
            <Text style={styles.calcLabel}>Subtotal</Text>
            <Text style={styles.calcVal}>R$ {Number(subtotal).toFixed(2).replace('.', ',')}</Text>
          </View>
          <View style={styles.calcRow}>
            <Text style={styles.calcLabel}>Taxa de Entrega</Text>
            <Text style={styles.calcVal}>
              {taxaEntrega > 0 ? `R$ ${taxaEntrega.toFixed(2).replace('.', ',')}` : 'Grátis'}
            </Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.calcRow}>
            <Text style={styles.totalLabel}>Total a Pagar</Text>
            <Text style={styles.totalVal}>R$ {valorTotal.toFixed(2).replace('.', ',')}</Text>
          </View>
        </View>

        {/* Botão de Envio SensorButton */}
        <View style={styles.actionContainer}>
          <TouchableOpacity
            style={[styles.sensorButton, enviando && { opacity: 0.7 }]}
            onPress={handleFinalizar}
            disabled={enviando}
            activeOpacity={0.88}
          >
            {enviando ? (
              <ActivityIndicator color={THEME.colors.white} />
            ) : (
              <>
                <Text style={styles.sensorButtonText}>
                  Confirmar e Enviar Pedido (R$ {valorTotal.toFixed(2).replace('.', ',')})
                </Text>
              </>
            )}
          </TouchableOpacity>
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
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: THEME.colors.border,
    backgroundColor: THEME.colors.card,
  },
  backButton: {
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: THEME.borderRadius.md,
    backgroundColor: THEME.colors.inputBackground,
  },
  headerTitle: {
    fontSize: 17,
    fontWeight: '800',
    color: THEME.colors.textPrimary,
  },
  container: {
    padding: 16,
    gap: 14,
    paddingBottom: 40,
  },
  card: {
    backgroundColor: THEME.colors.card,
    borderRadius: THEME.borderRadius.lg,
    padding: 16,
    borderWidth: 1,
    borderColor: THEME.colors.border,
    ...THEME.shadows.card,
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: '800',
    color: THEME.colors.textPrimary,
    marginBottom: 12,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  deliveryToggle: {
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
    borderColor: THEME.colors.border,
    backgroundColor: THEME.colors.inputBackground,
  },
  deliveryOptionActive: {
    backgroundColor: THEME.colors.primary,
    borderColor: THEME.colors.primary,
  },
  deliveryOptionText: {
    fontSize: 13,
    fontWeight: '700',
    color: THEME.colors.textSecondary,
  },
  deliveryOptionTextActive: {
    color: THEME.colors.white,
  },
  sensorEditGroup: {
    marginBottom: 10,
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
  row: {
    flexDirection: 'row',
  },
  paymentOptions: {
    gap: 10,
  },
  paymentOption: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 12,
    borderRadius: THEME.borderRadius.md,
    borderWidth: 1,
    borderColor: THEME.colors.border,
    backgroundColor: THEME.colors.inputBackground,
    gap: 12,
  },
  paymentOptionActive: {
    borderColor: THEME.colors.primary,
    backgroundColor: THEME.colors.primaryLight,
  },
  paymentInfo: {
    flex: 1,
  },
  paymentTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: THEME.colors.textPrimary,
  },
  paymentTitleActive: {
    color: THEME.colors.primaryDark,
  },
  paymentDesc: {
    fontSize: 11,
    color: THEME.colors.textSecondary,
    marginTop: 2,
  },
  calcRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingVertical: 4,
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
  divider: {
    height: 1,
    backgroundColor: THEME.colors.borderLight,
    marginVertical: 8,
  },
  totalLabel: {
    fontSize: 15,
    fontWeight: '800',
    color: THEME.colors.textPrimary,
  },
  totalVal: {
    fontSize: 17,
    fontWeight: '800',
    color: THEME.colors.primary,
  },
  actionContainer: {
    marginTop: 10,
  },
  sensorButton: {
    backgroundColor: THEME.colors.primary,
    height: 50,
    borderRadius: THEME.borderRadius.xl,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    ...THEME.shadows.button,
  },
  sensorButtonText: {
    color: THEME.colors.white,
    fontSize: 15,
    fontWeight: '700',
  },
});
