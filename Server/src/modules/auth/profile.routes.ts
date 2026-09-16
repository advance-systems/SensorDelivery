import { Router } from 'express';

import {
    autenticarToken,
    type AuthenticatedRequest,
} from '../../middleware/auth.middleware.js';

export const profileRoutes = Router();

profileRoutes.get(
    '/me',
    autenticarToken,
    (request: AuthenticatedRequest, response) => {
        return response.json({
            usuario: request.usuario,
        });
    },
);