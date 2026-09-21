import { Router, type Request } from 'express';
import { database } from '../database/connection.js';

const router = Router();

function normalizarLogoPublico(logoUrl: unknown, req: Request): string | null {
    const valor = String(logoUrl ?? '').trim();
    if (!valor) {
        return null;
    }
    let basePublica = (process.env.API_PUBLIC_URL?.trim()
        || `${req.protocol}://${req.get('host')}`).replace(/\/$/, '');

    // Se a base pública não começar com http, prefixar
    if (basePublica.includes('sistemassensor.com.br') && !basePublica.startsWith('https://')) {
        basePublica = basePublica.replace(/^http:\/\//, 'https://');
        if (!basePublica.startsWith('https://')) {
            basePublica = `https://${basePublica}`;
        }
    }

    let caminhoFinal = valor;
    if (valor.startsWith('/')) {
        caminhoFinal = `${basePublica}${valor}`;
    } else {
        try {
            const url = new URL(valor);
            if (url.pathname.startsWith('/uploads/') || url.pathname.startsWith('/api/uploads/')) {
                const cleanPath = url.pathname.startsWith('/api/uploads/') 
                    ? url.pathname.replace('/api/uploads/', '/uploads/')
                    : url.pathname;
                caminhoFinal = `${basePublica}${cleanPath}${url.search}`;
            }
        } catch {
            caminhoFinal = valor;
        }
    }

    if (!caminhoFinal.includes('?')) {
        caminhoFinal += '?v=2026';
    }
    return caminhoFinal;
}

router.get('/empresas', async (req, res) => {
    try {
        const resultado = await database.query(
            `SELECT id, nome_fantasia, razao_social, logo_url, telefone, email
             FROM empresas
             WHERE ativo = TRUE
             ORDER BY nome_fantasia`,
        );
        const empresas = resultado.rows.map((empresa) => ({
            ...empresa,
            logo_url: normalizarLogoPublico(empresa.logo_url, req),
        }));
        return res.status(200).json({ empresas });
    } catch (error) {
        console.error('Erro ao listar empresas públicas:', error);
        return res.status(500).json({ erro: 'Não foi possível listar as lojas.' });
    }
});

router.get('/status', async (req, res) => {
    try {
        const empresaId = String(
            req.query.empresaId ?? ''
        ).trim();

        if (!empresaId) {
            return res.status(400).json({
                erro: 'empresaId é obrigatório.',
            });
        }

        // ------------------------------------------------
        // DADOS DA EMPRESA
        // ------------------------------------------------
        const empresaResult = await database.query(
            `SELECT id, nome_fantasia, razao_social, logo_url, telefone, email
             FROM empresas
             WHERE id = $1
             LIMIT 1`,
            [empresaId],
        );
        const empresaDados = empresaResult.rows[0] ? {
            ...empresaResult.rows[0],
            logo_url: normalizarLogoPublico(empresaResult.rows[0].logo_url, req),
        } : null;

        // ------------------------------------------------
        // CONFIGURAÇÃO DA LOJA
        // ------------------------------------------------

        const configResult = await database.query(
            `
            SELECT
                modo_funcionamento,
                mensagem_fechada,
                taxa_entrega,
                pedido_minimo,
                tempo_entrega_minutos,
                pix_cidade_recebedor
            FROM loja_configuracao
            WHERE empresa_id = $1
            LIMIT 1
            `,
            [empresaId]
        );

        // Uma empresa nova (ou um banco recém-limpo) ainda pode não possuir
        // configuração de horários. Isso não significa que a API esteja fora
        // do ar: publicamos a loja como fechada até o painel ser configurado.
        const config = configResult.rows[0] ?? {
            modo_funcionamento: 'FECHADO',
            mensagem_fechada: 'Loja em configuração.',
            taxa_entrega: 0,
            pedido_minimo: 0,
            tempo_entrega_minutos: 45,
        };

        // ------------------------------------------------
        // DATA/HORA
        // ------------------------------------------------

        const agora = new Date();

        // JavaScript:
        // 0 = domingo
        // 1 = segunda
        // ...
        // 6 = sábado
        const diaSemana = agora.getDay();

        // ------------------------------------------------
        // HORÁRIO DE HOJE
        // ------------------------------------------------

        const horarioResult = await database.query(
            `
            SELECT
                dia_semana,
                horario_abertura,
                horario_fechamento,
                fechado
            FROM loja_horarios
            WHERE empresa_id = $1
              AND dia_semana = $2
            LIMIT 1
            `,
            [
                empresaId,
                diaSemana
            ]
        );

        const horario =
            horarioResult.rows[0] ?? null;

        let aberta = false;
        let motivo = '';

        // ------------------------------------------------
        // ABERTURA MANUAL
        // ------------------------------------------------

        if (config.modo_funcionamento === 'ABERTO') {
            aberta = true;
            motivo = 'ABERTURA_MANUAL';
        }

        // ------------------------------------------------
        // FECHAMENTO MANUAL
        // ------------------------------------------------

        else if (config.modo_funcionamento === 'FECHADO') {
            aberta = false;
            motivo = 'FECHAMENTO_MANUAL';
        }

        // ------------------------------------------------
        // AUTOMÁTICO
        // ------------------------------------------------

        else {
            if (!horario) {
                aberta = false;
                motivo = 'SEM_HORARIO';
            }
            else if (horario.fechado) {
                aberta = false;
                motivo = 'DIA_FECHADO';
            }
            else {
                const horaAtual =
                    agora
                        .toLocaleTimeString(
                            'pt-BR',
                            {
                                hour12: false,
                                timeZone: 'America/Sao_Paulo',
                            }
                        );

                aberta =
                    horaAtual >= horario.horario_abertura &&
                    horaAtual <= horario.horario_fechamento;

                motivo =
                    aberta
                        ? 'DENTRO_HORARIO'
                        : 'FORA_HORARIO';
            }
        }

        // ------------------------------------------------
        // TODOS OS HORÁRIOS
        // ------------------------------------------------

        const horariosResult = await database.query(
            `
            SELECT
                dia_semana,
                horario_abertura,
                horario_fechamento,
                fechado
            FROM loja_horarios
            WHERE empresa_id = $1
            ORDER BY dia_semana
            `,
            [empresaId]
        );

        // ------------------------------------------------
        // RESPOSTA
        // ------------------------------------------------

        return res.status(200).json({
            online: true,
            aberta,
            status: aberta ? 'ABERTA' : 'FECHADA',
            motivo,
            empresa: empresaDados ? {
                id: empresaDados.id,
                nome: empresaDados.nome_fantasia || empresaDados.razao_social,
                razaoSocial: empresaDados.razao_social,
                logoUrl: empresaDados.logo_url,
                telefone: empresaDados.telefone,
                email: empresaDados.email,
                cidade: config.pix_cidade_recebedor || '',
            } : null,
            mensagem: aberta
                ? 'Estamos recebendo pedidos.'
                : (config.mensagem_fechada || 'No momento não estamos recebendo pedidos.'),
            hoje: horario,
            horarios: horariosResult.rows,
            horarioFuncionamento: horario && !horario.fechado
                ? `${horario.horario_abertura?.slice(0, 5)} às ${horario.horario_fechamento?.slice(0, 5)}`
                : (horario?.fechado ? 'Fechado hoje' : '18:00 às 23:30'),
            tempoEntregaMin: config.tempo_entrega_minutos ? Math.max(15, config.tempo_entrega_minutos - 15) : 30,
            tempoEntregaMax: config.tempo_entrega_minutos || 50,
            taxaEntregaPadrao: Number(config.taxa_entrega || 0),
            pedidoMinimo: Number(config.pedido_minimo || 0),
        });
    } catch (error) {
        console.error('Erro ao consultar status da loja:', error);
        return res.status(500).json({
            online: false,
            aberta: false,
            status: 'INDISPONIVEL',
            erro: 'Não foi possível consultar a situação da loja.',
        });
    }
});

export default router;
