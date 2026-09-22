ALTER TABLE loja_configuracao 
ADD COLUMN IF NOT EXISTS data_ultimo_cleanup_rascunhos DATE;
