import React, { useState, useEffect, useRef } from 'react';
import { api } from '../api/client';
import { Package, Plus, Edit2, Search, AlertCircle, X, Check, Image as ImageIcon, Upload, Trash2 } from 'lucide-react';

interface Categoria {
  id: string;
  nome: string;
}

interface ProdutoSimples {
  id: string;
  nome: string;
  preco: number;
}

interface ComboItem {
  produtoId: string;
  produtoNome?: string;
  quantidade: number;
}

interface Combo {
  id: string;
  categoria_id: string;
  categoria_nome?: string;
  nome: string;
  descricao?: string;
  preco: number;
  preco_promocional?: number | null;
  imagem_url?: string | null;
  disponivel: boolean;
  destaque: boolean;
  itens?: ComboItem[];
}

export const Combos: React.FC = () => {
  const [combos, setCombos] = useState<Combo[]>([]);
  const [categorias, setCategorias] = useState<Categoria[]>([]);
  const [produtosDisponiveis, setProdutosDisponiveis] = useState<ProdutoSimples[]>([]);
  const [carregando, setCarregando] = useState(true);
  const [modalAberto, setModalAberto] = useState(false);
  const [salvando, setSalvando] = useState(false);
  const [enviandoImg, setEnviandoImg] = useState(false);
  const [erro, setErro] = useState('');
  const [busca, setBusca] = useState('');

  // Form
  const [editandoId, setEditandoId] = useState<string | null>(null);
  const [categoriaId, setCategoriaId] = useState('');
  const [nome, setNome] = useState('');
  const [descricao, setDescricao] = useState('');
  const [preco, setPreco] = useState('');
  const [precoPromocional, setPrecoPromocional] = useState('');
  const [imagemUrl, setImagemUrl] = useState('');
  const [destaque, setDestaque] = useState(false);
  const [disponivel, setDisponivel] = useState(true);
  const [itensCombo, setItensCombo] = useState<ComboItem[]>([]);

  // Item para adicionar ao combo
  const [produtoSelecionadoId, setProdutoSelecionadoId] = useState('');
  const [qtdItem, setQtdItem] = useState('1');

  const fileInputRef = useRef<HTMLInputElement>(null);

  const carregarDados = async () => {
    try {
      setCarregando(true);
      const [resCombos, resCats, resProds] = await Promise.all([
        api.get('/combos'),
        api.get('/combos/categorias'),
        api.get('/combos/produtos-disponiveis'),
      ]);

      setCombos(resCombos.data?.combos || (Array.isArray(resCombos.data) ? resCombos.data : []));
      const listaCats = resCats.data?.categorias || (Array.isArray(resCats.data) ? resCats.data : []);
      setCategorias(listaCats);
      const listaProds = resProds.data?.produtos || (Array.isArray(resProds.data) ? resProds.data : []);
      setProdutosDisponiveis(listaProds);

      if (listaCats.length > 0 && !categoriaId) {
        setCategoriaId(listaCats[0].id);
      }
      if (listaProds.length > 0 && !produtoSelecionadoId) {
        setProdutoSelecionadoId(listaProds[0].id);
      }
    } catch (err: any) {
      console.error('Erro ao carregar combos:', err);
    } finally {
      setCarregando(false);
    }
  };

  useEffect(() => {
    carregarDados();
  }, []);

  const formatarMoeda = (valor: number) => {
    return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(valor || 0);
  };

  const abrirModalNovo = () => {
    setEditandoId(null);
    if (categorias.length > 0) setCategoriaId(categorias[0].id);
    setNome('');
    setDescricao('');
    setPreco('');
    setPrecoPromocional('');
    setImagemUrl('');
    setDestaque(false);
    setDisponivel(true);
    setItensCombo([]);
    setErro('');
    setModalAberto(true);
  };

  const abrirModalEditar = async (combo: Combo) => {
    setEditandoId(combo.id);
    setCategoriaId(combo.categoria_id);
    setNome(combo.nome);
    setDescricao(combo.descricao || '');
    setPreco(Number(combo.preco || 0).toFixed(2).replace('.', ','));
    setPrecoPromocional(combo.preco_promocional ? Number(combo.preco_promocional).toFixed(2).replace('.', ',') : '');
    setImagemUrl(combo.imagem_url || '');
    setDestaque(Boolean(combo.destaque));
    setDisponivel(Boolean(combo.disponivel));
    setErro('');

    try {
      const resDetalhes = await api.get(`/combos/${combo.id}`);
      const itensCarregados = resDetalhes.data?.combo?.itens || [];
      setItensCombo(
        itensCarregados.map((it: any) => ({
          produtoId: it.produto_id,
          produtoNome: it.produto_nome,
          quantidade: Number(it.quantidade || 1),
        }))
      );
    } catch {
      setItensCombo([]);
    }

    setModalAberto(true);
  };

  const fecharModal = () => {
    setModalAberto(false);
    setEditandoId(null);
    setErro('');
  };

  const handleUploadImagem = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (!['image/jpeg', 'image/png', 'image/webp', 'image/gif'].includes(file.type)) {
      setErro('Selecione uma imagem válida (JPG, PNG ou WEBP).');
      return;
    }

    try {
      setEnviandoImg(true);
      setErro('');
      const buffer = await file.arrayBuffer();
      const res = await api.post('/uploads/imagens', buffer, {
        headers: { 'Content-Type': file.type },
      });
      if (res.data?.url) {
        setImagemUrl(res.data.url);
      }
    } catch (err: any) {
      setErro(err.response?.data?.erro || 'Erro ao enviar imagem.');
    } finally {
      setEnviandoImg(false);
      if (fileInputRef.current) fileInputRef.current.value = '';
    }
  };

  const adicionarItemAoCombo = () => {
    if (!produtoSelecionadoId) return;
    const prod = produtosDisponiveis.find((p) => p.id === produtoSelecionadoId);
    if (!prod) return;

    if (itensCombo.some((it) => it.produtoId === prod.id)) {
      setErro('Este produto já está adicionado ao combo.');
      return;
    }

    const qtd = Math.max(1, parseInt(qtdItem, 10) || 1);
    setItensCombo([...itensCombo, { produtoId: prod.id, produtoNome: prod.nome, quantidade: qtd }]);
    setErro('');
  };

  const removerItemDoCombo = (pId: string) => {
    setItensCombo(itensCombo.filter((it) => it.produtoId !== pId));
  };

  const salvarCombo = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!nome.trim()) {
      setErro('Nome do combo é obrigatório.');
      return;
    }
    if (!categoriaId) {
      setErro('Selecione uma categoria.');
      return;
    }
    if (itensCombo.length === 0) {
      setErro('Adicione pelo menos um produto à composição do combo.');
      return;
    }

    const precoNum = Number(preco.replace(/\./g, '').replace(',', '.')) || 0;
    const promoNum = precoPromocional.trim()
      ? Number(precoPromocional.replace(/\./g, '').replace(',', '.'))
      : null;

    try {
      setSalvando(true);
      setErro('');

      const payload = {
        categoriaId,
        nome: nome.trim(),
        descricao: descricao.trim(),
        preco: precoNum,
        precoPromocional: promoNum,
        imagemUrl: imagemUrl.trim() || null,
        destaque,
        disponivel,
        itens: itensCombo.map((it, idx) => ({
          produtoId: it.produtoId,
          quantidade: it.quantidade,
          ordem: idx,
        })),
      };

      if (editandoId) {
        await api.put(`/combos/${editandoId}`, payload);
      } else {
        await api.post('/combos', payload);
      }

      fecharModal();
      carregarDados();
    } catch (err: any) {
      console.error('Erro ao salvar combo:', err);
      setErro(err.response?.data?.erro || 'Erro ao salvar combo.');
    } finally {
      setSalvando(false);
    }
  };

  const alternarDisponibilidade = async (combo: Combo) => {
    try {
      await api.patch(`/combos/${combo.id}/disponibilidade`, { disponivel: !combo.disponivel });
      setCombos(combos.map((c) => (c.id === combo.id ? { ...c, disponivel: !c.disponivel } : c)));
    } catch (err: any) {
      console.error('Erro ao alternar disponibilidade:', err);
      alert(err.response?.data?.erro || 'Não foi possível alterar a disponibilidade.');
    }
  };

  const combosFiltrados = combos.filter((c) =>
    c.nome.toLowerCase().includes(busca.toLowerCase()) ||
    (c.descricao && c.descricao.toLowerCase().includes(busca.toLowerCase()))
  );

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white flex items-center gap-2">
            <Package className="w-7 h-7 text-indigo-400" />
            Combos & Promoções
          </h1>
          <p className="text-sm text-slate-400">
            Crie ofertas especiais agrupando pizzas, bebidas e sobremesas com preços exclusivos
          </p>
        </div>
        <button
          onClick={abrirModalNovo}
          className="inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-indigo-600 hover:bg-indigo-500 text-white font-medium rounded-xl transition-colors shadow-lg shadow-indigo-600/20"
        >
          <Plus className="w-5 h-5" />
          Novo Combo
        </button>
      </div>

      {/* Busca */}
      <div className="bg-[#152439] p-4 rounded-2xl border border-[#2A405B] flex items-center gap-3">
        <Search className="w-5 h-5 text-slate-400" />
        <input
          type="text"
          placeholder="Buscar combos ou promoções..."
          value={busca}
          onChange={(e) => setBusca(e.target.value)}
          className="bg-transparent border-none outline-none text-white w-full placeholder-slate-500 text-sm"
        />
        {busca && (
          <button onClick={() => setBusca('')} className="text-slate-400 hover:text-white">
            <X className="w-4 h-4" />
          </button>
        )}
      </div>

      {/* Tabela de Combos */}
      <div className="bg-[#152439] rounded-2xl border border-[#2A405B] overflow-hidden shadow-xl">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-slate-300">
            <thead className="bg-[#0B132B]/80 text-xs uppercase text-slate-400 font-semibold border-b border-[#2A405B]">
              <tr>
                <th className="px-6 py-4">Combo</th>
                <th className="px-6 py-4">Categoria</th>
                <th className="px-6 py-4">Preço Original</th>
                <th className="px-6 py-4">Preço Promocional</th>
                <th className="px-6 py-4">Status</th>
                <th className="px-6 py-4 text-right">Ações</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#2A405B]">
              {carregando ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-slate-400">
                    <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-500"></div>
                    <p className="mt-2">Carregando combos...</p>
                  </td>
                </tr>
              ) : combosFiltrados.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-slate-400">
                    <Package className="w-12 h-12 mx-auto text-slate-600 mb-2" />
                    <p className="text-base font-medium text-slate-300">Nenhum combo cadastrado</p>
                    <p className="text-xs text-slate-500 mt-1">
                      {busca ? 'Tente ajustar os termos da busca.' : 'Clique em "Novo Combo" para criar sua primeira oferta.'}
                    </p>
                  </td>
                </tr>
              ) : (
                combosFiltrados.map((combo) => (
                  <tr key={combo.id} className="hover:bg-[#1e324d]/40 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-12 h-12 rounded-xl bg-[#0B132B] border border-[#2A405B] overflow-hidden flex items-center justify-center shrink-0">
                          {combo.imagem_url ? (
                            <img
                              src={combo.imagem_url}
                              alt={combo.nome}
                              className="w-full h-full object-cover"
                            />
                          ) : (
                            <Package className="w-6 h-6 text-slate-500" />
                          )}
                        </div>
                        <div>
                          <div className="font-semibold text-white flex items-center gap-2">
                            {combo.nome}
                            {combo.destaque && (
                              <span className="px-2 py-0.5 bg-amber-500/10 text-amber-400 text-[10px] font-bold rounded-full border border-amber-500/20">
                                Destaque
                              </span>
                            )}
                          </div>
                          {combo.descricao && (
                            <div className="text-xs text-slate-400 line-clamp-1">
                              {combo.descricao}
                            </div>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className="px-2.5 py-1 bg-[#0B132B] rounded-lg border border-[#2A405B] text-xs text-slate-300">
                        {combo.categoria_nome || 'Combos'}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className={combo.preco_promocional ? 'line-through text-slate-500 text-xs' : 'text-white font-medium'}>
                        {formatarMoeda(combo.preco)}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      {combo.preco_promocional ? (
                        <span className="font-bold text-emerald-400">
                          {formatarMoeda(combo.preco_promocional)}
                        </span>
                      ) : (
                        <span className="text-xs text-slate-500">-</span>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      <button
                        onClick={() => alternarDisponibilidade(combo)}
                        className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium border transition-colors ${
                          combo.disponivel
                            ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20 hover:bg-emerald-500/20'
                            : 'bg-red-500/10 text-red-400 border-red-500/20 hover:bg-red-500/20'
                        }`}
                      >
                        {combo.disponivel ? (
                          <>
                            <Check className="w-3.5 h-3.5" />
                            Disponível
                          </>
                        ) : (
                          <>
                            <X className="w-3.5 h-3.5" />
                            Esgotado
                          </>
                        )}
                      </button>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <button
                        onClick={() => abrirModalEditar(combo)}
                        className="p-2 text-slate-400 hover:text-indigo-400 hover:bg-indigo-500/10 rounded-lg transition-colors"
                        title="Editar Combo"
                      >
                        <Edit2 className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal de Cadastro / Edição */}
      {modalAberto && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-[#152439] border border-[#2A405B] w-full max-w-2xl rounded-2xl shadow-2xl overflow-hidden max-h-[90vh] flex flex-col">
            {/* Modal Header */}
            <div className="px-6 py-4 border-b border-[#2A405B] flex items-center justify-between bg-[#0B132B]/50">
              <h2 className="text-lg font-bold text-white flex items-center gap-2">
                <Package className="w-5 h-5 text-indigo-400" />
                {editandoId ? 'Editar Combo' : 'Novo Combo'}
              </h2>
              <button
                onClick={fecharModal}
                className="text-slate-400 hover:text-white p-1 rounded-lg hover:bg-[#2A405B]/50 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Body */}
            <form onSubmit={salvarCombo} className="flex-1 overflow-y-auto p-6 space-y-5">
              {erro && (
                <div className="p-3 bg-red-500/10 border border-red-500/20 rounded-xl flex items-center gap-3 text-red-400 text-sm">
                  <AlertCircle className="w-5 h-5 shrink-0" />
                  <span>{erro}</span>
                </div>
              )}

              {/* Upload Foto */}
              <div className="flex items-center gap-4 p-3 bg-[#0B132B] rounded-xl border border-[#2A405B]">
                <div className="w-16 h-16 rounded-xl bg-[#152439] border border-[#2A405B] overflow-hidden flex items-center justify-center shrink-0">
                  {imagemUrl ? (
                    <img src={imagemUrl} alt="Preview" className="w-full h-full object-cover" />
                  ) : (
                    <ImageIcon className="w-6 h-6 text-slate-500" />
                  )}
                </div>
                <div className="flex-1">
                  <input
                    type="file"
                    ref={fileInputRef}
                    onChange={handleUploadImagem}
                    accept="image/*"
                    className="hidden"
                  />
                  <div className="flex items-center gap-2">
                    <button
                      type="button"
                      onClick={() => fileInputRef.current?.click()}
                      disabled={enviandoImg}
                      className="px-3 py-1.5 bg-indigo-600/20 hover:bg-indigo-600/30 text-indigo-400 text-xs font-semibold rounded-lg border border-indigo-500/30 transition-colors inline-flex items-center gap-1.5"
                    >
                      <Upload className="w-3.5 h-3.5" />
                      {enviandoImg ? 'Enviando...' : imagemUrl ? 'Alterar Imagem' : 'Enviar Imagem'}
                    </button>
                    {imagemUrl && (
                      <button
                        type="button"
                        onClick={() => setImagemUrl('')}
                        className="px-3 py-1.5 bg-red-500/10 hover:bg-red-500/20 text-red-400 text-xs font-semibold rounded-lg border border-red-500/20"
                      >
                        Remover
                      </button>
                    )}
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400">
                    Nome do Combo <span className="text-red-400">*</span>
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="Ex: Combo Família + Refri Grátis"
                    value={nome}
                    onChange={(e) => setNome(e.target.value)}
                    className="w-full px-3.5 py-2.5 bg-[#0B132B] border border-[#2A405B] rounded-xl text-white placeholder-slate-500 text-sm focus:border-indigo-500 focus:outline-none transition-colors"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400">
                    Categoria <span className="text-red-400">*</span>
                  </label>
                  <select
                    required
                    value={categoriaId}
                    onChange={(e) => setCategoriaId(e.target.value)}
                    className="w-full px-3.5 py-2.5 bg-[#0B132B] border border-[#2A405B] rounded-xl text-white text-sm focus:border-indigo-500 focus:outline-none transition-colors"
                  >
                    {categorias.map((c) => (
                      <option key={c.id} value={c.id}>
                        {c.nome}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="space-y-1.5">
                <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400">
                  Descrição
                </label>
                <textarea
                  rows={2}
                  placeholder="Ex: 1 Pizza Grande + 1 Refrigerante 2L + 1 Borda de Catupiry"
                  value={descricao}
                  onChange={(e) => setDescricao(e.target.value)}
                  className="w-full px-3.5 py-2.5 bg-[#0B132B] border border-[#2A405B] rounded-xl text-white placeholder-slate-500 text-sm focus:border-indigo-500 focus:outline-none transition-colors"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1.5">
                  <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400">
                    Preço Normal (R$) <span className="text-red-400">*</span>
                  </label>
                  <input
                    type="text"
                    required
                    placeholder="0,00"
                    value={preco}
                    onChange={(e) => setPreco(e.target.value)}
                    className="w-full px-3.5 py-2.5 bg-[#0B132B] border border-[#2A405B] rounded-xl text-white placeholder-slate-500 text-sm focus:border-indigo-500 focus:outline-none transition-colors"
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400">
                    Preço Promocional (R$)
                  </label>
                  <input
                    type="text"
                    placeholder="0,00 (opcional)"
                    value={precoPromocional}
                    onChange={(e) => setPrecoPromocional(e.target.value)}
                    className="w-full px-3.5 py-2.5 bg-[#0B132B] border border-[#2A405B] rounded-xl text-white placeholder-slate-500 text-sm focus:border-indigo-500 focus:outline-none transition-colors"
                  />
                </div>
              </div>

              {/* Composição do Combo (Produtos inclusos) */}
              <div className="space-y-3 pt-2">
                <label className="block text-xs font-semibold uppercase tracking-wider text-slate-400">
                  Composição do Combo (Produtos Inclusos) <span className="text-red-400">*</span>
                </label>

                <div className="flex gap-2">
                  <select
                    value={produtoSelecionadoId}
                    onChange={(e) => setProdutoSelecionadoId(e.target.value)}
                    className="flex-1 px-3 py-2 bg-[#0B132B] border border-[#2A405B] rounded-xl text-white text-xs focus:border-indigo-500 focus:outline-none"
                  >
                    {produtosDisponiveis.map((p) => (
                      <option key={p.id} value={p.id}>
                        {p.nome} ({formatarMoeda(p.preco)})
                      </option>
                    ))}
                  </select>
                  <input
                    type="number"
                    min="1"
                    max="99"
                    value={qtdItem}
                    onChange={(e) => setQtdItem(e.target.value)}
                    className="w-16 px-2 py-2 bg-[#0B132B] border border-[#2A405B] rounded-xl text-white text-xs text-center focus:border-indigo-500 focus:outline-none"
                  />
                  <button
                    type="button"
                    onClick={adicionarItemAoCombo}
                    className="px-3.5 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-xs font-semibold transition-colors flex items-center gap-1"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    Adicionar
                  </button>
                </div>

                <div className="space-y-1.5 bg-[#0B132B] p-3 rounded-xl border border-[#2A405B] min-h-[60px]">
                  {itensCombo.length === 0 ? (
                    <p className="text-xs text-slate-500 text-center py-2">
                      Nenhum produto adicionado ao combo ainda.
                    </p>
                  ) : (
                    itensCombo.map((it) => (
                      <div
                        key={it.produtoId}
                        className="flex items-center justify-between p-2 bg-[#152439] rounded-lg border border-[#2A405B]/60"
                      >
                        <span className="text-xs text-slate-200">
                          <strong className="text-indigo-400">{it.quantidade}x</strong> {it.produtoNome}
                        </span>
                        <button
                          type="button"
                          onClick={() => removerItemDoCombo(it.produtoId)}
                          className="p-1 text-slate-400 hover:text-red-400 transition-colors"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    ))
                  )}
                </div>
              </div>

              <div className="flex items-center gap-6 pt-2">
                <label className="flex items-center gap-2.5 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={destaque}
                    onChange={(e) => setDestaque(e.target.checked)}
                    className="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500 bg-[#0B132B] border-[#2A405B]"
                  />
                  <span className="text-sm text-slate-300 font-medium">Combo em Destaque</span>
                </label>

                <label className="flex items-center gap-2.5 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={disponivel}
                    onChange={(e) => setDisponivel(e.target.checked)}
                    className="w-4 h-4 rounded text-indigo-600 focus:ring-indigo-500 bg-[#0B132B] border-[#2A405B]"
                  />
                  <span className="text-sm text-slate-300 font-medium">Disponível para Pedidos</span>
                </label>
              </div>

              {/* Modal Footer */}
              <div className="pt-4 border-t border-[#2A405B] flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={fecharModal}
                  className="px-4 py-2 bg-transparent hover:bg-[#2A405B]/40 text-slate-300 text-sm font-medium rounded-xl transition-colors"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={salvando || enviandoImg}
                  className="inline-flex items-center gap-2 px-5 py-2.5 bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 text-white text-sm font-semibold rounded-xl transition-colors shadow-lg shadow-indigo-600/20"
                >
                  {salvando ? (
                    <>
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                      Salvando...
                    </>
                  ) : (
                    <>
                      <Check className="w-4 h-4" />
                      Salvar Combo
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Combos;
