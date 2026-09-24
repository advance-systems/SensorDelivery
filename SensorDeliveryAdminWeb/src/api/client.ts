import axios from 'axios';

export const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://sensordelivery-production.up.railway.app/api';

export const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 15000,
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('@SensorDelivery:token');
  const empresaId = localStorage.getItem('@SensorDelivery:empresaId');

  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }

  if (empresaId) {
    config.headers['X-Empresa-ID'] = empresaId;
  }

  return config;
}, (error) => {
  return Promise.reject(error);
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      // Se 401 não for na rota de login, desloga
      if (!window.location.pathname.includes('/login')) {
        localStorage.removeItem('@SensorDelivery:token');
        localStorage.removeItem('@SensorDelivery:usuario');
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);
