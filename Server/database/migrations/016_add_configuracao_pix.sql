ALTER TABLE loja_configuracao
    ADD COLUMN IF NOT EXISTS pix_chave VARCHAR(150),
    ADD COLUMN IF NOT EXISTS pix_nome_recebedor VARCHAR(25),
    ADD COLUMN IF NOT EXISTS pix_cidade_recebedor VARCHAR(15);
