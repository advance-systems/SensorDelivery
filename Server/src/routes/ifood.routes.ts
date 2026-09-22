import { Router } from 'express';
import { autenticarToken, empresaIdAutenticada } from '../middleware/auth.middleware.js';
import { exigirAcessoModulo } from '../middleware/permission.middleware.js';
import { IFoodService } from '../services/ifood.service.js';

const router = Router();

// Obter configurações do iFood da empresa
router.get('/configuracao', autenticarToken, exigirAcessoModulo('configuracoes'), async (req, res) => {
    try {
        const empresaId = empresaIdAutenticada(req);
        const config = await IFoodService.obterConfiguracao(empresaId);
        return res.json(config || {
            empresa_id: empresaId,
            ativo: false,
            client_id: null,
            client_secret: null,
            merchant_id: null,
            auto_confirmar_pedidos: false,
            polling_ativo: false,
        });
    } catch (error) {
        console.error('Erro ao obter configuração do iFood:', error);
        return res.status(500).json({ erro: 'Não foi possível carregar a configuração do iFood.' });
    }
});

// Salvar configurações do iFood
router.post('/configuracao', autenticarToken, exigirAcessoModulo('configuracoes'), async (req, res) => {
    try {
        const empresaId = empresaIdAutenticada(req);
        const {
            ativo,
            client_id,
            client_secret,
            merchant_id,
            auto_confirmar_pedidos,
            polling_ativo,
        } = req.body;

        const config = await IFoodService.salvarConfiguracao(empresaId, {
            ativo: Boolean(ativo),
            client_id,
            client_secret,
            merchant_id,
            auto_confirmar_pedidos: Boolean(auto_confirmar_pedidos),
            polling_ativo: Boolean(polling_ativo),
        });

        return res.json({ mensagem: 'Configuração do iFood salva com sucesso.', config });
    } catch (error) {
        console.error('Erro ao salvar configuração do iFood:', error);
        return res.status(500).json({ erro: 'Não foi possível salvar a configuração do iFood.' });
    }
});

// Testar conexão com o iFood
router.post('/testar-conexao', autenticarToken, exigirAcessoModulo('configuracoes'), async (req, res) => {
    try {
        const empresaId = empresaIdAutenticada(req);
        const token = await IFoodService.obterTokenValido(empresaId);
        return res.json({ sucesso: true, mensagem: 'Conexão com a API do iFood validada com sucesso!', tokenGerado: Boolean(token) });
    } catch (error) {
        console.error('Erro no teste de conexão iFood:', error);
        const msg = error instanceof Error ? error.message : 'Erro desconhecido';
        return res.status(400).json({ sucesso: false, erro: msg });
    }
});

// Forçar busca de novos pedidos (polling manual)
router.post('/sincronizar-pedidos', autenticarToken, exigirAcessoModulo('pedidos'), async (req, res) => {
    try {
        const empresaId = empresaIdAutenticada(req);
        const eventos = await IFoodService.consultarEventos(empresaId);
        const importados: Array<{ orderId: string; numero: number }> = [];

        for (const ev of eventos) {
            if (ev.code === 'PLC' || ev.fullCode === 'PLACED') {
                const { numero } = await IFoodService.importarPedidoIFood(empresaId, ev.orderId);
                importados.push({ orderId: ev.orderId, numero });
            }
        }

        if (eventos.length > 0) {
            await IFoodService.confirmarEventos(empresaId, eventos.map((e) => e.id));
        }

        return res.json({
            sucesso: true,
            totalEventos: eventos.length,
            pedidosImportados: importados,
        });
    } catch (error) {
        console.error('Erro na sincronização manual do iFood:', error);
        const msg = error instanceof Error ? error.message : 'Erro desconhecido';
        return res.status(500).json({ erro: 'Falha ao sincronizar pedidos do iFood.', detalhe: msg });
    }
});

export default router;
