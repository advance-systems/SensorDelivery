import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  TextInput,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { User, Phone, MapPin, Server, Save, Info } from 'lucide-react-native';
import { THEME } from '../constants/theme';
import { STORAGE_KEYS, ApiService, DEFAULT_API_URL } from '../services/api';
import { ClienteEndereco } from '../types';

export const AccountScreen: React.FC = () => {
  const [nome, setNome] = useState('');
  const [telefone, setTelefone] = useState('');
  const [cpf, setCpf] = useState('');

  const [cep, setCep] = useState('');
  const [logradouro, setLogradouro] = useState('');
  const [numero, setNumero] = useState('');
  const [bairro, setBairro] = useState('');
  const [cidade, setCidade] = useState('Bombinhas');
  const [uf, setUf] = useState('SC');

  const [apiUrl, setApiUrl] = useState(DEFAULT_API_URL);
  const [salvando, setSalvando] = useState(false);

  useEffect(() => {
    carregarDados();
  }, []);

  const carregarDados = async () => {
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
        setBairro(end.bairro || '');
        setCidade(end.cidade || 'Bombinhas');
        setUf(end.uf || 'SC');
      }

      const storedUrl = await AsyncStorage.getItem(STORAGE_KEYS.API_URL);
      if (storedUrl) {
        setApiUrl(storedUrl);
      }
    } catch (err) {
      console.warn('Erro ao carregar dados da conta:', err);
    }
  };

  const handleSalvar = async () => {
    setSalvando(true);
    try {
      await AsyncStorage.setItem(
        STORAGE_KEYS.CLIENTE_INFO,
        JSON.stringify({ nome, telefone, cpf })
      );

      await AsyncStorage.setItem(
        STORAGE_KEYS.CLIENTE_ENDERECO,
        JSON.stringify({
          nome,
          telefone,
          cep,
          logradouro,
          numero,
          bairro,
          cidade,
          uf,
        })
      );

      if (apiUrl.trim()) {
        await ApiService.setBaseUrl(apiUrl.trim());
      }

      Alert.alert('Sucesso', 'Seus dados foram atualizados com sucesso!');
    } catch {
      Alert.alert('Erro', 'Não foi possível salvar os dados.');
    } finally {
      setSalvando(false);
    }
  };

  return (
    <SafeAreaView style={styles.safeArea} edges={['top', 'left', 'right']}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Minha Conta</Text>
      </View>

      <ScrollView contentContainerStyle={styles.content} showsVerticalScrollIndicator={false}>
        {/* Dados Pessoais */}
        <View style={styles.card}>
          <View style={styles.cardTitleRow}>
            <User size={18} color={THEME.colors.primary} />
            <Text style={styles.cardTitle}>Dados Pessoais</Text>
          </View>

          <View style={styles.formGroup}>
            <Text style={styles.label}>Nome Completo</Text>
            <TextInput
              style={styles.input}
              placeholder="Seu nome"
              placeholderTextColor={THEME.colors.textMuted}
              value={nome}
              onChangeText={setNome}
            />
          </View>

          <View style={styles.formGroup}>
            <Text style={styles.label}>WhatsApp com DDD</Text>
            <TextInput
              style={styles.input}
              placeholder="(47) 99999-9999"
              placeholderTextColor={THEME.colors.textMuted}
              keyboardType="phone-pad"
              value={telefone}
              onChangeText={setTelefone}
            />
          </View>

          <View style={styles.formGroup}>
            <Text style={styles.label}>CPF (Opcional)</Text>
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

        {/* Endereço Padrão */}
        <View style={styles.card}>
          <View style={styles.cardTitleRow}>
            <MapPin size={18} color={THEME.colors.primary} />
            <Text style={styles.cardTitle}>Endereço Padrão</Text>
          </View>

          <View style={styles.formGroup}>
            <Text style={styles.label}>CEP</Text>
            <TextInput
              style={styles.input}
              placeholder="88215-000"
              placeholderTextColor={THEME.colors.textMuted}
              value={cep}
              onChangeText={setCep}
            />
          </View>

          <View style={styles.row}>
            <View style={[styles.formGroup, { flex: 3, marginRight: 8 }]}>
              <Text style={styles.label}>Rua / Logradouro</Text>
              <TextInput
                style={styles.input}
                placeholder="Rua ou Avenida"
                placeholderTextColor={THEME.colors.textMuted}
                value={logradouro}
                onChangeText={setLogradouro}
              />
            </View>
            <View style={[styles.formGroup, { flex: 1 }]}>
              <Text style={styles.label}>Nº</Text>
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
            <Text style={styles.label}>Bairro</Text>
            <TextInput
              style={styles.input}
              placeholder="Bairro"
              placeholderTextColor={THEME.colors.textMuted}
              value={bairro}
              onChangeText={setBairro}
            />
          </View>
        </View>

        {/* Configurações do Servidor (Idêntico ao Delphi uFrameContaMobile) */}
        <View style={styles.card}>
          <View style={styles.cardTitleRow}>
            <Server size={18} color={THEME.colors.primary} />
            <Text style={styles.cardTitle}>Servidor da API</Text>
          </View>

          <View style={styles.formGroup}>
            <Text style={styles.label}>URL do Backend</Text>
            <TextInput
              style={styles.input}
              placeholder="https://sensordelivery-production.up.railway.app"
              placeholderTextColor={THEME.colors.textMuted}
              value={apiUrl}
              onChangeText={setApiUrl}
              autoCapitalize="none"
            />
          </View>
        </View>

        {/* Botão Salvar */}
        <TouchableOpacity
          style={styles.saveBtn}
          onPress={handleSalvar}
          disabled={salvando}
          activeOpacity={0.88}
        >
          <Save size={20} color={THEME.colors.white} />
          <Text style={styles.saveBtnText}>Salvar Informações</Text>
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
  cardTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 14,
  },
  cardTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: THEME.colors.textPrimary,
  },
  formGroup: {
    marginBottom: 10,
  },
  row: {
    flexDirection: 'row',
  },
  label: {
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
  saveBtn: {
    backgroundColor: THEME.colors.primary,
    borderRadius: THEME.borderRadius.md,
    paddingVertical: 16,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    marginTop: 10,
    marginBottom: 30,
    ...THEME.shadows.floating,
  },
  saveBtnText: {
    color: THEME.colors.white,
    fontSize: 16,
    fontWeight: '700',
  },
});
