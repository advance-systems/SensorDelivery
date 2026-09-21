import React from 'react';

export const metadata = {
  title: 'Política de Privacidade | Sensor Delivery',
  description: 'Política de privacidade e termos de uso do aplicativo Sensor Delivery',
};

export default function PoliticaPrivacidade() {
  return (
    <div style={{ maxWidth: '800px', margin: '0 auto', padding: '40px 20px', fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif', color: '#333', lineHeight: '1.6' }}>
      <h1 style={{ color: '#111', fontSize: '28px', borderBottom: '2px solid #ea1d2c', paddingBottom: '12px' }}>
        Política de Privacidade – Sensor Delivery
      </h1>
      <p style={{ color: '#666', fontSize: '14px' }}>Última atualização: {new Date().toLocaleDateString('pt-BR')}</p>

      <section style={{ marginTop: '24px' }}>
        <h2 style={{ fontSize: '20px', color: '#222' }}>1. Introdução</h2>
        <p>
          A presente Política de Privacidade descreve como o aplicativo <strong>Sensor Delivery</strong> coleta, utiliza, armazena e protege as informações dos usuários ao utilizar nossos serviços de delivery e pedidos.
        </p>
      </section>

      <section style={{ marginTop: '24px' }}>
        <h2 style={{ fontSize: '20px', color: '#222' }}>2. Informações Coletadas</h2>
        <p>Para o correto funcionamento da plataforma e entrega dos pedidos, podemos coletar os seguintes dados:</p>
        <ul>
          <li><strong>Dados de Identificação:</strong> Nome completo, número de telefone/WhatsApp e endereço de e-mail.</li>
          <li><strong>Dados de Entrega:</strong> Endereço completo, complemento e referências de localização.</li>
          <li><strong>Histórico de Pedidos:</strong> Itens solicitados, horários, valores e status de entrega.</li>
          <li><strong>Dados do Dispositivo:</strong> Identificadores de notificação push para aviso de status do pedido.</li>
        </ul>
      </section>

      <section style={{ marginTop: '24px' }}>
        <h2 style={{ fontSize: '20px', color: '#222' }}>3. Finalidade do Uso dos Dados</h2>
        <p>Os dados coletados têm como finalidades exclusivas:</p>
        <ul>
          <li>Processar, confirmar e gerenciar seus pedidos de delivery.</li>
          <li>Possibilitar a comunicação direta com o cliente via WhatsApp/SMS/Notificação sobre o andamento do pedido.</li>
          <li>Realizar a entrega no endereço correto.</li>
          <li>Melhorar a experiência de navegação e desempenho do aplicativo.</li>
        </ul>
      </section>

      <section style={{ marginTop: '24px' }}>
        <h2 style={{ fontSize: '20px', color: '#222' }}>4. Compartilhamento de Informações</h2>
        <p>
          O <strong>Sensor Delivery</strong> não vende nem repassa suas informações pessoais a terceiros para fins de marketing. Os dados de endereço e contato são compartilhados estritamente com os entregadores e estabelecimentos parceiros responsáveis pelo atendimento do seu pedido.
        </p>
      </section>

      <section style={{ marginTop: '24px' }}>
        <h2 style={{ fontSize: '20px', color: '#222' }}>5. Segurança e Armazenamento</h2>
        <p>
          Adotamos práticas e protocolos de segurança adequados para proteger seus dados contra acessos não autorizados, alteração, divulgação ou destruição indevida.
        </p>
      </section>

      <section style={{ marginTop: '24px' }}>
        <h2 style={{ fontSize: '20px', color: '#222' }}>6. Direitos do Usuário e Exclusão de Dados</h2>
        <p>
          Em conformidade com a LGPD (Lei Geral de Proteção de Dados), você tem o direito de solicitar a confirmação, acesso, correção ou exclusão definitiva dos seus dados cadastrais a qualquer momento.
        </p>
        <p>
          Para solicitar a exclusão de sua conta e dados, entre em contato conosco através do suporte informado abaixo.
        </p>
      </section>

      <section style={{ marginTop: '24px' }}>
        <h2 style={{ fontSize: '20px', color: '#222' }}>7. Contato e Suporte</h2>
        <p>Em caso de dúvidas sobre esta Política de Privacidade ou sobre o tratamento de seus dados, entre em contato conosco:</p>
        <p>
          <strong>E-mail de Contato:</strong> suporte@sensordelivery.com.br<br />
          <strong>Aplicativo:</strong> Sensor Delivery
        </p>
      </section>
    </div>
  );
}
