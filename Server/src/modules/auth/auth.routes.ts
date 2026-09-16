import { Router } from 'express';
import { autenticarToken } from '../../middleware/auth.middleware.js';
import { AuthController } from './auth.controller.js';

export const authRoutes = Router();
const authController = new AuthController();

authRoutes.post('/login', authController.login.bind(authController));
authRoutes.post(
    '/selecionar-empresa',
    autenticarToken,
    authController.selecionarEmpresa.bind(authController),
);
