ALTER TABLE loja_configuracao 
ADD COLUMN IF NOT EXISTS cancelar_rascunhos_antigos BOOLEAN NOT NULL DEFAULT TRUE;
