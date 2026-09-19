import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  TextInput,
  Image,
  ActivityIndicator,
  Modal,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { X, Check, Plus, Minus } from 'lucide-react-native';
import { THEME } from '../constants/theme';
import { ApiService } from '../services/api';
import { useCart } from '../contexts/CartContext';

export const PizzaBuilderModal = ({ visible, produto, onClose }) => {
  const { adicionarItem } = useCart();

  const [tamanhos, setTamanhos] = useState([]);
  const [sabores, setSabores] = useState([]);
  const [bordas, setBordas] = useState([]);
  const [carregando, setCarregando] = useState(true);

  const [tamanhoSelecionado, setTamanhoSelecionado] = useState(null);
  const [saboresSelecionados, setSaboresSelecionados] = useState([]);
  const [bordaSelecionada, setBordaSelecionada] = useState(null);
  const [observacao, setObservacao] = useState('');
  const [quantidade, setQuantidade] = useState(1);

  useEffect(() => {
    if (visible && produto) {
      carregarOpcoes();
    }
  }, [visible, produto]);

  const carregarOpcoes = async () => {
    if (!produto) return;
    setCarregando(true);
    try {
      const [saboresTamanhos, listaBordas] = await Promise.all([
        ApiService.getSaboresTamanhos(produto.id),
        ApiService.getBordas(produto.id),
      ]);

      setTamanhos(saboresTamanhos.tamanhos || []);
      setSabores(saboresTamanhos.sabores || []);
      setBordas(listaBordas || []);

      if (saboresTamanhos.tamanhos?.length > 0) {
        const padrao = saboresTamanhos.tamanhos[1] || saboresTamanhos.tamanhos[0];
        setTamanhoSelecionado(padrao);
      }

      if (saboresTamanhos.sabores?.length > 0) {
        setSaboresSelecionados([saboresTamanhos.sabores[0]]);
      }

      if (listaBordas?.length > 0) {
        setBordaSelecionada(listaBordas[0]);
      }

      setQuantidade(1);
      setObservacao('');
    } catch (err) {
      console.warn('Erro ao carregar opções de pizza:', err);
    } finally {
      setCarregando(false);
    }
  };

  const handleToggleSabor = (sabor) => {
    if (!tamanhoSelecionado) return;

    const jaSelecionado = saboresSelecionados.some((s) => s.id === sabor.id);
    if (jaSelecionado) {
      if (saboresSelecionados.length > 1) {
        setSaboresSelecionados((prev) => prev.filter((s) => s.id !== sabor.id));
      }
    } else {
      if (saboresSelecionados.length < tamanhoSelecionado.maxSabores) {
        setSaboresSelecionados((prev) => [...prev, sabor]);
      } else {
        setSaboresSelecionados((prev) => [...prev.slice(1), sabor]);
      }
    }
  };

  const precoBase = tamanhoSelecionado ? Number(tamanhoSelecionado.precoBase) : Number(produto?.preco || 0);
  const maiorAdicionalSabor = saboresSelecionados.reduce(
    (max, s) => Math.max(max, Number(s.precoAdicional || 0)),
    0
  );
  const precoBorda = Number(bordaSelecionada?.preco || 0);
  const precoUnitarioTotal = precoBase + maiorAdicionalSabor + precoBorda;
  const precoFinal = precoUnitarioTotal * quantidade;

  const handleConfirmar = () => {
    if (!produto) return;

    adicionarItem({
      produtoId: produto.id,
      nome: tamanhoSelecionado
        ? `${produto.nome} (${tamanhoSelecionado.nome})`
        : produto.nome,
      precoUnitario: precoUnitarioTotal,
      quantidade,
      observacao,
      tipo: 'PIZZA',
      tamanho: tamanhoSelecionado,
      sabores: saboresSelecionados,
      borda: bordaSelecionada,
      imagemUrl: produto.imagemUrl,
    });

    onClose();
  };

  return (
    <Modal visible={visible} animationType="slide" transparent={false} onRequestClose={onClose}>
      <SafeAreaView style={styles.safeArea}>
        {/* Header Modal */}
        <View style={styles.header}>
          <TouchableOpacity onPress={onClose} style={styles.closeButton}>
            <X size={22} color={THEME.colors.textPrimary} />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>Montar Pizza</Text>
          <View style={{ width: 40 }} />
        </View>

        {carregando ? (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="large" color={THEME.colors.primary} />
            <Text style={styles.loadingText}>Carregando opções...</Text>
          </View>
        ) : (
          <ScrollView contentContainerStyle={styles.scrollContent} showsVerticalScrollIndicator={false}>
            {/* Banner */}
            <View style={styles.productBanner}>
              {produto?.imagemUrl ? (
                <Image source={{ uri: produto.imagemUrl }} style={styles.bannerImage} resizeMode="cover" />
              ) : (
                <View style={styles.placeholderBanner}>
                  <Text style={{ fontSize: 50 }}>🍕</Text>
                </View>
              )}
              <Text style={styles.prodName}>{produto?.nome}</Text>
              <Text style={styles.prodDesc}>{produto?.descricao || 'Personalize o tamanho, sabores e borda recheada'}</Text>
            </View>

            {/* 1. Tamanho */}
            <View style={styles.section}>
              <View style={styles.sectionHeader}>
                <Text style={styles.sectionTitle}>1. Escolha o Tamanho</Text>
                <Text style={styles.requiredTag}>Obrigatório</Text>
              </View>
              <View style={styles.optionsList}>
                {tamanhos.map((tam) => {
                  const isSelected = tamanhoSelecionado?.id === tam.id;
                  return (
                    <TouchableOpacity
                      key={tam.id}
                      style={[styles.optionCard, isSelected && styles.optionCardActive]}
                      onPress={() => {
                        setTamanhoSelecionado(tam);
                        if (saboresSelecionados.length > tam.maxSabores) {
                          setSaboresSelecionados(saboresSelecionados.slice(0, tam.maxSabores));
                        }
                      }}
                    >
                      <View style={styles.optionInfo}>
                        <Text style={[styles.optionName, isSelected && styles.optionTextActive]}>
                          {tam.nome}
                        </Text>
                        <Text style={styles.optionSub}>
                          Até {tam.maxSabores} {tam.maxSabores > 1 ? 'sabores' : 'sabor'} • {tam.fatias} fatias
                        </Text>
                      </View>
                      <View style={styles.optionRight}>
                        <Text style={[styles.optionPrice, isSelected && styles.optionTextActive]}>
                          R$ {Number(tam.precoBase).toFixed(2).replace('.', ',')}
                        </Text>
                        <View style={[styles.radioCircle, isSelected && styles.radioCircleActive]}>
                          {isSelected && <View style={styles.radioInner} />}
                        </View>
                      </View>
                    </TouchableOpacity>
                  );
                })}
              </View>
            </View>

            {/* 2. Sabores */}
            {tamanhoSelecionado && (
              <View style={styles.section}>
                <View style={styles.sectionHeader}>
                  <Text style={styles.sectionTitle}>
                    2. Escolha os Sabores ({saboresSelecionados.length}/{tamanhoSelecionado.maxSabores})
                  </Text>
                  <Text style={styles.requiredTag}>Selecione até {tamanhoSelecionado.maxSabores}</Text>
                </View>
                <View style={styles.optionsList}>
                  {sabores.map((sabor) => {
                    const isSelected = saboresSelecionados.some((s) => s.id === sabor.id);
                    return (
                      <TouchableOpacity
                        key={sabor.id}
                        style={[styles.optionCard, isSelected && styles.optionCardActive]}
                        onPress={() => handleToggleSabor(sabor)}
                      >
                        <View style={styles.optionInfo}>
                          <Text style={[styles.optionName, isSelected && styles.optionTextActive]}>
                            {sabor.nome}
                          </Text>
                          {sabor.descricao ? (
                            <Text style={styles.optionSub}>{sabor.descricao}</Text>
                          ) : null}
                          {sabor.precoAdicional ? (
                            <Text style={styles.adicionalText}>
                              + R$ {Number(sabor.precoAdicional).toFixed(2).replace('.', ',')}
                            </Text>
                          ) : null}
                        </View>
                        <View style={[styles.checkboxSquare, isSelected && styles.checkboxSquareActive]}>
                          {isSelected && <Check size={14} color={THEME.colors.white} />}
                        </View>
                      </TouchableOpacity>
                    );
                  })}
                </View>
              </View>
            )}

            {/* 3. Borda */}
            {bordas.length > 0 && (
              <View style={styles.section}>
                <View style={styles.sectionHeader}>
                  <Text style={styles.sectionTitle}>3. Borda Recheada</Text>
                  <Text style={styles.optionalTag}>Opcional</Text>
                </View>
                <View style={styles.optionsList}>
                  {bordas.map((borda) => {
                    const isSelected = bordaSelecionada?.id === borda.id;
                    return (
                      <TouchableOpacity
                        key={borda.id}
                        style={[styles.optionCard, isSelected && styles.optionCardActive]}
                        onPress={() => setBordaSelecionada(borda)}
                      >
                        <View style={styles.optionInfo}>
                          <Text style={[styles.optionName, isSelected && styles.optionTextActive]}>
                            {borda.nome}
                          </Text>
                        </View>
                        <View style={styles.optionRight}>
                          <Text style={[styles.optionPrice, isSelected && styles.optionTextActive]}>
                            {Number(borda.preco) > 0
                              ? `+ R$ ${Number(borda.preco).toFixed(2).replace('.', ',')}`
                              : 'Grátis'}
                          </Text>
                          <View style={[styles.radioCircle, isSelected && styles.radioCircleActive]}>
                            {isSelected && <View style={styles.radioInner} />}
                          </View>
                        </View>
                      </TouchableOpacity>
                    );
                  })}
                </View>
              </View>
            )}

            {/* Observações */}
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>Alguma observação?</Text>
              <TextInput
                style={styles.obsInput}
                placeholder="Ex: Sem cebola, massa bem assada..."
                placeholderTextColor={THEME.colors.textMuted}
                multiline
                numberOfLines={3}
                value={observacao}
                onChangeText={setObservacao}
              />
            </View>
          </ScrollView>
        )}

        {/* Barra Inferior */}
        <View style={styles.bottomBar}>
          <View style={styles.quantityControl}>
            <TouchableOpacity
              style={styles.qtyBtn}
              onPress={() => setQuantidade((q) => Math.max(1, q - 1))}
            >
              <Minus size={18} color={THEME.colors.textPrimary} />
            </TouchableOpacity>
            <Text style={styles.qtyText}>{quantidade}</Text>
            <TouchableOpacity
              style={styles.qtyBtn}
              onPress={() => setQuantidade((q) => q + 1)}
            >
              <Plus size={18} color={THEME.colors.textPrimary} />
            </TouchableOpacity>
          </View>

          <TouchableOpacity
            style={styles.confirmBtn}
            onPress={handleConfirmar}
            activeOpacity={0.88}
          >
            <Text style={styles.confirmBtnText}>Adicionar</Text>
            <Text style={styles.confirmBtnPrice}>
              R$ {precoFinal.toFixed(2).replace('.', ',')}
            </Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    </Modal>
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
    borderBottomWidth: 1,
    borderColor: THEME.colors.borderLight,
    backgroundColor: THEME.colors.card,
  },
  closeButton: {
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
  scrollContent: {
    paddingBottom: 40,
  },
  productBanner: {
    backgroundColor: THEME.colors.card,
    padding: 20,
    alignItems: 'center',
    borderBottomWidth: 1,
    borderColor: THEME.colors.borderLight,
  },
  bannerImage: {
    width: 140,
    height: 140,
    borderRadius: 70,
    marginBottom: 12,
  },
  placeholderBanner: {
    width: 120,
    height: 120,
    borderRadius: 60,
    backgroundColor: THEME.colors.background,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 12,
  },
  prodName: {
    fontSize: 22,
    fontWeight: '800',
    color: THEME.colors.textPrimary,
    textAlign: 'center',
  },
  prodDesc: {
    fontSize: 13,
    color: THEME.colors.textSecondary,
    textAlign: 'center',
    marginTop: 4,
  },
  section: {
    marginTop: 16,
    paddingHorizontal: 20,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
  },
  sectionTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: THEME.colors.textPrimary,
  },
  requiredTag: {
    fontSize: 11,
    fontWeight: '600',
    color: THEME.colors.primary,
    backgroundColor: THEME.colors.primaryLight,
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: THEME.borderRadius.sm,
  },
  optionalTag: {
    fontSize: 11,
    fontWeight: '600',
    color: THEME.colors.textSecondary,
    backgroundColor: THEME.colors.borderLight,
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: THEME.borderRadius.sm,
  },
  optionsList: {
    gap: 8,
  },
  optionCard: {
    backgroundColor: THEME.colors.card,
    borderRadius: THEME.borderRadius.md,
    padding: 14,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderWidth: 1,
    borderColor: THEME.colors.borderLight,
    ...THEME.shadows.card,
  },
  optionCardActive: {
    borderColor: THEME.colors.primary,
    backgroundColor: '#FFF9F7',
  },
  optionInfo: {
    flex: 1,
    marginRight: 10,
  },
  optionName: {
    fontSize: 14,
    fontWeight: '700',
    color: THEME.colors.textPrimary,
  },
  optionSub: {
    fontSize: 12,
    color: THEME.colors.textSecondary,
    marginTop: 2,
  },
  adicionalText: {
    fontSize: 12,
    color: THEME.colors.primary,
    fontWeight: '600',
    marginTop: 2,
  },
  optionRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  optionPrice: {
    fontSize: 14,
    fontWeight: '700',
    color: THEME.colors.textPrimary,
  },
  optionTextActive: {
    color: THEME.colors.primary,
  },
  radioCircle: {
    width: 20,
    height: 20,
    borderRadius: 10,
    borderWidth: 2,
    borderColor: THEME.colors.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  radioCircleActive: {
    borderColor: THEME.colors.primary,
  },
  radioInner: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: THEME.colors.primary,
  },
  checkboxSquare: {
    width: 20,
    height: 20,
    borderRadius: 4,
    borderWidth: 2,
    borderColor: THEME.colors.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  checkboxSquareActive: {
    borderColor: THEME.colors.primary,
    backgroundColor: THEME.colors.primary,
  },
  obsInput: {
    backgroundColor: THEME.colors.card,
    borderRadius: THEME.borderRadius.md,
    padding: 12,
    fontSize: 14,
    color: THEME.colors.textPrimary,
    borderWidth: 1,
    borderColor: THEME.colors.borderLight,
    marginTop: 8,
    textAlignVertical: 'top',
  },
  bottomBar: {
    backgroundColor: THEME.colors.card,
    paddingHorizontal: 20,
    paddingVertical: 14,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
    borderTopWidth: 1,
    borderColor: THEME.colors.borderLight,
    ...THEME.shadows.floating,
  },
  quantityControl: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: THEME.colors.background,
    borderRadius: THEME.borderRadius.md,
    paddingHorizontal: 4,
    paddingVertical: 4,
    borderWidth: 1,
    borderColor: THEME.colors.borderLight,
  },
  qtyBtn: {
    width: 32,
    height: 32,
    alignItems: 'center',
    justifyContent: 'center',
  },
  qtyText: {
    fontSize: 15,
    fontWeight: '800',
    color: THEME.colors.textPrimary,
    paddingHorizontal: 12,
  },
  confirmBtn: {
    flex: 1,
    backgroundColor: THEME.colors.primary,
    borderRadius: THEME.borderRadius.md,
    paddingVertical: 14,
    paddingHorizontal: 16,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  confirmBtnText: {
    color: THEME.colors.white,
    fontSize: 15,
    fontWeight: '700',
  },
  confirmBtnPrice: {
    color: THEME.colors.white,
    fontSize: 15,
    fontWeight: '800',
  },
});
