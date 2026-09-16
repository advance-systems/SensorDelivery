import { randomUUID } from 'node:crypto';
import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import express, { Router } from 'express';

const router = Router();
const tiposPermitidos: Record<string, string> = {
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/webp': '.webp',
    'image/gif': '.gif',
};

router.post('/imagens', express.raw({
    type: ['image/jpeg', 'image/png', 'image/webp', 'image/gif'],
    limit: '8mb',
}), async (req, res) => {
    const contentType = String(req.headers['content-type'] ?? '').split(';').at(0) ?? '';
    const extensao = tiposPermitidos[contentType];
    if (!extensao || !Buffer.isBuffer(req.body) || req.body.length === 0) {
        return res.status(400).json({ erro: 'Selecione uma imagem JPG, PNG, WEBP ou GIF.' });
    }
    try {
        const pasta = path.resolve(process.cwd(), 'uploads');
        await mkdir(pasta, { recursive: true });
        const nome = `${randomUUID()}${extensao}`;
        await writeFile(path.join(pasta, nome), req.body);
        const baseUrl = process.env.API_PUBLIC_URL?.trim().replace(/\/$/, '') ||
            `${req.protocol}://${req.get('host')}`;
        const url = `${baseUrl}/uploads/${nome}`;
        return res.status(201).json({ url, nome });
    } catch (error) {
        console.error('Erro ao salvar imagem:', error);
        return res.status(500).json({ erro: 'Não foi possível salvar a imagem.' });
    }
});

export default router;
