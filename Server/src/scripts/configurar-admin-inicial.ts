import { database } from '../database/connection.js';

function obrigatorio(nome: string): string {
  const valor = process.env[nome]?.trim();

  if (!valor) {
    throw new Error(`${nome} não foi informado.`);
  }

  return valor;
}

async function configurarAdminInicial(): Promise<void> {
  const email = obrigatorio('SENSOR_ADMIN_EMAIL').toLowerCase();
  const senha = obrigatorio('SENSOR_ADMIN_PASSWORD');

  if (senha.length < 8) {
    throw new Error('A senha inicial deve ter pelo menos 8 caracteres.');
  }

  const resultado = await database.query(
    `
      UPDATE usuarios
      SET email = $1,
          senha_hash = crypt($2, gen_salt('bf', 12)),
          ativo = TRUE,
          atualizado_em = CURRENT_TIMESTAMP
      WHERE email = 'admin@sensordelivery.local'
         OR tipo = 'ADMIN'
      RETURNING id
    `,
    [email, senha],
  );

  if (!resultado.rowCount) {
    throw new Error('O usuário administrador inicial não foi encontrado.');
  }

  console.log(`Administrador inicial configurado: ${email}`);
}

configurarAdminInicial()
  .catch((error) => {
    console.error('Falha ao configurar o administrador inicial:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await database.end();
  });
